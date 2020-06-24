import React, { useState, useEffect, useCallback } from "react"
import { View, Text } from "react-native"
import { Button, TextInput, ProgressBar, Snackbar } from "react-native-paper"
import AsyncStorage from '@react-native-community/async-storage'
import StatusBarColor from "../components/StatusBarColor"
import { useStyles } from "../theme"
import { translate } from "../util/i18n"
import SoftInputMode from "../util/SoftInputMode"
import { createLoginMatrixClient, createMatrixClient } from "../util/client"

export default LoginWizard = ({onLogin}) ->
  [theme, styles] = useStyles buildStyles
  [homeserver, setHomeserver] = useState 'matrix.org'
  [userName, setUserName] = useState ''
  [password, setPassword] = useState ''
  [loading, setLoading] = useState false
  [failure, setFailure] = useState false

  # In this UI we need to use ADJUST_PAN
  useEffect ->
    SoftInputMode.setSoftInputMode SoftInputMode.ADJUST_PAN

    # Reset to ADJUST_RESIZE when unmounted
    () ->
      SoftInputMode.setSoftInputMode SoftInputMode.ADJUST_RESIZE
  , []

  # The login function
  doLogin = useCallback ->
    setLoading true
    baseUrl = "https://#{homeserver}"
    tmpClient = createLoginMatrixClient baseUrl
    try
      resp = await tmpClient.login "m.login.password",
        user: userName
        password: password
      if resp.access_token
        # Write them to async storage
        await AsyncStorage.setItem "@base_url", baseUrl
        await AsyncStorage.setItem "@access_token", resp.access_token
        await AsyncStorage.setItem "@user_id", resp.user_id
        # Create the real client
        client = await createMatrixClient baseUrl, resp.access_token, resp.user_id
        await client.startClient()
        # Notify the main page to switch
        onLogin client  
    catch err
      setFailure true
      setLoading false
  , [homeserver, userName, password]

  <View style={styles.styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_PRIMARY}/>
    {
      # Expanded title area
    }
    <View style={styles.styleHeader}>
      <Text style={styles.styleTitle}>{translate "welcome"}</Text>
    </View>
    {
      # Progress bar
    }
    <ProgressBar
      style={styles.styleProgress}
      indeterminate={true}
      color={theme.COLOR_ACCENT}
      visible={loading}/>
    {
      # Content area
    }
    <View style={styles.styleBody}>
      {
        # Spacer
      }
      <View style={{ flex: 1 }}/>
      {
        # Main body
      }
      <View style={{ flex: 8 }}>
        <TextInput
          mode="outlined"
          label={translate "login_homeserver"}
          value={homeserver}
          onChangeText={setHomeserver}
          disabled={loading or failure}
          style={styles.styleTextInput}/>
        <TextInput
          mode="outlined"
          label={translate "login_username"}
          value={userName}
          onChangeText={setUserName}
          disabled={loading or failure}
          style={styles.styleTextInput}/>
        <TextInput
          mode="outlined"
          secureTextEntry={true}
          label={translate "login_password"}
          value={password}
          onChangeText={setPassword}
          disabled={loading or failure}
          style={styles.styleTextInput}/>
        {
          # Button bar
        }
        <View style={styles.styleButtonBar}>
          <Button
            style={{ flex: 1 }}
            compact={true}
            disabled={loading or failure}
            onPress={() ->}>
            {translate "login_help"}
          </Button>
          <Button
            style={{ flex: 1}}
            compact={true}
            disabled={loading or failure}
            onPress={doLogin}>
            {translate "login_login"}
          </Button>
        </View>
      </View>
      {
        # Spacer
      }
      <View style={{ flex: 1 }}/>
    </View>
    {
      # Failure toast
    }
    <Snackbar
      visible={failure and not loading}
      onDismiss={() -> setFailure false}
      action={{
        label: translate "ok"
        onPress: () -> setFailure false
      }}>
      {translate "err_failed_login"}
    </Snackbar>
  </View>

buildStyles = (theme) ->
  styleWrapper:
    flexDirection: 'column'
    alignSelf: 'stretch'
    flex: 1
  styleHeader:
    flexDirection: 'row'
    elevation: 5
    flex: 1
    backgroundColor: theme.COLOR_PRIMARY
  styleTitle:
    alignSelf: 'flex-end'
    fontFamily: 'sans-serif-condensed-light'
    color: theme.COLOR_TEXT_PRIMARY
    fontSize: 30
    marginStart: 15
    marginBottom: 10
  styleProgress:
    width: 'auto'
    height: 2
    alignSelf: 'stretch'
    backgroundColor: theme.COLOR_BACKGROUND
  styleBody:
    flex: 1
    alignSelf: 'stretch'
    flexDirection: 'row'
  styleTextInput:
    marginTop: 20
  styleButtonBar:
    flexDirection: 'row'
    alignSelf: 'flex-end'
    marginTop: 'auto'
    marginBottom: 20