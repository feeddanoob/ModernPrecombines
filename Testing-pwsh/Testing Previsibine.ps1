#Min Powershell version.
#Requires -Version 7.0
#Parameter blocks to add arguments for the script in case user doesn't want to write on console.
[CmdletBinding()]
param (
    #Not Mandatory on purpose, user should not be forced to run script with arguments when user input is available in console.
    [Parameter()]
    #Since this is a string input, should not be null or empty.
    [ValidateNotNullOrEmpty()]
    #Grouped up conditions
    [ValidateScript(
        {
            #If there are invalid characters such as '<', '>', and '*' in the file name stop and throw the exception
            if ($_.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1) {
                #If the name is just .esp return false and throw the exception
                if (-not $_.Equals(".esp") -and -not $_.Equals(".esm")) {
                    #Make sure the file name ends with a .esp or .esm extension. Not including .esl's because I am 100% not sure how the CK reacts to it.
                    if ($_.EndsWith(".esp") -or $_.EndsWith(".esm")) {
                        $true
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
    #[ValidateScript({($_.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1) -and (-not $_.Equals(".esp") -and -not $_.Equals(".esm")) -and ($_.EndsWith(".esp") -or $_.EndsWith(".esm"))})]
    [Alias("ESP", "ESM")]
    [string[]]
    $ESPName,

    #Like above not mandatory incase user wants to write on console but with an addition, have an option to save to a file.
    [Parameter()]
    #Like above, do not want null or empty
    [ValidateNotNullOrEmpty()]
    #See if the File exists in the path the user provided.
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
)
#Automatically looks for the FO4 installation path using Registry Keys
$FO4InstallPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\' -Name "installed path"

$MessageXEditPath = "Please put in your FO4Edit folder path here"

$MessageNoESP = "Please include the .esp or .esm extension"

$MessageInsert = "Insert a valid name for the esp/esm"

#$MessageMovingToFO4 = "Moving to the FO4 Directory"

#$MessageCK = "Checking to make sure the CK is in the FO4 root directory"

#$MessageFO4location = "Please put in your Fallout 4 Directory here"

$Disclaimer = DATA {
    "Insert MIT license here."
}

$Messages = DATA {
    ConvertFrom-StringData -StringData @'
    ESPNamePrecombine = Beginning the Precombine Setup for {0}.
    Startup = Did you start the powershell script previously? [Y] or [N]
    LeftOff1 = Where did you leave off?
    LeftOff2 = Precombines? [1]
    LeftOff3 = PSG Compression? [2]
    LeftOff4 = CSG Creation? [3]
    LeftOff5 = or Previs Generation? [4]
    WrongInput = Inputted a wrong value. Please choose a valid option.
    WrongInputEnd = Incorrect Response, script is ending
    ESPCKXEdit = Would you want to open the Creation Kit [1] or FO4Edit [2] to copy the contents of the CombinedObjects.esp to your plugin?
    ESPCK = You chose to use the CK, running the CK now. Please save the CombinedObjects.esp in the CK then close the CK.
    ESPXEdit = You chose to use FO4Edit, running FO4Edit now. Please use Searge's 03_MergeCombinedObjects xedit script to your plugin.
    ArchiveMesh = Packing the meshes to an archive.
    NoMesh = Meshes were not generated from the CK, Aborting.
    CheckCK = Checking to make sure the CK is in FO4's root directory.
    NoCK = Could not find the Creation Kit in Fallout 4's directory.
    FO4Loc = Could not find Fallout 4's location using registry key. Please put in your Fallout 4 Directory here.
    FO4Found = Found Fallout4.exe with the directory provided.
    CKFound = Found the Creation Kit in the same directory as Fallout4.exe.
    NOFO4 = Could not find Fallout4.exe with the location provided.
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
    If (Get-CK) {
        Get-xEdit
        Get-ESPExtension
        #CK1($script:ESPName)
    } else {
        Set-CK
        Get-xEdit
        Get-ESPExtension
        CK1($script:ESPName)
    }
}

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
        Write-Information -MessageData $Messages.NoMesh -InformationAction:Stop
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
    do {
        $script:FO4InstallPath = Read-Host -Prompt $Messages.FO4Loc
        if ($FO4InstallCheck = Test-Path -Path $FO4InstallPath\Fallout4.exe) {
            Write-Information -MessageData $Messages.FO4Found -InformationAction:Continue
            if (Test-Path -Path $FO4InstallPath\CreationKit.exe) {
                Write-Information -MessageData $Messages.CKFound -InformationAction:Continue
            } else {
                Write-Information -MessageData $Messages.NoCK -InformationAction:Stop
            }
        } else {
            Write-Information -MessageData $Messages.NOFO4 -InformationAction:Continue
        }
    } until($FO4InstallCheck)
}

Function Get-f4ck {
    if (Test-Path -Path $FO4InstallPath\f4ck_loader.exe) {
        Write-Information -MessageData "Found f4ck loader, commands will use f4ck loader" -InformationAction:Continue
        return 1
    } else {
        Write-Information -MessageData "f4ck loader was not found, using default." -InformationAction:Continue
        return 0
    }
}

Function Get-ESPExtension {
    [bool]$Complications = $false
    do {
        $script:ESPName = Read-Host -Prompt 'Type the name of your esp including the extension'
        if ($ESPName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1) {
            if (-not $ESPName.Equals(".esp") -and -not $ESPName.Equals(".esm")) {
                if ($ESPName.EndsWith(".esp") -or $ESPName.EndsWith(".esm")) {
                    Write-Information -MessageData ($Messages.ESPNamePrecombine -f $ESPName) -InformationAction:Continue
                    $Complications = $true
                } else {
                    Write-Information -MessageData $MessageNoESP -InformationAction:Continue
                }
            } else {
                Write-Information -MessageData $MessageInsert -InformationAction:Continue
            }
        } else {
            Write-Information -MessageData "Not a valid filename" -InformationAction:Continue
        }
    } until ($Complications)
}

Function Get-xEdit {  
    do {
        $script:PathXEdit = Read-Host -Prompt $MessageXEditPath
        if ($PathXEditCheck = Test-Path -Path $PathXEdit\FO4Edit.exe) {
            Write-Information -MessageData "Found FO4Edit.exe. Continuing." -InformationAction:Continue
        } else {
            Write-Information -MessageData "Did not find FO4Edit.exe, please provide the correct directory to FO4Edit" -InformationAction:Inquire
        }
    } until ($PathXEditCheck)
}

#MainFunction
$Disclaimer
