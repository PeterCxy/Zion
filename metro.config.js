/**
 * Metro configuration for React Native
 * https://github.com/facebook/react-native
 *
 * @format
 */

module.exports = {
  transformer: {
    getTransformOptions: async () => ({
      transform: {
        experimentalImportSupport: false,
        inlineRequires: false,
      },
    }),
    babelTransformerPath: require.resolve(
      'react-native-coffeescript-transformer'
    )
  },
  resolver: {
    extraNodeModules:
      Object.assign({}, require('node-libs-react-native'), {
        vm: require.resolve('node-libs-react-native/mock/vm')
      }),
    sourceExts: ['js', 'coffee', 'ts', 'tsx']
  }
};
