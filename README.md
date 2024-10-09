# PowerCLI Scripts for VMware VM Balancing

![VMware-vCenter](https://img.shields.io/badge/VMware-vCenter-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-%5E5.1-blue)
![GitHub License](https://img.shields.io/github/license/virtualox/VM-Balancer)

Automate the balancing of virtual machines (VMs) across hosts in a VMware vCenter cluster, ensuring no host exceeds a specified VM limit. This solution leverages PowerCLI scripts to streamline VM distribution while maintaining security through encrypted credential management. Additionally, it includes robust exclusion mechanisms to protect critical or specialized VMs from unintended migrations and an enhanced dry-run feature for safer script execution.
## Features

- **Automated VM Balancing:** Distributes VMs evenly across hosts in a cluster, adhering to a maximum VM limit per host.
- **Secure Credential Handling:** Utilizes encrypted credential storage and a shared encryption key to protect sensitive information, enabling secure sharing among multiple administrators and automated tasks.
- **Configurable Parameters:** Easily adjust settings such as vCenter server details, cluster name, VM limits, and exclusion criteria.
- **VM Exclusions:**
  - **Name-Based Exclusion:** Prevents VMs with specific names or naming patterns from being migrated.
  - **Tag-Based Exclusion:** Excludes VMs assigned certain VMware tags from migration.
- **Enhanced Dry-Run Mode:** Simulates the migration process accurately by considering host capacities, preventing unrealistic migration proposals.
- **Error Handling & Logging:** Provides informative output and warnings for failed migrations.
- **Flexible Usage:** Supports both simulation (dry-run) and actual migration operations.

## Prerequisites

Before using the VM Balancer scripts, ensure the following prerequisites are met:

- **PowerShell 5.1 or Higher:** The scripts are compatible with PowerShell version 5.1 and above.
- **VMware PowerCLI Module:** Required for interacting with vCenter. Install using PowerShell.
- **vCenter Server Access:** Administrative credentials with permissions to manage VMs and hosts within the target cluster.
- **Windows Environment:** Scripts are designed to run on Windows systems.

## Installation

1. **Clone the Repository:**

   ```powershell
   git clone https://github.com/virtualox/vm-balancer.git
   ```
2. **Navigate to the Directory**:

   ```powershell
   cd vm-balancer
   ```
   
3. **Install VMware PowerCLI (if not already installed):**

   Open PowerShell with administrative privileges and run:

   ```powershell
   Install-Module -Name VMware.PowerCLI -Scope CurrentUser
   ```
   or
   ```powershell
   Install-Module -Name VMware.PowerCLI -Scope AllUsers
   ```
   
   **Note:**
   You may need to accept prompts to install NuGet provider and trust the PowerCLI repository.

## Scripts

This repository contains three primary PowerShell scripts:

### 1. Generate-EncryptionKey.ps1

**Purpose:**

Generates a secure encryption key for encrypting and decrypting vCenter credentials. This key enables multiple administrators or automated tasks to access shared credentials securely.

**Filename:** `Generate-EncryptionKey.ps1`

**Description:**

This script creates a 256-bit (32-byte) encryption key using a cryptographically secure random number generator. The key is saved to a specified file path and should be securely stored with restricted access permissions.

**Usage:**

1. **Configure the Script:**
   * Open `Generate-EncryptionKey.ps1` in a text editor.
   * Update the $encryptionKeyPath variable to specify where you want to store the encryption key. Ensure this directory is secure and accessible to all intended administrators or automated tasks.

2. **Run the Script:**
   Open PowerShell with administrative privileges and execute:
   ```powershell
   .\Generate-EncryptionKey.ps1
   ```
   **Note:** If an encryption key already exists at the specified path, the script will prompt you to confirm overwriting it.

3. **Secure the Encryption Key:**
   
   The script sets the file permissions so that only the current user has full control. Ensure that this file is stored in a secure location and is not accessible to unauthorized users.

### 2. Create-VCenterCredentials.ps1

**Purpose:**

Securely store vCenter credentials by encrypting them using a shared encryption key and saving them to a file. This ensures credentials are not exposed in plain text within scripts and can be securely shared among multiple administrators or automated tasks.

**Filename:** `Create-VCenterCredentials.ps1`

**Description:**

This script prompts the user to enter vCenter credentials, encrypts the password using a predefined encryption key, and saves the encrypted credentials along with the username to a specified file. This setup allows multiple administrators or automated tasks to access shared credentials securely.

**Usage:**
1. **Ensure Encryption Key Exists:**
   * Run `Generate-EncryptionKey.ps1` to create the encryption key before executing this script.

2. **Configure the Script:**

   * Open `Create-VCenterCredentials.ps1` in a text editor.
   * Confirm that the `$encryptionKeyPath` and `$credentialPath` variables match the paths used in `Generate-EncryptionKey.ps1` and `Balance-VMs.ps1`.
     
3. **Run the Script:**

   Open PowerShell and execute:
   ```powershell
   .\Create-VCenterCredentials.ps1
   ```

4. **Enter Credentials:**

   A prompt will appear asking for your vCenter credentials. Enter the **username** and **password** with appropriate permissions.
   
5. **Secure Storage:**

   The script sets file permissions so that only the current user has full control. Ensure that the credentials file is stored in a secure location and is not accessible to unauthorized users.

### 3. Balance-VMs.ps1

**Purpose:**

Balances the number of VMs across hosts in a specified vCenter cluster, ensuring no host exceeds the defined VM limit. It utilizes the encrypted credentials and encryption key to authenticate with vCenter, applies exclusion criteria based on VM names and tags, and supports an enhanced dry-run mode for safe testing.

**Filename:** `Balance-VMs.ps1`

**Description:**

This script connects to a vCenter server using encrypted credentials, identifies overloaded hosts within a specified cluster, and migrates VMs to underloaded hosts to maintain a balanced distribution. It excludes specified VMs from migration based on their names or assigned tags. Additionally, it includes an enhanced dry-run mode to simulate migrations safely.

## Usage

### **Step 1: Securely Store vCenter Credentials**

Before running the balancing script, securely store your vCenter credentials using the `Create-VCenterCredentials.ps1` script.

1. **Ensure Encryption Key Exists:**
   * Run `Generate-EncryptionKey.ps1` to create the encryption key.
2. **Create Encrypted Credentials:**
   * Run `Create-VCenterCredentials.ps1` to encrypt and store your vCenter credentials.

### Step 2: Configure the Balancing Script

1. **Open `Balance-VMs.ps1` in a text editor.**
2. **Update Configuration Variables:**
   At the top of the script, set the following variables:
   * `$encryptionKeyPath`: Path to the encryption key file generated by `Generate-EncryptionKey.ps1`.
   * `$credentialPath`: Path to the encrypted credentials file generated by `Create-VCenterCredentials.ps1`.
   * `$vcServer`: Your vCenter server's hostname or IP address.
   * `$clusterName`: The name of the cluster you wish to balance.
   * `$maxVMsPerHost`: Maximum number of VMs allowed per host.
  
   **Example:**
   ```powershell
   # === Configuration Variables ===

   # Path to the encryption key file
   $encryptionKeyPath = "C:\Secure\Credentials\encryptionKey.key"

   # Path to the encrypted credentials file
   $credentialPath = "C:\Secure\Credentials\vcCredentials.xml"

   # vCenter Server details
   $vcServer = "vcenter.mycompany.com"
   $clusterName = "ProductionCluster"

   # VM balancing settings
   $maxVMsPerHost = 60

   # Exclusion Settings

   ## Name-Based Exclusion
   # Specify exact VM names or use wildcards for patterns
   $excludeVMNames = @(
       "cp-replica-*",    # Exclude VMs with names starting with 'cp-replica-'
       "horizon-*",       # Exclude VMs managed by Horizon (assuming they start with 'horizon-')
       "*-replica*",      # Exclude any VM containing '-replica' in its name
       "Important-VM1",   # Exclude specific VM by exact name
       "Critical-VM2"     # Add more as needed
   )

   ## Tag-Based Exclusion
   # Specify the names of tags assigned to VMs that should be excluded
   $excludeVMTags = @(
       "DoNotMigrate",
       "Infrastructure",
       "VDI"
   )

   # === End of Configuration Variables ===
   ```
3. **Configure Exclusion Criteria:**
   * **Name-Based Exclusion (`$excludeVMNames`):** Add VM name patterns that should be excluded from migration. Use wildcards (*) as needed.
   * **Tag-Based Exclusion (`$excludeVMTags`):** Assign specific tags to VMs in vCenter that should not be migrated. Ensure these tags are accurately reflected in the array.

### Step 3: Execute the Balancing Script

**Option 1: Perform a Dry-Run**

A dry-run allows you to simulate the migration process without making any actual changes. This helps verify that the script behaves as expected and respects exclusion criteria.

1. **Run the Script with Dry-Run Parameter:**
   ```powershell
   .\Balance-VMs.ps1 -DryRun
   ```
   
2. **Review Output:**
   * The script will display which VMs would be migrated and to which hosts.
   * It will not perform any actual migrations.
   * Excluded VMs based on name or tag criteria will be skipped and indicated in the output.

**Option 2: Execute Actual Migration**

Once satisfied with the dry-run results, proceed to perform the actual VM migrations.

1. **Run the Script Without Dry-Run Parameter:**
   ```powershell
   .\Balance-VMs.ps1
   ```

2. **Monitor Process:**
   - Observe the console output for migration actions.
   - Address any warnings or errors that may arise during execution.
   
### Step 4: Verify Balancing
After execution, verify that the VMs have been appropriately distributed across hosts within the cluster, ensuring no host exceeds the specified VM limit. Also, confirm that excluded VMs remain on their original hosts.

## Testing
* **Dry Run:** Always perform a dry-run before executing actual migrations to ensure the script behaves as expected.
  ```powershell
  .\Balance-VMs.ps1 -DryRun
  ```
* **Verify Exclusions:**
  * Ensure the account used has the necessary permissions to perform VM migrations.
* **Check Host Capacities:**
  * Confirm that the number of proposed migrations does not exceed the target hosts' capacities.
* **Permissions:**
  * Ensure the account used has the necessary permissions to perform VM migrations.

## **Security Considerations**
* **Encrypted Credentials and Encryption Key:**
  * The credentials file (`vcCredentials.xml`) is encrypted using a shared encryption key (`encryptionKey.key`). This setup allows multiple administrators and automated tasks to access the same credentials securely.
  * **Secure Storage:** Ensure both the encryption key and encrypted credentials files are stored in secure locations with restricted access permissions.
  * **NTFS Permissions:** Restrict access to the following files to only authorized users and groups:
    * **Encryption Key:** `C:\Secure\Credentials\encryptionKey.key`
    * **Encrypted Credentials:** `C:\Secure\Credentials\vcCredentials.xml`

**Example PowerShell Commands to Set Permissions:**

```powershell
# Restrict access to the encryption key
$keyFile = "C:\Secure\Credentials\encryptionKey.key"
$acl = Get-Acl -Path $keyFile
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule ($currentUser, "FullControl", "Allow")
$acl.SetAccessRule($rule)
Set-Acl -Path $keyFile -AclObject $acl

# Restrict access to the credentials file
$credFile = "C:\Secure\Credentials\vcCredentials.xml"
$acl = Get-Acl -Path $credFile
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule ($currentUser, "FullControl", "Allow")
$acl.SetAccessRule($rule)
Set-Acl -Path $credFile -AclObject $acl
```

* **Regularly Rotate Encryption Keys and Credentials:**
  * Implement a process to periodically regenerate the encryption key and re-encrypt the credentials to enhance security.
* **Backup Encryption Key and Credentials Securely:**
  * Store backups of the encryption key and encrypted credentials in a secure, redundant location to prevent data loss.
* **Monitor Access to Sensitive Files:**
  * Implement auditing to track access to the encryption key and credentials files, ensuring that only authorized access occurs.

## Troubleshooting
* **Credential Errors:**
  * **Issue:** Script fails to connect to vCenter.
  * **Solution:** Ensure that the credentials file exists at the specified path and was created by the same user on the current machine.

* **Cluster Not Found:**
  * **Issue:* Script reports that the specified cluster was not found.
  * **Solution:** Verify the `$clusterName` variable is correctly set to the exact name of your target cluster.

* **VM Migration Failures:**
  * **Issue:** VMs fail to migrate due to resource constraints or other issues.
  * **Solution:** Check the target hosts for sufficient CPU, memory, and storage resources. Review vCenter tasks and events for detailed error messages.

* **PowerCLI Module Issues:**
  * **Issue:** Errors related to missing PowerCLI cmdlets.
  * **Solution:** Ensure that VMware PowerCLI is installed and imported correctly. Run `Import-Module VMware.PowerCLI` before executing the scripts.

* **Encryption Key Issues:**
  * **Issue:** Unable to decrypt credentials.
  * **Solution:** Ensure that the encryption key file is present at the specified path and has not been altered or corrupted. Regenerate the key and re-encrypt credentials if necessary.

## Security Best Practices
1. **Restrict Access to Encryption Key and Credentials Files:**
   * Ensure that only authorized administrators and automated tasks have read access to:
     * Encryption Key: `C:\Secure\Credentials\encryptionKey.key`
     * Encrypted Credentials: `C:\Secure\Credentials\vcCredentials.xml`
2. **Regularly Rotate Encryption Keys and Credentials:**
   * Implement a schedule to regenerate the encryption key and re-encrypt the credentials periodically to minimize security risks.
3. **Backup Encryption Key and Credentials Securely:**
   * Store backups in a secure, separate location to prevent data loss while maintaining access control.
4. **Monitor Access to Sensitive Files:**
   * Enable auditing on the encryption key and credentials files to track unauthorized access attempts.
5. **Use Strong Encryption Practices:**
   * Ensure that the encryption key is sufficiently random and protected against unauthorized access.
6. **Educate Administrators:**
   * Train all administrators on the importance of securing the encryption key and encrypted credentials, and the protocols for handling sensitive information.

## Contributing
Contributions are welcome! If you have suggestions for improvements or encounter [issues](https://github.com/virtualox/vm-balancer/issues), please open an issue or submit a [pull request](https://github.com/virtualox/vm-balancer/pulls).

## Acknowledgements
* **[VMware](https://github.com/vmware) PowerCLI:** The foundation for automating vSphere tasks.
