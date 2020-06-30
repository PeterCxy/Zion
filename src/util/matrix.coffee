# Extra functions for matrix
# Often imported as "mext" in other modules

AVATAR_SIZE = 64 # TODO: should we calculate this based on DPI?
AVATAR_SIZE_SMALL = 32

# Calculate avatar URL of a room
# if the room is a direct chat, return the
# avatar of the other user
# otherwise returns the room avatar directly
export calculateRoomAvatarURL = (client, room) ->
  fallback = room.getAvatarFallbackMember()
  if not fallback?
    room.getAvatarUrl client.getHomeserverUrl(), AVATAR_SIZE, AVATAR_SIZE, "scale", false
  else
    fallback.getAvatarUrl client.getHomeserverUrl(), AVATAR_SIZE, AVATAR_SIZE, "scale", false

# Calculate the small avatar URL of a room member
export calculateMemberSmallAvatarURL = (client, member) ->
  member.getAvatarUrl client.getHomeserverUrl(),
    AVATAR_SIZE_SMALL, AVATAR_SIZE_SMALL, "scale", false