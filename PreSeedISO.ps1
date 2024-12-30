<#
.SYNOPSIS
This PowerShell script automates the process of customizing a Debian installation ISO by adding a preseed configuration file to enable quick Debian setup.

.DESCRIPTION
This PowerShell script automates the process of customizing a Debian installation ISO by adding a preseed configuration file. Here's a brief overview of the script's purpose:

Mount the Original ISO: 
The script mounts the specified Debian ISO file (e.g., debian-12.5.0-amd64-netinst.iso) to a temporary drive letter.

Check for Existing Drive Letter: 
It verifies if the specified drive letter is already in use by another volume. If the drive letter is occupied, the script exits with an error.

Copy ISO Contents: 
Once the ISO is mounted, it copies all its contents to a temporary folder.

Add Preseed Configuration: 
The script adds a preseed configuration file (preseed.cfg) into the appropriate directory in the copied contents to automate the Debian installation process.

Copy Required Boot Files: 
It ensures that the required boot files (like isolinux.bin) are present, copying them from the mounted ISO if necessary.

Create a New ISO: 
Using oscdimg (from the Windows ADK), the script creates a new customized ISO with the preseed file integrated.

Cleanup: 
After creating the new ISO, it unmounts the original ISO and cleans up the temporary folder.

.LICENSE
This script is licensed under the MIT License (see LICENSE file).

.AUTHOR
Karthikeyan Manimaran (karthikeyan14june@gmail.com)

.DATE
Created on: 2024-12-30

.USAGE
Example usage: ./PreSeedISO.ps1
#>

Write-Host " "
Write-Host " "

Write-Host "Welcome to PreSeedISO tool!"

Write-Host " "

# Display ASCII art when the script runs
Write-Host "____           ____                _   ___ ____   ___"
Write-Host "|  _ \ _ __ ___/ ___|  ___  ___  __| | |_ _/ ___| / _ \ "
Write-Host "| |_) | '__/ _ \___ \ / _ \/ _ \/ _` |  | |\___ \| | | |"
Write-Host "|  __/| | |  __/___) |  __/  __/ (_| |  | | ___) | |_| |"
Write-Host "|_|   |_|  \___|____/ \___|\___|\__,_| |___|____/ \___/ "

Write-Host " "
Write-Host " "

# Prompt user for their name
$mountedVolumeLetter = Read-Host "Enter disk letter to mount: (e.g., D, E, etc.)"

Write-Host " "
Write-Host " "

Write-Host "The ISO with temporarily mount as disk $mountedVolumeLetter :"

Write-Host " "
Write-Host " "

# Get the directory where the script is located
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Find the first .iso file in the same folder as the script
$sourceISO = Get-ChildItem -Path $scriptDirectory -Filter *.iso | Select-Object -First 1
$sourceISO = Join-Path $scriptDirectory $sourceISO

Write-Host "ISO files found in the path $sourceISO" -ForegroundColor Green
if ($null -eq $sourceISO) {
    Write-Host "No ISO files found in the script directory." -ForegroundColor Red
    exit
}

$tempFolder = Join-Path $scriptDirectory "Temp"

$preseedFile = Join-Path $scriptDirectory "preseed.cfg"
if ($null -eq $sourceISO) {
    Write-Host "No ISO files found in the script directory." -ForegroundColor Red
    exit
}
Write-Host "Preseed file found at path $preseedFile" -ForegroundColor Green

# Calculate the position from the start of the string
$positionFromStart = $sourceISO.Length - 4
$outputISO = $sourceISO.Insert($positionFromStart, "-preseed")
Write-Host "Output ISO: $outputISO" -ForegroundColor Green

Write-Host "Temporary folder for mounting ISO: $tempFolder" -ForegroundColor Green

Write-Host "Mounted Volume Drive Letter: $mountedVolumeLetter" -ForegroundColor Green

