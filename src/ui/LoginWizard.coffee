import React, { useState, useEffect } from "react"
import { View, Text } from "react-native"
import { Button, TextInput } from "react-native-paper"
import StatusBarColor from "../components/StatusBarColor"
import * as theme from "../theme/default"
import { translate } from "../util/i18n"
import SoftInputMode from "../util/SoftInputMode"

export default LoginWizard = () ->
  [homeserver, setHomeserver] = useState 'matrix.org'
  [userName, setUserName] = useState ''
  [password, setPassword] = useState ''

  # In this UI we need to use ADJUST_PAN
  useEffect ->
    SoftInputMode.setSoftInputMode SoftInputMode.ADJUST_PAN

    # Reset to ADJUST_RESIZE when unmounted
    () ->
      SoftInputMode.setSoftInputMode SoftInputMode.ADJUST_RESIZE
  , []

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
            onPress={() ->}>
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