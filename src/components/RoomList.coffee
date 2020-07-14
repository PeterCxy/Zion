import React, { useCallback, useContext, useEffect, useRef, useState } from "react"
import { Image, FlatList, PixelRatio, Text, View } from "react-native"
import { TouchableRipple } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import { useNavigation } from '@react-navigation/native'
import Avatar from "./Avatar"
import AvatarBadgeWrapper from "./AvatarBadgeWrapper"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
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
        encrypted: client.isRoomEncrypted room.roomId
        favorite: room.tags['m.favourite']? # we don't follow the "order" as in Riot Web
    .sort (x, y) ->
      # Prioritize favorite rooms
      if x.favorite and not y.favorite
        -1
      else if not x.favorite and y.favorite
        1
      else
        y.timestamp - x.timestamp

getLatestMessage = (room) ->
  events = room.getLiveTimeline().getEvents()
  latest = events[events.length - 1]
  [latest.getTs(), mext.eventToDescription(latest)]

renderRoom = (theme, styles, {item}) ->
  <RoomComponent
    theme={theme}
    styles={styles}
    item={item}/>

# Use a standalone component to prevent excessive re-rendering
RoomComponent = React.memo ({theme, styles, item}) ->
  navigation = useNavigation()
  avatarDataRef = useRef null

  <TouchableRipple
    onPress={->
      navigation.navigate "Chat",
        roomId: item.key
        avatarPlaceholder: avatarDataRef.current
    }
    rippleColor={theme.COLOR_RIPPLE}
    style={styles.styleRoomItem}>
    <View style={styles.styleRoomItem}>
      <AvatarBadgeWrapper
        style={styles.styleRoomAvatarWrapper}
        icon={if item.encrypted then "shield"}>
        <SharedElement id={"room.#{item.key}.avatar"}>
          <Avatar
            style={styles.styleRoomAvatar}
            dataRef={avatarDataRef}
            name={item.name}
            url={item.avatar}/>
        </SharedElement>
      </AvatarBadgeWrapper>
      <View style={styles.styleTextContainer}>
        <Text numberOfLines={1} style={styles.styleTextTitle}>{item.name}</Text>
        <Text numberOfLines={1} style={styles.styleTextSummary}>{item.summary}</Text>
        <Text numberOfLines={1} style={styles.styleTextTime}>
          {
            if new Date().getTime() - item.timestamp < 24 * 60 * 60 * 1000
              # Show time (HH:MM) if the latest message is within 24 hours
              util.formatTime new Date item.timestamp
            else
              # Show date if the latest message is more than a day ago
              new Date(item.timestamp).toLocaleDateString undefined,
                weekday: 'short'
                year: 'numeric'
                month: 'short'
                day: 'numeric'
          }
        </Text>
      </View>
      {
        if item.favorite
          <View style={styles.styleFavoriteWrapper}>
            <Icon
              name="star"
              size={18}
              color={theme.COLOR_ACCENT}/>
          </View>
      }
    </View>
  </TouchableRipple>
, (x, y) -> JSON.stringify(x.item) == JSON.stringify(y.item)

export default RoomList = () ->
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
      renderItem={(data) -> renderRoom theme, styles, data}/>
  </>

buildStyles = (theme) ->
    styleRoomItem:
      flex: 1
      flexDirection: "row"
      alignSelf: "stretch"
      alignItems: "center"
      borderBottomWidth: 1 / PixelRatio.get()
      borderBottomColor: theme.COLOR_ROOM_LIST_DIVIDER
    styleRoomAvatarWrapper:
      width: 56
      height: 56
      margin: 16
    styleRoomAvatar:
      width: 56
      height: 56
      borderRadius: 28
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
    styleTextTime:
      fontSize: 13
      marginTop: 8
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
    styleFavoriteWrapper:
      justifyContent: 'center'
      alignItems: 'center'
      padding: 10