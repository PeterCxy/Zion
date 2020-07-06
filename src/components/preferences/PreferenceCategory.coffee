import React from "react"
import { Text, View, PixelRatio } from "react-native"
import { ActivityIndicator } from "react-native-paper"
import { useStyles } from "../../theme"
import * as constants from "./constants"

export default PreferenceCategory = React.memo ({title, loading, children}) ->
  [theme, styles] = useStyles buildStyles

  <View style={styles.styleWrapper}>
    <View style={styles.styleTitleWrapper}>
      <Text style={styles.styleTitle}>{title}</Text>
      <ActivityIndicator
        animating={loading? and loading}
        hideWhenStopped={true}
        color={theme.COLOR_ACCENT}
        size={10}/>
    </View>
    <View style={styles.styleChildrenWrapper}>
      {children}
    </View>
  </View>

buildStyles = (theme) ->
    styleWrapper:
      backgroundColor: theme.COLOR_BACKGROUND
      marginTop: constants.PREF_CONTENT_MARGIN
    styleChildrenWrapper:
      flexDirection: 'column'
      borderTopColor: theme.COLOR_PREFERENCE_DIVIDER
      borderTopWidth: 1 / PixelRatio.get()
    styleTitleWrapper:
      flexDirection: 'row'
      alignItems: 'center'
    styleTitle:
      fontSize: 14
      marginBottom: 5
      marginRight: 5
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
      marginStart: constants.PREF_ICON_SIZE + constants.PREF_ICON_MARGIN * 2