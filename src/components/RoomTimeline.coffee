import React, { useCallback, useContext, useEffect, useRef, useState } from "react"
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
  date = new Date msg.ts

  <>
    <Avatar
      style={if msg.self then styles.styleMsgAvatarReverse else styles.styleMsgAvatar}
      name={msg.sender.name}
      url={msg.sender.avatar}/>
    <View
      style={if msg.self then styles.styleMsgBubbleReverse else styles.styleMsgBubble}>
      {
        if not msg.self
          <Text
            numberOfLines={1}
            style={styles.styleMsgSender}>
            {msg.sender.name}
          </Text>
      }
      <Text
        style={if msg.self then styles.styleMsgTextReverse else styles.styleMsgText}>
        {msg.text}
      </Text>
      <Text
        style={styles.styleMsgTime}>
        {translate "time_format_hour_minute",
          ('' + date.getHours()).padStart(2, '0'),
          ('' + date.getMinutes()).padStart(2, '0')}
      </Text>
    </View>
  </>

renderUnknown = (ev) ->
  <Text>{translate "room_event_unknown", ev.ev_type}</Text>

export default RoomTimeline = ({roomId}) ->
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles

  # The TimelineWindow object
  # this is internally mutable
  tlWindowRef = useRef null
  getTlWindow = useCallback ->
    if not tlWindowRef.current?
      tlWindowRef.current =
        new TimelineWindow client, client.getRoom(roomId).getUnfilteredTimelineSet()
    tlWindowRef.current
  , []

  # These  should be transformed events
  # that are immutable and contain information
  # enough for rendering
  [events, setEvents] = useState []
  # Initialize to the loading state
  [loading, setLoading] = useState true

  # Callback to update events
  updateEvents = useCallback ->
    setEvents transformEvents client, getTlWindow().getEvents()
  , []

  # Initialize the timeline window
  useEffect ->
    do ->
      await getTlWindow().load()
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
      maxWidth: '80%'
      paddingStart: 10
      paddingEnd: 10
      borderRadius: 8
    styleMsgBubbleReverse:
      backgroundColor: theme.COLOR_PRIMARY
    styleMsgText:
      fontSize: 14
      color: theme.COLOR_CHAT_TEXT
    styleMsgTextReverse:
      color: theme.COLOR_TEXT_PRIMARY
    styleMsgSender:
      fontSize: 12
      fontWeight: 'bold'
      marginTop: 5
      marginBottom: 5
      color: theme.COLOR_SECONDARY
    styleMsgTime:
      fontSize: 12
      marginTop: 5
      marginBottom: 5
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND

  styles.styleLineWrapperReverse =
    Object.assign {}, styles.styleLineWrapper, styles.styleLineWrapperReverse
  styles.styleMsgAvatarReverse =
    Object.assign {}, styles.styleMsgAvatar, styles.styleMsgAvatarReverse
  styles.styleMsgBubbleReverse =
    Object.assign {}, styles.styleMsgBubble, styles.styleMsgBubbleReverse
  styles.styleMsgTextReverse =
    Object.assign {}, styles.styleMsgText, styles.styleMsgTextReverse

  styles