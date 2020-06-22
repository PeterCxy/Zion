# Thanks: <https://medium.com/reactbrasil/react-native-setting-a-status-bar-background-color-on-android-and-ios-1cba14a4e3f9>
import React, { useMemo } from "react"
import { View, StatusBar } from "react-native"
import * as theme from "../theme/default"

export default StatusBarColor = (props) ->
  styleStatusBar = useMemo =>
    return
      height: StatusBar.currentHeight
      backgroundColor: props.backgroundColor
  , [StatusBar.currentHeight, props.backgroundColor]

  <View style={styleStatusBar}>
    <StatusBar
      translucent
      barStyle="light-content"
      backgroundColor={styleStatusBar.backgroundColor}/>
  </View>
