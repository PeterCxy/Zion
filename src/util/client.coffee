import SQLite from 'react-native-sqlite-2'
import setGlobalVars from "indexeddbshim/src/browser-noninvasive"
import * as m from 'matrix-js-sdk'
import { setNativeCrypto } from 'matrix-js-sdk/lib/crypto/aes'
import { verificationMethods } from 'matrix-js-sdk/lib/crypto'
import { LocalIndexedDBStoreBackend } from 'matrix-js-sdk/lib/store/indexeddb-local-backend'
import React from 'react'
import LocalStorage from './LocalStorage'
import * as Olm from './olm'
import * as NativeCrypto from './NativeCrypto'

initGlobals = ->
  # This is needed by `browser-request`, used by matrix-js-sdk
  global.location =
    href: "https://example.com"
  # The Olm object for matrix-js-sdk
  global.Olm = Olm
  setNativeCrypto NativeCrypto

initIndexedDB = ->
  win = {}
  setGlobalVars win,
    win: SQLite
    checkOrigin: false
    deleteDatabaseFiles: false
    useSQLiteIndexes: true
  win.indexedDB

initIndexedDBStore = (indexedDB) ->
  store = new ExtraIndexedDBStore
    indexedDB: indexedDB
    localStorage: new LocalStorage "local"
    dbName: 'matrix-client'
  await store.startup()
  store

initIndexedDBCryptoStore = (indexedDB) ->
  store = new m.IndexedDBCryptoStore indexedDB, 'matrix-client-crypto-store-db'
  await store.startup()
  store

export MatrixClientContext = React.createContext null

export createMatrixClient = (baseUrl, token, uid, deviceId, getSecretStorageKey) ->
  initGlobals()
  indexedDB = initIndexedDB()
  client = m.createClient
    baseUrl: baseUrl
    accessToken: token
    userId: uid
    deviceId: deviceId
    store: await initIndexedDBStore indexedDB
    cryptoStore: await initIndexedDBCryptoStore indexedDB
    sessionStore: new m.WebStorageSessionStore new LocalStorage "session"
    verificationMethods: [verificationMethods.SAS]
    cryptoCallbacks:
      getSecretStorageKey: getSecretStorageKey
  await client.initCrypto()
  await client.startClient
    pendingEventOrdering: 'detached'
    clientWellKnownPollPeriod: 60 * 60
  # TODO: remove this (force users to verify everyone in room before sending?)
  client.setGlobalErrorOnUnknownDevices false
  client

export createLoginMatrixClient = (baseUrl) ->
  initGlobals()
  m.createClient
    baseUrl: baseUrl

class ExtraIndexedDBStore extends m.IndexedDBStore
  constructor: (opts) ->
    super opts
    # Use our own backend
    this.backend = new ExtraIndexedDBBackend opts.indexedDB, opts.dbName + "-real"

CHUNK_SIZE = 768 * 1024

# A hacked IndexedDBLocalBackend that stores sync data in its own db
# and loads them chunks to avoid oversize issues
# (we cannot do this through the IndexedDB shim abstraction)
class ExtraIndexedDBBackend extends LocalIndexedDBStoreBackend
  constructor: (indexedDBInterface, dbName) ->
    super indexedDBInterface, dbName
    @myDb = SQLite.openDatabase "extra.db", "1.0", "", 1

  _init: ->
    await super._init()

    new Promise (resolve, reject) =>
      @myDb.transaction (txn) ->
        txn.executeSql(
          "CREATE TABLE IF NOT EXISTS sync(clobber TEXT PRIMARY KEY NOT NULL, data TEXT)",
          [],
          () => resolve null,
          (err) => reject err
        )

  _persistSyncData: (nextBatch, roomsData, groupsData) ->
    console.log "Persisting sync data up to #{nextBatch} into extra db"
    obj =
      nextBatch: nextBatch
      roomsData: roomsData
      groupsData: groupsData
    
    new Promise (resolve, reject) =>
      @myDb.transaction (txn) ->
        txn.executeSql(
          "INSERT OR REPLACE INTO sync(clobber, data) VALUES (:clobber, :data)",
          ["-", JSON.stringify(obj)],
          () => resolve null,
          (_, err) => reject err
        )

  _loadSyncData: ->
    pos = 1
    data = ""
    while true
      chunk = null
      try
        chunk = await @_loadSyncDataChunk pos
      catch err
        return {}
      data += chunk
      if chunk.length < CHUNK_SIZE
        break
      pos += CHUNK_SIZE

    if data == ""
      return {}
    else
      JSON.parse data

  _loadSyncDataChunk: (pos) ->
    new Promise (resolve, reject) =>
      @myDb.transaction (txn) ->
        txn.executeSql(
          "SELECT substr(data, :pos, :chunk_size) FROM sync",
          [pos, CHUNK_SIZE],
          (_, res) ->
            if res.rows.length > 0
              resolve Object.values(res.rows.item(0))[0]
            else
              resolve ""
          ,
          (err) -> reject err
        )