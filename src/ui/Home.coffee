import React from "react"
import { View } from "react-native"
import { NavigationContainer } from "@react-navigation/native"
import { createStackNavigator } from '@react-navigation/stack'
import StatusBarColor from "../components/StatusBarColor"
import HomeRoomList from "./HomeRoomList"
import * as theme from "../theme/default"

Stack = createStackNavigator()

export default Home = () ->
  <View style={styleWrapper}>
    <StatusBarColor
      backgroundColor={theme.COLOR_SECONDARY}/>
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{ headerShown: false }}>
        <Stack.Screen
          name="HomeRoomList"
          component={HomeRoomList}/>
      </Stack.Navigator>
    </NavigationContainer>
  </View>

styleWrapper =
  flex: 1
  alignSelf: 'stretch'