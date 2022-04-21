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
    [string]$ESPName

    #Like above not mandatory incase user wants to write on console but with an addition, have an option to save to a file.
    # [Parameter()]
    # #Like above, do not want null or empty
    # [ValidateNotNullOrEmpty()]
    # #See if FO4Edit exists in the path the user provided for CLI.
    # [ValidateScript(
    #     {
    #         # if ([String]::IsNullOrEmpty($_)) {
    #         #     Write-Information -MessageData ($Messages.InvalidSetting -f "PathXEdit")
    #         #     (Get-Content -Path ".\Testing Previsibine.txt") | Where-Object { $_ -notmatch "PathXEdit" } | Set-Content -Path ".\Testing Previsibine.txt"
    #         #     $XEditCheck1 = Test-Path -Path (Get-XEdit)
    #         #     # $XEditCheck2 = Test-Path -Path (Get-XEditFile)
    #         #     if ($XEditCheck1) {
    #         #         return $true
    #         #     }
    #         # } else {
    #             if (Test-Path -Path $_\FO4Edit.exe) {
    #                 $true
    #             } else {
    #                 throw "Could not find FO4Edit with that file path provided."
    #             }
    #         # }
    #     }
    # )]
    # [Alias("XEdit", "FO4Edit")]
    # [string]$PathXEdit

    #May add more parameters, when I complete the script.
)
#Automatically looks for the FO4 installation path using Registry Keys

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
FO4ESP = Found the plugin at {0}. Beginning the precombine setup for {1}.
FO4Loc = Could not find Fallout 4's location using registry key. Please put in your Fallout 4 Directory here
FO4LocSettings = Could not find Fallout 4's location using the settings file. Please put in your Fallout 4 Directory here
FO4NoESP = Could not find the plugin in the Fallout 4/Data folder. Please put the plugin in the Data folder.
FoundDir = Found {0} with the directory provided.
InvalidSetting = Empty or null value found for {0} in the settings file.
LeftOff1 = Where did you leave off?
LeftOff2 = Precombines? [1]
LeftOff3 = PSG Compression? [2]
LeftOff4 = CSG Creation? [3]
LeftOff5 = or Previs Generation? [4]
NoCK = Could not find the Creation Kit in Fallout 4's directory.
NoCKNoFO4 = Could not find neither the Creation Kit or Fallout 4 through the Registry Keys.
NoESPExt = Please include the esp/esm extension.
NoESPName = Please put the file name after the extension.
NoESPValid = Not a valid file name.
NoF4CK = F4CK loader was not found, using the creation kit for all CLI actions.
NoFoundDir = Could not find {0} with the location provided.
NoMesh = Meshes were not generated from the CK, Aborting. Check your created plugin.
SettingsFound = Found {0} from settings file. Continuing.
SettingsLoad = Found a settings file, loading data from the file.
SettingsNotFound = Did not find {0} in the settings file.
SettingsQ = Would you like to create a settings file? This may save you time from inputting things again when running the script. [Y] or [N]
Startup = Did you start the powershell script previously? [Y] or [N] (Choose [N] if you did not create a settings file.)
WrongInput = Inputted a wrong value. Please choose a valid option.
WrongInputEnd = Incorrect Response, script is ending
XeditPath = Please input FO4Edit's directory.
XeditPathSetting = Could not find FO4Edit's location using the settings file. Please put in your FO4Edit's Directory here
'@
}

# Function MainFunction {
#     $script:FO4InstallPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\' -Name "installed path"
#     if (-not (Test-Path -Path ".\Testing Previsibine.txt")) {
#         $SettingsCreation = Read-Host -Prompt $Messages.SettingsQ
#         if ($SettingsCreation -eq "Y" -or $SettingsCreation -eq "Yes") {
#             Write-Information -MessageData $Messages.CreateSettings -InformationAction:Continue
#             Set-Content -Path ".\Testing Previsibine.txt" -Value '[Settings]'
#             If (Test-CK) {
#                 if ([string]::IsNullOrEmpty($PathXEdit)) {
#                     Set-XEdit -Settings $true
#                 } else {
#                     Add-Content -Path ".\Testing Previsibine.txt" -Value "PathXEdit = $PathXEdit"
#                 }
#                 if ([string]::IsNullOrEmpty($ESPName)) {
#                     Set-ESPExtension
#                 }
#                 Start-CK1 -ESP $script:ESPName
#             } else {
                
