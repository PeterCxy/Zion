# Thanks: <https://medium.com/better-programming/creating-a-multi-language-app-in-react-native-9828b138c274>
import { default as i18njs } from "i18n-js"
import * as RNLocalize from "react-native-localize"
import memoize from "lodash.memoize"
import { I18nManager } from "react-native"

translations =
  en: () => require("../translations/en.json")

export translate = memoize(
  (key, config) => i18njs.t(key, config),
  (key, config) => if config then (key + JSON.stringify(config)) else key
)

export reloadI18n = () ->
  fallback =
    languageTag: 'en'
    isRTL: false

  { languageTag, isRTL } =
    RNLocalize.findBestAvailableLanguage(Object.keys translations) or fallback

  translate.cache.clear()
  I18nManager.forceRTL isRTL
  i18njs.translations = { [languageTag]: translations[languageTag]() }
  i18njs.locale = languageTag