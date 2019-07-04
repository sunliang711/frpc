#!/bin/bash

#need golang installed
if ! command -v go >/dev/null 2>&1;then
    echo "Need golang installed!!"
    exit 1
fi

#check git command
if ! command -v git >/dev/null 2>&1;then
    echo "Need git installed!!"
    exit 1
fi

export GOPATH=$PWD/go
oldpwd=$PWD

mkdir -pv $GOPATH/src/github.com/fatedier
cd $GOPATH/src/github.com/fatedier
git clone https://github.com/fatedier/frp.git
cd frp
#strip binary
sed -i bak 's/go build/& -ldflags "-s" /' Makefile

echo "Compile Linux64 version of frp..."
env GOOS=linux GOARCH=amd64 make
mv bin $oldpwd/frp-bin-linux64

echo
echo "Compile Macos version of frp..."
env GOOS=darwin GOARCH=amd64 make
mv bin $oldpwd/frp-bin-macos

echo
echo "Compile Win64 version of frp..."
env GOOS=windows GOARCH=amd64 make
mv bin $oldpwd/frp-bin-win64

echo
echo "Compile Win32 version of frp..."
env GOOS=windows GOARCH=386 make
mv bin $oldpwd/frp-bin-win32

echo
echo "Compile Arm5 version of frp..."
env GOOS=linux GOARCH=arm GOARM=5 make
mv bin $oldpwd/frp-bin-arm5
