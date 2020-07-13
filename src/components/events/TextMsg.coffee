import React, { useMemo } from "react"
import { View, Text } from "react-native"
import linkifyHtml from 'linkifyjs/html'
import linkifyStr from 'linkifyjs/string'
import HTML from "react-native-render-html"
import { useStyles } from "../../theme"
import { translate } from "../../util/i18n"
import * as util from "../../util/util"

htmlRenderers =
  blockquote: (_, children, __, passProps) ->
    styles = passProps.renderersProps.styles

    <View style={styles.styleMsgQuoteWrapper} key={passProps.key}>
      <View style={styles.styleMsgQuoteLine}/>
      <View style={styles.styleMsgQuoteContent}>
        {children}
      </View>
    </View>

# Workaround: <https://github.com/archriss/react-native-render-html/issues/216>
fixHtml = (html) ->
  html.replace /> </g, '><span style="color:transparent;">-</span><'

# A text (or formatted text, i.e. HTML) message
export default TextMsg = ({ev}) ->
  [theme, styles] = useStyles buildStyles

  styles = if ev.self then styles.reverse else styles

  date = useMemo ->
    new Date ev.ts
  , [ev.ts]

  bubbleStyle = if not ev.failed
    styles.styleMsgBubble
  else
    styles.styleMsgBubbleReverseFailed

  if ev.type == 'msg_html' and ev.body.indexOf('<li>') != -1
    # There is a weird bug about lists in react-native-render-html
    # that causes the view, when in auto width, wrapping at each character
    # for now, let's fix it by making the width constant
    bubbleStyle = Object.assign {}, bubbleStyle, { width: '80%' }

  fixedHtml = useMemo ->
    return null if not ev.body or ev.body == ""
    # Linkify both string and html to always produce html
    html = if ev.type == 'msg_html'
      linkifyHtml ev.body
    else
      linkifyStr ev.body
    fixHtml html
  , [ev.body]

  <View style={styles.styleMsgBubbleWrapper}>
    <View
      style={bubbleStyle}>
      {
        if not ev.self
          <Text
            numberOfLines={1}
            style={styles.styleMsgSender}>
            {ev.sender.name}
          </Text>
      }
      {
        if fixedHtml?
          <HTML
            html={fixedHtml}
            renderersProps={{
              styles: styles
            }}
            tagsStyles={{
              code: styles.styleCodeText
              a: styles.styleMsgLink
            }}
            renderers={htmlRenderers}
            style={styles.styleMsgText}
            baseFontStyle={styles.styleMsgText}/>
      }
      {
        if ev.reactions?
          <View style={styles.styleReactionWrapper}>
            {
              Object.entries(ev.reactions).map ([key, value]) ->
                <Text
                  style={styles.styleReaction}
                  key={key}>
                  {key} {value}
                </Text>
            }
          </View>
      }
      {
        if ev.edited
          <Text
            style={styles.styleMsgTime}>
            {translate 'room_msg_edited'}
          </Text>
      }
      <Text
        style={styles.styleMsgTime}>
        {util.formatTime date}
      </Text>
    </View>
  </View>

buildStyles = (theme) ->
  styles =
    styleMsgBubbleWrapper:
      # Make the wrapper width fill the rest of the flexbox
      # Without wrapper, the max width of the bubble is
      # relative to the entire list, not the rest of flex
      flex: 1
    styleMsgBubble:
      alignSelf: 'flex-start' # Wrap-Content
      backgroundColor: theme.COLOR_CHAT_BUBBLE
      maxWidth: '90%'
      paddingStart: 10
      paddingEnd: 10
      borderRadius: 8
    styleMsgBubbleReverse:
      alignSelf: 'flex-end'
      paddingTop: 5
      backgroundColor: theme.COLOR_PRIMARY
    styleMsgBubbleReverseFailed:
      backgroundColor: theme.COLOR_CHAT_BUBBLE_FAILED
    styleMsgText:
      fontSize: 14
      color: theme.COLOR_CHAT_TEXT
    styleMsgTextReverse:
      color: theme.COLOR_TEXT_PRIMARY
    styleMsgSender:
      fontSize: 12
      fontWeight: 'bold'
      marginTop: 5
      marginBottom: 5
      color: theme.COLOR_SECONDARY
    styleMsgTime:
      fontSize: 12
      marginTop: 5
      marginBottom: 5
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
    styleMsgTimeReverse:
      color: theme.COLOR_TEXT_PRIMARY
      opacity: 0.4
    styleMsgQuoteWrapper:
      flexDirection: 'row'
      marginBottom: 10
    styleMsgQuoteLine:
      width: 2
      height: '100%'
      backgroundColor: theme.COLOR_CHAT_QUOTE_LINE
    styleMsgQuoteLineReverse:
      opacity: 0.7
      backgroundColor: theme.COLOR_TEXT_PRIMARY
    styleMsgQuoteContent:
      marginStart: 10
      opacity: 0.5
    styleCodeText:
      fontFamily: 'monospace'
      color: theme.COLOR_CHAT_INLINE_CODE
    styleMsgLink:
      color: theme.COLOR_CHAT_LINK
    styleMsgLinkReverse:
      color: theme.COLOR_CHAT_LINK_ON_BACKGROUND
    styleReactionWrapper:
      width: '100%'
      flexDirection: 'row'
      flexWrap: 'wrap'
    styleReaction:
      marginTop: 5
      marginBottom: 5
      marginEnd: 5
      fontSize: 12
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
    styleReactionReverse:
      color: theme.COLOR_TEXT_PRIMARY
  
  styles.reverse = Object.assign {}, styles,
    styleMsgBubble: Object.assign {}, styles.styleMsgBubble, styles.styleMsgBubbleReverse
    styleMsgText: Object.assign {}, styles.styleMsgText, styles.styleMsgTextReverse
    styleMsgTime: Object.assign {}, styles.styleMsgTime, styles.styleMsgTimeReverse
    styleReaction: Object.assign {}, styles.styleReaction, styles.styleReactionReverse
    styleMsgLink: Object.assign {}, styles.styleMsgLink, styles.styleMsgLinkReverse
    styleMsgQuoteLine: Object.assign {}, styles.styleMsgQuoteLine, styles.styleMsgQuoteLineReverse
    # Failed is always reverse
    styleMsgBubbleReverseFailed: Object.assign {}, styles.styleMsgBubbleReverse, styles.styleMsgBubbleReverseFailed

  styles