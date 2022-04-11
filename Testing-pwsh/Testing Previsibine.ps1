#Min Powershell version.
#Requires -Version 7.0
#Parameter blocks to add arguments for the script in case user doesn't want to write on console.
<#
    .SYNOPSIS
        The goal of the script is to automate certain processes of generating previsibine (precombine + previs) using the clean method.
    .DESCRIPTION
        The script automates processes which have command line arguments for generating previsibine (precombine + previs) using the clean method.
        Due to the nature of generating with the clean method, this script will be running almost none stop.
        However, I have inputted Stops if the user wishes to stop at a certain process or function, they will be able to continue the process or function of where they left off.
        The script first tries to find the Fallout 4 path using registry keys, if the registry exists then the script continues. 
        However, if the registry key was not found the user would have to tell the script where Fallout4.exe is located, it's directory.
        The parameters of the script are not mandatory, they were meant to be replacements for writing in the console.
        The variables can be stored in a text file for future usages of the script on another plugin.
    .PARAMETER $ESPName
        The User will input a valid file name of the ESP/ESM and checks if the ESP/ESM that they inputted exists in the Fallout 4\Data folder.
    .PARAMETER $PathXEdit
        The User will input a valid directory to their FO4Edit.exe's location
#>
[CmdletBinding()]
param (
    #Not Mandatory on purpose, user should not be forced to run script with arguments when user input is available in console.
    [Parameter()]
    #Since this is a string input, should not be null or empty.
    [ValidateNotNullOrEmpty()]
    <#
        Checks to see if there are any invalid characters in the file name, 
        if the .esp/.esm extension is in the file, 
        and there is a name for the .esp/.esm
    #>
    [ValidateScript(
        {
            if ($_.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1) {
                if (-not $_.Equals(".esp") -and -not $_.Equals(".esm")) {
                    if ($_.EndsWith(".esp") -or $_.EndsWith(".esm")) {
                        $FO4InstallPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\' -Name "installed path"
                        if (Test-Path -Path $FO4InstallPath\Data\$_) {
                            $true
                        } else {
                            throw "Could not find the plugin in the Data folder."
                        }
                    } else {
                        throw "Please include the .esp or .esm extension."
                    }
                } else {
                    throw "Insert a name for the esp/esm extension."
                }
            } else {
                throw "Not a valid file name."
            }
        }
    )]
    [Alias("ESP", "ESM")]
    [string[]]
    $ESPName,

    #Like above not mandatory incase user wants to write on console but with an addition, have an option to save to a file.
    [Parameter()]
    #Like above, do not want null or empty
    [ValidateNotNullOrEmpty()]
    #See if FO4Edit exists in the path the user provided for CLI.
    [ValidateScript(
        { 
            if (Test-Path -Path $_\FO4Edit.exe) {
                $true
            } else {
                throw "Could not find FO4Edit with that file path provided."
            }
        }
    )]
    [Alias("XEdit", "FO4Edit")]
    [string[]]
    $PathXEdit

    #May add more parameters, when I complete the script.
)
#Automatically looks for the FO4 installation path using Registry Keys
$FO4InstallPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\' -Name "installed path"

$Disclaimer = DATA {
    "Insert MIT license here."
}

