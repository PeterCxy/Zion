import SQLite from 'react-native-sqlite-2'
import setGlobalVars from "@indexeddbshim/indexeddbshim/src/browser-noninvasive"
import * as m from 'matrix-js-sdk'
import React from 'react'

initGlobals = ->
  # This is needed by `browser-request`, used by matrix-js-sdk
  global.location =
    href: "https://example.com"

initIndexedDB = ->
  win = {}
  setGlobalVars win,
    win: SQLite
    checkOrigin: false
    deleteDatabaseFiles: false
    useSQLiteIndexes: true
  win.indexedDB

initIndexedDBStore = ->
  store = new m.IndexedDBStore
    indexedDB: initIndexedDB()
    dbName: 'matrix-client'
  await store.startup()
  store

export MatrixClientContext = React.createContext null

export createMatrixClient = (baseUrl, token, uid) ->
  initGlobals()
  m.createClient
    baseUrl: baseUrl
    accessToken: token
    userId: uid
    store: await initIndexedDBStore()

export createLoginMatrixClient = (baseUrl) ->
  initGlobals()
  m.createClient
    baseUrl: baseUrl