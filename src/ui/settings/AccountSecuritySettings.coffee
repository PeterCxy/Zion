import React, { useContext, useEffect, useState } from "react"
import { ScrollView, View } from "react-native"
import { Appbar } from "react-native-paper"
import PreferenceCategory from "../../components/preferences/PreferenceCategory"
import Preference from "../../components/preferences/Preference"
import { MatrixClientContext } from "../../util/client"
import { translate } from "../../util/i18n"

export default AccountSecuritySettings = ({navigation}) ->
  client = useContext MatrixClientContext

  [backupEnabled, setBackupEnabled] = useState ->
    client.getKeyBackupEnabled()
  [backupLoading, setBackupLoading] = useState true
  [backupInfo, setBackupInfo] = useState null

  [sessionId, setSessionId] = useState -> client.deviceId
  [sessionKey, setSessionKey] = useState ->
    # From matrix-react-sdk/src/utils/FormattingUtils
    client.getDeviceEd25519Key()?.match(/.{1,4}/g).join(" ")

  [devices, setDevices] = useState null
  [deviceCryptoInfoMap, setDeviceCryptoInfoMap] = useState {}
  [devicesLoading, setDevicesLoading] = useState true

  useEffect ->
    unmounted = false

    onBackupEnabledStateChange = (enabled) ->
      setBackupEnabled enabled
    
    client.on 'crypto.keyBackupStatus', onBackupEnabledStateChange

    do ->
      _backupInfo = await client.getKeyBackupVersion()
      unless unmounted
        setBackupInfo _backupInfo
        setBackupLoading false

    do ->
      _devices = await client.getDevices()
      _devices = _devices?.devices?.map (device) ->
        Object.assign {}, device,
          trusted: client.checkDeviceTrust client.getUserId(), device.device_id
      unless unmounted or not _devices?
        setDevices _devices
        setDevicesLoading false

    return ->
      unmounted = true

      client.removeListener 'crypto.keyBackupStatus', onBackupEnabledStateChange
  , []

  <>
    <Appbar.Header>
      <Appbar.BackAction
        onPress={-> navigation.goBack()}/>
      <Appbar.Content
        title={translate "settings_account_security"}/>
    </Appbar.Header>
    <ScrollView>
      <View style={{ flexDirection: "column" }}>
        <PreferenceCategory
          loading={backupLoading}
          title={translate "settings_account_security_backup"}>
          <Preference
            icon="information"
            title={translate "settings_account_security_backup_status"}
            summary={translate if backupEnabled
              "settings_account_security_backup_status_enabled"
            else
              "settings_account_security_backup_status_disabled"
            }/>
          {
            if not backupLoading
              <Preference
                icon="dots-horizontal-circle-outline"
                title={translate "settings_account_security_backup_info"}
                summary={if not backupInfo?
                  translate "settings_account_security_backup_info_uninitialized"
                else
                  translate "settings_account_security_backup_info_details",
                    backupInfo.algorithm, backupInfo.version
                }/>
          }
          {
            if not backupLoading and backupInfo?
              <Preference
                icon="backup-restore"
                title={translate "settings_account_security_backup_restore"}/>
          }
        </PreferenceCategory>
        <PreferenceCategory
          title={translate "settings_account_security_cryptography"}>
          <Preference
            icon="account-outline"
            title={translate "settings_account_security_cryptography_session_id"}
            summary={sessionId}/>
          <Preference
            icon="key"
            title={translate "settings_account_security_cryptography_session_key"}
            summary={sessionKey ? translate "settings_account_security_cryptography_session_key_unsupported"}/>
        </PreferenceCategory>
        <PreferenceCategory
          loading={devicesLoading}
          title={translate "settings_account_security_devices"}>
          {
            if devices?
              devices.map (device) ->
                <Preference
                  key={device.device_id}
                  icon={
                    if device.trusted
                      "shield-check"
                    else
                      "shield-alert"
                  }
                  title={device.display_name}
                  titleWeight={if device.device_id is sessionId then 'bold'}
                  summary={
                    "#{device.device_id}, #{device.last_seen_ip}\n#{new Date(device.last_seen_ts).toLocaleString()}"}/>
          }
        </PreferenceCategory>
      </View>
    </ScrollView>
  </>