$Messages = DATA {
    ConvertFrom-StringData -StringData @'
    ArchiveMesh = Packing the meshes to an archive.
    CKFound = Found the Creation Kit in the same directory as Fallout4.exe.
    CheckCK = Checking to make sure the CK is in FO4's root directory.
    CreateSettings = Creating the setting file for future use.
    ESPCK = You chose to use the CK, running the CK now. Please save the CombinedObjects.esp in the CK then close the CK.
    ESPCKXEdit = Would you want to open the Creation Kit [1] or FO4Edit [2] to copy the contents of the CombinedObjects.esp to your plugin?
    ESPWork = Type the name of your esp file.
    ESPXEdit = You chose to use FO4Edit, running FO4Edit now. Please use Searge's 03_MergeCombinedObjects xedit script to your plugin.
    F4CK = Found the F4CK loader, will be using that instead.
    FO4Loc = Could not find Fallout 4's location using registry key. Please put in your Fallout 4 Directory here.
    FO4ESP = Found the plugin at {0}. Beginning the precombine setup for {1}.
    FO4NoESP = Could not find the plugin in the Fallout 4/Data folder. Please put the plugin in the Data folder.
    FoundDir = Found {0} with the directory provided.
    LeftOff1 = Where did you leave off?
    LeftOff2 = Precombines? [1]
    LeftOff3 = PSG Compression? [2]
    LeftOff4 = CSG Creation? [3]
    LeftOff5 = or Previs Generation? [4]
    NoCK = Could not find the Creation Kit in Fallout 4's directory.
    NoESPExt = Please include the esp/esm extension.
    NoESPName = Please put the file name after the extension.
    NoESPValid = Not a valid file name.
    NoF4CK = F4CK loader was not found, using the creation kit for all CLI actions.
    NoFoundDir = Could not find {0} with the location provided.
    NoMesh = Meshes were not generated from the CK, Aborting. Check your created plugin.
    NoXEdit = Could not find FO4Edit.exe with the location provided.
    SettingsLoad = Found a settings file, loading data from the file.
    SettingsQ = Would you like to create a settings file? This may save you time from inputting things again when running the script. [Y] or [N]
    Startup = Did you start the powershell script previously? [Y] or [N]
    WrongInput = Inputted a wrong value. Please choose a valid option.
    WrongInputEnd = Incorrect Response, script is ending
    XeditPath = Please input FO4Edit's directory.
'@
}

Function MainFunction {
    <#
    $Startup = Read-Host -Prompt $Messages.Startup
    if ($Startup -eq "Y" -or $Startup -eq "yes") {
        $NoobLoop = $false
        do {
            $LeftOff = Read-Host -Prompt ($Messages.LeftOff1 + "`n" + $Messages.LeftOff2 + "`n" + $Messages.LeftOff3 + "`n" + $Messages.LeftOff4 + "`n" + $Messages.LeftOff5 + "`n")
            if ($LeftOff -eq "1") {
                $NoobLoop = $True

            } elseif ($LeftOff -eq "2") {
                $NoobLoop = $True
            } elseif ($LeftOff -eq "3") {
                $NoobLoop = $True
            } elseif ($LeftOff -eq "4") {
                $NoobLoop = $True
            } else {
                Write-Information -MessageData $Messages.WrongInput
            }
        } until ($NoobLoop)
    } elseif ($Startup -eq "N" -or $Startup -eq "No") {
        If (Get-CK) {
            Get-xEdit
            Get-ESPExtension
            CK1($script:ESPName)
        } else {
            Set-CK
            Get-xEdit
            Get-ESPExtension
            CK1($script:ESPName)
        }
    } else {
        Write-Information -MessageData $Messages.WrongInput
    }
    #>
    if (-not (Test-Path -Path ".\Testing Precombines.txt")) {
        $SettingsCreation = Read-Host -Prompt $Messages.SettingsQ
        if ($SettingsCreation -eq "Y" -or $SettingsCreation -eq "Yes") {
            Write-Information -MessageData $Messages.CreateSettings -InformationAction:Continue
            Set-Content -Path ".\Testing-Precombines.txt" -Value '[Settings]'
            If (Get-CK) {
                if ([string]::IsNullOrEmpty($PathXEdit)) {
                    Set-xEdit -Settings $true
                } else {
                    Add-Content -Path ".\Testing-Precombines.txt" -Value "PathXEdit = $PathXEdit"
                }
                if ([string]::IsNullOrEmpty($ESPName)) {
                    Get-ESPExtension
                }
                CK1 -ESP $script:ESPName
            } else {
                Set-CK -Settings $true
                Set-xEdit -Settings $true
                Get-ESPExtension
                CK1 -ESP $script:ESPName
            }
        } elseif ($SettingsCreation -eq "N" -or $SettingsCreation -eq "No") {
            If (Get-CK) {
                Set-xEdit
                Get-ESPExtension
                CK1 -ESP $script:ESPName
            } else {
                Set-CK
                Set-xEdit
                Get-ESPExtension
                CK1 -ESP $script:ESPName
            }
        } else {
            Write-Error -Message $Messages.WrongInputEnd
        }
    } else {
        Write-Information -MessageData $Messages.SettingsLoad -InformationAction:Continue
        Read-File
    }
    If (Get-CK) {
        Set-xEdit
        Get-ESPExtension
        CK1 -ESP $script:ESPName
    } else {
        Set-CK
        Set-xEdit
        Get-ESPExtension
        CK1 -ESP $script:ESPName
    }
}

