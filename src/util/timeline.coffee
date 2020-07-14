import { EventStatus } from 'matrix-js-sdk'
import * as mext from './matrix'
import { translate } from './i18n'

# Transform raw room events from the Matrix client
# to a series of immutable data objects that
# we show in the RoomTimeline list
#   - client: the Matrix client object
#   - events: the return value of TimelineWindow.getEvents()
# returns the transformed list in *reverse* order,
# i.e. the newest events are at lower indices.
# This function is splitted out from RoomTimeline
export transformEvents = (client, events) ->
  replaced = {}
  reactions = {}

  events
    # The FlatList itself in RoomTimeline has been inverted, so we have to invert again
    # Also, this allows us to see redaction / edits before the actual event
    .reverse()
    .map (ev, idx, array) ->
      res = transformEvent client, ev, replaced, reactions
      # Some events themselves do not need to be shown, like redactions
      return null if not res?
      Object.assign {}, res,
        key: ev.getId()
        ts: ev.getTs()
        prev_ts: array[idx - 1]?.getTs()
        sender:
          id: ev.sender.userId
          name: ev.sender.name
          avatar: mext.calculateMemberSmallAvatarURL client, ev.sender
          tinyAvatar: mext.calculateMemberTinyAvatarURL client, ev.sender
        self: ev.sender.userId == client.getUserId()
        sent: (not ev.status?) or (ev.status == EventStatus.SENT)
        failed: ev.status == EventStatus.NOT_SENT
    .filter (ev) -> ev?
    # Work around some empty room state (membership) events
    # see membership handling in matrix.coffee for details
    .filter (ev) -> ev.type isnt 'room_state' or (ev.body? and ev.body isnt "")

transformEvent = (client, ev, replaced, reactions) ->
  if ev.isRedacted()
    return redactedEvent ev

  content = ev.getContent()
  # Handle replacement (edits)
  if replaced[ev.getId()]
    content = Object.assign {}, { orig: content }, replaced[ev.getId()].newContent
    content.edited = true
  if ev.isRelation 'm.replace'
    origId = ev.getAssociatedId()
    ts = ev.getTs()
    if replaced[origId]? and replaced[origId].ts > ts
      # We only take the latest replacement
      return null
    replaced[origId] =
      ts: ts
      newContent: content['m.new_content']
    return null

  ret = switch ev.getType()
    when "m.room.message" then messageEvent client, content
    when "m.sticker" then stickerEvent client, content
    when "m.room.encrypted" then encryptedEvent ev
    when "m.room.redaction"
      # Handled by matrix-js-sdk, we just need to ignore these
      null
    when "m.reaction"
      # Record reaction to a message
      # The original message always comes later (because we process in reverse order)
      reactedTo = ev.getAssociatedId()
      reactionKey = ev.getContent()["m.relates_to"]["key"] # The emoji of the reaction
      if not reactions[reactedTo]?
        reactions[reactedTo] = {}
      if not reactions[reactedTo][reactionKey]?
        reactions[reactedTo][reactionKey] = 0
      reactions[reactedTo][reactionKey] += 1
      null
    else
      if mext.isStateEvent ev
        stateEvent ev
      else
        unknownEvent ev

  # Handle reactions to the current message
  # Since we process in reverse order, we always collect
  # all reactions before the original message
  if reactions[ev.getId()]?
    ret.reactions = reactions[ev.getId()]

  return ret

redactedEvent = (ev) ->
  evType = ev.getType()

  if evType is 'm.room.message' or evType is 'm.sticker'
      type: 'msg_text'
      redacted: true
      body: translate 'room_msg_redacted'
  else
    # If the original event was not something that shows
    # as a message in the timeline, do not add more messages
    # to the timeline.
    # This can happen when the user redacts a reactions.
    null

messageEvent = (client, content) ->
  ret = {}
  
  switch content.msgtype
    when "m.text", "m.notice"
      #console.log content
      switch content.format
        when 'org.matrix.custom.html'
          ret.type = 'msg_html'
          ret.body = content.formatted_body
          if (not ret.body.startsWith "<mx-reply>") and content.orig?.formatted_body?
            # If the event is an edited message without "<mx-reply>"
            # (which is what Riot does even when editing messages that are replies)
            # and if the original message is a rich reply, we prepend the original
            # <mx-reply> block
            # (edits to reply messages will always be `org.matrix.custom.html`, but
            #  may not include the <mx-reply> header, just like Riot)
            replyBlock = mext.extractMxReplyHeader content.orig.formatted_body
            ret.body = replyBlock + ret.body if replyBlock?
        else
          ret.type = 'msg_text'
          ret.body = content.body
    when "m.image"
      ret.type = 'msg_image'
      ret.info =
        width: content.info.w
        height: content.info.h
        url: content.url
        mime: content.info.mimetype
        cryptoInfo: content.file
      ret.info.thumbnail = if content.info.thumbnail_info?
          width: content.info.thumbnail_info.w
          height: content.info.thumbnail_info.h
          url: content.info.thumbnail_url
          mime: content.info.thumbnail_info.mimetype
          cryptoInfo: content.info.thumbnail_file
      else
        Object.assign {}, ret.info
    when "m.file", "m.audio", "m.video"
      # General attachments
      ret.type = 'msg_attachment'
      ret.info =
        title: content.filename ? content.body
        url: content.url
        mime: content.info.mimetype
        size: content.info.size
        cryptoInfo: content.file
    when "m.bad.encrypted"
      ret.type = 'msg_text'
      ret.body = translate 'room_msg_bad_encryption'
      ret.unknown = true
    else
      ret.type = 'unknown'
      ret.ev_type = "msg_#{content.msgtype}"
      ret.unknown = true

  # Whatever event it is, the content always has a body that
  # describes the content
  ret.plaintext = content.body

  if content.edited
    ret.edited = true

  ret

stickerEvent = (client, content) ->
  return
    type: 'msg_sticker'
    url: client.mxcUrlToHttp content.url
    width: content.info.w
    height: content.info.h
    plaintext: content.body

encryptedEvent = (ev) ->
    type: 'msg_text' # Pretend it's a message and show a placeholder
    body: translate 'room_msg_encrypted_placeholder'
    unknown: true

stateEvent = (ev) ->
    type: 'room_state'
    body: mext.eventToDescription ev

unknownEvent = (ev) ->
    type: 'unknown'
    ev_type: ev.getType()
    unknown: true