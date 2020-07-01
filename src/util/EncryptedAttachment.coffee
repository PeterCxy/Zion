import { NativeModules } from "react-native"
import * as RNFS from 'react-native-fs'
import AsyncFileOps from './AsyncFileOps'

Native = NativeModules.EncryptedAttachment

export decryptAttachmentToBase64 = (srcPath, cryptoInfo) ->
  if cryptoInfo.v != "v2"
    return Promise.reject "Unknown version #{cryptoInfo.v}"
  iv = cryptoInfo.iv
  key = cryptoInfo.key.k
  hash = cryptoInfo.hashes['sha256']
  if not hash?
    return Promise.reject "Must have sha256 hash"
  dstPath = srcPath + "_decrypted"
  await Native.decrypt srcPath, dstPath, iv, key, hash
  #res = await RNFS.readFile dstPath, 'base64'
  res = await AsyncFileOps.readAsBase64 dstPath
  await RNFS.unlink dstPath
  return res