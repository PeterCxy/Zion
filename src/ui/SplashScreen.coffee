import React from "react"
import { View, Text } from "react-native"
import { ProgressBar } from "react-native-paper"
import StatusBarColor from "../components/StatusBarColor"
import * as theme from "../theme/default"
import { translate } from "../util/i18n"

export default SplashScreen = () ->
  <View style={styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_PRIMARY}/>
    <View style={styleMain}>
      <Text style={styleMainText}>{translate "app_name"}</Text>
      <ProgressBar
        style={styleProgressBar}
        color={theme.COLOR_ACCENT}
        indeterminate={true}/>
    </View>
  </View>

styleWrapper =
  flex: 1
  alignSelf: 'stretch'
  alignItems: 'center'
  justifyContent: 'center'
  backgroundColor: theme.COLOR_PRIMARY

styleMain =
  flexDirection: 'column'

styleMainText =
  color: theme.COLOR_TEXT_PRIMARY
  fontFamily: 'sans-serif-condensed-light'
  fontSize: 40

styleProgressBar =
  width: 40
  height: 2
  marginTop: 10
  alignSelf: 'center'
  backgroundColor: theme.COLOR_PRIMARY