Function Read-File {
    Get-Content -Path ".\Testing-Precombines.txt" | ForEach-Object {
        $var = $_ -split ' = '
        Set-Variable -Name $var[0] -Value $var[1] -Scope:Script
    }
}

<#
    .SYNOPSIS
        The Save-ESP1 function provides the user a choice on whether to save the data in the Precombined.esp to their plugin.
        Once the User made their choice, the program will open. After the user is done saving the info from the Precombined.esp to their plugin, the function ends.
    .DESCRIPTION
    The Save-ESP1 function takes the variables $PathXEdit and $FO4InstallPath and has the user choose an option on how to save their Precombined
#>
Function Save-ESP1 {
    param {
        [string]$XEdit
        [string]$FO4Install
    }
    [bool]$CaseManager = $false
    do {
        $ChoicesNum = Read-Host -Prompt $Messages.ESPCKXEdit
        if ($ChoicesNum -eq "1") {
            Write-Information -MessageData $Messages.ESPCK -InformationAction:Continue
            if (Get-f4ck) {
                Start-Process -FilePath "$FO4Install\f4ck_loader.exe" -Wait
            } else {
                Start-Process -FilePath "$FO4Install\CreationKit.exe" -Wait
            }
            $CaseManager = $true
        } elseif ($ChoicesNum -eq "2") {
            Write-Information -MessageData $Messages.ESPXEdit
            Start-Process -FilePath "$XEdit\FO4Edit.exe" -Wait -ArgumentList "-quickedit:$ESPName"
            $CaseManager = $true
        } else {
            Write-Information -MessageData $Messages.WrongInput -InformationAction:Continue
        }
    } until ($CaseManager)
    do {
        $Decision1 = Read-Host -Prompt "Type [Y] if you wish to continue."
        if ($Decision1 -eq "Y") {
            
        }
    } until (condition)
}

Function CK1 {
    param (
        [string]$ESP
    )
    if (Get-f4ck) {
        Start-Process -FilePath $FO4InstallPath\f4ck_loader.exe -Wait -ArgumentList "-GeneratePrecombined:""$ESP"" clean all"
        if ($ESP.EndsWith(".esp")) {
            $ESPSplit = $ESP.Replace(".esp", "")
        } elseif ($ESP.EndsWith(".esm")) {
            $ESPSplit = $ESP.Replace(".esm", "")
        }
        #Write-Information -MessageData $ESPSplit -InformationAction:Continue
        ArchiveInit($ESPSplit)
    } else {
        Start-Process -FilePath $FO4InstallPath\CreationKit.exe -Wait -ArgumentList "-GeneratePrecombined:""$ESP"" clean all"
        if ($ESP.EndsWith(".esp")) {
            $ESPSplit = $ESP.Replace(".esp", "")
        } elseif ($ESP.EndsWith(".esm")) {
            $ESPSplit = $ESP.Replace(".esm", "")
        }
        #Write-Information -MessageData $ESPSplit -InformationAction:Continue
        ArchiveInit($ESPSplit)
    }  
}

