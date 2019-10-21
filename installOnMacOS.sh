#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"

user="${SUDO_USER:-$(whoami)}"
home="$(eval echo ~$user)"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 5)
reset=$(tput sgr0)
runAsRoot(){
    verbose=0
    while getopts ":v" opt;do
        case "$opt" in
            v)
                verbose=1
                ;;
            \?)
                echo "Unknown option: \"$OPTARG\""
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
    cmd="$@"
    if [ -z "$cmd" ];then
        echo "${red}Need cmd${reset}"
        exit 1
    fi

    if [ "$verbose" -eq 1 ];then
        echo "run cmd:\"${red}$cmd${reset}\" as root."
    fi

    if (($EUID==0));then
        sh -c "$cmd"
    else
        if ! command -v sudo >/dev/null 2>&1;then
            echo "Need sudo cmd"
            exit 1
        fi
        sudo sh -c "$cmd"
    fi
}

case $(uname) in
    Darwin)
        ;;
    *)
        echo "Only on MacOS"
        exit 1
esac

usage(){
    cat<<EOF
Usage: $(basename $0) cmd
cmd
    install
    uninstall
EOF
    exit 1
}

binDir=$home/.frpc
serviceDir=$home/Library/LaunchAgents

install(){
    if [ ! -d $binDir ];then
        mkdir -p $binDir || { echo "make $binDir error.";exit 1; }
    fi
    if [ ! -d $serviceDir ];then
        mkdir -p $serviceDir || { echo "make $serviceDir error.";exit 1; }
    fi
    cp ./Darwin/frpc $binDir
    cp frpc.ini $binDir
    cp frpc_full.ini $binDir
    cat<<EOF>$serviceDir/frpc.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>frpc</string>
    <key>ProgramArguments</key>
    <array>
        <string>$binDir/frpc</string>
        <string>-c</string>
        <string>$binDir/frpc.ini</string>
    </array>
    <key>StandardOutPath</key>
    <string>/tmp/privoxy-1.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/privoxy-1.log</string>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    echo "Edit ${green}$binDir/frpc.ini${reset} to config"
}

uninstall(){
    systemctl --user stop frpc 2>/dev/null
    launchctl unload -w $serviceDir/frpc.plist
    rm -rf $binDir || { echo "rm $binDir error.";exit 1; }
    rm $serviceDir/frpc.plist || { echo "rm $serviceDir/frpc.plist error.";exit 1; }
}

cmd=$1
case $cmd in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        usage
        ;;
esac
