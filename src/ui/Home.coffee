import React, { useContext, useEffect, useMemo } from "react"
import { View } from "react-native"
import { NavigationContainer, DefaultTheme as NavDefTheme } from "@react-navigation/native"
import { createDrawerNavigator } from '@react-navigation/drawer'
import { createSharedElementStackNavigator } from 'react-navigation-shared-element'
import changeNavigationBarColor from "react-native-navigation-bar-color"
import DrawerContent from "../components/DrawerContent"
import StatusBarColor from "../components/StatusBarColor"
import HomeRoomList from "./HomeRoomList"
import Chat from "./Chat"
import ImageViewerScreen from "./ImageViewerScreen"
import RoomDetails from "./RoomDetails"
import VerificationRequestHandler from "../components/VerificationRequestHandler" 
import ThemeContext from "../theme"

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
    <Drawer.Navigator drawerContent={-> <DrawerContent/>}>
      <Drawer.Screen
        name="HomeInner"
        component={HomeInner}/>
    </Drawer.Navigator>
  </NavigationContainer>

HomeInner = () ->
  {theme} = useContext ThemeContext

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
    </Stack.Navigator>
    <VerificationRequestHandler/>
  </View>

styleWrapper =
  flex: 1
  alignSelf: 'stretch'