function ArchiveInit {
    param (
        [string]$ESP
    )
    if ([bool](Get-ChildItem -Recurse | Where-Object Name -Like "*.nif")) {
        Write-Information -MessageData $Messages.ArchiveMesh -InformationAction:Continue
        Start-Process -FilePath "$FO4InstallPath\Tools\Archive2\Archive2.exe" -Wait -ArgumentList """$FO4InstallPath\Data\Meshes"" -c=""$FO4InstallPath\Data\$ESP - Main.ba2"""
    } else {
        Write-Error -Message $Messages.NoMesh
    }
}

Function Get-CK {
    Write-Information -MessageData $Messages.CheckCK -InformationAction:Continue
    if ($TestCKLoc = Test-Path -Path $FO4InstallPath\CreationKit.exe) {
        return $TestCKLoc
    } else {
        Write-Information -MessageData $Messages.NoCK -InformationAction:Continue
        return 0
    }
}

Function Set-CK {
    [CmdletBinding()]
    param (
        [Parameter()]
        [bool]$Settings = $false
    )
    do {
        $script:FO4InstallPath = Read-Host -Prompt $Messages.FO4Loc
        if ($FO4InstallCheck = Test-Path -Path $FO4InstallPath\Fallout4.exe) {
            Write-Information -MessageData ($Messages.FoundDir -f "Fallout4.exe") -InformationAction:Continue
            if (Test-Path -Path $FO4InstallPath\CreationKit.exe) {
                Write-Information -MessageData $Messages.CKFound -InformationAction:Continue
            } else {
                Write-Error -Message $Messages.NoCK
            }
        } else {
            Write-Information -MessageData ($Messages.NoFoundDir -f "Fallout4.exe") -InformationAction:Continue
        }
    } until($FO4InstallCheck)
    if ($Settings) {
        Add-Content -Path ".\Testing-Precombines.txt" -Value "PathCK = $FO4InstallPath"
    }
}

Function Get-f4ck {
    if (Test-Path -Path $FO4InstallPath\f4ck_loader.exe) {
        Write-Information -MessageData $Messages.F4CK -InformationAction:Continue
        return 1
    } else {
        Write-Information -MessageData $Messages.NoF4CK -InformationAction:Continue
        return 0
    }
}

Function Get-ESPExtension {
    [bool]$Complications = $false
    do {
        $script:ESPName = Read-Host -Prompt $Messages.ESPWork
        if ($ESPName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1) {
            if (-not $ESPName.Equals(".esp") -and -not $ESPName.Equals(".esm")) {
                if ($ESPName.EndsWith(".esp") -or $ESPName.EndsWith(".esm")) {
                    $Complications = $true
                } else {
                    Write-Information -MessageData $Messages.NoESPExt -InformationAction:Continue
                }
            } else {
                Write-Information -MessageData $Messages.NoESPName -InformationAction:Continue
            }
        } else {
            Write-Information -MessageData $Messages.NoESPValid -InformationAction:Continue
        }
    } until ($Complications)
    if (Test-Path -Path "$FO4InstallPath\Data\$ESPName") {
        Write-Information -MessageData ($Messages.FO4ESP -f ($FO4InstallPath + "Data\"), $ESPName) -InformationAction:Continue
    } else {
        Write-Error -Message $Messages.FO4NoESP
    }
}

Function Set-xEdit {
    [CmdletBinding()]
    param (
        [Parameter()]
        [bool]$Settings = $false
    )
    do {
        $script:PathXEdit = Read-Host -Prompt $Messages.XeditPath
        if ($PathXEditCheck = Test-Path -Path $PathXEdit\FO4Edit.exe) {
            Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
        } else {
            Write-Information -MessageData ($Messages.NoFoundDir -f "FO4Edit.exe") -InformationAction:Inquire
        }
    } until ($PathXEditCheck)
    if ($Settings) {
        Add-Content -Path ".\Testing-Precombines.txt" -Value "PathXEdit = $PathXEdit"
    }
}

#MainFunction
$Disclaimer
#Get-ESPExtension
