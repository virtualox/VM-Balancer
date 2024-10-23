<#
.SYNOPSIS
    Generates a secure encryption key for encrypting and decrypting vCenter credentials.

.DESCRIPTION
    This script creates a 256-bit (32-byte) encryption key using a cryptographically secure random number generator.
    The key is saved to a specified file path and should be securely stored with restricted access permissions.

.PARAMETER EncryptionKeyPath
    The file path where the encryption key will be stored. Default is "C:\Secure\Credentials\encryptionKey.key".

.EXAMPLE
    .\Generate-EncryptionKey.ps1
    Generates an encryption key and saves it to the default path.

.EXAMPLE
    .\Generate-EncryptionKey.ps1 -EncryptionKeyPath "D:\Keys\MyEncryptionKey.key"
    Generates an encryption key and saves it to the specified path.

.AUTHOR
    virtualox

.GITHUB_REPOSITORY
    https://github.com/virtualox/VM-Balancer

.LICENSE
    This script is licensed under the GPL-3.0 License. See the LICENSE file for more information.

.NOTES
    - Ensure the encryption key file is stored in a secure location with restricted access.
    - This key is required for both encrypting and decrypting the vCenter credentials.
    - Do not share the encryption key file publicly or store it in insecure locations.
#>

[CmdletBinding()]
param (
    [string]$EncryptionKeyPath = "C:\Secure\Credentials\encryptionKey.key"
)

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

        # Use the appropriate RNG method based on .NET version
        if ([System.Security.Cryptography.RandomNumberGenerator].GetMethod('Fill', [Type[]]@([Byte[]]))) {
            # For .NET Core and .NET 5+
            [System.Security.Cryptography.RandomNumberGenerator]::Fill($key)
        }
        else {
            # For .NET Framework
            [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
        }

        # Save the key to the specified path
        Set-Content -Path $Path -Value $key -Encoding Byte -Force

        Write-Output "Encryption key successfully generated and saved to '$Path'."
    }
    catch {
        Write-Error "Failed to generate encryption key: $_"
        exit 1
    }
}

# Function to check if running as administrator
function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Main Execution

# Check if running as administrator
if (-not (Test-IsAdministrator)) {
    Write-Warning "You need to run this script as an Administrator to set file permissions."
    exit 1
}

if (Test-EncryptionKeyExists -Path $EncryptionKeyPath) {
    Write-Warning "Encryption key already exists at '$EncryptionKeyPath'."

    do {
        $userInput = Read-Host "Do you want to overwrite the existing key? (Y/N)"
    } until ($userInput -match '^[YyNn]$')

    if ($userInput -ne 'Y' -and $userInput -ne 'y') {
        Write-Output "Operation cancelled by the user."
        exit
    }
}

# Ensure the directory exists
$directory = Split-Path -Path $EncryptionKeyPath -Parent
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
Generate-EncryptionKey -Path $EncryptionKeyPath

# Secure the encryption key file by setting appropriate permissions
try {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    # Secure the encryption key file
    $aclFile = Get-Acl -Path $EncryptionKeyPath

    # Remove all existing permissions except for the current user
    $accessRules = $aclFile.Access | Where-Object { $_.IdentityReference -ne $currentUser }
    foreach ($rule in $accessRules) {
        $aclFile.RemoveAccessRule($rule)
    }

    # Define the access rule: Only the current user has full control
    $accessRuleFile = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $currentUser,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        [System.Security.AccessControl.InheritanceFlags]::None,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $aclFile.SetAccessRuleProtection($true, $false)
    $aclFile.SetAccessRule($accessRuleFile)
    Set-Acl -Path $EncryptionKeyPath -AclObject $aclFile

    Write-Output "Set restricted permissions on '$EncryptionKeyPath'."
}
catch {
    Write-Warning "Failed to set permissions on '$EncryptionKeyPath'. Please ensure it is secured properly."
}
