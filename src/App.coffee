import React, { useState, useEffect } from "react"
import { YellowBox } from "react-native"
import { DefaultTheme, Provider as PaperProvider } from 'react-native-paper'
import AsyncStorage from '@react-native-community/async-storage'
import * as theme from "./theme/default"
import LoginWizard from "./ui/LoginWizard"
import SplashScreen from "./ui/SplashScreen"
import Home from "./ui/Home"
import { reloadI18n } from "./util/i18n"
import { createMatrixClient, MatrixClientContext } from "./util/client"

# matrix-js-sdk sets long timers.
# We need to sort this out at some point,
# but for now just mute them
YellowBox.ignoreWarnings ['Setting a timer']

export default App = () ->
  [i18nLoaded, setI18nLoaded] = useState false
  [loaded, setLoaded] = useState false
  [client, setClient] = useState null

  if not i18nLoaded
    reloadI18n()
    setI18nLoaded true

  # Load log-in information
  useEffect ->
    doLoad = ->
      baseUrl = await AsyncStorage.getItem "@base_url"
      token = await AsyncStorage.getItem "@access_token"
      uid = await AsyncStorage.getItem "@user_id"

      if not (baseUrl and token and uid)
        setLoaded true
        setClient null
      else
        # We have the full information to construct client
        client = await createMatrixClient baseUrl, token, uid
        # Inialize the client
        await client.startClient()
        setClient client
        setLoaded true
    doLoad()
    return
  , []

  <PaperProvider theme={paperTheme}>
    {
      if not loaded
        <SplashScreen/>
      else if not client?
        <LoginWizard onLogin={(client) -> setClient client}/>
      else
        <MatrixClientContext.Provider
          value={client}>
          <Home/>
        </MatrixClientContext.Provider>
    }
  </PaperProvider>

paperTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: theme.COLOR_BACKGROUND,
    primary: theme.COLOR_PRIMARY,
    secondary: theme.COLOR_SECONDARY,
    accent: theme.COLOR_ACCENT
  }
}