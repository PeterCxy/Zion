import React, { useCallback, useContext, useEffect, useMemo, useRef, useState } from "react"
import { View, Text, TouchableWithoutFeedback, useWindowDimensions } from "react-native"
import linkifyHtml from 'linkifyjs/html'
import linkifyStr from 'linkifyjs/string'
import HTML from "react-native-render-html"
import { useStyles } from "../../theme"
import { MatrixClientContext } from "../../util/client"
import { translate } from "../../util/i18n"
import * as util from "../../util/util"
import NativeUtils from "../../util/NativeUtils"
import ImageThumbnail from "../ImageThumbnail"
import { useNavigation } from "@react-navigation/native"
import { TouchableRipple } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"

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
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  windowScale = useWindowDimensions().scale
  navigation = useNavigation()

  styles = if ev.self then styles.reverse else styles

  date = useMemo ->
    new Date ev.ts
  , [ev.ts]

  fixedHtml = useMemo ->
    return null if not ev.body or ev.body == ""
    # Linkify both string and html to always produce html
    html = if ev.type == 'msg_html'
      linkifyHtml ev.body
    else
      linkifyStr ev.body
    fixHtml html
  , [ev.body]

  # The link to show preview for
  [previewLink, setPreviewLink] = useState null
  [previewInfo, setPreviewInfo] = useState null
  [previewImgWidth, previewImgHeight] =
    util.useFitImageDimensions previewInfo?['og:image:width'], previewInfo?['og:image:height']
  previewImgUrl = useMemo ->
    return unless previewInfo? and previewInfo['og:image'] and previewImgWidth? and previewImgHeight?

    url = client.mxcUrlToHttp previewInfo['og:image'],
      previewImgWidth * windowScale, previewImgHeight * windowScale, 'scale'

    return url
  , [previewInfo, previewImgWidth, previewImgHeight]
  previewImgDataRef = useRef null

  findLink = useCallback (nodes, arr = []) ->
    return if previewLink?

    for node in nodes
      continue if node.name == 'mx-reply' # Do not preview links in reply

      if node.name == 'a'
        arr.push node.attribs.href
      else if node.children?
        findLink node.children, arr
    arr = arr.filter (link) -> util.isWebAddr link
    return if arr.length is 0
    setPreviewLink arr[0]
  , [previewLink]

  # Fetch link if it was found for the first time
  useEffect ->
    return unless previewLink?
    unmounted = false
    
    do ->
      try
        info = await client.getUrlPreview previewLink, new Date().getTime()
        info['og:description'] = info['og:description']?.replace /\n/g, ' '
        setPreviewInfo info unless unmounted
      catch err
        console.log err

    return ->
      unmounted = true
  , [previewLink]

  <View style={styles.styleWrapper}>
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
          baseFontStyle={styles.styleMsgText}
          onParsed={(parsed) -> findLink parsed}
          onLinkPress={(ev, href) ->
            NativeUtils.openURL href if util.isWebAddr href
          }/>
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
    {
      if previewInfo?
        <View style={Object.assign {}, styles.styleMsgQuoteWrapper, { marginTop: 5, marginBottom: 0 }}>
          <View style={styles.styleMsgQuoteLine}/>
          <View style={styles.styleMsgQuoteContent}>
            <View style={styles.styleUrlPreviewWrapper}>
              {
                if previewInfo['og:title']?
                  <TouchableWithoutFeedback
                    onPress={-> NativeUtils.openURL previewLink}>
                    <Text style={styles.styleUrlPreviewTitle} numberOfLines={1}>
                      {previewInfo['og:title']}
                    </Text>
                  </TouchableWithoutFeedback>
              }
              {
                if previewInfo['og:site_name']?
                  <Text style={styles.styleUrlPreviewSite} numberOfLines={1}>
                    {previewInfo['og:site_name']}
                  </Text>
              }
              {
                if previewInfo['og:description']?
                  <Text style={styles.styleUrlPreviewDesc}>
                    {previewInfo['og:description']}
                  </Text>
              }
            </View>
          </View>
        </View>
    }
    {
      if previewImgUrl? and not (previewInfo['og:title']? or previewInfo['og:site_name']? or previewInfo['og:description']?)
        # Show content of pure-picture URLs (e.g. Imgur) directly
        <TouchableRipple
          onPress={->
            if previewImgDataRef.current?
              navigation.navigate "ImageViewerScreen",
                thumbnailUrl: previewImgUrl,
                thumbnailDataUrl: previewImgDataRef.current
                # Fake an "info" object just like in the image type
                info:
                  url: previewInfo['og:image']
          }>
          <SharedElement id={"image.thumbnail.#{previewImgUrl}"}>
            <ImageThumbnail
              width={previewImgWidth}
              height={previewImgHeight}
              url={previewImgUrl}
              refDataUrl={previewImgDataRef}/>
          </SharedElement>
        </TouchableRipple>
    }
    <Text
      style={styles.styleMsgTime}>
      {util.formatTime date}
    </Text>
  </View>

buildStyles = (theme) ->
  styles =
    styleWrapper:
      marginStart: 10
      marginEnd: 10
    styleWrapperReverse:
      marginTop: 5
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
    styleUrlPreviewWrapper:
      flexDirection: 'column'
    styleUrlPreviewTitle:
      color: theme.COLOR_CHAT_LINK
      fontWeight: 'bold'
      textDecorationLine: 'underline'
      fontSize: 14
    styleUrlPreviewTitleReverse:
      color: theme.COLOR_CHAT_LINK_ON_BACKGROUND
    styleUrlPreviewSite:
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
      fontSize: 13
      marginBottom: 3
    styleUrlPreviewSiteReverse:
      color: theme.COLOR_TEXT_PRIMARY
    styleUrlPreviewDesc:
      fontSize: 14
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
    styleUrlPreviewDescReverse:
      color: theme.COLOR_TEXT_PRIMARY
  
  styles.reverse = Object.assign {}, styles,
    styleWrapper: Object.assign {}, styles.styleWrapper, styles.styleWrapperReverse
    styleMsgText: Object.assign {}, styles.styleMsgText, styles.styleMsgTextReverse
    styleMsgTime: Object.assign {}, styles.styleMsgTime, styles.styleMsgTimeReverse
    styleReaction: Object.assign {}, styles.styleReaction, styles.styleReactionReverse
    styleMsgLink: Object.assign {}, styles.styleMsgLink, styles.styleMsgLinkReverse
    styleMsgQuoteLine: Object.assign {}, styles.styleMsgQuoteLine, styles.styleMsgQuoteLineReverse
    styleUrlPreviewTitle: Object.assign {}, styles.styleUrlPreviewTitle, styles.styleUrlPreviewTitleReverse
    styleUrlPreviewSite: Object.assign {}, styles.styleUrlPreviewSite, styles.styleUrlPreviewSiteReverse
    styleUrlPreviewDesc: Object.assign {}, styles.styleUrlPreviewDesc, styles.styleUrlPreviewDescReverse

  styles