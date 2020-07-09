import React, { useEffect, useRef } from "react"
import { Text, View } from "react-native"
import { TouchableRipple } from "react-native-paper"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
import { useStyles } from "../theme"
import RBSheet from "react-native-raw-bottom-sheet"

SHEET_ITEM_HEIGHT = 48
SHEET_TITLE_HEIGHT = 48
SHEET_ITEM_ICON_SIZE = 24

# A thin wrapper over RBSheet that adds a default height to the sheet
# based on the number of children and the item height
# Also adds a "show" property to allow controlling open / close
# without using refs explicitly.
# The "onClose" event will fire whenever the state changes to closed,
# whether it's triggered by a prop change or user input.
# However, it may fire multiple times when the state is changed
# to closed programmatically.
export BottomSheet = (_props) ->
  [theme, styles] = useStyles buildStyles
  props = Object.assign {}, _props
  if not props.height?
    children = React.Children.toArray props.children
    if children[0]?.type is React.Fragment
      # Use the length of the fragment's children to calculate height
      children = React.Children.toArray children[0].props.children
    props.height = SHEET_ITEM_HEIGHT * children.length
  if props.title?
    props.height += SHEET_TITLE_HEIGHT
  props.customStyles =
    container:
      backgroundColor: theme.COLOR_BACKGROUND
  delete props.children

  refRBSheet = useRef null
  useEffect ->
    return unless refRBSheet.current?

    # Using the state of the RBSheet is pretty dirty, but
    # we have to do this to avoid firing open() and close()
    # repeatedly
    if _props.show and not refRBSheet.current.state.modalVisible
      refRBSheet.current.open()
    else if not _props.show and refRBSheet.current.state.modalVisible
      refRBSheet.current.close()
  , [_props.show]

  <RBSheet
    ref={refRBSheet}
    {...props}>
    <View style={styles.styleItemsWrapper}>
      {
        if props.title?
          <View style={styles.styleTitle}>
            <Text style={styles.styleTitleText}>{props.title}</Text>
          </View>
      }
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
    styleTitle:
      paddingStart: 20
      height: SHEET_TITLE_HEIGHT
      flexDirection: 'row'
      alignItems: 'center'
    styleTitleText:
      fontSize: 14
      fontWeight: 'bold'
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND