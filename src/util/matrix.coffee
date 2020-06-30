# Extra functions for matrix
# Often imported as "mext" in other modules

AVATAR_SIZE = 64 # TODO: should we calculate this based on DPI?
AVATAR_SIZE_SMALL = 32

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