# Create the folder if it doesn't exist
if (-not (Test-Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory
    Write-Host "Folder created at: $tempFolder"
} else {
    Write-Host "Folder already exists at: $tempFolder"
}

# Check if the specified drive letter is already in use
$existingVolume = Get-Volume | Where-Object { $_.DriveLetter -eq $mountedVolumeLetter }

Write-Host " "
Write-Host " "

if ($existingVolume) {
    Write-Host "Error: Drive letter $mountedVolumeLetter is already in use. Please choose a different drive letter." -ForegroundColor Red
    Exit 1
} else {
    Write-Host "Drive letter $mountedVolumeLetter is available. Proceeding with mounting the ISO..." -ForegroundColor Green
}

Write-Host " "
Write-Host " "

# Mount the ISO (this is Windows' built-in mounting feature)
Write-Host "Mounting the ISO..."
Mount-DiskImage -ImagePath $sourceISO
Start-Sleep -Seconds 10  # Allow time for the disk to mount

# Ensure the mounted volume is accessible
$mountedVolumePath = "${mountedVolumeLetter}:"

Write-Host "Mounted volume path: $mountedVolumePath"

Write-Host " "
Write-Host " "

# Copy the contents of the mounted ISO to the temporary folder
# Check if the mounted volume path exists
if (Test-Path $mountedVolumePath) {
    try {
        Write-Host "Copying contents from mounted ISO to temporary folder..."

        # Copy the contents from the mounted ISO to the temporary folder
        Copy-Item -Path "$mountedVolumePath\*" -Recurse -Destination $tempFolder -Force

        Write-Host "ISO contents copied to temporary folder." -ForegroundColor Green

        Write-Host " "
        Write-Host " "
    }
    catch {
        Write-Host "Error occurred while copying the ISO contents: $_" -ForegroundColor Red

        Write-Host " "
        Write-Host " "
    }
} else {
    Write-Host "The specified mounted volume path does not exist: $mountedVolumePath" -ForegroundColor Red
}

Write-Host " "
Write-Host " "

# Add the preseed.cfg to the appropriate directory (usually in the "preseed" folder or root)
$preseedDest = "$tempFolder\preseed"
If (-Not (Test-Path $preseedDest)) {
    Write-Host "Creating preseed folder in temporary directory..."
    New-Item -ItemType Directory -Force -Path $preseedDest
} else {
    Write-Host "Preseed folder already exists in temporary directory."
}

Write-Host " "
Write-Host " "

Write-Host "Copying preseed.cfg to the preseed folder..."
Copy-Item -Path $preseedFile -Destination $preseedDest -Force

Write-Host " "
Write-Host " "

Write-Host "Preseed configuration file added to temporary folder."

# Ensure isolinux.bin exists in the temp folder
$isolinuxBinPath = "$tempFolder\isolinux\isolinux.bin"
If (-Not (Test-Path $isolinuxBinPath)) {
    Write-Host "Error: isolinux.bin not found in the temporary folder, checking mounted ISO..."  -ForegroundColor Red

    $originalIsolinuxBinPath = "${mountedVolumePath}\isolinux\isolinux.bin"
    If (Test-Path $originalIsolinuxBinPath) {
        Write-Host "Copying isolinux.bin from the mounted ISO..."
        Copy-Item -Path $originalIsolinuxBinPath -Destination "$tempFolder\isolinux" -Force
        Write-Host "isolinux.bin copied to temporary folder."  -ForegroundColor Green
    } Else {
        Write-Host "Error: isolinux.bin not found in the source ISO." -ForegroundColor Red
        Exit 1
    }
} else {
    Write-Host "isolinux.bin already exists in temporary folder."
}

Write-Host " "
Write-Host " "

# Unmount the ISO after copying the files
Write-Host "Unmounting ISO..."
Dismount-DiskImage -ImagePath $sourceISO

Write-Host "ISO unmounted successfully."  -ForegroundColor Green

# Generate a new ISO using oscdimg (this requires the Windows ADK)
$oscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

Write-Host "oscdimg path: $oscdimgPath"

# Run oscdimg to create the new ISO
$arguments = "-u2", "-b$isolinuxBinPath", "-m", "-o", "$tempFolder", "$outputISO"
Write-Host "Running oscdimg to create the new ISO..."

Start-Process -FilePath $oscdimgPath -ArgumentList $arguments -Wait -NoNewWindow

Write-Host " "
Write-Host " "

Write-Host "ISO creation process completed." -ForegroundColor Green

Write-Host " "
Write-Host " "

# Check if the new ISO was created successfully
If (Test-Path $outputISO) {
    Write-Host "ISO created successfully at: $outputISO" -ForegroundColor Green
} Else {
    Write-Host "Error: ISO not found. Please check the output path." -ForegroundColor Red
    exit 1
}

Write-Host " "
Write-Host " "

# Clean up the temporary folder with error handling
try {
    Write-Host "Cleaning up temporary folder..."
    Remove-Item -Path $tempFolder -Recurse -Force
    Write-Host " "
    Write-Host " "
    Write-Host "Temporary folder cleaned up successfully." -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to remove some items in the temporary folder. Please check manually." -ForegroundColor Yellow
}

Write-Host " "
Write-Host " "

Write-Host "Thank you for using PreSeed ISO! The Preseeded ISO is created is the same folder this script is being run."
Write-Host "The temp folder and the mount that was created by this script are are cleaned up, you don't have to worry :-)"
