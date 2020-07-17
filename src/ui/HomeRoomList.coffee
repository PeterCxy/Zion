import React, { useContext, useEffect, useMemo, useState } from "react"
import { View } from "react-native"
import { Appbar } from "react-native-paper"
import RoomList from "../components/RoomList"
import { BottomSheet, BottomSheetItem } from "../components/BottomSheet"
import { translate } from "../util/i18n"
import { MatrixClientContext } from "../util/client"
import * as mext from "../util/matrix"

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
  # Saves the current room object (as defined in RoomList.coffee)
  # selected via long-ress (short-press is handled in RoomList directly via navigation)
  [selectedRoom, setSelectedRoom] = useState null

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
    <RoomList
      onRoomSelected={setSelectedRoom}/>
    <BottomSheet
      title={translate "room_ops"}
      show={selectedRoom?}
      onClose={-> setSelectedRoom null}>
      {
        if not selectedRoom?.favorite
          <BottomSheetItem
            icon="star-outline"
            title={translate "room_ops_favorite"}
            onPress={->
              setSelectedRoom null
              try
                await mext.setRoomFavorite client, selectedRoom.key
              catch err
                console.log "cannot set room favorite"
                console.log err
            }/>
        else
          <BottomSheetItem
            icon="star"
            title={translate "room_ops_unfavorite"}
            onPress={->
              setSelectedRoom null
              try
                await mext.unsetRoomFavorite client, selectedRoom.key
              catch err
                console.log "cannot remove room favorite"
                console.log err
            }/>
      }
    </BottomSheet>
  </>
