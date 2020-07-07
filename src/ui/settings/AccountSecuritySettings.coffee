import React, { useContext, useEffect, useState } from "react"
import { ScrollView, Text, View } from "react-native"
import { ActivityIndicator, Appbar, Button, Dialog, TextInput } from "react-native-paper"
import PreferenceCategory from "../../components/preferences/PreferenceCategory"
import Preference from "../../components/preferences/Preference"
import { MatrixClientContext } from "../../util/client"
import { translate } from "../../util/i18n"
import ThemeContext from "../../theme"

export default AccountSecuritySettings = ({navigation}) ->
  client = useContext MatrixClientContext

  [backupEnabled, setBackupEnabled] = useState ->
    client.getKeyBackupEnabled()
  [backupLoading, setBackupLoading] = useState true
  [backupInfo, setBackupInfo] = useState null
  [restoreDialogVisible, setRestoreDialogVisible] = useState false

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
          trusted: client.checkDeviceTrust(client.getUserId(), device.device_id).isVerified()
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
            if not backupLoading
              <Preference
                onPress={-> setRestoreDialogVisible true}
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
                      "cloud-question"
                  }
                  title={device.display_name}
                  titleWeight={if device.device_id is sessionId then 'bold'}
                  summary={
                    "#{device.device_id}, #{device.last_seen_ip}\n#{new Date(device.last_seen_ts).toLocaleString()}"}/>
          }
        </PreferenceCategory>
      </View>
    </ScrollView>
    <RestoreKeyBackupDialog
      visible={restoreDialogVisible}
      onDismiss={-> setRestoreDialogVisible false}/>
  </>

# The dialog used for restoring backup
RESTORE_STATE_INITIAL = 0
RESTORE_STATE_WAITING = 1
RESTORE_STATE_SUCCESS = 2
RESTORE_STATE_FAIL = 3

RestoreKeyBackupDialog = ({visible, onDismiss}) ->
  {theme} = useContext ThemeContext
  client = useContext MatrixClientContext
  [state, setState] = useState RESTORE_STATE_INITIAL
  [result, setResult] = useState null

  # Reset the state every time visibility is changed
  useEffect ->
    setState RESTORE_STATE_INITIAL
  , [visible]

  # Actually do restoring
  useEffect ->
    return unless state == RESTORE_STATE_WAITING

    do ->
      {backupInfo} = await client.checkKeyBackup()
      try
        res = await client.restoreKeyBackupWithCache undefined, undefined, backupInfo
      catch err
        try
          res = await client.restoreKeyBackupWithSecretStorage backupInfo
        catch err
          console.log err
          setState RESTORE_STATE_FAIL
          return
      setResult res
      setState RESTORE_STATE_SUCCESS
    return
  , [state]

  <Dialog
    visible={visible}
    onDismiss={onDismiss}
    dismissable={false}>
    <Dialog.Title>
      {translate "settings_account_security_backup_restore_dialog_title"}
    </Dialog.Title>
    <Dialog.Content>
      {
        switch state
          when RESTORE_STATE_INITIAL
            <Text>{translate "settings_account_security_backup_restore_dialog_content"}</Text>
          when RESTORE_STATE_WAITING
            <View style={{ flexDirection: "row" }}>
              <ActivityIndicator
                animating={true}
                color={theme.COLOR_ACCENT}/>
              <Text style={{ marginStart: 10 }}>
                {translate "settings_account_security_backup_restore_dialog_waiting"}
              </Text>
            </View>
          when RESTORE_STATE_SUCCESS
            <Text>
              {
                translate "settings_account_security_backup_restore_dialog_success",
                  result.imported, result.total
              }
            </Text>
          when RESTORE_STATE_FAIL
            <Text>
              {translate "settings_account_security_backup_restore_dialog_fail"}
            </Text>
      }
    </Dialog.Content>
    <Dialog.Actions>
      {
        switch state
          when RESTORE_STATE_INITIAL
            <>
              <Button
                onPress={onDismiss}>
                {translate "cancel"}
              </Button>
              <Button
                onPress={-> setState RESTORE_STATE_WAITING}>
                {translate "continue"}
              </Button>
            </>
          when RESTORE_STATE_SUCCESS, RESTORE_STATE_FAIL
            <Button
              onPress={onDismiss}>
              {translate "ok"}
            </Button>
      }
    </Dialog.Actions>
  </Dialog>