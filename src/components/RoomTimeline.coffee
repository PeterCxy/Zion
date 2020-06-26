import React, { useCallback, useContext, useEffect, useRef, useState } from "react"
import { FlatList } from "react-native"
import linkifyHtml from 'linkifyjs/html'
import linkifyStr from 'linkifyjs/string'
import { EventTimeline, TimelineWindow } from "matrix-js-sdk"
import Avatar from "./Avatar"
import EventComponent from "./events/Event"
import { MatrixClientContext } from "../util/client"

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
      #console.log content
      switch content.format
        when 'org.matrix.custom.html'
          ret.type = 'msg_html'
          ret.html = linkifyHtml content.formatted_body
        else
          ret.type = 'msg_html' # We linkify and escape the content as HTML
          ret.html = linkifyStr content.body
    else
      ret.type = 'unknown'
      ret.ev_type = "msg_#{content.msgtype}"

  ret

unknownEvent = (ev) ->
    type: 'unknown'
    ev_type: ev.getType()

export default RoomTimeline = ({roomId, onLoadingStateChange}) ->
  client = useContext MatrixClientContext

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
  [loading, _setLoading] = useState true
  setLoading = useCallback (newValue) ->
    _setLoading newValue
    onLoadingStateChange newValue
  , [onLoadingStateChange]

  # Callback to update events
  updateEvents = useCallback ->
    setEvents transformEvents client, getTlWindow().getEvents()
  , []

  # Initialize the timeline window
  useEffect ->
    do ->
      await getTlWindow().load()
      updateEvents()
      setLoading false

      # TODO: register timeline update event listener
    return
  , []

  <FlatList
    inverted
    data={events}
    renderItem={(data) -> <EventComponent ev={data.item}/>}/>
