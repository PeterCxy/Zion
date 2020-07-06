import React from "react"
import { Text, View, PixelRatio } from "react-native"
import { TouchableRipple } from "react-native-paper"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
import { useStyles } from "../../theme"
import * as constants from "./constants"

export default Preference = React.memo ({icon, title, titleWeight, summary, onPress}) ->
  [theme, styles] = useStyles buildStyles

  <View style={styles.styleWrapper}>
    <TouchableRipple
      style={styles.styleRipple}
      onPress={onPress ? ->}
      rippleColor={theme.COLOR_RIPPLE}>
      <View style={styles.styleWrapperInner}>
        <View style={styles.styleIconTitleWrapper}>
          <Icon
            size={constants.PREF_ICON_SIZE}
            color={theme.COLOR_TEXT_ON_BACKGROUND}
            name={icon}
            style={styles.styleIcon}/>
          <Text style={Object.assign {}, styles.styleTitle,
            fontWeight: titleWeight ? 'normal'
          }>
            {title}
          </Text>
        </View>
        {
          if summary?
            <Text style={styles.styleSummary}>{summary}</Text>
        }
      </View>
    </TouchableRipple>
  </View>

buildStyles = (theme) ->
    styleWrapper:
      width: '100%'
      backgroundColor: theme.COLOR_PREFERENCE_BACKGROUND
      borderBottomColor: theme.COLOR_PREFERENCE_DIVIDER
      borderBottomWidth: 1 / PixelRatio.get()
    styleRipple:
      width: '100%'
    styleWrapperInner:
      width: '100%'
      flexDirection: 'column'
    styleIconTitleWrapper:
      width: '100%'
      flexDirection: 'row'
      alignItems: 'center'
      marginTop: constants.PREF_CONTENT_MARGIN
      marginBottom: constants.PREF_CONTENT_MARGIN
    styleIcon:
      marginLeft: constants.PREF_ICON_MARGIN
      marginRight: constants.PREF_ICON_MARGIN
    styleTitle:
      fontSize: 14
      color: constants.COLOR_TEXT_ON_BACKGROUND
    styleSummary:
      fontSize: 14
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
      marginTop: -constants.PREF_CONTENT_MARGIN / 2
      marginStart: constants.PREF_ICON_SIZE + constants.PREF_ICON_MARGIN * 2
      marginBottom: constants.PREF_CONTENT_MARGIN