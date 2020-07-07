import React, { useEffect, useRef } from "react"
import { Text, View } from "react-native"
import { TouchableRipple } from "react-native-paper"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
import { useStyles } from "../theme"
import RBSheet from "react-native-raw-bottom-sheet"

SHEET_ITEM_HEIGHT = 48
SHEET_ITEM_ICON_SIZE = 24

# A thin wrapper over RBSheet that adds a default height to the sheet
# based on the number of children and the item height
export BottomSheet = (_props) ->
  [theme, styles] = useStyles buildStyles
  props = Object.assign {}, _props
  if not props.height?
    props.height = SHEET_ITEM_HEIGHT * React.Children.toArray(props.children).length
  props.customStyles =
    container:
      backgroundColor: theme.COLOR_BACKGROUND
  delete props.children

  refRBSheet = useRef null
  # TODO: this logic somehow glitches when opening / closing rapidly
  useEffect ->
    return unless refRBSheet.current?

    if _props.show
      refRBSheet.current.open()
    else
      refRBSheet.current.close()
  , [_props.show]

  <RBSheet
    ref={refRBSheet}
    {...props}>
    <View style={styles.styleItemsWrapper}>
      {_props.children}
    </View>
  </RBSheet>

export BottomSheetItem = ({icon, title, onPress}) ->
  [theme, styles] = useStyles buildStyles
  <TouchableRipple
    rippleColor={theme.COLOR_RIPPLE}
    onPress={onPress ? ->}
    style={styles.styleItem}>
    <View style={styles.styleItemInner}>
      <Icon
        style={styles.styleItemIcon}
        size={SHEET_ITEM_ICON_SIZE}
        name={icon}
        color={theme.COLOR_TEXT_ON_BACKGROUND}/>
      <Text
        style={styles.styleItemText}>
        {title}
      </Text>
    </View>
  </TouchableRipple>

buildStyles = (theme) ->
    styleItemsWrapper:
      height: '100%'
      flexDirection: 'column'
    styleItem:
      width: '100%'
      height: SHEET_ITEM_HEIGHT
    styleItemInner:
      width: '100%'
      height: SHEET_ITEM_HEIGHT
      flexDirection: 'row'
      alignItems: 'center'
    styleItemIcon:
      marginStart: 20
      marginEnd: 30
    styleItemText:
      fontSize: 14
      color: theme.COLOR_TEXT_ON_BACKGROUND