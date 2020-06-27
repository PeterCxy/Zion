import React, { useCallback, useState } from "react"
import { View, TextInput } from "react-native"
import { IconButton, Snackbar } from "react-native-paper"
import { useStyles } from "../theme"
import { translate } from "../util/i18n"

export default MessageComposer = () ->
  [theme, styles] = useStyles buildStyles
  [text, setText] = useState ""
  [showTextEmptyPrompt, setShowTextEmptyPrompt] = useState false

  onSend = useCallback ->
    toSend = text.trim()
    if toSend is ""
      setShowTextEmptyPrompt true
    # TODO: actually implement this
  , [text]

  <>
    <View style={styles.styleWrapper}>
      <TextInput
        placeholder={translate "chat_placeholder"}
        value={text}
        onChangeText={setText}
        style={styles.styleTextInput}/>
      <IconButton
        icon="send"
        color={theme.COLOR_PRIMARY}
        onPress={onSend}/>
    </View>
    <Snackbar
      visible={showTextEmptyPrompt}
      onDismiss={-> setShowTextEmptyPrompt false}
      action={{
        label: translate "ok"
        onPress: -> setShowTextEmptyPrompt false
      }}
      duration={Snackbar.DURATION_SHORT}>
      {translate "chat_text_empty"}
    </Snackbar>
  </>

buildStyles = (theme) ->
    styleWrapper:
      flexDirection: "row"
      justifyContent: "center"
      alignItems: "center"
      backgroundColor: theme.COLOR_CHAT_COMPOSER
      elevation: 5
      height: 48
      padding: 4
    styleTextInput:
      flex: 1
      marginStart: 10
      marginEnd: 10
      alignSelf: "stretch"