import React, { useMemo } from "react"
import { StatusBar, Text, View } from "react-native"
import { useStyles } from "../theme"

export default DrawerContent = () ->
  [theme, styles] = useStyles buildStyles

  stylesWrapper = useMemo ->
    Object.assign {}, styles.stylesWrapper,
      paddingTop: StatusBar.currentHeight
  , [StatusBar.currentHeight]

  <View style={stylesWrapper}>
  </View>

buildStyles = (theme) ->
    stylesWrapper:
      flex: 1
      backgroundColor: theme.COLOR_BACKGROUND