$DataPath = "$($ENV:APPDATA)\EndpointManager"

if (!(Test-Path -Path $DataPath)) {
    New-Item -ItemType Directory -Path $DataPath
}

Invoke-WebRequest -Uri "<URL to the data file>" `
                  -OutFile "$DataPath\data.json" `
                  -UseBasicParsing `
                  -ErrorAction SilentlyContinue

$inputxml = Get-Content '..\VSProject\Endpoint Manager\MainWindow.xaml' -Raw

$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
}
catch{
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | ForEach-Object{
    try {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}

Get-FormVariables

#===========================================================================
# Functions
#===========================================================================



#===========================================================================
# Use this space to add code to the various form elements in your GUI
#===========================================================================

$ComputerInfo = Get-ComputerInfo | Select-Object WindowsProductName, `
                                                 WindowsVersion, `
                                                 OsArchitecture, `
                                                 OsVersion, `
                                                 CsName, `
                                                 CsManufacturer, `
                                                 CsModel, `
                                                 CsWorkgroup, `
                                                 @{N="CsTotalPhysicalMemory"; E={"{0:N2} GB" -f ($_.CsTotalPhysicalMemory / 1GB)}}

$JsonFilePath = (Get-Item -Path "$DataPath\data.json").FullName

$Data = (Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json).data
$Version = (Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json).version

$WPFtxtHostInfo.Text=@"
Computer name: $($ComputerInfo.CsName)
Support telephone: <please select your country and location>
"@

$WPFtxtSysinfo.Text = @"
Support information:

Computer brand: $($ComputerInfo.CsManufacturer)
Computer model: $($ComputerInfo.CsModel)

Windows product: $($ComputerInfo.WindowsProductName)
Windows version: $($ComputerInfo.WindowsVersion)
Windows build version: $($ComputerInfo.OsVersion)
Windows architecture: $($ComputerInfo.OsArchitecture)

Workgroup: $($ComputerInfo.CsWorkGroup)

Physical Memory: $($ComputerInfo.CsTotalPhysicalMemory)

Using config file: $JsonFilePath
Config file version: $Version
"@

$WPFmnuExit.Add_Click({
    $Form.Close()
})

$WPFcmbCountry.add_SelectionChanged({

    # Fill locations, based on the country

    param($sender, $args)
    $Country = $sender.SelectedItem

    $Locations = ($Data | Where-Object {$_.Country -eq $Country}).Location

    $WPFcmbLocation.Items.Clear()

    foreach ($Location in $Locations) {
        $WPFcmbLocation.Items.Add($Location)
    }

    # Reset support number

    $WPFtxtHostInfo.Text=@"
Computer name: $($ComputerInfo.CsName)
Support telephone: <please select your country and location>
"@

})

$WPFcmbLocation.add_SelectionChanged({

    # Fill printers, based on the location

    $WPFlstPrinters.Items.Clear()
    $WPFlstDrives.Items.Clear()

    $Country = $WPFcmbCountry.SelectedItem
    $Location = $WPFcmbLocation.SelectedItem
    $Printers = ($Data | Where-Object {$_.Country -eq $Country -and $_.Location -eq $Location}).Printers

    foreach ($Printer in $Printers) {
        $WPFlstPrinters.Items.Add("$($Printer.DisplayName)")
    }

    # Fill network drives, based on the location

    $Drives = ($Data | Where-Object {$_.Country -eq $Country -and $_.Location -eq $Location}).Drives

    foreach ($Drive in $Drives) {
        $WPFlstDrives.Items.Add("$($Drive.DisplayName)")
    }

    # Set support number variable

    $Script:SupportNumber = (($Data | Where-Object {$_.Country -eq $Country -and $_.Location -eq $Location}).PhoneNumbers | Where-Object {$_.Name -eq "Service Desk"}).Number

    $WPFtxtHostInfo.Text=@"
Computer name: $($ComputerInfo.CsName)
Support telephone: $($Script:SupportNumber)
"@

})

$WPFbtnMap.Add_Click({

    $Country = $WPFcmbCountry.SelectedItem
    $Location = $WPFcmbLocation.SelectedItem
    $SelectedPrinter = $WPFlstPrinters.SelectedItem
    $Printer = ($Data | Where-Object {$_.Country -eq $Country -and $_.Location -eq $Location}).Printers | Where-Object {$_.DisplayName -eq $SelectedPrinter}
    
    if ($null -ne $Printer) {
        try {
            Add-Printer -ConnectionName "\\$($Printer.PrinterServer)\$($Printer.Name)" -ErrorAction Stop
            [System.Windows.MessageBox]::Show("Successfully added printer $($WPFlstPrinters.SelectedItem)", 'Printer added...', 'Ok')
        }
        catch {
            [System.Windows.MessageBox]::Show("Cannot connect to $($WPFlstPrinters.SelectedItem).`r`nPlease contact Service Desk.", 'Error', 'Ok', 'Error')
        }
    } else {
        [System.Windows.MessageBox]::Show('Please select a printer first', 'Warning', 'Ok', 'Warning')
    }

})

$WPFbtnMapDefault.Add_Click({

    $Country = $WPFcmbCountry.SelectedItem
    $Location = $WPFcmbLocation.SelectedItem
    $SelectedPrinter = $WPFlstPrinters.SelectedItem
    $Printer = ($Data | Where-Object {$_.Country -eq $Country -and $_.Location -eq $Location}).Printers | Where-Object {$_.DisplayName -eq $SelectedPrinter}

    if ($null -ne $Printer) {
        try {
            Add-Printer -ConnectionName "\\$($Printer.PrinterServer)\$($Printer.Name)" -ErrorAction Stop
            (New-Object -ComObject WScript.Network).SetDefaultPrinter("\\$($Printer.PrinterServer)\$($Printer.Name)")
            [System.Windows.MessageBox]::Show("Successfully added printer $($WPFlstPrinters.SelectedItem)`r`nIt is set as default printer", 'Printer added...', 'Ok')
        }
        catch {
            [System.Windows.MessageBox]::Show("Cannot connect to $($WPFlstPrinters.SelectedItem).`r`nPlease contact Service Desk.", 'Error', 'Ok', 'Error')
        }
    } else {
        [System.Windows.MessageBox]::Show('Please select a printer first', 'Warning', 'Ok', 'Warning')
    }

})

$WPFbtnDriveMap.Add_Click({

    $Country = $WPFcmbCountry.SelectedItem
    $Location = $WPFcmbLocation.SelectedItem
    $SelectedDrive = $WPFlstDrives.SelectedItem
    $Drive = ($Data | Where-Object {$_.Country -eq $Country -and $_.Location -eq $Location}).Drives | Where-Object {$_.DisplayName -eq $SelectedDrive}

    if ($null -ne (Get-PSDrive -Name $Drive.DriveLetter)) {
        try {
            Remove-PSDrive -Name $Drive.DriveLetter -ErrorAction Stop
        }
        catch {
            [System.Windows.MessageBox]::Show("Could not delete driveletter $($Drive.DriveLetter).`r`n`r`n$($Error[0])`r`n`r`nPlease contact Service Desk.", 'Error', 'Ok', 'Error')
        }
    }

    if ($null -ne $Drive) {
        try {
            New-PSDrive -Name $Drive.DriveLetter -Root $Drive.Path -PSProvider FileSystem -Persist -Scope Global -ErrorAction Stop
            [System.Windows.MessageBox]::Show("Successfully connected drive $($WPFlstDrives.SelectedItem)", 'Drive connected...', 'Ok')
        }
        catch {
            [System.Windows.MessageBox]::Show("Cannot connect to $($Drive.Path).`r`n`r`n$($Error[0])`r`n`r`nPlease contact Service Desk.", 'Error', 'Ok', 'Error')
        }
    } else {
        [System.Windows.MessageBox]::Show('Please select a drive first', 'Warning', 'Ok', 'Warning')
    }

})

foreach ($Country in ($Data.Country | Select-Object -Unique)) {
    
    $WPFcmbCountry.Items.Add($Country) | Out-Null
}

$Form.ShowDialog() | Out-Null