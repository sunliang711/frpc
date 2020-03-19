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
    Linux)
        ;;
    *)
        echo "Only on systemd Linux version"
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
serviceDir=$home/.config/systemd/user

install(){
    if [ ! -d $binDir ];then
        mkdir -p $binDir || { echo "make $binDir error.";exit 1; }
    fi
    if [ ! -d $serviceDir ];then
        mkdir -p $serviceDir || { echo "make $serviceDir error.";exit 1; }
    fi
    cp ./linux/frpc $binDir
    cp frpc.ini $binDir
    cp frpc_full.ini $binDir
    cat<<EOF>$serviceDir/frpc.service
[Uint]
Description=frpc service

[Service]
Type=simple
ExecStart=$binDir/frpc -c $binDir/frpc.ini
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    echo "Edit ${green}$binDir/frpc.ini${reset} to config"
    echo "Then issue '${green}systemctl --user start frpc${reset}'"
}

uninstall(){
    systemctl --user stop frpc 2>/dev/null
    rm -rf $binDir || { echo "rm $binDir error.";exit 1; }
    rm $serviceDir/frpc.service || { echo "rm $serviceDir/frpc.service error.";exit 1; }
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
