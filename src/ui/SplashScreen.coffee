import React, { useEffect } from "react"
import { View, Text } from "react-native"
import { ProgressBar } from "react-native-paper"
import changeNavigationBarColor from "react-native-navigation-bar-color"
import StatusBarColor from "../components/StatusBarColor"
import { useStyles } from "../theme"
import { translate } from "../util/i18n"

export default SplashScreen = () ->
  [theme, styles] = useStyles buildStyles

  useEffect ->
    changeNavigationBarColor theme.COLOR_PRIMARY
  , []

  <View style={styles.styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_PRIMARY}/>
    <View style={styles.styleMain}>
      <Text style={styles.styleMainText}>{translate "app_name"}</Text>
      <ProgressBar
        style={styles.styleProgressBar}
        color={theme.COLOR_ACCENT}
        indeterminate={true}/>
    </View>
  </View>

buildStyles = (theme) ->
    styleWrapper:
      flex: 1
      alignSelf: 'stretch'
      alignItems: 'center'
      justifyContent: 'center'
      backgroundColor: theme.COLOR_PRIMARY
    styleMain:
      flexDirection: 'column'
    styleMainText:
      color: theme.COLOR_TEXT_PRIMARY
      fontFamily: 'sans-serif-condensed-light'
      fontSize: 40
    styleProgressBar:
      width: 40
      height: 2
      marginTop: 10
      alignSelf: 'center'
      backgroundColor: theme.COLOR_PRIMARY