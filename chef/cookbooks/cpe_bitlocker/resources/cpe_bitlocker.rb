#
# Cookbook:: cpe_bitlocker
# Resources:: cpe_bitlocker
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2022-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_bitlocker
provides :cpe_bitlocker, :os => ['windows']

default_action :manage

action :manage do
  encrypt if encrypt?
  configure if configure?
  cleanup if cleanup?
end

action_class do # rubocop:disable Metrics/BlockLength
  def encrypt?
    node['cpe_bitlocker']['encrypt']
  end

  def configure?
    node['cpe_bitlocker']['configure']
  end

  def cleanup?
    node['cpe_bitlocker']['cleanup']
  end

  def encrypt
    # Return if disk fully encrypted or encryption in progress
    return if encryption_status['ConversionStatus'] == 2 || encryption_status['ProtectionStatus'] == 1

    # Remove existing encryption remnants
    cleanup if node.tpm_owned?

    # Enable Bitlocker
    enable_bitlocker

    case encryption_status['ConversionStatus']
    when 0
      node.windows_create_eventlog(
        'Application', 'chef-bitlocker', '1005', 'Warn', "#{encryption_status['DriveLetter']}" \
        'Drive Disk Not Encrypted'
      )
    when 1
      node.windows_create_eventlog(
        'Application', 'chef-bitlocker', '1006', 'Info', "#{encryption_status['DriveLetter']}" \
        'Drive Disk Fully Encrypted'
      )
    when 2
      node.windows_create_eventlog(
        'Application', 'chef-bitlocker', '1006', 'Info', "#{encryption_status['DriveLetter']}" \
        'Drive Disk Encryption In Progress'
      )
    when 3
      node.windows_create_eventlog(
        'Application', 'chef-bitlocker', '1005', 'Warn', "#{encryption_status['DriveLetter']}" \
        'Drive Decryption In Progress'
      )
    else
      node.windows_create_eventlog(
        'Application', 'chef-bitlocker', '1005', 'Warn', "#{encryption_status['DriveLetter']}" \
        'Drive Encryption Paused'
      )
    end
  end

  def configure
    # Set Bitlocker Policy Registry Settings
    registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE' do
      values [
        { :name => 'EncryptionMethodWithXtsOs', :type => :dword, :data => 7 },
        { :name => 'EncryptionMethodWithXtsFdv', :type => :dword, :data => 7 },
        { :name => 'EncryptionMethodWithXtsRdv', :type => :dword, :data => 4 },
        { :name => 'FDVRecovery', :type => :dword, :data => 1 },
        { :name => 'FDVRecoveryPassword', :type => :dword, :data => 2 },
        { :name => 'FDVManageDRA', :type => :dword, :data => 1 },
        { :name => 'FDVHideRecoveryPage', :type => :dword, :data => 1 },
        { :name => 'FDVActiveDirectoryBackup', :type => :dword, :data => 1 },
        { :name => 'FDVRequireActiveDirectoryBackup', :type => :dword, :data => 1 },
        { :name => 'RDVDenyCrossOrg', :type => :dword, :data => 0 },
        { :name => 'OSRecovery', :type => :dword, :data => 1 },
        { :name => 'OSManageDRA', :type => :dword, :data => 1 },
        { :name => 'OSRecoveryPassword', :type => :dword, :data => 1 },
        { :name => 'OSRecoveryKey', :type => :dword, :data => 2 },
        { :name => 'OSHideRecoveryPage', :type => :dword, :data => 1 },
        { :name => 'OSActiveDirectoryBackup', :type => :dword, :data => 1 },
        { :name => 'OSRequireActiveDirectoryBackup', :type => :dword, :data => 1 },
        { :name => 'OSActiveDirectoryInfoToStore', :type => :dword, :data => 1 },
        { :name => 'UseAdvancedStartup', :type => :dword, :data => 1 },
        { :name => 'EnableBDEWithNoTPM', :type => :dword, :data => 0 },
        { :name => 'UseTPMKey', :type => :dword, :data => 0 },
        { :name => 'UseTPMKeyPIN', :type => :dword, :data => 0 },
        { :name => 'UseTPM', :type => :dword, :data => 1 },
      ]
      action :create
    end
  end

  def cleanup
    # Remove Existing Bitlocker Settings
    registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE' do
      recursive true
      action :delete_key
    end

    # Take Ownership of TPM
    set_tpm_ownsership
    if node.tpm_owned?
      node.windows_create_eventlog('Application', 'chef-bitlocker', '1002', 'Info', 'TPM is Owned')
    else
      node.windows_create_eventlog('Application', 'chef-bitlocker', '1002', 'Warn', 'Unable to take TPM Ownership')
    end

    # Remove Any Existing Recovery Password KeyProtector (GPO/USB/MDM)
    if !encryption_status['KeyProtector'].nil?
      remove_bitlocker_key_protectors
      if encryption_status['KeyProtector'].nil?
        node.windows_create_eventlog('Application', 'chef-bitlocker', '1003', 'Info', 'Key Protector Cleared')
      else
        node.windows_create_eventlog('Application', 'chef-bitlocker', '1003', 'Warn', 'Unable to clear Key Protector')
      end
    else
      node.windows_create_eventlog('Application', 'chef-bitlocker', '1003', 'Info', 'Key Protector Empty')
    end
  end

  def encryption_status
    node.disk_encryption_info
  end

  def set_tpm_ownsership
    return unless windows? && node.tpm?

    unless node.tpm_owned? || node.provisioning_in_progress?
      powershell_script 'Set TPM Ownership' do
        ignore_failure true
        code <<-PSSCRIPT
          try {
            $TPMClass = Get-WmiObject -Namespace "root\\cimv2\\Security\\MicrosoftTPM" -Class "Win32_TPM"
            $NewPassPhrase = (New-Guid).Guid.Replace("-", "").SubString(0, 14)
            $NewOwnerAuth = $TPMClass.ConvertToOwnerAuth($NewPassPhrase).OwnerAuth
            $TPMClass.TakeOwnership($NewOwnerAuth)
            exit 0
          }
          catch {
            exit 1
          }
        PSSCRIPT
      end
    end
  end

  def remove_bitlocker_key_protectors
    unless windows?
      Chef::Log.warn('node.remove_bitlocker_key_protectors called on non-windows!')
      return {}
    end

    powershell_script 'Remove Bitlocker Key Protectors' do
      only_if { !node.provisioning_in_progress? }
      ignore_failure true
      code <<-PSSCRIPT
        try {
          Get-BitLockerVolume -MountPoint $env:SystemRoot | select -expandproperty 'KeyProtector' `
          | foreach $_.KeyProtectorId {
            Remove-BitLockerKeyProtector -MountPoint $env:SystemRoot -KeyProtectorId $_.KeyProtectorId
          }
          exit 0
        }
        catch {
          exit 1
        }
      PSSCRIPT
    end
    Chef::Log.info("Clearing Recovery Password KeyProtectors for: #{encryption_status['DriveLetter']}")
  end

  def enable_bitlocker
    unless windows?
      Chef::Log.warn('node.enable_bitlocker called on non-windows!')
      return {}
    end

    powershell_script 'Enable Bitlocker' do
      only_if { node.tpm? && node.powershell_module?('BitLocker') }
      not_if { node.provisioning_in_progress? }
      ignore_failure true
      code <<-PSSCRIPT
        try {
          ($encrypt = Enable-BitLocker -MountPoint #{encryption_status['DriveLetter']} -TpmProtector -UsedSpaceOnly `
            -EncryptionMethod "XtsAes256" -SkipHardwareTest -ErrorAction SilentlyContinue -WarningAction silentlyContinue) | out-null
          ($encrypt = Enable-BitLocker -MountPoint #{encryption_status['DriveLetter']} -RecoveryPasswordProtector -UsedSpaceOnly `
            -EncryptionMethod "XtsAes256" -SkipHardwareTest -ErrorAction SilentlyContinue -WarningAction silentlyContinue) | out-null
          BackupToAAD-BitLockerKeyProtector -MountPoint #{encryption_status['DriveLetter']} -KeyProtectorId `
            ((Get-BitLockerVolume -MountPoint #{encryption_status['DriveLetter']} ).KeyProtector `
            | where {$_.KeyProtectorType -eq "RecoveryPassword" }).KeyProtectorId -ErrorAction SilentlyContinue `
           -WarningAction silentlyContinue | Out-Null
          exit 0
        }
        catch {
          exit 1
        }
      PSSCRIPT
    end
    Chef::Log.info("Enabling Bitlocker for: #{encryption_status['DriveLetter']}")
  end

  def suspend_bitlocker(reboot_count)
    unless windows?
      Chef::Log.warn('node.suspend_bitlocker called on non-windows!')
      return {}
    end

    powershell_script 'Suspend Bitlocker' do
      only_if { !node.provisioning_in_progress? }
      ignore_failure true
      code <<-PSSCRIPT
        try {
          Suspend-BitLocker -MountPoint #{encryption_status['DriveLetter']} -RebootCount #{reboot_count}
          exit 0
        }
        catch {
          exit 1
        }
      PSSCRIPT
    end
    Chef::Log.info("Suspending Bitlocker for: #{encryption_status['DriveLetter']}")
  end

  def disable_bitlocker
    unless windows?
      Chef::Log.warn('node.disable_bitlocker called on non-windows!')
      return {}
    end

    powershell_script 'Disabling Bitlocker' do
      only_if { !node.provisioning_in_progress? }
      ignore_failure true
      code <<-PSSCRIPT
        try {
          Disable-BitLocker -MountPoint #{encryption_status['DriveLetter']}
          exit 0
        }
        catch {
          exit 1
        }
      PSSCRIPT
    end
    Chef::Log.info("Disabling Bitlocker for: #{encryption_status['DriveLetter']}")
  end
end
