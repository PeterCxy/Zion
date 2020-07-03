import React, { useContext, useEffect, useMemo, useState } from "react"
import { View } from "react-native"
import { Appbar } from "react-native-paper"
import RoomList from "../components/RoomList"
import { translate } from "../util/i18n"
import { MatrixClientContext } from "../util/client"

STATE_ERROR = -1
STATE_SYNCING = 0
STATE_CONNECTING = 1
STATE_LIVE = 2

export default HomeRoomList = ({navigation}) ->
  stateMessages = useMemo ->
    return
      [STATE_ERROR]: translate 'sync_state_error'
      [STATE_SYNCING]: translate 'sync_state_syncing'
      [STATE_CONNECTING]: translate 'sync_state_connecting'
      [STATE_LIVE]: translate 'sync_state_live'
  , []

  client = useContext MatrixClientContext

  # Use our own sync states to accomodate for possible API changes
  [syncState, setSyncState] = useState STATE_CONNECTING

  # Listen for connection state changes
  useEffect ->
    onStateChange = (state, prevState, data) ->
      switch
        when state is 'SYNCING' and data? and data.catchingUp
          setSyncState STATE_SYNCING
        when state is 'SYNCING' and (not data? or not data.catchingUp)
          setSyncState STATE_LIVE
        when state is 'ERROR'
          setSyncState STATE_ERROR
        when state is 'RECONNECTING' or state is 'PREPARED'
          setSyncState STATE_CONNECTING

    client.on 'sync', onStateChange

    return ->
      client.removeListener 'sync', onStateChange
  , []

  <>
    <Appbar.Header>
      <Appbar.Action
        icon="menu"
        onPress={-> navigation.openDrawer()}/>
      <Appbar.Content
        title={translate "app_name"}
        subtitle={stateMessages[syncState]}/>
    </Appbar.Header>
    <RoomList onEnterRoom={(roomId) -> navigation.navigate "Chat", roomId: roomId}/>
  </>
