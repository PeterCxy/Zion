import React, { useContext, useEffect, useMemo, useState } from "react"
import { Appbar } from "react-native-paper"
import Avatar from "../components/Avatar"
import { MatrixClientContext } from "../util/client"

export default Chat = ({route, navigation}) ->
  {roomId} = route.params
  client = useContext MatrixClientContext
  # Because rooms are mutable, they are not compatible with React
  # So we need to first extract the initial state and keep them
  # as-is. DO NOT use initialRoom anymore.
  initialRoom = useMemo ->
    client.getRoom roomId
  , [roomId]
  initialName = useMemo ->
    initialRoom.name
  , [roomId]
  initialAvatar = useMemo ->
    initialRoom.getAvatarUrl client.getHomeserverUrl(), 64, 64, "scale", false
  , [roomId]

  [name, setName] = useState initialName
  [avatar, setAvatar] = useState initialAvatar

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
  </>

styleAvatar =
  width: 40
  height: 40
  borderRadius: 20
  marginLeft: 10