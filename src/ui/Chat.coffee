import React, { useContext, useEffect, useState } from "react"
import { View } from "react-native"
import { Appbar, ProgressBar } from "react-native-paper"
import Avatar from "../components/Avatar"
import RoomTimeline from "../components/RoomTimeline"
import MessageComposer from "../components/MessageComposer"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import * as mext from "../util/matrix"

export default Chat = ({route, navigation}) ->
  {roomId} = route.params
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles

  # Set initial states
  # Note that the room objects themselves are mutable,
  # so we should NOT keep references to them and depend
  # on their internal state. Instead, we should only
  # update the state based on events.
  [name, setName] = useState -> client.getRoom(roomId).name
  [avatar, setAvatar] = useState ->
    mext.calculateRoomAvatarURL client, client.getRoom roomId
  [loading, setLoading] = useState true

  # Listen to room name updates
  # TODO: also implement room avatar updates?
  useEffect ->
    onNameChange = (room) ->
      return if room.roomId != roomId
      setName room.name

    client.on 'Room.name', onNameChange

    return ->
      client.removeListener 'Room.name', onNameChange
  , []

  <>
    <Appbar.Header>
      <Appbar.BackAction onPress={-> navigation.goBack()}/>
      <Avatar
        name={name}
        url={avatar}
        style={styles.styleAvatar}/>
      <Appbar.Content title={name} />
    </Appbar.Header>
    <View style={styles.styleContentWrapper}>
      <RoomTimeline
        style={styles.styleTimeline}
        roomId={roomId}
        onLoadingStateChange={setLoading}/>
      <ProgressBar
        style={styles.styleProgress}
        indeterminate={true}
        color={theme.COLOR_ACCENT}
        visible={loading}/>
    </View>
    <MessageComposer
      roomId={roomId}/>
  </>

buildStyles = (theme) ->
    styleContentWrapper:
      flex: 1
      flexDirection: 'column-reverse' # To make sure ProgressBar always appear on top
      alignSelf: 'stretch'
    styleAvatar:
      width: 40
      height: 40
      borderRadius: 20
      marginLeft: 10
    styleProgress:
      width: '100%'
      height: 2
      backgroundColor: 'rgba(0, 0, 0, 0)'
    styleTimeline:
      marginTop: -2 # Make progress bar overlay the timeline itself