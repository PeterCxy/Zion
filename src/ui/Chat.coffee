import React, { useContext, useEffect, useState } from "react"
import { Appbar, ProgressBar } from "react-native-paper"
import Avatar from "../components/Avatar"
import RoomTimeline from "../components/RoomTimeline"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"

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
    client.getRoom roomId
      .getAvatarUrl client.getHomeserverUrl(), 64, 64, "scale", false
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
    <ProgressBar
      style={styles.styleProgress}
      indeterminate={true}
      color={theme.COLOR_ACCENT}
      visible={loading}/>
    <RoomTimeline
      roomId={roomId}
      onLoadingStateChange={setLoading}/>
  </>

buildStyles = (theme) ->
    styleAvatar:
      width: 40
      height: 40
      borderRadius: 20
      marginLeft: 10
    styleProgress:
      width: 'auto'
      height: 2
      alignSelf: 'stretch'
      backgroundColor: theme.COLOR_BACKGROUND