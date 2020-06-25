# Thanks: <https://medium.com/better-programming/creating-a-multi-language-app-in-react-native-9828b138c274>
import { default as i18njs } from "i18n-js"
import * as RNLocalize from "react-native-localize"
import memoize from "lodash.memoize"
import { I18nManager } from "react-native"

translations =
  en: () => require("../translations/en.json")

_translate = memoize(
  (key, config) => i18njs.t(key, config),
  (key, config) => if config then (key + JSON.stringify(config)) else key
)

# Get a translated string for a given key
# The string can be a template, something like
# > %a has invited %b
# and the template arguments should be passed as
# varargs to this function.
# %a will be replaced by the first argument, %b
# by the second, and so on
# if there is only one argument, using % would be
# enough.
export translate = (key, args...) ->
  str = _translate key
  if not args or args.length == 0
    str
  else
    str.replace /(?<!\\)%([a-z]?)/g, (match) ->
      if match == "%"
        args[0]
      else
        args[match.charCodeAt(1) - 97] # 97 = 'a'

export reloadI18n = () ->
  fallback =
    languageTag: 'en'
    isRTL: false

  { languageTag, isRTL } =
    RNLocalize.findBestAvailableLanguage(Object.keys translations) or fallback

  _translate.cache.clear()
  I18nManager.forceRTL isRTL
  i18njs.translations = { [languageTag]: translations[languageTag]() }
  i18njs.locale = languageTag