# pony-zmq [![CircleCI](https://circleci.com/gh/jemc/pony-zmq.svg?style=shield)](https://circleci.com/gh/jemc/pony-zmq)

Pure Pony implementation of the ZeroMQ messaging library.

## Testing

1. Get [stable](https://github.com/jemc/pony-stable) (to manage dependencies).
2. Get
   [libsodium](https://download.libsodium.org/doc/installation/index.html)
   (required for [pony-sodium](https://github.com/jemc/pony-sodium)).
   On OSX just to `brew install libsodium'.
3. Fetch dependencies: `stable fetch`
3. `stable env ponyc --debug zmq/test`
4. `./test`
