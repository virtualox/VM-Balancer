<#
.SYNOPSIS
    Generates a secure encryption key for encrypting and decrypting vCenter credentials.

.DESCRIPTION
    This script creates a 256-bit (32-byte) encryption key using a cryptographically secure random number generator.
    The key is saved to a specified file path and should be securely stored with restricted access permissions.

.USAGE
    .\Generate-EncryptionKey.ps1

.NOTES
    - Ensure the encryption key file is stored in a secure location with restricted access.
    - This key is required for both encrypting and decrypting the vCenter credentials.
    - Do not share the encryption key file publicly or store it in insecure locations.
#>

# === Configuration Variables ===

# Path where the encryption key will be stored
$encryptionKeyPath = "C:\Secure\Credentials\encryptionKey.key" # <-- Update this path

# === End of Configuration Variables ===

# Function to check if the encryption key already exists
function Test-EncryptionKeyExists {
    param (
        [string]$Path
    )
    return (Test-Path -Path $Path)
}

# Function to generate a secure encryption key
function Generate-EncryptionKey {
    param (
        [string]$Path
    )
    try {
        # Create a 32-byte (256-bit) key
        $key = New-Object byte[] 32
        [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)
        
        # Save the key to the specified path
        $key | Set-Content -Path $Path -Encoding Byte -Force
        
        Write-Output "Encryption key successfully generated and saved to '$Path'."
    }
    catch {
        Write-Error "Failed to generate encryption key: $_"
        exit 1
    }
}

# Main Execution
if (Test-EncryptionKeyExists -Path $encryptionKeyPath) {
    Write-Warning "Encryption key already exists at '$encryptionKeyPath'."
    $userInput = Read-Host "Do you want to overwrite the existing key? (Y/N)"
    if ($userInput -ne 'Y' -and $userInput -ne 'y') {
        Write-Output "Operation cancelled by the user."
        exit
    }
}

# Ensure the directory exists
$directory = Split-Path -Path $encryptionKeyPath -Parent
if (-not (Test-Path -Path $directory)) {
    try {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
        Write-Output "Created directory '$directory'."
    }
    catch {
        Write-Error "Failed to create directory '$directory': $_"
        exit 1
    }
}

# Generate the encryption key
Generate-EncryptionKey -Path $encryptionKeyPath

# Secure the encryption key file by setting appropriate permissions
try {
    $acl = Get-Acl -Path $encryptionKeyPath
    # Define the access rule: Only the current user has full control
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $permission = "$currentUser","FullControl","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $encryptionKeyPath -AclObject $acl
    Write-Output "Set restricted permissions on '$encryptionKeyPath'."
}
catch {
    Write-Warning "Failed to set permissions on '$encryptionKeyPath'. Please ensure it is secured properly."
}