#             }
#         } elseif ($SettingsCreation -eq "N" -or $SettingsCreation -eq "No") {
#             If (Test-CK) {
#                 if ([string]::IsNullOrEmpty($PathXEdit)) {
#                     Set-XEdit
#                 }
#                 if ([string]::IsNullOrEmpty($ESPName)) {
#                     Set-ESPExtension
#                 }
#                 Start-CK1 -ESP $script:ESPName
#             } else {
                
#             }
#         } else {
#             Write-Error -Message $Messages.WrongInputEnd
#         }
#     } else {
#         Write-Information -MessageData $Messages.SettingsLoad -InformationAction:Continue
#         Read-File
#         If (Test-CK) {
#             Set-XEdit -File $true
#             Set-ESPExtension
#             Start-CK1 -ESP $script:ESPName
#         } else {

#         }
#     }
#     If (Test-CK) {
#         Set-XEdit
#         Set-ESPExtension
#         Start-CK1 -ESP $script:ESPName
#     } else {

#     }
# }

function Main {
    if (Test-File) {
        # $CKMain = Test-FO4CK
        # $XEditMain = Test-XEdit
        $CKTrial = Test-Path -Path (Get-CK)
        $XEditTrial = Test-Path -Path (Get-XEdit)
        if ($CKTrial -and $XEditTrial) {
            Write-Information -MessageData "My Brother" -InformationAction:Continue
            # Set-ESPExtension
        } elseif ($CKTrial) {
            Write-Information -MessageData "Found CK" -InformationAction:Continue
            if (Test-XEditFile) {
                # Set-ESPExtension
            }
        } elseif ($XEditTrial) {
            Write-Information -MessageData "Found Xedit" -InformationAction:Continue
            if (Test-FO4CK) {
                # Set-ESPExtension
            }
        } else {
            Write-Information -MessageData "neither" -InformationAction:Continue
            if ((Test-FO4CK) -and (Test-XEditFile)) {
                # Set-ESPExtension
            }
        }
        (Get-Content -Path ".\Testing Previsibine.txt") | Sort-Object | Set-Content -Path ".\Testing Previsibine.txt"
        # if ($CKMain -and $XEditMain) {
        #     Set-ESPExtension
        #     #Start-CK1
        # } elseif ($CKMain) {
        #     Write-Information -MessageData "Found CK but not Xedit" -InformationAction:Continue
        # } elseif ($XEditMain) {
        #     Write-Information -MessageData "Found XEdit but not CK" -InformationAction:Continue
        # } else {
        #     Write-Information -MessageData "Found neither CK or XEdit" -InformationAction:Continue
        # }
    } else {
        $SettingsCreation = Read-Host -Prompt $Messages.SettingsQ
        if ($SettingsCreation -eq "Y" -or $SettingsCreation -eq "Yes") {
            Write-Information -MessageData $Messages.CreateSettings -InformationAction:Continue
            $CKMain = Test-CK
            $XEditMain = Test-XEdit
            if ($CKMain -and $XEditMain) {
                Set-ESPExtension
                #Start-CK1
            }
            Write-File
        } elseif ($SettingsCreation -eq "N" -or $SettingsCreation -eq "No") {
            $CKMain = Test-CK
            $XEditMain = Test-XEdit
            if ($CKMain -and $XEditMain) {
                Set-ESPExtension
                #Start-CK1
            }
        } else {
            Write-Error -Message $Messages.WrongInputEnd
        }
    }
}

Function Test-File {
    if ($FileChecker = Test-Path -Path ".\Testing Previsibine.txt") {
        Read-File
        return $FileChecker
    }
}

