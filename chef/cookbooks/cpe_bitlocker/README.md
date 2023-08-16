cpe_bitlocker Cookbook
========================

Encrypts and Configures Bitlocker for Windows

This cookbook depends on the following cookbooks

* cpe_uber_utils

These cookbooks are offered by Uber in the [IT-CPE](https://github.com/uber/IT-CPE)) repository.

Attributes
----------

* node['cpe_bitlocker']
* node['cpe_bitlocker']['encrypt']
* node['cpe_bitlocker']['configure']

Notes
-----

For details on configuration options, see the official documentation: <https://docs.microsoft.com/en-us/windows/win32/secprov/getconversionstatus-win32-encryptablevolume>

Usage
-----

Before using this cookbook to encrypt bitlocker, you will need to ensure that the bitlocker Powershell Module is installed on the target device and available. See <https://docs.microsoft.com/en-us/powershell/module/bitlocker/backup-bitlockerkeyprotector?view=windowsserver2019-ps>:

    Backup-BitLockerKeyProtector
      [-MountPoint] <String[]>
      [-KeyProtectorId] <String>
      [-WhatIf]
      [-Confirm]
      [<CommonParameters>]

    $BLV = Get-BitLockerVolume -MountPoint "C:"
    Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId

Background
----------

**BitLocker encryption process**
The following steps describe the flow of events that should result in a successful encryption of a Windows device that has *not* been previously encrypted with BitLocker.

INTUNE

1. An administrator configures a BitLocker policy in Intune with the desired settings, and targets a user group or device group.
2. The policy is saved to a tenant in the Intune service.
3. A Windows Device Management (MDM) client syncs with the Intune service and processes the BitLocker policy settings.
4. The BitLocker MDM policy Refresh scheduled task runs on the device that replicates the BitLocker policy settings to full volume encryption (FVE) registry key.
5. BitLocker encryption is initiated on the drives.
CHEF
***NOTE:***  In the event that intune has not encrypted the device for whatever reason (See <https://docs.microsoft.com/en-us/windows/security/information-protection/bitlocker/troubleshoot-bitlocker>) We are using chef to kick encryption

6. Removes Existing FVE Registry settings
7. Takes TPM Ownership
8. Removes GPO/WS1 KeyProtectors
9. Enables Bitlocker
10. Backs up Bitlocker Key to AAD
11. Creates New Bitlocker Registry Setting Mirroring the policies we set with Intune Profile
