import { NativeModules } from "react-native"

###
 * encrypt a string in native code
 *
 * @param {string} data the plaintext to encrypt
 * @param {Uint8Array} key the encryption key to use
 * @param {string} name the name of the secret
 * @param {string} ivStr the base64-encoded initialization vector to use
###
export encryptNative = (data, key, name, ivStr) ->
  await NativeModules.NativeCrypto.encryptNative data,
    Buffer.from(key).toString('base64'), name, ivStr

###
 * decrypt a string in native code
 *
 * @param {object} data the encrypted data
 * @param {string} data.ciphertext the ciphertext in base64
 * @param {string} data.iv the initialization vector in base64
 * @param {string} data.mac the HMAC in base64
 * @param {Uint8Array} key the encryption key to use
 * @param {string} name the name of the secret
###
export decryptNative = (data, key, name) ->
  await NativeModules.NativeCrypto.decryptNative data.ciphertext,
    data.iv, data.mac, Buffer.from(key).toString('base64'), name