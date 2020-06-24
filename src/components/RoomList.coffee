import React, { useContext, useEffect, useState } from "react"
import { Image, FlatList, Text, View } from "react-native"
import { TouchableRipple } from "react-native-paper"
import Avatar from "./Avatar"
import * as theme from "../theme/default"
import { MatrixClientContext } from "../util/client"

# Transform a list of rooms received from the SDK
# to a list that we can use
transformRooms = (client, rooms) ->
  rooms.map (room) ->
      _room: room
      key: room.roomId
      name: room.name
      avatar: room.getAvatarUrl client.getHomeserverUrl(), 64, 64, "scale", false

renderRoom = ({item}) ->
  <TouchableRipple
    onPress={->}
    rippleColor={theme.COLOR_RIPPLE}
    style={styleRoomItem}>
    <View style={styleRoomItem}>
      <Avatar
        style={styleRoomAvatar}
        name={item.name}
        url={item.avatar}/>
      <View style={styleTextContainer}>
        <Text numberOfLines={1} style={styleTextTitle}>{item.name}</Text>
        <Text numberOfLines={1} style={styleTextSummary}>Lorem Ipsum</Text>
      </View>
    </View>
  </TouchableRipple>

export default RoomList = () ->
  client = useContext MatrixClientContext
  [rooms, setRooms] = useState []

  # Load rooms on mount
  useEffect ->
    newRooms = transformRooms client, client.getRooms()
    setRooms newRooms
  , []

  <>
    <FlatList
      data={rooms}
      renderItem={renderRoom}/>
  </>

styleRoomItem =
  flex: 1
  flexDirection: "row"
  alignSelf: "stretch"

styleRoomAvatar =
  width: 56
  height: 56
  borderRadius: 28
  margin: 16

styleTextContainer =
  flexDirection: "column"
  alignSelf: "stretch"
  marginTop: 16
  marginStart: 6
  marginBottom: 16

styleTextTitle =
  fontSize: 16
  fontWeight: "bold"
  color: theme.COLOR_TEXT_ON_BACKGROUND

styleTextSummary =
  fontSize: 14
  marginTop: 8
  color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND