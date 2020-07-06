import React from "react"
import AccountSecuritySettings from "./AccountSecuritySettings"

# Builds stack navigation screens for the settings
# We split these out from the home screen so we don't
# end up with a messy long list there
export default buildSettingsScreens = (Stack) ->
  <>
    <Stack.Screen
      name="AccountSecuritySettings"
      component={AccountSecuritySettings}/>
  </>