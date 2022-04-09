#Min Powershell version.
#Requires -Version 7.0
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    
    [ValidateScript(
        { 
            if ($_.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1) {
                if (-not $_.Equals(".esp") -and -not $_.Equals(".esm")) {
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

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript(
        { 
            if (Test-Path -Path $_\FO4Edit.exe) {
                $true
            } else {
                throw "Could not find FO4Edit with that file path."
            }
        }
    )]
    [Alias("XEdit", "FO4Edit")]
    [string[]]
    $PathXEdit
)
#Automatically looks for the FO4 installation path using Registry Keys
$FO4InstallPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4\' -Name "installed path"
#Blank ESP/ESM file name, I decided to have the user input the ESP/ESM file for precombine generation in the case there might be multiple files in the DATA folder. 
#$script:ESPName = $null
#Blank Path to XEdit folder location, kinda wish there was a way to find XEdit without using Get-ChildItem "C:\" -recurse -ErrorAction:SilentlyContinue -Include "FO4Edit.exe" as that will take forever.
#$script:PathXEdit = $null

$MessageXEditPath = "Please put in your FO4Edit folder path here"

$MessageNoESP = "Please include the .esp or .esm extension"

$MessageInsert = "Insert a valid name for the esp/esm"

#$MessageMovingToFO4 = "Moving to the FO4 Directory"

$MessageCK = "Checking to make sure the CK is in the FO4 root directory"

$MessageFO4location = "Please put in your Fallout 4 Directory here"

$Disclaimer = DATA {
    "DISCLAIMER: This script is only to be used after you created the base previsibine ESP/ESM."
    "It will not guide you how to create the base previsibine ESP/ESM, for that look at StarHammer's Guide in the Github REPO"
    "Although this script tries to fully automate the process, it cannot. Your participation will be required."
    "If you have any problems with the Powershell Script create an issue/PR in MY, feeddanoob, Github REPO."
    "The ESP/ESM as well as all its masters are to be assumed in the Fallout 4 Data folder, you would need to copy paste, create hardlinks, or use MO2's uvfs (not recommended) for your ESP/ESM."
    "This script will look into your Registry to find Fallout 4, therefore only legit FO4 installations are supported."
    "This script will be only in English (US) but translations can be supported "
    "This script was created using VSCode and with Powershell 7.x in mind, please download and install the latest Powershell"
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
        Write-Information -MessageData "Packing the meshes to an archive" -InformationAction:Continue
        Start-Process -FilePath "$FO4InstallPath\Tools\Archive2\Archive2.exe" -Wait -ArgumentList """$FO4InstallPath\Data\Meshes"" -c=""$FO4InstallPath\Data\$ESP - Main.ba2"""
    } else {
        Write-Information -MessageData "Meshes were not created, Aborting" -InformationAction:Stop
    }
}

Function Get-CK {
    #Set-Location $FO4InstallPath
    #Write-Information -MessageData $MessageMovingToFO4 -InformationAction:Continue
    Write-Information -MessageData $MessageCK -InformationAction:Continue
    if ($TestCKLoc = Test-Path -Path $FO4InstallPath\CreationKit.exe) {
        return $TestCKLoc
    } else {
        Write-Information -MessageData "Could not find the CK in the Fallout 4 Directory, exiting." -InformationAction:Continue
        return 0
    }
}

Function Set-CK {
    do {
        $script:FO4InstallPath = Read-Host -Prompt $MessageFO4location
        if ($FO4InstallCheck = Test-Path -Path $FO4InstallPath\Fallout4.exe) {
            Write-Information -MessageData "Found Fallout4.exe, now looking for the Creation Kit." -InformationAction:Continue
            if (Test-Path -Path $FO4InstallPath\CreationKit.exe) {
                Write-Information -MessageData "Found the Creation Kit" -InformationAction:Continue
                #Set-Location $FO4InstallPath
            } else {
                Write-Information -MessageData "Could not find the Creation Kit in the FO4 Directory, please install the Creation Kit in the FO4 directory." -InformationAction:Stop
            }
        } else {
            Write-Information -MessageData "Could not find Fallout4.exe with that directory, please input the correct directory." -InformationAction:Continue
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
