import React, { useCallback, useContext, useEffect, useRef, useState } from "react"
import { FlatList } from "react-native"
import { FAB } from "react-native-paper"
import { EventTimeline, EventStatus, TimelineWindow } from "matrix-js-sdk"
import Avatar from "./Avatar"
import EventComponent from "./events/Event"
import { translate } from "../util/i18n"
import { MatrixClientContext } from "../util/client"
import * as mext from "../util/matrix"

# Transform raw events to what we show in the timeline
transformEvents = (client, events) ->
  redacted = []
  replaced = {}

  events
    # The FlatList itself has been inverted, so we have to invert again
    # Also, this allows us to see redaction / edits before the actual event
    .reverse()
    .map (ev, idx, array) ->
      res = transformEvent client, ev, redacted, replaced
      # Some events themselves do not need to be shown, like redactions
      return null if not res?
      Object.assign {}, res,
        key: ev.getId()
        ts: ev.getTs()
        prev_ts: array[idx - 1]?.getTs()
        sender:
          name: ev.sender.name
          avatar: mext.calculateMemberSmallAvatarURL client, ev.sender
          tinyAvatar: mext.calculateMemberTinyAvatarURL client, ev.sender
        self: ev.sender.userId == client.getUserId()
        sent: (not ev.status?) or (ev.status == EventStatus.SENT)
        # TODO: handle errored pending events
    .filter (ev) -> ev?

transformEvent = (client, ev, redacted, replaced) ->
  if ev.getId() in redacted
    return redactedEvent ev

  content = ev.getContent()
  # Handle replacement (edits)
  if replaced[ev.getId()]
    content = Object.assign {}, replaced[ev.getId()].newContent
    content.edited = true
  if ev.isRelation 'm.replace'
    origId = ev.getAssociatedId()
    ts = ev.getTs()
    if replaced[origId]? and replaced[origId].ts > ts
      # We only take the latest replacement
      return null
    replaced[origId] =
      ts: ts
      newContent: content['m.new_content']
    return null

  switch ev.getType()
    when "m.room.message" then messageEvent client, content
    when "m.sticker" then stickerEvent client, content
    when "m.room.encrypted" then encryptedEvent ev
    when "m.room.redaction"
      redacted.push ev.getAssociatedId()
      null
    else
      if mext.isStateEvent ev
        stateEvent ev
      else
        unknownEvent ev

redactedEvent = (ev) ->
    type: 'msg_text'
    body: translate 'room_msg_redacted'

messageEvent = (client, content) ->
  ret = {}
  
  switch content.msgtype
    when "m.text", "m.notice"
      #console.log content
      switch content.format
        when 'org.matrix.custom.html'
          ret.type = 'msg_html'
          ret.body = content.formatted_body
        else
          ret.type = 'msg_text'
          ret.body = content.body
    when "m.image"
      ret.type = 'msg_image'
      # TODO: handle encrypted images
      ret.info =
        width: content.info.w
        height: content.info.h
        url: content.url
      ret.info.thumbnail = if content.info.thumbnail?
          width: content.info.thumbnail_info.w
          height: content.info.thumbnail_info.h
          url: content.info.thumbnail_url
      else
        ret.info
    when "m.bad.encrypted"
      ret.type = 'msg_text'
      ret.body = translate 'room_msg_bad_encryption'
    else
      ret.type = 'unknown'
      ret.ev_type = "msg_#{content.msgtype}"

  if content.edited
    ret.edited = true

  ret

stickerEvent = (client, content) ->
  return
    type: 'msg_sticker'
    url: client.mxcUrlToHttp content.url, content.info.w, content.info.h, 'scale'
    width: content.info.w
    height: content.info.h

encryptedEvent = (ev) ->
    type: 'msg_text' # Pretend it's a message and show a placeholder
    body: translate 'room_msg_encrypted_placeholder'

stateEvent = (ev) ->
    type: 'room_state'
    body: mext.eventToDescription ev

unknownEvent = (ev) ->
    type: 'unknown'
    ev_type: ev.getType()

export default RoomTimeline = (props) ->
  # We can force reload RoomTimelineInner by incrementing the key
  # This is used when the user clicks on the FAB to force
  # load the latest timeline state.
  [key, setKey] = useState 0

  <RoomTimelineInner
    key={key}
    forceReload={-> setKey key + 1}
    {...props}/>

