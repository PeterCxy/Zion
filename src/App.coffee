import React, { useCallback, useMemo, useState, useEffect } from "react"
import { LogBox } from "react-native"
import { DefaultTheme, Provider as PaperProvider } from 'react-native-paper'
import AsyncStorage from '@react-native-community/async-storage'
import ThemeContext from "./theme"
import * as defTheme from "./theme/default"
import LoginWizard from "./ui/LoginWizard"
import SplashScreen from "./ui/SplashScreen"
import Home from "./ui/Home"
import useSecretStorageKeyHandler from "./components/SecretStorageKeyHandler"
import { reloadI18n } from "./util/i18n"
import { createMatrixClient, MatrixClientContext } from "./util/client"

# matrix-js-sdk uses console.error extensively
# I don't want a red screen every time the sync
# API returns 429 or something
console.reportErrorsAsExceptions = false

LogBox.ignoreLogs [
  # matrix-js-sdk sets long timers.
  # We need to sort this out at some point,
  # but for now just mute them
  'Setting a timer',
  # We already show these in UI -- don't spam plz
  'Error decrypting event'
]

export default App = () ->
  [i18nLoaded, setI18nLoaded] = useState false
  [loaded, setLoaded] = useState false
  [client, setClient] = useState null
  [curTheme, setCurTheme] = useState defTheme
  [secretKeyAccessDialog, getSecretStorageKey] = useSecretStorageKeyHandler()
  setCurTheme = useCallback setCurTheme, []

  paperTheme = useMemo ->
    {
      ...DefaultTheme,
      colors: {
        ...DefaultTheme.colors,
        background: curTheme.COLOR_BACKGROUND,
        primary: curTheme.COLOR_PRIMARY,
        secondary: curTheme.COLOR_SECONDARY,
        accent: curTheme.COLOR_ACCENT
      }
    }
  , [curTheme]

  if not i18nLoaded
    reloadI18n()
    setI18nLoaded true

  # Load log-in information
  useEffect ->
    do ->
      baseUrl = await AsyncStorage.getItem "@base_url"
      token = await AsyncStorage.getItem "@access_token"
      uid = await AsyncStorage.getItem "@user_id"
      deviceId = await AsyncStorage.getItem "@device_id"

      if not (baseUrl and token and uid and deviceId)
        setLoaded true
        setClient null
      else
        # We have the full information to construct client
        client = await createMatrixClient baseUrl, token, uid, deviceId, getSecretStorageKey
        setClient client
        setLoaded true
    return
  , []

  <ThemeContext.Provider value={{ theme: curTheme, setTheme: setCurTheme }}>
    <PaperProvider theme={paperTheme}>
      {
        if not loaded
          <SplashScreen/>
        else if not client?
          <LoginWizard
            onLogin={(client) -> setClient client}
            getSecretStorageKey={getSecretStorageKey}/>
        else
          <MatrixClientContext.Provider
            value={client}>
            <Home/>
          </MatrixClientContext.Provider>
      }
      {secretKeyAccessDialog}
    </PaperProvider>
  </ThemeContext.Provider>
