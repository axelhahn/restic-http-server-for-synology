#!/bin/bash

. color.class.sh || exit 2

export _version=0.6

function header(){

# https://patorjk.com/software/taag/#p=display&f=Small+Block&t=Synology+-+Restic+Server&x=none&v=4&h=4&w=80&we=false

color.echo yellow "

   ▞▀▖         ▜               ▛▀▖      ▐  ▗     ▞▀▖               
   ▚▄ ▌ ▌▛▀▖▞▀▖▐ ▞▀▖▞▀▌▌ ▌ ▄▄▖ ▙▄▘▞▀▖▞▀▘▜▀ ▄ ▞▀▖ ▚▄ ▞▀▖▙▀▖▌ ▌▞▀▖▙▀▖
   ▖ ▌▚▄▌▌ ▌▌ ▌▐ ▌ ▌▚▄▌▚▄▌     ▌▚ ▛▀ ▝▀▖▐ ▖▐ ▌ ▖ ▖ ▌▛▀ ▌  ▐▐ ▛▀ ▌  
   ▝▀ ▗▄▘▘ ▘▝▀  ▘▝▀ ▗▄▘▗▄▘     ▘ ▘▝▀▘▀▀  ▀ ▀▘▝▀  ▝▀ ▝▀▘▘   ▘ ▝▀▘▘  v${_version}
"
color.echo green "
📄 Source: https://github.com/axelhahn/restic-http-server-for-synology
📜 License: GNU GPL 3.0
📗 Docs: https://www.axel-hahn.de/docs/restic-http-server-for-synology/

    "

}

function _h2(){
        echo
        color.echo purple "      ________________________________________________________________"
        color.echo purple "_____/  $*"
        echo
}

function _quit(){
        >&2 color.echo red "❌ ERROR: $1"
        exit ${2:-1}
}
