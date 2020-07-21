import React, { useContext, useEffect, useRef, useState } from "react"
import { View } from "react-native"
import { Appbar, ProgressBar } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import Avatar from "../components/Avatar"
import AvatarBadgeWrapper from "../components/AvatarBadgeWrapper"
import { BottomSheet, BottomSheetItem } from "../components/BottomSheet"
import RoomTimeline from "../components/RoomTimeline"
import MessageComposer from "../components/MessageComposer"
import { useEmojiPicker } from "../components/EmojiPicker"
import { useAssociatedMessageComposer } from "../components/AssociatedMessageComposer"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"
import * as mext from "../util/matrix"

export default Chat = ({route, navigation}) ->
  {roomId, avatarPlaceholder} = route.params
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles

  avatarDataRef = useRef null

  # Set initial states
  # Note that the room objects themselves are mutable,
  # so we should NOT keep references to them and depend
  # on their internal state. Instead, we should only
  # update the state based on events.
  [name, setName] = useState -> client.getRoom(roomId).name
  [memberCount, setMemberCount] = useState ->
    client.getRoom(roomId).getJoinedMemberCount()
  [avatar, setAvatar] = useState ->
    mext.calculateRoomAvatarURL client, client.getRoom roomId
  [isEncrypted, setIsEncrypted] = useState -> client.isRoomEncrypted roomId
  [loading, setLoading] = useState true
  [hasUntrustedDevice, setHasUntrustedDevice] = useState false

  # Operations available when the menu is triggered by long-clicking
  # the selectedMsg should be a transformed event as defined in
  # ../util/timeline.coffee
  [selectedMsg, setSelectedMsg] = useState null
  # Extra information associated with the selected message
  # see EventWithAvatar for details
  [selectedMsgExtraInfo, setSelectedMsgExtraInfo] = useState null

  [emojiPickerComponent, invokeEmojiPicker] = useEmojiPicker()
  [replyComposerComponent, invokeReplyComposer] =
    useAssociatedMessageComposer()

  # Listen to room name updates
  # TODO: also implement room avatar / encrypted state updates?
  useEffect ->
    unmounted = false

    onNameChange = (room) ->
      return if room.roomId != roomId
      setName room.name

    onMembershipChange = (event, state, member) ->
      return if member.roomId != roomId
      setMemberCount client.getRoom(roomId).getJoinedMemberCount()

    client.on 'Room.name', onNameChange
    client.on 'RoomState.members', onMembershipChange

    do ->
      res = await client.getRoom(roomId).hasUnverifiedDevices()
      setHasUntrustedDevice res unless unmounted

    return ->
      unmounted = true
      client.removeListener 'Room.name', onNameChange
      client.removeListener 'RoomState.members', onMembershipChange
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
            placeholder={avatarPlaceholder}
            dataRef={avatarDataRef}
            style={styles.styleAvatar}/>
        </SharedElement>
      </AvatarBadgeWrapper>
      <Appbar.Content
        onPress={->
          navigation.navigate "RoomDetails",
            roomId: roomId
            avatarPlaceholder: avatarDataRef.current
        }
        title={name}
        subtitle={
          if hasUntrustedDevice
            translate "room_has_untrusted_devices"
          else
            translate "room_member_count", memberCount
        }/>
    </Appbar.Header>
    <View style={styles.styleContentWrapper}>
      <RoomTimeline
        style={styles.styleTimeline}
        roomId={roomId}
        onMessageSelected={(msg, extraInfo) ->
          unless msg.redacted or (not msg.sent and not msg.failed)
            setSelectedMsgExtraInfo extraInfo
            setSelectedMsg msg
        }
        onLoadingStateChange={setLoading}/>
      <ProgressBar
        style={styles.styleProgress}
        indeterminate={true}
        color={theme.COLOR_ACCENT}
        visible={loading}/>
    </View>
    <MessageComposer
      onSendClicked={(text) ->
        try
          await mext.sendMessage client, roomId, text
        catch err
          # Get rid of yellow box on this...
          console.log "Failed to send message, error:"
          console.log err
      }
      onSendSticker={(stickerInfo) ->
        try
          await mext.sendSticker client, roomId, stickerInfo.content.url,
            stickerInfo.content.description, stickerInfo.content.info
        catch err
          console.log "Failed to send sticker, error:"
          console.log err
      }/>
    <MessageOpsMenu
      roomId={roomId}
      onDismiss={->
        setSelectedMsg null
        setSelectedMsgExtraInfo null
      }
      invokeEmojiPicker={invokeEmojiPicker}
      invokeReplyComposer={invokeReplyComposer}
      show={selectedMsg?}
      msg={selectedMsg}
      extraInfo={selectedMsgExtraInfo}/>
    {emojiPickerComponent}
    {replyComposerComponent}
  </>

