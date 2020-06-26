import React, { useMemo } from "react"
import { View, Text } from "react-native"
import HTML from "react-native-render-html"
import { useStyles } from "../../theme"
import { translate } from "../../util/i18n"

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
  date = useMemo ->
    new Date ev.ts
  , [ev.ts]

  <View
    style={if ev.self then styles.styleMsgBubbleReverse else styles.styleMsgBubble}>
    {
      if not ev.self
        <Text
          numberOfLines={1}
          style={styles.styleMsgSender}>
          {ev.sender.name}
        </Text>
    }
    {  
      if ev.text
        <Text
          style={if ev.self then styles.styleMsgTextReverse else styles.styleMsgText}>
          {ev.text}
        </Text>
      else if ev.html
        fixedHtml = useMemo ->
          fixHtml ev.html
        , [ev.html]

        <HTML
          html={fixedHtml}
          renderersProps={{
            styles: styles
          }}
          renderers={htmlRenderers}
          style={if ev.self then styles.styleMsgTextReverse else styles.styleMsgText}
          baseFontStyle={if ev.self then styles.styleMsgTextReverse else styles.styleMsgText}/>
    }
    <Text
      style={if ev.self then styles.styleMsgTimeReverse else styles.styleMsgTime}>
      {translate "time_format_hour_minute",
        ('' + date.getHours()).padStart(2, '0'),
        ('' + date.getMinutes()).padStart(2, '0')}
    </Text>
  </View>

buildStyles = (theme) ->
  styles =
    styleMsgBubble:
      backgroundColor: theme.COLOR_CHAT_BUBBLE
      maxWidth: '80%'
      paddingStart: 10
      paddingEnd: 10
      borderRadius: 8
    styleMsgBubbleReverse:
      paddingTop: 5
      backgroundColor: theme.COLOR_PRIMARY
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
    styleMsgQuoteContent:
      marginStart: 10
      opacity: 0.5

  styles.styleMsgBubbleReverse =
    Object.assign {}, styles.styleMsgBubble, styles.styleMsgBubbleReverse
  styles.styleMsgTextReverse =
    Object.assign {}, styles.styleMsgText, styles.styleMsgTextReverse
  styles.styleMsgTimeReverse =
    Object.assign {}, styles.styleMsgTime, styles.styleMsgTimeReverse

  styles