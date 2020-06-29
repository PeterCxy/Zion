import React, { useContext, useEffect, useMemo, useState } from "react"
import { View } from "react-native"
import { NavigationContainer, DefaultTheme as NavDefTheme } from "@react-navigation/native"
import { createStackNavigator } from '@react-navigation/stack'
import changeNavigationBarColor from "react-native-navigation-bar-color"
import StatusBarColor from "../components/StatusBarColor"
import HomeRoomList from "./HomeRoomList"
import Chat from "./Chat"
import SASVerificationDialog from "./SASVerificationDialog"
import ThemeContext from "../theme"
import { MatrixClientContext } from "../util/client"

Stack = createStackNavigator()

export default Home = () ->
  client = useContext MatrixClientContext
  {theme} = useContext ThemeContext

  [verifier, setVerifier] = useState null

  NavTheme = useMemo ->
    {
      ...NavDefTheme,
      colors: {
        ...NavDefTheme.colors,
        background: theme.COLOR_BACKGROUND
      }
    }
  , [theme]

  useEffect ->
    changeNavigationBarColor theme.COLOR_BACKGROUND
  , []

  useEffect ->
    onVerificationRequest = (request) ->
      if request.verifier
        console.log "has verifier"
        setVerifier request.verifier
    client.on 'crypto.verification.request', onVerificationRequest

    return ->
      client.removeListener 'crypto.verification.request', onVerificationRequest
  , []

  <View style={styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_SECONDARY}/>
    <NavigationContainer theme={NavTheme}>
      <Stack.Navigator
        screenOptions={{ headerShown: false }}>
        <Stack.Screen
          name="HomeRoomList"
          component={HomeRoomList}/>
        <Stack.Screen
          name="Chat"
          component={Chat}/>
      </Stack.Navigator>
    </NavigationContainer>
    {
      if verifier
        <SASVerificationDialog
          verifier={verifier}
          onDismiss={-> setVerifier null}/>
    }
  </View>

styleWrapper =
  flex: 1
  alignSelf: 'stretch'