import { NativeModules } from "react-native"

# Bridges
ManagerBridge = NativeModules.OlmManagerBridge
AccountBridge = NativeModules.OlmAccountBridge
SessionBridge = NativeModules.OlmSessionBridge
UtilityBridge = NativeModules.OlmUtilityBridge
InboundGroupSessionBridge = NativeModules.OlmInboundGroupSessionBridge
OutboundGroupSessionBridge = NativeModules.OlmOutboundGroupSessionBridge
PkEncryptionBridge = NativeModules.OlmPkEncryptionBridge
PkDecryptionBridge = NativeModules.OlmPkDecryptionBridge
PkSigningBridge = NativeModules.OlmPkSigningBridge
SASBridge = NativeModules.OlmSASBridge

# We don't need asynchronous initialization
export init = -> Promise.resolve null

# The library version
export get_library_version = ->
  ManagerBridge.getLibraryVersion().split '.'
    .map (x) -> Number.parseInt x

# The Account class
export class Account
  constructor: ->
    @nativeId = 0

  pickle: (key) => AccountBridge.pickle @nativeId, key
  unpickle: (key, pickle) =>
    @nativeId = AccountBridge.unpickle key, pickle
  create: => @nativeId = AccountBridge.create()
  free: => AccountBridge.free @nativeId
  identity_keys: => AccountBridge.identityKeys @nativeId
  sign: (message) => AccountBridge.sign @nativeId, message
  one_time_keys: => AccountBridge.oneTimeKeys @nativeId
  mark_keys_as_published: =>
    AccountBridge.markKeysAsPublished @nativeId
  max_number_of_one_time_keys: =>
    AccountBridge.maxNumberOfOneTimeKeys @nativeId
  generate_one_time_keys: (number_of_keys) =>
    AccountBridge.generateOneTimeKeys @nativeId, number_of_keys
  remove_one_time_keys: (session) =>
    AccountBridge.removeOneTimeKeys @nativeId, session.nativeId

# The Session class
export class Session
  constructor: ->
    @nativeId = SessionBridge.create()

  pickle: (key) => SessionBridge.pickle @nativeId, key
  unpickle: (key, pickle) =>
    @nativeId = SessionBridge.unpickle key, pickle
  free: => SessionBridge.free @nativeId
  create_outbound: (account, their_identity_key, their_one_time_key) =>
    SessionBridge.createOutbound @nativeId,
      account.nativeId, their_identity_key, their_one_time_key
  create_inbound: (account, one_time_key_message) =>
    SessionBridge.createInbound @nativeId,
      account.nativeId, one_time_key_message
  create_inbound_from: (account, identity_key, one_time_key_message) =>
    SessionBridge.createInboundFrom @nativeId,
      account.nativeId, identity_key, one_time_key_message
  session_id: => SessionBridge.sessionId @nativeId
  has_received_message: => SessionBridge.hasReceivedMessage @nativeId
  matches_inbound: (one_time_key_message) =>
    SessionBridge.matchesInbound @nativeId, one_time_key_message
  matches_inbound_from: (identity_key, one_time_key_message) =>
    SessionBridge.matchesInboundFrom @nativeId, identity_key,
      one_time_key_message
  encrypt: (plaintext) =>
    SessionBridge.encrypt @nativeId, plaintext
  decrypt: (message_type, message) =>
    SessionBridge.decrypt @nativeId, message_type, message
  describe: => "unimplemented description" # TODO: what should we use here?

# The Utility class
# Because this class has no internal state,
# we actually modelled it as a static class in the bridge side
# but for compatibility we still make it an actual class
export class Utility
  constructor: ->

  free: =>

  sha256: (input) => UtilityBridge.sha256 input
  ed25519_verify: (key, message, signature) =>
    if not UtilityBridge.ed25519verify key, message, signature
      throw "Cannot verify message"

