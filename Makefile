all:
	swift build $(CFLAGS) --product protoc-gen-zap --static-swift-stdlib -c release
	cp .build/release/protoc-gen-zap .
test:
	protoc -I/usr/local/include -I. -I./googleapis --plugin=protoc-gen-custom=./protoc-gen-zap --custom_out=. rpc.proto
clean:
	-rm -rf Packages
	-rm -rf .build build
	-rm -rf protoc-gen-zap
