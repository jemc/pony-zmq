all: test
.PHONY: all test clean lldb lldb-test ci ci-setup

PKG=zmq

bin/test: $(shell find ${PKG} .deps -name *.pony)
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
	apt-get update && apt-get install -y libsodium-dev
	stable fetch
