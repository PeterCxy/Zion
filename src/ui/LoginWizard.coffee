import React, { useState, useEffect, useCallback } from "react"
import { View, Text } from "react-native"
import { Button, TextInput, ProgressBar } from "react-native-paper"
import AsyncStorage from '@react-native-community/async-storage'
import StatusBarColor from "../components/StatusBarColor"
import * as theme from "../theme/default"
import { translate } from "../util/i18n"
import SoftInputMode from "../util/SoftInputMode"
import { createLoginMatrixClient, createMatrixClient } from "../util/client"

export default LoginWizard = ({onLogin}) ->
  [homeserver, setHomeserver] = useState 'matrix.org'
  [userName, setUserName] = useState ''
  [password, setPassword] = useState ''
  [loading, setLoading] = useState false

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
      # TODO: actually show the error
      setLoading false
  , [homeserver, userName, password]

  <View style={styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_PRIMARY}/>
    {
      # Expanded title area
    }
    <View style={styleHeader}>
      <Text style={styleTitle}>{translate "welcome"}</Text>
    </View>
    {
      # Progress bar
    }
    <ProgressBar
      style={styleProgress}
      indeterminate={true}
      color={theme.COLOR_ACCENT}
      visible={loading}/>
    {
      # Content area
    }
    <View style={styleBody}>
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
          style={styleTextInput}/>
        <TextInput
          mode="outlined"
          label={translate "login_username"}
          value={userName}
          onChangeText={setUserName}
          style={styleTextInput}/>
        <TextInput
          mode="outlined"
          secureTextEntry={true}
          label={translate "login_password"}
          value={password}
          onChangeText={setPassword}
          style={styleTextInput}/>
        {
          # Button bar
        }
        <View style={styleButtonBar}>
          <Button
            style={{ flex: 1 }}
            compact={true}
            onPress={() ->}>
            {translate "login_help"}
          </Button>
          <Button
            style={{ flex: 1}}
            compact={true}
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
  </View>

styleWrapper =
  flexDirection: 'column'
  alignSelf: 'stretch'
  flex: 1

styleHeader =
  flexDirection: 'row'
  elevation: 5
  flex: 1
  backgroundColor: theme.COLOR_PRIMARY

styleTitle =
  alignSelf: 'flex-end'
  fontFamily: 'sans-serif-condensed-light'
  color: theme.COLOR_TEXT_PRIMARY
  fontSize: 30
  marginStart: 15
  marginBottom: 10

styleProgress =
  width: 'auto'
  height: 2
  alignSelf: 'stretch'
  backgroundColor: theme.COLOR_BACKGROUND

styleBody =
  flex: 1
  alignSelf: 'stretch'
  flexDirection: 'row'

styleTextInput =
  marginTop: 20

styleButtonBar =
  flexDirection: 'row'
  alignSelf: 'flex-end'
  marginTop: 'auto'
  marginBottom: 20