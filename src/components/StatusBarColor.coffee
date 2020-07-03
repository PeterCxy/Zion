# Thanks: <https://medium.com/reactbrasil/react-native-setting-a-status-bar-background-color-on-android-and-ios-1cba14a4e3f9>
import React, { useMemo } from "react"
import { View, StatusBar } from "react-native"

export default StatusBarColor = (props) ->
  styleStatusBar = useMemo =>
    return
      height: StatusBar.currentHeight
      backgroundColor: props.backgroundColor
  , [StatusBar.currentHeight, props.backgroundColor]

  # The View is actually what decides the color of the status bar
  # The <StatusBar> element itself only determines the overlay color,
  # which should be transparent for views like drawer to draw under
  <View style={styleStatusBar}>
    <StatusBar
      translucent
      barStyle="light-content"
      backgroundColor="rgba(0, 0, 0, #{props.opacity ? 0.20})"/>
  </View>