# The InboundGroupSession class
export class InboundGroupSession
  constructor: ->
    @nativeId = 0

  pickle: (key) => InboundGroupSessionBridge.pickle @nativeId, key
  unpickle: (key, pickle) =>
    @nativeId = InboundGroupSessionBridge.unpickle key, pickle
  free: => InboundGroupSessionBridge.free @nativeId
  create: (session_key) =>
    @nativeId = InboundGroupSessionBridge.create session_key
    @
  import_session: (session_key) =>
    @nativeId = InboundGroupSessionBridge.importSession session_key
    @
  decrypt: (message) =>
    InboundGroupSessionBridge.decrypt @nativeId, message
  session_id: =>
    InboundGroupSessionBridge.sessionId @nativeId
  first_known_index: =>
    InboundGroupSessionBridge.firstKnownIndex @nativeId
  export_session: (message_index) =>
    InboundGroupSessionBridge.exportSession @nativeId, message_index

# The OutboundGroupSession class
export class OutboundGroupSession
  constructor: ->
    @nativeId = 0

  pickle: (key) => OutboundGroupSessionBridge.pickle @nativeId, key
  unpickle: (key, pickle) =>
    @nativeId = OutboundGroupSessionBridge.unpickle key, pickle
  free: => OutboundGroupSessionBridge.free @nativeId
  create: =>
    @nativeId = OutboundGroupSessionBridge.create()
  encrypt: (plaintext) =>
    OutboundGroupSessionBridge.encrypt @nativeId, plaintext
  session_id: =>
    OutboundGroupSessionBridge.sessionId @nativeId
  session_key: =>
    OutboundGroupSessionBridge.sessionKey @nativeId
  message_index: =>
    OutboundGroupSessionBridge.messageIndex @nativeId

# The PkEncryption class
export class PkEncryption
  constructor: ->
    @nativeId = PkEncryptionBridge.create()

  free: => PkEncryptionBridge.free @nativeId
  set_recipient_key: (key) =>
    PkEncryptionBridge.setRecipientKey @nativeId, key
  encrypt: (plaintext) =>
    PkEncryptionBridge.encrypt @nativeId, plaintext

# The PkDecryption class
export class PkDecryption
  constructor: ->
    @nativeId = PkDecryptionBridge.create()

  free: => PkDecryptionBridge.free @nativeId
  init_with_private_key: (key) =>
    PkDecryptionBridge.initWithPrivateKey @nativeId,
      Buffer.from(key).toString 'base64'
  generate_key: =>
    PkDecryptionBridge.generateKey @nativeId
  get_private_key: =>
    Buffer.from PkDecryptionBridge.getPrivateKey(@nativeId), 'base64'
  decrypt: (ephemeral_key, mac, ciphertext) =>
    PkDecryptionBridge.decrypt @nativeId, ephemeral_key, mac, ciphertext

# The PkSigning class
export class PkSigning
  constructor: ->
    @nativeId = PkSigningBridge.create()

  free: => PkSigningBridge.free @nativeId
  init_with_seed: (seed) =>
    PkSigningBridge.initWithSeed @nativeId,
      Buffer.from(seed).toString 'base64'
  generate_seed: =>
    Buffer.from PkSigningBridge.generateSeed(@nativeId), 'base64'
  sign: (message) =>
    PkSigningBridge.sign @nativeId, message

# The SAS class
export class SAS
  constructor: ->
    @nativeId = SASBridge.create()

  free: => SASBridge.free @nativeId
  get_pubkey: => SASBridge.getPubkey @nativeId
  set_their_key: (their_key) =>
    SASBridge.setTheirKey @nativeId, their_key
  generate_bytes: (info, length) =>
    Buffer.from SASBridge.generateBytes(@nativeId, info, length), 'base64'
  calculate_mac: (input, info) =>
    SASBridge.calculateMac @nativeId, input, info
  calculate_mac_long_kdf: (input, info) =>
    SASBridge.calculateMacLongKdf @nativeId, input, info