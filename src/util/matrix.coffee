# Extra functions for matrix
# Often imported as "mext" in other modules
import { translate } from "./i18n"
import { PixelRatio } from "react-native"
import Markdown from "./Markdown"
import escape from 'lodash/escape'

export AVATAR_SIZE_HUGE = 128 * PixelRatio.get()
export AVATAR_SIZE = 64 * PixelRatio.get()
export AVATAR_SIZE_SMALL = 32 * PixelRatio.get()
export AVATAR_SIZE_TINY = 24 * PixelRatio.get()

_calculateRoomAvatarURL = (client, room, size) ->
  roomAvatar = room.getAvatarUrl client.getHomeserverUrl(),
    size, size, "scale", false
  if roomAvatar?
    roomAvatar
  else
    room.getAvatarFallbackMember()?.getAvatarUrl client.getHomeserverUrl(),
      size, size, "scale", false

# Calculate avatar URL of a room
# if the room is a direct chat, and does not
# have an avatar of its own,
# return the avatar of the other user
# otherwise returns the room avatar directly
# null if none
export calculateRoomAvatarURL = (client, room) ->
  _calculateRoomAvatarURL client, room, AVATAR_SIZE

export calculateRoomHugeAvatarURL = (client, room) ->
  _calculateRoomAvatarURL client, room, AVATAR_SIZE_HUGE

# Calculate the small avatar URL of a room member
export calculateMemberSmallAvatarURL = (client, member) ->
  member.getAvatarUrl client.getHomeserverUrl(),
    AVATAR_SIZE_SMALL, AVATAR_SIZE_SMALL, "scale", false

export calculateMemberTinyAvatarURL = (client, member) ->
  member.getAvatarUrl client.getHomeserverUrl(),
    AVATAR_SIZE_TINY, AVATAR_SIZE_TINY, "scale", false

# Convert a known event to a description of the event
# that can be shown in room lists or as state events
# in the room timeline.
export eventToDescription = (ev) ->
  #console.log "type = #{ev.getType()}"
  switch ev.getType()
    when 'm.room.message'
      translate "room_event_message", ev.sender.name, messageToDescription ev.getContent()
    when 'm.room.encrypted'
      translate "room_event_message", ev.sender.name,
        translate "room_msg_encrypted_placeholder"
    when 'm.room.redaction'
      translate "room_event_message_redacted", ev.sender.name
    when 'm.reaction'
      translate "room_event_message", ev.sender.name, ev.getContent()["m.relates_to"]["key"]
    when 'm.room.create'
      translate "room_event_created"
    when 'm.sticker'
      translate "room_event_sticker", ev.sender.name
    when 'm.room.member'
      membershipToDescription ev
    when 'm.room.name'
      translate "room_event_name_changed", ev.sender.name, ev.getContent().name
    when 'm.room.server_acl'
      translate "room_event_server_acl_changed", ev.sender.name
    else translate "room_event_unknown", ev.getType()

messageToDescription = (content) ->
  #console.log "msgType = #{content.msgtype}"
  switch content.msgtype
    when "m.text", "m.notice" then content.body
    when "m.image" then translate 'room_event_image'
    when "m.bad.encrypted" then translate 'room_msg_bad_encryption'
    else translate "room_msg_unknown", content.msgtype

membershipToDescription = (ev) ->
  content = ev.getContent()
  prevContent = ev.getPrevContent()
  # <https://matrix.org/docs/spec/client_server/latest#m-room-member>
  switch
    when content.membership is 'invite'
      translate "room_event_invite", ev.sender.name, ev.target.name
    when content.membership is 'join' and prevContent.membership isnt 'join'
      translate "room_event_join", content.displayname
    when content.membership is 'join' and prevContent.membership is 'join'
      if prevContent.displayname isnt content.displayname
        translate "room_event_changed_name", content.displayname,
          prevContent.displayname
      else if (not prevContent.avatar_url?) and (not content.avatar_url?)
        # I don't know why Matrix IRC bridge produces a bunch of avatar changes
        # where the previous avatar is null while the current avatar is undefined
        ""
      else if prevContent.avatar_url isnt content.avatar_url
        translate "room_event_changed_avatar", content.displayname
    when content.membership is 'leave' and prevContent.membership is 'invite'
      if ev.getStateKey() == ev.getSender()
        translate "room_event_invite_rejected", content.displayname
      else
        translate "room_event_invite_revoked", ev.sender.name, ev.target.name
    when content.membership is 'leave' and prevContent.membership isnt 'ban'
      if ev.getStateKey() == ev.getSender()
        translate "room_event_leave", content.displayname
      else
        translate "room_event_kicked", ev.target.name
    when content.membership is 'leave' and prevContent.membership is 'ban'
      translate "room_event_unbanned", ev.target.name
    when content.membership is 'ban'
      translate "room_event_banned", ev.target.name
    else
      content.membership

