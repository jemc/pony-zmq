all: test
.PHONY: all test clean lldb lldb-test ci ci-setup

PKG=zmq

.deps: bundle.json
	stable fetch
	touch .deps

bin/test: .deps $(shell find ${PKG} .deps -name *.pony)
	mkdir -p bin
	stable env ponyc --debug -o bin ${PKG}/test

test: bin/test
	$^

clean:
	rm -rf .deps bin

lldb:
	stable env lldb -o run -- $(shell which ponyc) --debug -o /tmp ${PKG}/test

lldb-test: bin/test
	lldb -o run -- bin/test

ci: test

ci-setup:
	ls pony-stable || git clone --depth=1 https://github.com/ponylang/pony-stable
	make -C pony-stable install
	apt-get update && apt-get install -y libsodium-dev
