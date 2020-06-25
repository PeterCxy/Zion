import React, { useCallback, useContext, useEffect, useMemo, useState } from "react"
import { FlatList, Text } from "react-native"
import { EventTimeline, TimelineWindow } from "matrix-js-sdk"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"

# Transform raw events to what we show in the timeline
transformEvents = (events) ->
  events.map transformEvent

transformEvent = (ev) ->
    unknownEvent ev

unknownEvent = (ev) ->
    type: 'unknown'
    key: ev.getId()
    ev_type: ev.getType()

# Rendering functions
renderEvent = (ev) ->
  switch ev.type
    when 'unknown' then renderUnknown ev

renderUnknown = (ev) ->
  <Text>{translate "room_event_unknown", ev.ev_type}</Text>

export default RoomTimeline = ({roomId}) ->
  client = useContext MatrixClientContext

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
    setEvents transformEvents mutTlWindow.getEvents()
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
      renderItem={(data) -> renderEvent data.item}/>
  </>
