import { NativeModules } from "react-native"

Native = NativeModules.EncryptedAttachment

# Returns a temporary file with decoded content
# The caller is responsible for cleaning up the temp file
export decryptAttachment = (srcPath, cryptoInfo) ->
  if cryptoInfo.v != "v2"
    return Promise.reject "Unknown version #{cryptoInfo.v}"
  iv = cryptoInfo.iv
  key = cryptoInfo.key.k
  hash = cryptoInfo.hashes['sha256']
  if not hash?
    return Promise.reject "Must have sha256 hash"
  dstPath = srcPath + "_decrypted"
  await Native.decrypt srcPath, dstPath, iv, key, hash
  return dstPath