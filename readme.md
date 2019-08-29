# PowerShell GUI with externally managed data

## Introduction

This code supports my blog post about "[PowerShell GUI scripts with externally managed data](https://www.christofvg.be/2019/08/25/PowerShell-GUI-with-externally-managed-data/)".

## Folder structure

Since GitHub doesn't support the same layout as Azure DevOps, I created a folder layout that separates the different parts of the application.

### GUI

This folder contains the code of the PowerShell GUI script. It also contains a folder with a build script that converts the PowerShell code to an executable. This code is out of scope of the post, but will be described in a following post.

The Application directory contains following directories:

* bin: The PowerShell GUI script
* VSProject: The Visual Studio solution, containing the WPF project with the XAML code for the PowerShell GUI script

### data

This folder contains the data file, used as external data for the PowerShell GUI script. Obviously, this should be in a separate repository in your Azure DevOps project to separate it from the code. But since this is not possible in GitHub, I added it to a different folder.

The Build script contains the code that is used during build to update the version in the JSON file.

## Call-to-action!

Please reach out on Twitter [@cvangeendert](https://twitter.com/cvangeendert) to leave any comments about my approach! I would really appreciate suggestions :-)