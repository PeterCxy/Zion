import React, { useCallback, useContext, useEffect, useMemo, useState } from "react"
import { StatusBar, ScrollView, Text, View } from "react-native"
import { TouchableRipple } from "react-native-paper"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
import Avatar from "./Avatar"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"
import * as mext from "../util/matrix"

export default DrawerContent = ({navigation}) ->
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles

  [userId, setUserId] = useState ->
    client.getUserId()
  [userName, setUserName] = useState ->
    client.getUser(userId).displayName # TODO: this may be unknown?
  [avatarUrl, _setAvatarUrl] = useState null

  setAvatarUrl = useCallback (url) ->
    if url?
      _setAvatarUrl client.mxcUrlToHttp url, mext.AVATAR_SIZE, mext.AVATAR_SIZE
    else
      _setAvatarUrl null
  , []

  useEffect ->
    unmounted = false

    setAvatarUrl client.getUser(userId).avatarUrl

    onNameChange = (ev, user) ->
      return unless user.userId == userId
      setUserName user.displayName

    onAvatarChange = (ev, user) ->
      return unless user.userId == userId
      setAvatarUrl user.avatarUrl

    client.on 'User.displayName', onNameChange
    client.on 'User.avatarUrl', onAvatarChange

    do ->
      # The display name and avatar url won't be loaded automatically
      # so we have to tell the client to load it
      profile = await client.getProfileInfo userId
      unless unmounted
        setUserName profile.displayname
        setAvatarUrl profile.avatar_url

    return ->
      unmounted = true
      client.removeListener 'User.displayName', onNameChange
      client.removeListener 'User.avatarUrl', onAvatarChange
  , []

  styleUserInfoWrapper = useMemo ->
    Object.assign {}, styles.styleUserInfoWrapper,
      height: styles.styleUserInfoWrapper.height + StatusBar.currentHeight
      padidngTop: StatusBar.currentHeight
  , [StatusBar.currentHeight]

  <View style={styles.styleWrapper}>
    <View style={styleUserInfoWrapper}>
      <Avatar
        style={styles.styleUserInfoAvatar}
        name={userName}
        url={avatarUrl}/>
      <Text style={styles.styleUserInfoText}>{userName}</Text>
      <Text style={styles.styleUserInfoText}>{userId}</Text>
    </View>
    <ScrollView style={styles.styleOptionsScrollView}>
      <View style={styles.styleOptionsWrapper}>
        <DrawerOption
          styles={styles}
          onPress={-> navigation.navigate "Settings"}
          theme={theme}
          title={translate "settings"}
          icon="settings"/>
      </View>
    </ScrollView>
  </View>

DrawerOption = ({styles, theme, title, icon, onPress}) ->
  <TouchableRipple
    style={styles.styleOption}
    onPress={onPress ? ->}>
    <View style={styles.styleOptionInner}>
      <Icon
        style={styles.styleOptionIcon}
        size={20}
        name={icon}
        color={theme.COLOR_TEXT_ON_BACKGROUND}/>
      <Text
        style={styles.styleOptionText}>
        {title}
      </Text>
    </View>
  </TouchableRipple>

buildStyles = (theme) ->
    styleUserInfoWrapper:
      backgroundColor: theme.COLOR_PRIMARY
      height: 200
      flexDirection: "column"
      alignItems: "flex-start"
      justifyContent: "flex-end"
      padding: 10
      paddingStart: 15
    styleUserInfoAvatar:
      width: 64
      height: 64
      borderRadius: 32
      borderWidth: 1
      borderColor: theme.COLOR_SECONDARY
      marginBottom: 15
    styleUserInfoText:
      color: theme.COLOR_TEXT_PRIMARY
      fontSize: 13
      paddingTop: 3
    styleWrapper:
      flex: 1
      flexDirection: 'column'
      backgroundColor: theme.COLOR_BACKGROUND
    styleOptionsScrollView:
      width: '100%'
      alignSelf: 'stretch'
    styleOptionsWrapper:
      width: '100%'
      marginTop: 20
      flexDirection: "column"
    styleOption:
      width: '100%'
      height: 48
    styleOptionInner:
      width: '100%'
      height: '100%'
      flexDirection: "row"
      alignItems: "center"
    styleOptionIcon:
      marginStart: 10
      marginEnd: 10
    styleOptionText:
      fontSize: 14
      color: theme.COLOR_TEXT_ON_BACKGROUND