Function Write-File {
    Set-Content -Path ".\Testing Previsibine.txt" -Value '[Settings]'
    Add-Content -Path ".\Testing Previsibine.txt" -Value "FO4InstallPath = $FO4InstallPath"
    Add-Content -Path ".\Testing Previsibine.txt" -Value "PathXEdit = $PathXEdit"
}

Function Read-File {
    $Words = @('[Settings]', 'FO4InstallPath', 'PathXEdit')
    (Get-Content -Path ".\Testing Previsibine.txt") | ForEach-Object {
        foreach ($Word in $Words) {
            if ($_.StartsWith($Word)) {
                $_
            }
        }
    }| Set-Content -Path ".\Testing Previsibine.txt"
    Get-Content -Path ".\Testing Previsibine.txt" | ForEach-Object {
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
            if (Test-f4ck) {
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
}

Function Start-CK1 {
    param (
        [string]$ESP
    )
    if (Test-f4ck) {
        Start-Process -FilePath $FO4InstallPath\f4ck_loader.exe -Wait -ArgumentList "-GeneratePrecombined:""$ESP"" clean all"
        if ($ESP.EndsWith(".esp")) {
            $ESPSplit = $ESP.Replace(".esp", "")
        } elseif ($ESP.EndsWith(".esm")) {
            $ESPSplit = $ESP.Replace(".esm", "")
        }
        #Write-Information -MessageData $ESPSplit -InformationAction:Continue
        Start-Archive1 -ESP $ESPSplit
    } else {
        Start-Process -FilePath $FO4InstallPath\CreationKit.exe -Wait -ArgumentList "-GeneratePrecombined:""$ESP"" clean all"
        if ($ESP.EndsWith(".esp")) {
            $ESPSplit = $ESP.Replace(".esp", "")
        } elseif ($ESP.EndsWith(".esm")) {
            $ESPSplit = $ESP.Replace(".esm", "")
        }
        #Write-Information -MessageData $ESPSplit -InformationAction:Continue
        Start-Archive1 -ESP $ESPSplit
    }  
}

function Start-Archive1 {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ESP
    )
    if ([bool](Get-ChildItem -Recurse | Where-Object Name -Like "*.nif")) {
        Write-Information -MessageData $Messages.ArchiveMesh -InformationAction:Continue
        Start-Process -FilePath "$FO4InstallPath\Tools\Archive2\Archive2.exe" -Wait -ArgumentList """$FO4InstallPath\Data\Meshes"" -c=""$FO4InstallPath\Data\$ESP - Main.ba2"""
    } else {
        Write-Error -Message $Messages.NoMesh
    }
}

Function Set-ESPExtension {
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
        $ESPMessage = $Messages.FO4ESP -f ($FO4InstallPath + "Data\"), $ESPName
        Write-Information -MessageData $ESPMessage -InformationAction:Continue
    } else {
        Write-Error -Message $Messages.FO4NoESP
    }
}

Function Test-f4ck {
    if (Test-Path -Path $FO4InstallPath\f4ck_loader.exe) {
        Write-Information -MessageData $Messages.F4CK -InformationAction:Continue
        return $true
    } else {
        Write-Information -MessageData $Messages.NoF4CK -InformationAction:Continue
        return $false
    }
}

Function Test-FO4CK {
    if ([String]::IsNullOrEmpty($FO4InstallPath)) {
        Write-Information -MessageData ($Messages.InvalidSetting -f "FO4InstallPath")
        Edit-FO4CK
        $FO4InstallCheck1 = Test-Path -Path (Get-CK)
        # $FO4InstallCheck2 = Test-Path -Path (Get-FO4CK)
        if ($FO4InstallCheck1) {
            return $true
        }
    } else {
        $CKFileCheck = Test-Path -Path (Get-CK)
        $FO4FileCheck = Test-Path -Path (Get-FO4)
        if ($CKFileCheck -and $FO4FileCheck) {
            Write-Information -MessageData ($Messages.FoundDir -f "CreationKit.exe") -InformationAction:Continue
            return $true
        } else {
            Edit-FO4CK
            $FO4InstallCheck1 = Test-Path -Path (Get-CK)
            $FO4InstallCheck2 = Test-Path -Path (Get-FO4CK)
            if ($FO4InstallCheck1 -or $FO4InstallCheck2) {
                return $true
            }
        }
    }
}

Function Edit-FO4CK {
    if ([string]::IsNullOrEmpty($FO4InstallPath)) {
        (Get-Content -Path ".\Testing Previsibine.txt") | Where-Object { $_ -notmatch "FO4InstallPath" } | Set-Content -Path ".\Testing Previsibine.txt"
        if (Test-CK) {
            Add-Content -Path ".\Testing Previsibine.txt" -Value "FO4InstallPath = $FO4InstallPath"
        }
    } else {
        # $FileCheck = Get-CK
        if (Test-Path -Path (Get-CK)) {
            Write-Information -MessageData ($Messages.FoundDir -f "CreationKit.exe") -InformationAction:Continue
        } else {
            $one = "FO4InstallPath = $FO4InstallPath"        
            do {
                Set-FO4CK
                if ($FO4InstallCheck = Test-Path -Path $FO4Exe2) {
                    Write-Information -MessageData ($Messages.FoundDir -f "Fallout4.exe") -InformationAction:Continue
                    # $CKPath = Get-FO4CK
                    if (Test-Path -Path (Get-FO4CK)) {
                        Write-Information -MessageData $Messages.CKFound -InformationAction:Continue
                        $two = "FO4InstallPath = $FO4InstallPath2"
                        (Get-Content -Path ".\Testing Previsibine.txt").Replace($one, $two) | Set-Content -Path ".\Testing Previsibine.txt"
                    } else {
                        Write-Error -Message $Messages.NoCK
                    }
                } else {
                    Write-Warning -Message ($Messages.NoFoundDir -f "Fallout4.exe")
                }
            } until ($FO4InstallCheck)
        }
    }
}

Function Get-FO4CK {
    if ($FO4InstallPath2.EndsWith("\")) {
        $CKExe2 = $FO4InstallPath2 + "CreationKit.exe"
        return $CKExe2
    } else {
        $CKExe2 = $FO4InstallPath2 + "\CreationKit.exe"
        return $CKExe2
    }
}

Function Set-FO4CK {
    $script:FO4InstallPath2 = Read-Host -Prompt $Messages.FO4LocSettings
    $script:FO4Exe2 = $FO4InstallPath2 + "\Fallout4.exe"
}

# Function Set-CK {
#     $script:FO4InstallPath = Read-Host -Prompt $Messages.FO4Loc
#     Write-Information -MessageData $FO4InstallPath -InformationAction:Continue
#     $script:CKPath = $script:FO4InstallPath + "\CreationKit.exe"
#     Write-Information -MessageData $CKPath -InformationAction:Continue
# }

# Function Set-CK {
#     [CmdletBinding()]
#     param (
#         [Parameter()]
#         [bool]$Settings = $false
#     )
#     do {
#         $script:FO4InstallPath = Read-Host -Prompt $Messages.FO4Loc
#         if ($FO4InstallCheck = Test-Path -Path $FO4InstallPath\Fallout4.exe) {
#             Write-Information -MessageData ($Messages.FoundDir -f "Fallout4.exe") -InformationAction:Continue
#             if (Test-Path -Path $FO4InstallPath\CreationKit.exe) {
#                 Write-Information -MessageData $Messages.CKFound -InformationAction:Continue
#             } else {
#                 Write-Error -Message $Messages.NoCK
#             }
#         } else {
#             Write-Information -MessageData ($Messages.NoFoundDir -f "Fallout4.exe") -InformationAction:Continue
#         }
#     } until($FO4InstallCheck)
#     if ($Settings) {
#         Add-Content -Path ".\Testing Previsibine.txt" -Value "FO4InstallPath = $FO4InstallPath"
#     }
# }

Function Test-CK {
    # [CmdletBinding()]
    # param (
    #     [Parameter()]
    #     [bool]$Settings = $false
    # )
    Write-Information -MessageData $Messages.CheckCK -InformationAction:Continue
    if (Test-FO4) {
        # $CKPath = Get-CK
        if ($TestCKLoc = Test-Path -Path (Get-CK)) {
            Write-Information -MessageData $Messages.CKFound -InformationAction:Continue
            return $TestCKLoc
        } else {
            Write-Error -Message $Messages.NoCK
        }
    }
}

Function Get-CK {
    #$script:FO4InstallPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\' -Name "installed path"
    #Write-Information -MessageData $FO4InstallPath -InformationAction:Continue
    if ($FO4InstallPath.EndsWith("\")) {
        $CK = $FO4InstallPath + "CreationKit.exe"
        return $CK
    } else {
        $CK = $FO4InstallPath + "\CreationKit.exe"
        return $CK
    }
}

Function Test-FO4 {
    if (Test-Path -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\') {
        $script:FO4InstallPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\' -Name "installed path"
        # $FO4Exe = Get-FO4
        if ($FO4InstallCheck = Test-Path -Path (Get-FO4)) {
            Write-Information -MessageData ($Messages.FoundDir -f "Fallout4.exe") -InformationAction:Continue
            return $FO4InstallCheck
        }
    } else {
        do {
            Set-FO4
            if ($FO4InstallCheck = Test-Path -Path $FO4) {
                Write-Information -MessageData ($Messages.FoundDir -f "Fallout4.exe") -InformationAction:Continue
                return $FO4InstallCheck
            } else {
                Write-Warning -MessageData ($Messages.NoFoundDir -f "Fallout4.exe")
            }
        } until($FO4InstallCheck)
    }
}

Function Get-FO4 {
    if ($FO4InstallPath.EndsWith("\")) {
        $FO4 = $FO4InstallPath + "Fallout4.exe"
        return $FO4
    } else {
        $FO4 = $FO4InstallPath + "\Fallout4.exe"
        return $FO4
    }
}

Function Set-FO4 {
    $script:FO4InstallPath = Read-Host -Prompt $Messages.FO4Loc
    $script:FO4 = $FO4InstallPath + "\Fallout4.exe"
}

# Function Set-XEdit {
#     [CmdletBinding()]
#     param (
#         # [Parameter()]
#         # [bool]$Settings = $false,

#         [Parameter()]
#         [bool]$File = $false
#     )
#     if ($File) {
#         $one = "PathXEdit = $PathXEdit"
#         if ($PathXEditCheck = Test-Path -Path $PathXEdit\FO4Edit.exe) {
#             Write-Information -MessageData ($Messages.SettingsFound -f "FO4Edit.exe") -InformationAction:Continue
#         } else {
#             Write-Information -MessageData ($Messages.SettingsNotFound -f "FO4Edit.exe") -InformationAction:Continue
#             do {
#                 $script:PathXEdit2 = Read-Host -Prompt $Messages.XeditPath
#                 if ($PathXEditCheck = Test-Path -Path $PathXEdit2\FO4Edit.exe) {
#                     Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
#                 } else {
#                     Write-Warning -Message ($Messages.NoFoundDir -f "FO4Edit.exe") -WarningAction:Inquire
#                 }
#             } until ($PathXEditCheck)
#             $two = "PathXEdit = $PathXEdit2"
#             (Get-Content -Path ".\Testing Previsibine.txt").Replace($one, $two) | Set-Content -Path ".\Testing Previsibine.txt"
#         }
#     } else {
#         do {
#             $script:PathXEdit = Read-Host -Prompt $Messages.XeditPath
#             if ($PathXEditCheck = Test-Path -Path $PathXEdit\FO4Edit.exe) {
#                 Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
#             } else {
#                 Write-Warning -Message ($Messages.NoFoundDir -f "FO4Edit.exe") -WarningAction:Inquire
#             }
#         } until ($PathXEditCheck)
#         # if ($Settings) {
#         #     Add-Content -Path ".\Testing Previsibine.txt" -Value "PathXEdit = $PathXEdit"
#         # }
#     }
# }

Function Test-XEditFile {
    if ([String]::IsNullOrEmpty($PathXEdit)) {
        Write-Information -MessageData ($Messages.InvalidSetting -f "PathXEdit")
        Edit-XEditFile
        $XEditCheck1 = Test-Path -Path (Get-XEdit)
        # $XEditCheck2 = Test-Path -Path (Get-XEditFile)
        if ($XEditCheck1) {
            return $true
        }
    } else {
        $XEditFileCheck = Test-Path -Path (Get-XEdit)
        if ($XEditFileCheck) {
            Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
            return $true
        } else {
            Edit-XEditFile
            $XEditCheck1 = Test-Path -Path (Get-XEdit)
            $XEditCheck2 = Test-Path -Path (Get-XEditFile)
            if ($XEditCheck1 -or $XEditCheck2) {
                return $true
            }
        }
    }
}

Function Edit-XEditFile {
    if ([string]::IsNullOrEmpty($PathXEdit)) {
        (Get-Content -Path ".\Testing Previsibine.txt") | Where-Object { $_ -notmatch "PathXEdit" } | Set-Content -Path ".\Testing Previsibine.txt"
        # $XEditTesting = Test-XEdit
        if (Test-XEdit) {
            Add-Content -Path ".\Testing Previsibine.txt" -Value "PathXEdit = $PathXEdit"
        }
    } else {
        # $FileCheck = Get-CK
        if (Test-Path -Path (Get-XEdit)) {
            Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
        } else {
            $one = "PathXEdit = $PathXEdit"        
            do {
                Set-XEditFile
                if ($XEditCheck = Test-Path -Path $XEditExe2) {
                    Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
                    $two = "PathXEdit = $PathXEdit2"
                    (Get-Content -Path ".\Testing Previsibine.txt").Replace($one, $two) | Set-Content -Path ".\Testing Previsibine.txt"
                } else {
                    Write-Warning -Message ($Messages.NoFoundDir -f "FO4Edit.exe")
                }
            } until ($XEditCheck)
        }
    }
}

Function Get-XEditFile {
    if ($PathXEdit2.EndsWith("\")) {
        $XEditExe2 = $PathXEdit2 + "FO4Edit.exe"
        return $XEditExe2
    } else {
        $XEditExe2 = $PathXEdit2 + "\FO4Edit.exe"
        return $XEditExe2
    }
}

Function Set-XEditFile {
    $script:PathXEdit2 = Read-Host -Prompt $Messages.XeditPathSetting
    $script:XEditExe2 = $PathXEdit2 + "\FO4Edit.exe"
}

Function Test-XEdit {
    # $XPathEdit = Get-xEdit
    if ($PathXEditCheck = Test-Path -Path (Get-XEdit)) {
        Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
        return $PathXEditCheck
    } else {
        do {
            Set-XEdit
            if ($PathXEditCheck = Test-Path -Path $XEdit) {
                Write-Information -MessageData ($Messages.FoundDir -f "FO4Edit.exe") -InformationAction:Continue
                return $PathXEditCheck
            } else {
                Write-Warning -Message ($Messages.NoFoundDir -f "FO4Edit.exe") -WarningAction:Inquire
            }
        } until ($PathXEditCheck)
    }
}

Function Get-XEdit {
    $XEdit = $PathXEdit + "\FO4Edit.exe"
    return $XEdit
}

Function Set-XEdit {
    $script:PathXEdit = Read-Host -Prompt $Messages.XeditPath
    $script:XEdit = $PathXEdit + "\FO4Edit.exe"
}

#MainFunction
$Disclaimer
#Set-ESPExtension

#Test-CK
Main
#(Get-Content -Path ".\Testing Previsibine.txt") | Sort-Object | Set-Content -Path ".\Testing Previsibine.txt"
# Read-File
# Test-FO4CK