Chat.sharedElements = (route, otherRoute, showing) ->
  # Only use the avatar animation when coming from or to room list
  # (because we don't share the avatar with ImageViewerScreen)
  if otherRoute.name == "HomeRoomList" or otherRoute.name == "RoomDetails"
    ["room.#{route.params.roomId}.avatar"]

MessageOpsMenu = ({show, msg, extraInfo, roomId, invokeEmojiPicker, invokeReplyComposer, onDismiss}) ->
  client = useContext MatrixClientContext

  <BottomSheet
    title={translate "msg_ops"}
    show={show}
    onClose={onDismiss}>
    {
      if not msg?.failed
        renderNormalMessageOpsMenu client, msg, extraInfo,
          roomId, invokeEmojiPicker, invokeReplyComposer, onDismiss
      else
        renderFailedMessageOpsMenu client, msg, roomId, onDismiss
    }
  </BottomSheet>

renderNormalMessageOpsMenu = (client, msg, extraInfo, roomId, invokeEmojiPicker, invokeReplyComposer, onDismiss) ->
  <>
    <BottomSheetItem
      icon="reply"
      title={translate "msg_ops_reply"}
      onPress={->
        onDismiss()
        try
          replyText = await invokeReplyComposer
            title: translate "msg_ops_reply"
            origMsg: msg
          await mext.sendMessage client, roomId, replyText, msg
        catch err
          console.log "reply failed, err:"
          console.log err
      }/>
    {
      if msg?.type is 'msg_text' or msg?.type is 'msg_html'
        # Only allow reactions for text messages
        <BottomSheetItem
          icon="emoticon"
          title={translate "msg_ops_reaction"}
          onPress={->
            onDismiss()
            try
              emoji = await invokeEmojiPicker()
              await mext.sendReaction client, roomId, msg.key, emoji.code
            catch err
              # Cancelled, just ignore
              console.log "emoji picker was cancelled or failed to send reaction"
          }/>
    }
    {
      if msg?.self and msg?.type isnt 'msg_attachment' and msg?.type isnt 'msg_image'
        # Allow editing messages from self
        # we don't merge this and redaction with a fragment
        # because that messes with the height calculation of BottomSheet
        <BottomSheetItem
          icon="pencil"
          title={translate "msg_ops_edit"}
          onPress={->
            onDismiss()
            try
              # Use the same composer as when we are replying
              # TODO: set initial text?
              newText = await invokeReplyComposer
                title: translate "msg_ops_edit"
                origMsg: msg
              await mext.sendEdit client, roomId, msg, newText
            catch err
              console.log "Failed to edit message, error:"
              console.log err
          }/>
    }
    {
      if extraInfo?.savable
        <BottomSheetItem
          icon="download"
          title={translate "msg_ops_save"}
          onPress={->
            onDismiss()
            try
              await extraInfo.save()
            catch err
              console.log "Failed to save message, error:"
              console.log err
          }/>
    }
    {
      if extraInfo?.shareable
        <BottomSheetItem
          icon="share"
          title={translate "msg_ops_share"}
          onPress={->
            onDismiss()
            extraInfo.share()
          }/>
    }
    {
      if msg?.self
        # Only allow redacting messages from self
        <BottomSheetItem
          icon="delete"
          title={translate "msg_ops_redact"}
          onPress={->
            onDismiss()
            try
              await mext.sendRedaction client, roomId, msg.key
            catch err
              console.log "Failed to redact event, error:"
              console.log err
          }/>
    }
  </>

renderFailedMessageOpsMenu = (client, msg, roomId, onDismiss) ->
  <>
    <BottomSheetItem
      icon="cancel"
      title={translate "cancel"}
      onPress={->
        onDismiss()
        mext.cancelEvent client, roomId, msg.key
      }/>
    <BottomSheetItem
      icon="refresh"
      title={translate "msg_ops_resend"}
      onPress={->
        onDismiss()
        try
          await mext.resendEvent client, roomId, msg.key
        catch err
          console.log "Failed to resend, error:"
          console.log err
      }/>
  </>

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
      borderWidth: 1
      borderColor: theme.COLOR_SECONDARY
    styleProgress:
      width: '100%'
      height: 2
      backgroundColor: 'rgba(0, 0, 0, 0)'
    styleTimeline:
      marginTop: -2 # Make progress bar overlay the timeline itself