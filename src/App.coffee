import React, { useState } from "react"
import LoginWizard from "./ui/LoginWizard"
import { reloadI18n } from "./util/i18n"

export default App = () ->
  [i18nLoaded, setI18nLoaded] = useState false

  if not i18nLoaded
    reloadI18n()
    setI18nLoaded true

  <>
    <LoginWizard/>
  </>