# Thanks:
# <https://medium.com/@habibridho/implementing-collapsing-toolbar-using-react-native-4a84e1718f11>
import React, { useContext, useRef } from "react"
import { Animated, ScrollView, Text, View } from "react-native"
import { Appbar } from "react-native-paper"
import ThemeContext, { useStyles } from "../theme"
import { DEFAULT_APPBAR_HEIGHT } from "../util/util"

export default CollapsingHeaderView = (props) ->
  {
    headerHeight, headerBackground,
    renderHeader, renderAppbar,
    children, goBack
  } = props
  [theme, styles] = useStyles buildStyles
  scrollY = useRef(new Animated.Value 0).current
  headerHeightAnim = scrollY.interpolate
    inputRange: [0, headerHeight]
    outputRange: [headerHeight, 0]
    extrapolate: 'clamp'
  marginTopAnim = scrollY.interpolate
    inputRange: [0, headerHeight]
    outputRange: [0, -headerHeight / 2]
    extrapolate: 'clamp'
  opacityAnim = scrollY.interpolate
    # Make appbar opacity 1 when the remaining height is the height
    # of the appbar.
    inputRange: [0, headerHeight - DEFAULT_APPBAR_HEIGHT]
    outputRange: [0, 1]
    extrapolate: 'clamp'
  scrollEv = Animated.event [
      nativeEvent:
        contentOffset:
          y: scrollY
  ], { useNativeDriver: false }

  <View style={styles.styleContainer}>
    <ScrollView
      contentContainerStyle={{ paddingTop: headerHeight }}
      onScroll={scrollEv}>
      {children}
    </ScrollView>
    <Animated.View style={
      Object.assign {}, styles.styleHeader,
        height: headerHeightAnim
        backgroundColor: headerBackground
      }>
      <Animated.View style={{ width: '100%', height: headerHeight, marginTop: marginTopAnim }}>
        <Appbar.BackAction
          style={styles.styleHeaderBackAction}
          color={theme.COLOR_TEXT_PRIMARY}
          onPress={goBack}/>
        {renderHeader()}
      </Animated.View>
    </Animated.View>
    <Animated.View style={Object.assign {}, styles.styleAppbarWrapper,
      opacity: opacityAnim
    }>
      {renderAppbar()}
    </Animated.View>
  </View>

buildStyles = (theme) ->
    styleContainer:
      flex: 1
      alignSelf: "stretch"
    styleHeader:
      position: 'absolute'
      top: 0
      left: 0
      width: '100%'
      elevation: 5
      overflow: 'hidden'
    styleAppbarWrapper:
      position: 'absolute'
      top: 0
      left: 0
      width: '100%'
      elevation: 5
    styleHeaderBackAction:
      marginLeft: 10