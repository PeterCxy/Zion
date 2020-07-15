import React, { useMemo } from "react"
import { Text, View } from "react-native"
import { useStyles } from "../../theme"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
import filesize from "filesize"

export default Attachment = ({ev}) ->
  [theme, styles] = useStyles buildStyles

  styles = if ev.self then styles.reverse else styles
  iconColor = if ev.self then theme.COLOR_TEXT_PRIMARY else theme.COLOR_TEXT_ON_BACKGROUND

  readableSize = useMemo ->
    filesize ev.info.size,
      base: 2
      locale: true
      round: 2
  , [ev.info.size]

  <View style={styles.styleWrapper}>
    <View style={styles.styleActionIconWrapper}>
      <Icon
        name="download"
        size={24}
        color={iconColor}/>
    </View>
    <View style={styles.styleInfoWrapper}>
      <Text style={styles.styleInfoTitle} numberOfLines={1}>
        {ev.info.title}
      </Text>
      <Text style={styles.styleInfoSize} numberOfLines={1}>
        {readableSize}
      </Text>
    </View>
  </View>

buildStyles = (theme) ->
  styles =
    styleWrapper:
      flexDirection: 'row'
      alignItems: 'center'
      margin: 10
    styleActionIconWrapper:
      width: 48
      height: 48
      borderRadius: 24
      backgroundColor: 'rgba(0, 0, 0, .2)'
      alignItems: 'center'
      justifyContent: 'center'
    styleInfoWrapper:
      flexDirection: 'column'
      marginStart: 8
    styleInfoTitle:
      fontSize: 14
      color: theme.COLOR_TEXT_ON_BACKGROUND
    styleInfoTitleReverse:
      color: theme.COLOR_TEXT_PRIMARY
    styleInfoSize:
      fontSize: 14
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
    styleInfoSizeReverse:
      color: theme.COLOR_TEXT_PRIMARY
      opacity: 0.5

  styles.reverse = Object.assign {}, styles,
    styleInfoTitle: Object.assign {}, styles.styleInfoTitle, styles.styleInfoTitleReverse
    styleInfoSize: Object.assign {}, styles.styleInfoSize, styles.styleInfoSizeReverse

  styles