RoomTimelineInner = ({roomId, onLoadingStateChange, style, forceReload}) ->
  client = useContext MatrixClientContext

  # Record the current onLoadingStateChange callback
  # For all of our asynchronous operations
  # (because the callback may change when async operations finish)
  loadingChangeRef = useRef onLoadingStateChange
  loadingChangeRef.current = onLoadingStateChange

  # Record scroll position using a mutable ref
  scrollPosRef = useRef 0

  # Ref to the flat list
  flatListRef = useRef null

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
  # If true, a button is shown to the user to jump to the latest
  # timeline.
  [hasNewerEvents, setHasNewerEvents] = useState false
  [initialized, setInitialized] = useState false
  # Initialize to the loading state
  [loading, _setLoading] = useState true
  setLoading = useCallback (newValue) ->
    _setLoading newValue
    loadingChangeRef.current newValue
  , []

  # Callback to update events
  updateEvents = useCallback ->
    setEvents transformEvents client,
      [...getTlWindow().getEvents(), ...client.getRoom(roomId).getPendingEvents()]
  , []

  # Initialize the timeline window
  useEffect ->
    do ->
      await getTlWindow().load()
      updateEvents()
      updateReadReceipt()
      setInitialized true
      setLoading false
    return
  , []

  # Update read receipt to the latest event in window
  updateReadReceipt = useCallback ->
    events = getTlWindow().getEvents()
    client.sendReadReceipt events[events.length - 1]
  , []

  # Load all events that are present in memory until cannot load anymore
  # makes no API request. If there is a need for request, we show the
  # FAB to let the user reload the timeline.
  loadUntilLatest = useCallback (ignoreScrollPos = false) ->
    # If the user is scrolling back, tell the user that the latest position
    # must be jumped over using the button
    if (not ignoreScrollPos) and scrollPosRef.current != 0
      setHasNewerEvents true
      return Promise.resolve false
    # Do not make requests -- if we need to make requests, it means that
    # we have missed a lot of messages in between, in which case
    # the user should be responsible for jumping to the latest
    while getTlWindow().canPaginate EventTimeline.FORWARDS
      try
        # Note: Since we are making no requests, this "await" is actually synchronous
        #       so we don't need to care about the loading state either
        if not await getTlWindow().paginate EventTimeline.FORWARDS, 20, false
          break
      catch err
        console.warn err
        return Promise.resolve false
    if getTlWindow().canPaginate EventTimeline.FORWARDS
      # We have missed some events between the latest and the last loaded one
      # and have to fetch from API
      # Therefore, show the FAB to jump to current timeline
      setHasNewerEvents true
      return Promise.resolve false
    setHasNewerEvents false
    updateEvents()
    # We can send receipt because if we reached here, the client must be at the
    # bottom of the timeline
    # We don't care about whether this is actually sent or not
    updateReadReceipt()
    return Promise.resolve true
  , []

  # Register timeline update event listener
  useEffect ->
    return if not initialized

    onTimelineUpdate = (_, room) ->
      return if not room or room.roomId != roomId
      loadUntilLatest()

    onEventDecrypted = (ev) ->
      return if roomId != ev.getRoomId()
      loadUntilLatest()

    client.on 'Room.timeline', onTimelineUpdate
    client.on 'Room.localEchoUpdated', onTimelineUpdate # For message sent status
    client.on 'Event.decrypted', onEventDecrypted

    return ->
      client.removeListener 'Room.timeline', onTimelineUpdate
      client.removeListener 'Room.localEchoUpdated', onTimelineUpdate
      client.removeListener 'Event.decrypted', onEventDecrypted
  , [initialized]

  # Detect scroll to end
  onEndReached = useCallback ->
    return if loading # Do not load while loading
    return if not getTlWindow().canPaginate EventTimeline.BACKWARDS

    setLoading true
    try
      await getTlWindow().paginate EventTimeline.BACKWARDS, 20
      updateEvents()
    catch err
      console.warn err
    setLoading false
  , [loading]

  # Other scroll events
  onScroll = useCallback (scrollEv) ->
    lastY = scrollPosRef.current
    scrollPosRef.current = scrollEv.nativeEvent.contentOffset.y
    if lastY != 0 and scrollPosRef.current == 0
      # If the user has scrolled back to bottom,
      # we try to load back events that may be present in memory
      # If we fail, we keep showing the jump-to-latest FAB
      loadUntilLatest()
  , []

  # The jump-to-latest button
  onJumpToLatest = useCallback ->
    if not await loadUntilLatest true
      # If there are messages that we need to fetch from API
      # we need to force reload this screen to jump to the
      # latest live timeline
      # But first we need to reset the loading status on the parent
      setLoading true
      forceReload()
    else
      # Otherwise, if everything we need for latest is in memory,
      # just scroll to the start.
      flatListRef.current.scrollToOffset 0
  , []

  <>
    <FlatList
      inverted
      ref={flatListRef}
      style={style}
      data={events}
      onEndReached={onEndReached}
      onEndReachedThreshold={1}
      onScroll={onScroll}
      renderItem={(data) -> <EventComponent ev={data.item}/>}/>
    <FAB
      style={{
        position: 'absolute',
        margin: 16,
        right: 0,
        bottom: 0,
        elevation: 10
      }}
      visible={hasNewerEvents}
      icon="arrow-down"
      onPress={onJumpToLatest}/>
  </>
