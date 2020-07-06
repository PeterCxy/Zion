import React from "react"
import { Text, View, PixelRatio } from "react-native"
import { useStyles } from "../../theme"
import * as constants from "./constants"

export default PreferenceCategory = React.memo ({title, children}) ->
  [theme, styles] = useStyles buildStyles

  <View style={styles.styleWrapper}>
    <Text style={styles.styleTitle}>{title}</Text>
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
    styleTitle:
      fontSize: 14
      marginBottom: 5
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
      marginStart: constants.PREF_ICON_SIZE + constants.PREF_ICON_MARGIN * 2