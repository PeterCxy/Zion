import React, { useContext, useEffect, useMemo } from "react"
import { View } from "react-native"
import { NavigationContainer, DefaultTheme as NavDefTheme } from "@react-navigation/native"
import { createSharedElementStackNavigator } from 'react-navigation-shared-element'
import changeNavigationBarColor from "react-native-navigation-bar-color"
import StatusBarColor from "../components/StatusBarColor"
import HomeRoomList from "./HomeRoomList"
import Chat from "./Chat"
import VerificationRequestHandler from "../components/VerificationRequestHandler" 
import ThemeContext from "../theme"

Stack = createSharedElementStackNavigator()

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

  <View style={styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_SECONDARY}/>
    <NavigationContainer theme={NavTheme}>
      <Stack.Navigator
        screenOptions={{ headerShown: false }}>
        <Stack.Screen
          name="HomeRoomList"
          component={HomeRoomList}/>
        <Stack.Screen
          name="Chat"
          component={Chat}
          sharedElements={Chat.sharedElements}/>
      </Stack.Navigator>
    </NavigationContainer>
    <VerificationRequestHandler/>
  </View>

styleWrapper =
  flex: 1
  alignSelf: 'stretch'