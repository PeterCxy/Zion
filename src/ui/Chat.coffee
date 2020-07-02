import React, { useContext, useEffect, useState } from "react"
import { View } from "react-native"
import { Appbar, ProgressBar } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import Avatar from "../components/Avatar"
import AvatarBadgeWrapper from "../components/AvatarBadgeWrapper"
import RoomTimeline from "../components/RoomTimeline"
import MessageComposer from "../components/MessageComposer"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"
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
  [isEncrypted, setIsEncrypted] = useState -> client.isRoomEncrypted roomId
  [loading, setLoading] = useState true
  [hasUntrustedDevice, setHasUntrustedDevice] = useState false

  # Listen to room name updates
  # TODO: also implement room avatar / encrypted state updates?
  useEffect ->
    unmounted = false

    onNameChange = (room) ->
      return if room.roomId != roomId
      setName room.name

    client.on 'Room.name', onNameChange

    do ->
      res = await client.getRoom(roomId).hasUnverifiedDevices()
      setHasUntrustedDevice res unless unmounted

    return ->
      unmounted = true
      client.removeListener 'Room.name', onNameChange
  , []

  <>
    <Appbar.Header>
      <Appbar.BackAction onPress={-> navigation.goBack()}/>
      <AvatarBadgeWrapper
        icon={if isEncrypted then "shield"}
        color={if hasUntrustedDevice then theme.COLOR_ROOM_BADGE_UNTRUSTED}
        style={styles.styleAvatarWrapper}>
        <SharedElement id={"room.#{roomId}.avatar"}>
          <Avatar
            name={name}
            url={avatar}
            style={styles.styleAvatar}/>
        </SharedElement>
      </AvatarBadgeWrapper>
      <Appbar.Content
        title={name}
        subtitle={if hasUntrustedDevice then translate "room_has_untrusted_devices"}/>
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

Chat.sharedElements = (route, otherRoute, showing) ->
  # Only use the avatar animation when coming from or to room list
  # (because we don't share the avatar with ImageViewerScreen)
  if otherRoute.name == "HomeRoomList"
    ["room.#{route.params.roomId}.avatar"]

buildStyles = (theme) ->
    styleContentWrapper:
      flex: 1
      flexDirection: 'column-reverse' # To make sure ProgressBar always appear on top
      alignSelf: 'stretch'
    styleAvatarWrapper:
      width: 40
      height: 40
      marginStart: 10
    styleAvatar:
      width: 40
      height: 40
      borderRadius: 20
    styleProgress:
      width: '100%'
      height: 2
      backgroundColor: 'rgba(0, 0, 0, 0)'
    styleTimeline:
      marginTop: -2 # Make progress bar overlay the timeline itself