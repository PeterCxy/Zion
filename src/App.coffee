import React, { useState } from "react"
import { DefaultTheme, Provider as PaperProvider } from 'react-native-paper'
import * as theme from "./theme/default"
import LoginWizard from "./ui/LoginWizard"
import { reloadI18n } from "./util/i18n"

export default App = () ->
  [i18nLoaded, setI18nLoaded] = useState false

  if not i18nLoaded
    reloadI18n()
    setI18nLoaded true

  <PaperProvider theme={paperTheme}>
    <LoginWizard/>
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