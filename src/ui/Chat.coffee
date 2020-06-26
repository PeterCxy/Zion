import React, { useContext, useEffect, useMemo, useState } from "react"
import { Appbar } from "react-native-paper"
import Avatar from "../components/Avatar"
import RoomTimeline from "../components/RoomTimeline"
import { MatrixClientContext } from "../util/client"

export default Chat = ({route, navigation}) ->
  {roomId} = route.params
  client = useContext MatrixClientContext

  # Set initial states
  # Note that the room objects themselves are mutable,
  # so we should NOT keep references to them and depend
  # on their internal state. Instead, we should only
  # update the state based on events.
  [name, setName] = useState -> client.getRoom(roomId).name
  [avatar, setAvatar] = useState ->
    client.getRoom roomId
      .getAvatarUrl client.getHomeserverUrl(), 64, 64, "scale", false

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
        style={styleAvatar}/>
      <Appbar.Content title={name} />
    </Appbar.Header>
    <RoomTimeline roomId={roomId}/>
  </>

styleAvatar =
  width: 40
  height: 40
  borderRadius: 20
  marginLeft: 10