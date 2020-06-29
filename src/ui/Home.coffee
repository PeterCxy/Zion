import React, { useContext, useEffect, useMemo, useRef, useState } from "react"
import { View } from "react-native"
import { Banner } from "react-native-paper"
import { NavigationContainer, DefaultTheme as NavDefTheme } from "@react-navigation/native"
import { createStackNavigator } from '@react-navigation/stack'
import changeNavigationBarColor from "react-native-navigation-bar-color"
import StatusBarColor from "../components/StatusBarColor"
import HomeRoomList from "./HomeRoomList"
import Chat from "./Chat"
import SASVerificationDialog from "./SASVerificationDialog"
import ThemeContext from "../theme"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"
import { verificationMethods } from 'matrix-js-sdk/lib/crypto'

Stack = createStackNavigator()

export default Home = () ->
  client = useContext MatrixClientContext
  {theme} = useContext ThemeContext

  verifyingRef = useRef false

  [verifier, setVerifier] = useState null
  [pendingVerificationRequest, setPendingVerificationRequest] = useState null

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
        if verifyingRef.current
          console.log "rejecting verification because one is in progress"
          request.verifier.cancel 'Already in progress'
          return
        verifyingRef.current = true
        setVerifier request.verifier
      else if request.pending
        console.log "pending verification request"
        if not request.methods.includes verificationMethods.SAS
          console.log "Zion only supports SAS verification"
          request.cancel()
          return
        if verifyingRef.current
          console.log "rejecting verification because one is in progress"
          request.cancel()
          return
        verifyingRef.current = true
        setPendingVerificationRequest request
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
    <Banner
      visible={pendingVerificationRequest?}
      actions={[
        {
          label: translate("decline"),
          onPress: ->
            verifyingRef.current = false
            pendingVerificationRequest.cancel()
            setPendingVerificationRequest null
        },
        {
          label: translate("accept"),
          onPress: ->
            await pendingVerificationRequest.accept()
            setVerifier pendingVerificationRequest.beginKeyVerification verificationMethods.SAS
            setPendingVerificationRequest null
        }
      ]}>
      {translate "verification_pending"}
    </Banner>
    {
      if verifier
        <SASVerificationDialog
          verifier={verifier}
          onDismiss={->
            setVerifier null
            verifyingRef.current = false
          }/>
    }
  </View>

styleWrapper =
  flex: 1
  alignSelf: 'stretch'