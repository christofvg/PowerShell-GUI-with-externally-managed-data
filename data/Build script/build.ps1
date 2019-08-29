# Convert JSON file to a PowerShell object (also acts as a test)

try {
    $JsonData = Get-Content -Path "$(System.DefaultWorkingDirectory)\data.json" -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
} 
catch {
    Write-Host "##VSO[task.logissue type=error]$($Error[0].Exception.Message)"
    Write-Host "##vso[task.complete result=Failed;]Error"
}

# Convert the version to a version object and update the version

[version]$Version = $JsonData.version

$JsonData.version = "$($Version.Major).$($Version.Minor).$(Build.BuildNumber)"

# Convert the object back to a JSON file

Set-Content -Path "$(System.DefaultWorkingDirectory)\data.json" -Value ($JsonData | ConvertTo-Json -Depth 5) -Force