import { NativeModules } from "react-native"

Bridge = NativeModules.LocalStorageBridge

# Polyfill of LocalStorage using synchronous native module
export default class LocalStorage
  constructor: (@name) ->
    Bridge.instantiate @name

  getItem: (key) =>
    Bridge.getItem @name, key

  setItem: (key, value) =>
    Bridge.setItem @name, key, value

  removeItem: (key) =>
    Bridge.removeItem @name, key

  key: (index) =>
    Bridge.key @name, index

  clear: =>
    Bridge.clear @name