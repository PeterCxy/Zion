import React, { useCallback, useContext, useEffect, useState } from "react"
import { Image, FlatList, Text, View } from "react-native"
import { TouchableRipple } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import Avatar from "./Avatar"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import * as mext from "../util/matrix"
import * as util from "../util/util"

# Transform a list of rooms received from the SDK
# to a list that we can use
transformRooms = (client, rooms) ->
  rooms
    .filter (room) -> room.getMyMembership(client.getUserId()) == "join"
    .map (room) ->
      [ts, desc] = getLatestMessage room

      # We should NOT keep track of the original Room object
      # because they are mutable.
      # Instead, we always build our own immutable state
      # out of the original object.
      return
        key: room.roomId
        name: room.name
        avatar: mext.calculateRoomAvatarURL client, room
        summary: desc
        timestamp: ts
    .sort (x, y) -> y.timestamp - x.timestamp

getLatestMessage = (room) ->
  events = room.getLiveTimeline().getEvents()
  latest = events[events.length - 1]
  [latest.getTs(), mext.eventToDescription(latest)]

renderRoom = (onEnterRoom, theme, styles, {item}) ->
  <TouchableRipple
    onPress={->
      onEnterRoom item.key
    }
    rippleColor={theme.COLOR_RIPPLE}
    style={styles.styleRoomItem}>
    <View style={styles.styleRoomItem}>
      <SharedElement id={"room.#{item.key}.avatar"}>
        <Avatar
          style={styles.styleRoomAvatar}
          name={item.name}
          url={item.avatar}/>
      </SharedElement>
      <View style={styles.styleTextContainer}>
        <Text numberOfLines={1} style={styles.styleTextTitle}>{item.name}</Text>
        <Text numberOfLines={1} style={styles.styleTextSummary}>{item.summary}</Text>
      </View>
    </View>
  </TouchableRipple>

export default RoomList = ({onEnterRoom}) ->
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  [rooms, setRooms] = useState []

  refreshRooms = useCallback ->
    util.asyncRunAfterInteractions ->
      newRooms = transformRooms client, client.getRooms()
      setRooms newRooms
    return
  , []

  # Load rooms on mount
  useEffect ->
    refreshRooms()
  , []

  # Install sync listener to refresh rooms
  useEffect ->
    # TODO: maybe this is too much of work to update all rooms on all sync events?
    #       maybe we can do better?
    client.on 'sync', refreshRooms
    client.on 'Event.decrypted', refreshRooms
    
    return ->
      client.removeListener 'sync', refreshRooms
      client.removeListener 'Event.decrypted', refreshRooms
  , []

  <>
    <FlatList
      data={rooms}
      renderItem={(data) -> renderRoom onEnterRoom, theme, styles, data}/>
  </>

buildStyles = (theme) ->
    styleRoomItem:
      flex: 1
      flexDirection: "row"
      alignSelf: "stretch"
    styleRoomAvatar:
      width: 56
      height: 56
      borderRadius: 28
      margin: 16
    styleTextContainer:
      flex: 1
      flexDirection: "column"
      alignSelf: "stretch"
      marginTop: 16
      marginStart: 6
      marginBottom: 16
      marginEnd: 16
    styleTextTitle:
      fontSize: 16
      fontWeight: "bold"
      color: theme.COLOR_TEXT_ON_BACKGROUND
    styleTextSummary:
      fontSize: 14
      marginTop: 8
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND