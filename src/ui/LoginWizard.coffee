import React from "react"
import { View, Text } from "react-native"
import StatusBarColor from "../components/StatusBarColor"
import * as theme from "../theme/default"
import { translate } from "../util/i18n"

export default LoginWizard = () ->
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
    <View style={{ flex: 1 }}>
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