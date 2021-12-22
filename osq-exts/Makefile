all: build

build:
	GOOS=darwin GOARCH=amd64 go build -o ./build/darwin/darwin.osq.amd64.ext
	GOOS=darwin GOARCH=arm64 go build -o ./build/darwin/darwin.osq.arm64.ext
	GOOS=linux GOARCH=amd64 go build -o ./build/linux/linux.osq.amd64.ext
	GOOS=linux GOARCH=arm64 go build -o ./build/linux/linux.osq.arm64.ext
	GOOS=windows GOARCH=amd64 go build -o ./build/windows/windows.osq.amd64.ext.exe
	GOOS=windows GOARCH=arm64 go build -o ./build/windows/windows.osq.arm64.ext.exe

test:
	go test -race -cover ./...

clean:
	rm -rf ./build
