# Extra functions for matrix
# Often imported as "mext" in other modules
import { translate } from "./i18n"

AVATAR_SIZE = 64 # TODO: should we calculate this based on DPI?
AVATAR_SIZE_SMALL = 32
AVATAR_SIZE_TINY = 24

# Calculate avatar URL of a room
# if the room is a direct chat, and does not
# have an avatar of its own,
# return the avatar of the other user
# otherwise returns the room avatar directly
# null if none
export calculateRoomAvatarURL = (client, room) ->
  roomAvatar = room.getAvatarUrl client.getHomeserverUrl(),
    AVATAR_SIZE, AVATAR_SIZE, "scale", false
  if roomAvatar?
    roomAvatar
  else
    room.getAvatarFallbackMember()?.getAvatarUrl client.getHomeserverUrl(),
      AVATAR_SIZE, AVATAR_SIZE, "scale", false

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
    when 'm.reaction'
      translate "room_event_message", ev.sender.name, ev.getContent()["m.relates_to"]["key"]
    when 'm.room.create'
      translate "room_event_created"
    when 'm.sticker'
      translate "room_event_sticker", ev.sender.name
    when 'm.room.member'
      content = ev.getContent()
      switch content.membership
        when 'invite'
          translate "room_event_invite", ev.sender.name, content.displayname
        when 'join'
          translate "room_event_join", content.displayname
        when 'leave'
          translate "room_event_leave", content.displayname
        else
          content.membership
    when 'm.room.name'
      translate "room_event_name_changed", ev.sender.name
    when 'm.room.server_acl'
      translate "room_event_server_acl_changed", ev.sender.name
    else translate "room_event_unknown", ev.getType()

messageToDescription = (content) ->
  #console.log "msgType = #{content.msgtype}"
  switch content.msgtype
    when "m.text" then content.body
    when "m.bad.encrypted" then translate 'room_msg_bad_encryption'
    else translate "room_msg_unknown", content.msgtype

# State events
STATE_EVENTS = [
  "m.room.create", "m.room.member",
  "m.room.name", "m.room.server_acl"
]

export isStateEvent = (ev) -> ev.getType() in STATE_EVENTS