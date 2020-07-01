import { NativeModules } from "react-native"

# We expect the native side to provide some
# truly-asynchronous file operations (see Java for details)
# The issue with RNFS's write and read operations
# is that they are not truly asynchronous -- they
# run on a separate thread but only one thread.
# This makes one operation block all the other
# read / writes, which can be suboptimal if we
# have several reads / writes in parallel.
# (RNFetchBlob does not have this issue)
# The native side must implement these using
# separate threads for each operation.
export default NativeModules.AsyncFileOps;