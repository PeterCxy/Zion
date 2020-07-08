import React, { useCallback, useState } from "react"
import { Button, Dialog, TextInput } from "react-native-paper"
import { translate } from "../util/i18n"
import { deriveSecretStorageKey } from "../util/NativeCrypto"
import { useInvokeDialogForResult } from "../util/util"

# Returns [UIComponent, getSecretStorageKey]
export default useSecretStorageKeyHandler = ->
  [renderedComponent, invokeDialogForResult] =
    useInvokeDialogForResult SecretStorageKeyHandlerDialog

  # Adapted from: matrix-react-sdk/src/CrossSigningManager.js
  getSecretStorageKey = useCallback ({keys}) ->
    keyInfoEntries = Object.entries keys
    if keyInfoEntries.length > 1
      return Promise.reject "Multiple key request unsupported"
    [name, info] = keyInfoEntries[0]
    # Create a promise and delegate everything to the SecretStorageKeyHandler
    # TODO: implement recovery key support?
    passphrase = await invokeDialogForResult()
    key = await deriveSecretStorageKey passphrase,
      info.passphrase.salt, info.passphrase.iterations
    [name, key]
  , []

  [renderedComponent, getSecretStorageKey]

# If the device has not been initialized with the key to the secret storage,
# we prompt the user to provide the recovery passphrase or recovery keys
# However this should be rarely needed since devices automatically
# gain those keys when verified via cross-signing.
SecretStorageKeyHandlerDialog = React.memo ({show, resolvePromise, rejectPromise}) ->
  [passphrase, setPassphrase] = useState ""

  <Dialog
    visible={show}
    onDismiss={-> rejectPromise "dismissed"}>
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