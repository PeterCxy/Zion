import React, { useCallback, useContext, useEffect, useRef, useState } from "react"
import { FlatList } from "react-native"
import { FAB } from "react-native-paper"
import { EventTimeline, EventStatus, TimelineWindow } from "matrix-js-sdk"
import Avatar from "./Avatar"
import EventComponent from "./events/Event"
import { MatrixClientContext } from "../util/client"
import { transformEvents } from "../util/timeline"
import * as util from "../util/util"

export default RoomTimeline = (props) ->
  # We can force reload RoomTimelineInner by incrementing the key
  # This is used when the user clicks on the FAB to force
  # load the latest timeline state.
  [key, setKey] = useState 0

  <RoomTimelineInner
    key={key}
    forceReload={-> setKey key + 1}
    {...props}/>

RoomTimelineInner = ({roomId, onLoadingStateChange, onMessageSelected, style, forceReload}) ->
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

  # Because we cannot proceed the TimelineWindow forwards when the user scrolls back,
  # (due to an inherent limitation of FlatList of React Native)
  # we cannot receive redactions / reactions either unless the list
  # stays at scroll position 0.
  # This is a terrible experience. However since redactions and reactions
  # do not show up as separate items in the list, only adding them would
  # not result in any trouble
  # Therefore we keep a separate list of new redaction / reaction events
  # when the user is scrolling back and app. When a new redaction / reaction
  # is received, it is appended to this list, and when rendering, they are
  # appended to the usual event list as normal events.
  # We make this a mutable Ref to simplify the code handling this, and to avoid
  # worrying about state inconsistencies.
  # We also use a map from id to event to facilitate deduplication
  liveMessageStateEventsRef = useRef {}

  # Callback to update events
  updateEvents = useCallback ->
    events = getTlWindow().getEvents()

    # Deduplicate the temporary live state events list
    # because if an event is available from the TimelineWindow,
    # then the user must have scrolled to the latest timeline at
    # some point
    for ev in events
      if liveMessageStateEventsRef.current[ev.getId()]?
        delete liveMessageStateEventsRef.current[ev.getId()]

    liveEvents = Object.values liveMessageStateEventsRef.current

    setEvents transformEvents client,
      [...events, ...liveEvents, ...client.getRoom(roomId).getPendingEvents()]
  , []

  # Initialize the timeline window
  useEffect ->
    # We might be in the middle of the transition animation
    # So let's wait until that finishes before we load
    util.asyncRunAfterInteractions ->
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
    # (reference: https://github.com/facebook/react-native/issues/25239
    #  , basically, if we add new items to the head of the list,
    #  React Native won't behave nicely for us)
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
        res = await util.asyncRunAfterInteractions ->
          getTlWindow().paginate EventTimeline.FORWARDS, 20, false
        if not res
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
    await util.asyncRunAfterInteractions -> updateEvents()
    # We can send receipt because if we reached here, the client must be at the
    # bottom of the timeline
    # We don't care about whether this is actually sent or not
    updateReadReceipt()
    return Promise.resolve true
  , []

  # Register timeline update event listener
  useEffect ->
    return if not initialized

    onTimelineUpdate = (ev, room, toStartOfTimeline, removed, {liveEvent}) ->
      return if not room or room.roomId != roomId
      unless await loadUntilLatest()
        # If the user is scrolling back, as described above,
        # we have to keep a separate list of new message state events
        # (redactions and reactions etc.)
        # so that these will be reflected in the timeline
        evType = ev.getType()
        return unless liveEvent and (evType is "m.reaction" or evType is "m.room.redaction")
        liveMessageStateEventsRef.current[ev.getId()] = ev
        updateEvents()

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
      await util.asyncRunAfterInteractions ->
        getTlWindow().paginate EventTimeline.BACKWARDS, 20
      await util.asyncRunAfterInteractions -> updateEvents()
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
      renderItem={(data) -> <EventComponent ev={data.item} onMessageSelected={onMessageSelected}/>}/>
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
