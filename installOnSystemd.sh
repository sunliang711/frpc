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

case $(uname)in
    Linux)
        ;;
    *)
        echo "Only on systemd Linux version"
        exit 1
esac

if (($EUID!=0));then
    echo "Need run as root"
    exit 1
fi

usage(){
    cat<<EOF
Usage: $(basename $0) cmd
cmd
    install
    uninstall
EOF
    exit 1
}

dest=$home/.frpc
install(){
    if [ ! -d $dest ];then
        mkdir $dest
    fi
    cp ./linux/frpc $dest
    cp frpc.ini $dest
    cat<<EOF>$home/.config/systemd/user/frpc.service
[Uint]
Description=frpc service

[Service]
Type=simple
ExecStart=$dest/.frpc/frpc -c $dest/.frpc/frpc.ini
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    echo "Edit $dest/.frpc/frpc.ini to config"
    echo "Then systemctl --user start frpc"
}

uninstall(){
    systemctl --user stop frpc 2>/dev/null
    rm -rf $dest
    rm $home/.config/systemd/user/frpc.service
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
