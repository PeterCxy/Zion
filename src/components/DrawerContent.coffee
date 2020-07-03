import React, { useCallback, useContext, useEffect, useMemo, useState } from "react"
import { StatusBar, Text, View } from "react-native"
import Avatar from "./Avatar"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import * as mext from "../util/matrix"

export default DrawerContent = () ->
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
  </View>

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
    stylesWrapper:
      flex: 1
      backgroundColor: theme.COLOR_BACKGROUND