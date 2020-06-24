import React, { useCallback, useContext, useEffect, useState } from "react"
import { Image, FlatList, Text, View } from "react-native"
import { TouchableRipple } from "react-native-paper"
import Avatar from "./Avatar"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"

# Transform a list of rooms received from the SDK
# to a list that we can use
transformRooms = (client, rooms) ->
  rooms.map (room) ->
    [ts, desc] = getLatestMessage room

    return
      _room: room
      key: room.roomId
      name: room.name
      avatar: room.getAvatarUrl client.getHomeserverUrl(), 64, 64, "scale", false
      summary: desc
      timestamp: ts
  .sort (x, y) -> y.timestamp - x.timestamp

getLatestMessage = (room) ->
  events = room.getLiveTimeline().getEvents()
  latest = events[events.length - 1]
  [latest.getTs(), eventToDescription(latest)]

eventToDescription = (ev) ->
  #console.log "type = #{ev.getType()}"
  switch ev.getType()
    when 'm.room.message'
      "#{ev.sender.name}: #{messageToDescription ev.getContent()}"
    when 'm.room.create'
      translate "room_event_created"
    when 'm.sticker'
      translate("room_event_sticker").replace "%", ev.sender.name
    else '...'

messageToDescription = (content) ->
  #console.log "msgType = #{content.msgtype}"
  switch content.msgtype
    when "m.text" then content.body

renderRoom = (theme, styles, {item}) ->
  <TouchableRipple
    onPress={->}
    rippleColor={theme.COLOR_RIPPLE}
    style={styles.styleRoomItem}>
    <View style={styles.styleRoomItem}>
      <Avatar
        style={styles.styleRoomAvatar}
        name={item.name}
        url={item.avatar}/>
      <View style={styles.styleTextContainer}>
        <Text numberOfLines={1} style={styles.styleTextTitle}>{item.name}</Text>
        <Text numberOfLines={1} style={styles.styleTextSummary}>{item.summary}</Text>
      </View>
    </View>
  </TouchableRipple>

export default RoomList = () ->
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  [rooms, setRooms] = useState []

  refreshRooms = useCallback ->
    newRooms = transformRooms client, client.getRooms()
    setRooms newRooms
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
    
    return ->
      client.removeListener 'sync', refreshRooms
  , []

  <>
    <FlatList
      data={rooms}
      renderItem={(data) -> renderRoom theme, styles, data}/>
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