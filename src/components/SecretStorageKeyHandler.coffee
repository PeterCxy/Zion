import React, { useCallback, useState } from "react"
import { Button, Dialog, TextInput } from "react-native-paper"
import { translate } from "../util/i18n"
import { deriveSecretStorageKey } from "../util/NativeCrypto"

# Returns [UIComponent, getSecretStorageKey]
export default useSecretStorageKeyHandler = ->
  [resolvePromise, setResolvePromise] = useState null
  [rejectPromise, setRejectPromise] = useState null
  [show, setShow] = useState false

  # Adapted from: matrix-react-sdk/src/CrossSigningManager.js
  getSecretStorageKey = useCallback ({keys}) ->
    keyInfoEntries = Object.entries keys
    if keyInfoEntries.length > 1
      return Promise.reject "Multiple key request unsupported"
    [name, info] = keyInfoEntries[0]
    # Create a promise and delegate everything to the SecretStorageKeyHandler
    # TODO: implement recovery key support?
    passphrase = await new Promise (resolve, reject) ->
      setResolvePromise (orig) ->
        if orig?
          reject "Cannot handle multiple simultaneous requests" 
          return

        (res) ->
          setShow false
          setRejectPromise null
          setResolvePromise null
          resolve res
      setRejectPromise (orig) ->
        if orig?
          reject "Cannot handle multiple simultaneous requests" 
          return

        (err) ->
          setShow false
          setRejectPromise null
          setResolvePromise null
          reject err
      setShow true
    
    key = await deriveSecretStorageKey passphrase, info.passphrase.salt, info.passphrase.iterations
    [name, key]
  , []

  component =
    <SecretStorageKeyHandlerDialog
      show={show}
      resolvePromise={resolvePromise}
      rejectPromise={rejectPromise}/>

  [component, getSecretStorageKey]

SecretStorageKeyHandlerDialog = React.memo ({show, resolvePromise, rejectPromise}) ->
  [passphrase, setPassphrase] = useState ""

  <Dialog
    visible={show}>
    <Dialog.Title>
      {translate "secret_storage_key_access_title"}
    </Dialog.Title>
    <Dialog.Content>
      <TextInput
        mode="outlined"
        secureTextEntry={true}
        label={translate "secret_storage_key_access_input"}
        onChangeText={(text) -> setPassphrase text}/>
    </Dialog.Content>
    <Dialog.Actions>
      <Button
        onPress={-> rejectPromise "User cancelled"}>
        {translate "cancel"}
      </Button>
      <Button
        disabled={not (passphrase? and passphrase.trim() isnt "")}
        onPress={-> resolvePromise passphrase}>
        {translate "continue"}
      </Button>
    </Dialog.Actions>
  </Dialog>