# State events
STATE_EVENTS = [
  "m.room.create", "m.room.member",
  "m.room.name", "m.room.server_acl"
]

export isStateEvent = (ev) -> ev.getType() in STATE_EVENTS

export findPendingEventInRoom = (client, roomId, eventId) ->
  for ev in client.getRoom(roomId).getPendingEvents()
    if ev.getId() == eventId
      return ev
  return null

# matrix-react-sdk/src/editor/serialize.ts
# renders `text` into HTML if the text is written in Markdown
# or if forceHtml = true (when sending replies)
# Also renders HTML if the text contains Markdown backlash escapes
# when the text itself does not contain any Markdown format
# (e.g. text like `\*test\*` is not considered to be Markdown
#       because it renders to zero rich-text elements, but
#       showing this as-is would be very jarring)
export renderHtmlIfNeeded = (text, forceHtml = false) ->
  parser = new Markdown text
  if forceHtml or not parser.isPlainText()
    return parser.toHTML()
  if text.indexOf("\\") > -1
    return parser.toPlaintext()
  # Otherwise, don't return anything and the caller should
  # not attach formatted body

# Functions for sending different types of events
# `replyTo` should be a message object returned by
# `transformEvent` from `./timeline.coffee`.
# (null if not a reply)
export sendMessage = (client, roomId, text, replyTo) ->
  # TODO: how do we handle at-ing users
  content =
    msgtype: 'm.text'
    body: text

  richText = renderHtmlIfNeeded text, replyTo?
  if richText?
    content = Object.assign {}, content,
      format: 'org.matrix.custom.html'
      formatted_body: richText

  if replyTo?
    # A reply must be in rich text
    content.body = "> <#{replyTo.sender.id}> #{replyTo.plaintext}\n\n#{content.body}"
    content.formatted_body = """
      <mx-reply>
        <blockquote>
          <a href="https://matrix.to/#/#{roomId}/#{replyTo.key}">In reply to</a> 
          <a href="https://matrix.to/#/#{replyTo.sender.id}">#{replyTo.sender.id}</a>
          <br/>
          #{replyTo.body?.replace(/<mx-reply>.*<\/mx-reply>/g, '') ? escape(replyTo.plaintext)}
        </blockquote>
      </mx-reply>
    """ + content.formatted_body
    content.formatted_body = content.formatted_body
      .replace /^ +/gm, ''
      .replace /\n/g, ''
    content['m.relates_to'] =
      'm.in_reply_to':
        'event_id': replyTo.key

  client.sendEvent roomId, "m.room.message", content

export sendReaction = (client, roomId, origId, emoji) ->
  client.sendEvent roomId, 'm.reaction',
    'm.relates_to':
      'event_id': origId
      'key': emoji
      'rel_type': 'm.annotation'

export sendRedaction = (client, roomId, origId) ->
  client.redactEvent roomId, origId

export cancelEvent = (client, roomId, eventId) ->
  ev = findPendingEventInRoom client, roomId, eventId
  # Don't throw an exception if not found because it must have succeeded or been cancelled somewhere else
  client.cancelPendingEvent ev if ev?

export resendEvent = (client, roomId, eventId) ->
  ev = findPendingEventInRoom client, roomId, eventId
  client.resendEvent ev, client.getRoom roomId if ev?