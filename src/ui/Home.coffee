import React, { useContext, useEffect, useMemo } from "react"
import { View } from "react-native"
import { NavigationContainer, DefaultTheme as NavDefTheme } from "@react-navigation/native"
import { createDrawerNavigator } from '@react-navigation/drawer'
import { createSharedElementStackNavigator } from 'react-navigation-shared-element'
import changeNavigationBarColor from "react-native-navigation-bar-color"
import { EventStatus } from "matrix-js-sdk"
import DrawerContent from "../components/DrawerContent"
import StatusBarColor from "../components/StatusBarColor"
import HomeRoomList from "./HomeRoomList"
import Chat from "./Chat"
import ImageViewerScreen from "./ImageViewerScreen"
import RoomDetails from "./RoomDetails"
import Settings from "./Settings"
import buildSettingsScreens from "./settings"
import VerificationRequestHandler from "../components/VerificationRequestHandler" 
import ThemeContext from "../theme"
import { MatrixClientContext } from "../util/client"

Drawer = createDrawerNavigator()
Stack = createSharedElementStackNavigator()

# A wrapper over Home which provides the global drawer
# note that navigation events will be bubbled up if
# inner navigators cannot handle
export default Home = () ->
  {theme} = useContext ThemeContext

  NavTheme = useMemo ->
    {
      ...NavDefTheme,
      colors: {
        ...NavDefTheme.colors,
        background: theme.COLOR_BACKGROUND
      }
    }
  , [theme]

  useEffect ->
    changeNavigationBarColor theme.COLOR_BACKGROUND
  , []

  <NavigationContainer theme={NavTheme}>
    <Drawer.Navigator
      drawerContent={(props) -> <DrawerContent {...props}/>}>
      <Drawer.Screen
        name="HomeInner"
        component={HomeInner}/>
    </Drawer.Navigator>
  </NavigationContainer>

HomeInner = (props) ->
  {theme} = useContext ThemeContext
  client = useContext MatrixClientContext

  # Some global event logic
  # we do it here because they are "global"
  useEffect ->
    # Cancel all redaction and reactions automatically
    # if they were ever to fail.
    # These events do not have their own standalone entries,
    # and they are reflected in the state of some previous event.
    # If we don't cancel them, the user won't know that the operation
    # had failed, which is not a wise choise to make
    onPendingStateChange = (ev) ->
      evType = ev.getType()
      return unless evType is 'm.room.redaction' or evType is 'm.reaction'
      return unless ev.status is EventStatus.NOT_SENT

      client.cancelPendingEvent ev

    client.on 'Room.localEchoUpdated', onPendingStateChange

    return ->
      client.removeListener 'Room.localEchoUpdated', onPendingStateChange
  , []

  <View style={styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_PRIMARY}/>
    <Stack.Navigator
      screenOptions={{ headerShown: false }}>
      <Stack.Screen
        name="HomeRoomList"
        component={HomeRoomList}/>
      <Stack.Screen
        name="Chat"
        component={Chat}
        sharedElements={Chat.sharedElements}/>
      <Stack.Screen
        name="ImageViewerScreen"
        component={ImageViewerScreen}
        sharedElements={ImageViewerScreen.sharedElements}
        options={ImageViewerScreen.navigationOptions}/>
      <Stack.Screen
        name="RoomDetails"
        component={RoomDetails}
        sharedElements={RoomDetails.sharedElements}/>
      <Stack.Screen
        name="Settings"
        component={Settings}/>
      {buildSettingsScreens Stack}
    </Stack.Navigator>
    <VerificationRequestHandler/>
  </View>

styleWrapper =
  flex: 1
  alignSelf: 'stretch'