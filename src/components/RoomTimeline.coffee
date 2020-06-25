import React, { useCallback, useContext, useEffect, useMemo, useState } from "react"
import { FlatList, Text, View } from "react-native"
import { EventTimeline, TimelineWindow } from "matrix-js-sdk"
import Avatar from "./Avatar"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"

# Transform raw events to what we show in the timeline
transformEvents = (client, events) ->
  events.map (ev) ->
    res = transformEvent client, ev
    Object.assign {}, res,
      key: ev.getId()
      ts: ev.getTs()
      self: ev.sender.userId == client.getUserId()
  .reverse() # The FlatList itself has been inverted, so we have to invert again

transformEvent = (client, ev) ->
  switch ev.getType()
    when "m.room.message" then messageEvent client, ev
    else unknownEvent ev

messageEvent = (client, ev) ->
  ret =
    sender:
      name: ev.sender.name
      avatar: ev.sender.getAvatarUrl client.getHomeserverUrl(), 32, 32, "scale", false

  content = ev.getContent()
  switch content.msgtype
    when "m.text"
      ret.type = 'msg_text'
      ret.text = content.body
    else
      ret.type = 'unknown'
      ret.ev_type = "msg_#{content.msgtype}"

  ret

unknownEvent = (ev) ->
    type: 'unknown'
    ev_type: ev.getType()

# Rendering functions
renderEvent = (styles, ev) ->
  lineStyle = styles.styleLineWrapper
  if ev.self
    lineStyle = styles.styleLineWrapperReverse

  <View style={lineStyle}>
  {
    switch ev.type
      when 'msg_text' then renderTxtMsg styles, ev
      when 'unknown' then renderUnknown ev
  }
  </View>

renderTxtMsg = (styles, msg) ->
  <>
    <Avatar
      style={if msg.self then styles.styleMsgAvatarReverse else styles.styleMsgAvatar}
      name={msg.sender.name}
      url={msg.sender.avatar}/>
    <Text
      style={if msg.self then styles.styleMsgBubbleReverse else styles.styleMsgBubble}>
      {msg.text}
    </Text>
  </>

renderUnknown = (ev) ->
  <Text>{translate "room_event_unknown", ev.ev_type}</Text>

export default RoomTimeline = ({roomId}) ->
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles

  # The Room object
  # this is internally mutable
  mutRoom = useMemo ->
    client.getRoom roomId
  , [roomId]

  # The TimelineWindow object
  # this is internally mutable
  mutTlWindow = useMemo ->
    new TimelineWindow client, mutRoom.getUnfilteredTimelineSet()

  # These  should be transformed events
  # that are immutable and contain information
  # enough for rendering
  [events, setEvents] = useState []
  # Initialize to the loading state
  [loading, setLoading] = useState true

  # Callback to update events
  updateEvents = useCallback ->
    setEvents transformEvents client, mutTlWindow.getEvents()
  , []

  # Initialize the timeline window
  useEffect ->
    do ->
      await mutTlWindow.load()
      updateEvents()

      # TODO: register timeline update event listener
    return
  , []

  <>
    <FlatList
      inverted
      data={events}
      renderItem={(data) -> renderEvent styles, data.item}/>
  </>

buildStyles = (theme) ->
  styles =
    styleLineWrapper:
      alignSelf: "stretch"
      flexDirection: "row"
      padding: 10
    styleLineWrapperReverse:
      flexDirection: "row-reverse"
    styleMsgAvatar:
      width: 32
      height: 32
      marginEnd: 10
      borderRadius: 16
    styleMsgAvatarReverse:
      marginStart: 10
      marginEnd: 0
    styleMsgBubble:
      backgroundColor: theme.COLOR_CHAT_BUBBLE
      color: theme.COLOR_CHAT_TEXT
      maxWidth: '80%'
      padding: 10
      borderRadius: 8
      fontSize: 14
    styleMsgBubbleReverse:
      backgroundColor: theme.COLOR_PRIMARY
      color: theme.COLOR_TEXT_PRIMARY

  styles.styleLineWrapperReverse =
    Object.assign {}, styles.styleLineWrapper, styles.styleLineWrapperReverse
  styles.styleMsgAvatarReverse =
    Object.assign {}, styles.styleMsgAvatar, styles.styleMsgAvatarReverse
  styles.styleMsgBubbleReverse =
    Object.assign {}, styles.styleMsgBubble, styles.styleMsgBubbleReverse

  styles