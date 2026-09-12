#!/usr/bin/bash
# ======================================================================
#
# INSTALL RESTIC HTTP SERVER ON SYNOLOGY NAS
# Supports:
#   - ARMv7 (armv7l / armv7)
#   - ARM64 (aarch64 / arm64)
#   - x86_64
#
# Downloads prebuilt binaries from GitHub releases
# https://github.com/restic/rest-server
# ----------------------------------------------------------------------
# License: GNU GPL 3.0
# ----------------------------------------------------------------------
# 2021-03-29  www.axelhahn.de  init ... but WIP
# 2021-03-31  www.axelhahn.de  create logrotate.d
# 2025-12-26  www.axelhahn.de  fetch version from h2 node (arm64 linux compiled version is not available in html source)
# 2026-05-28  basti122303      add multi-arch support
# 2026-09-12  www.axelhahn.de  install bcrypt-tool
# ======================================================================

set -e

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

# GitHub <author>/<project>
projectRest="restic/rest-server"
projectBcrypt="shoenig/bcrypt-tool"

remoteVersionRest=
resticLink=rest-server

resticScript=rest_server.sh
autostart=/usr/local/etc/rc.d/$resticScript
logrotation=/etc/logrotate.d/restic_server

# ------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------

function _quit(){
        >&2 echo "❌ CRITICAL ERROR: $*"
        >&2 exit 1
}

function _h2(){
        echo
        echo
        echo "_____/  $*"
        echo
}

function _hr(){
    echo
    echo "-------------------------------------------------------------------------------"
    echo
}

function _getLocalVersion(){
        local _prj="$1"

        case "$_prj" in
            $projectBcrypt)
                ls -1 bcrypt/*gz 2>/dev/null | sort -n | tail -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""
                ;;
            $projectRest)
                # ls -1 rest-server*gz  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' 
                ls -1 | grep "rest-server_[0-9].*_" | sort -n | tail -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""
                # ./rest-server/rest-server --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
                ;;
            *)
                _quit "Unknown tool: $_tool"
                ;;
        esac
}

# ---------------------------------------------------------------------
# GET LATEST VERSION FROM GITHUB
# param  1: project name (e.g. restic/rest-server)
# ---------------------------------------------------------------------
function _getRemoteVersion() {
    local _prj="$1"
	curl -s "https://api.github.com/repos/${_prj}/releases/latest" | grep '"tag_name"' | cut -d '"' -f4 | sed 's/^v//'
exit
}

# ---------------------------------------------------------------------
# ARCH DETECTION
# Maps uname -m → rest-server binary naming
# ---------------------------------------------------------------------
function get_arch() {
    case "$(uname -m)" in
        x86_64)
            echo "linux_amd64"
            ;;
        aarch64|arm64)
            echo "linux_arm64"
            ;;
        armv7l|armv7*)
            echo "linux_armv7"
            ;;
        *)
            _quit "Unsupported architecture: $(uname -m)"
            ;;
    esac
}

function downloadAndExtract() {
    local _url="$1"
    local _targetdir="$2"
    
    local _dlFile="$( basename "$url" )"

    # remark: a subshell to finish in the same directory
    (
        _h2 "Download ${_url}"
        if [ -n "$_targetdir" ]; then
            mkdir -p "$_targetdir" || _quit "Unable to create target directory: $_targetdir"
            cd "$_targetdir" || _quit "Unable to change to target directory: $_targetdir"
        fi
        if [ -f "$_dlFile" ]; then
            echo "SKIP download: $_dlFile already exists"
        else
            if ! wget -O ${_dlFile}.tmp -S "$url"; then
                _quit "Download failed for URL: $_url"
            fi
            mv ${_dlFile}.tmp ${_dlFile}
        fi

        _h2 "Extract ${_dlFile}"
        pwd
        tar -xvzf "${_dlFile}" || _quit "Extraction failed."
    )
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

# https://patorjk.com/software/taag/#p=display&f=Small+Block&t=Synology+-+Restic+Server&x=none&v=4&h=4&w=80&we=false
echo "
   ▞▀▖         ▜               ▛▀▖      ▐  ▗     ▞▀▖               
   ▚▄ ▌ ▌▛▀▖▞▀▖▐ ▞▀▖▞▀▌▌ ▌ ▄▄▖ ▙▄▘▞▀▖▞▀▘▜▀ ▄ ▞▀▖ ▚▄ ▞▀▖▙▀▖▌ ▌▞▀▖▙▀▖
   ▖ ▌▚▄▌▌ ▌▌ ▌▐ ▌ ▌▚▄▌▚▄▌     ▌▚ ▛▀ ▝▀▖▐ ▖▐ ▌ ▖ ▖ ▌▛▀ ▌  ▐▐ ▛▀ ▌  
   ▝▀ ▗▄▘▘ ▘▝▀  ▘▝▀ ▗▄▘▗▄▘     ▘ ▘▝▀▘▀▀  ▀ ▀▘▝▀  ▝▀ ▝▀▘▘   ▘ ▝▀▘▘  
   
📄 Source: https://github.com/axelhahn/restic-http-server-for-synology
📜 License GNU GPL 3.0


    INSTALLER
"
cd $( dirname $0 ) || _quit "cannot change directory ..."

_hr

# Detect CPU architecture
arch=$(get_arch)
echo "[INFO] architecture: $arch"

# # remoteVersionRest=$( _getRemoteVersion "${urlBaseRest}" )
remoteVersionRest=$( _getRemoteVersion "${projectRest}" )
localResticVersion=$( _getLocalVersion "${projectRest}" )
echo "
[INFO] remote version: $remoteVersionRest
[INFO] local version : $localResticVersion"

# test -z "$remoteVersionRest" && _quit "Unable to detect remote version."

if [ -z "$localResticVersion" ]; then
    echo "
    
    WELCOME

    This installer brings up the Restic rest server on your Synology NAS. 

    (1)
    It will download the latest version of 
         - rest-server binary - to start http restic server
         - bcrypt binary      - to create blowfish hashes in .htpasswd file
    and install it in the current directory.

    (2)
    Needed working directories will be created.
    
    (3)
    Autostart of Restic rest service will be enabled.
"
elif [ "$remoteVersionRest" = "$localResticVersion" ]; then
    echo "       --> Versions are equal - reinstalling current version"
else 
    echo "       --> Update was found"
fi
echo
echo -n "Press ENTER to continue or Ctrl + C to abort ... "; read dummy

resticDir=rest-server_${remoteVersionRest}_${arch}

_hr

echo "Download tools from Github..."
echo

for myproject in "${projectRest}" "${projectBcrypt}"
do
    echo
    echo "-----=====#####|  $myproject"
    echo
    urlBase="https://github.com/${myproject}/releases"

    remoteVersion=$( _getRemoteVersion "${myproject}" )
    echo "Version on server: $remoteVersion"

    localVersion=$( _getLocalVersion "${myproject}" )
    echo "Version local    : $localVersion"

    prj="$( echo "$myproject" | cut -f 2 -d '/' )"
    url="${urlBase}/download/v${remoteVersion}/${prj}_${remoteVersion}_${arch}.tar.gz"
    target=""; test "$myproject" = "${projectBcrypt}" && target="bcrypt"

    downloadAndExtract "${url}" "${target}"
done

_hr
echo "Preparing local files ..."
echo

resticDir=rest-server_${remoteVersionRest}_${arch}

_h2 "Create Link"
rm -f $resticLink || true
ln -s $resticDir $resticLink && ls -l $resticLink || _quit "Unable to create softlink $resticLink."


_h2 "Make binary executable"
chmod 750 $resticDir/rest-server
ls -l $resticDir/rest-server


_h2 "Init dirs"
test -d log  || mkdir log  || _quit "unable to create dir [log]."
test -d data || mkdir data || _quit "unable to create dir [data]."
ls -ld log data


# 
# removed after writing useradmin.sh
#
# _h2 "Init default user and password $auth"
# test -f data/.htpasswd && echo "SKIP: data/.htpasswd already exists"
# test -f data/.htpasswd || echo "creating default $auth (unencrypted)" \
#       && echo $auth >data/.htpasswd \
#       || _quit "Unable to create default user and password"


_h2 "Create config"
test -f "$( pwd )/rest_server.conf" && echo "SKIP: rest_server.conf already exists"
test -f "$( pwd )/rest_server.conf" || cp "$( pwd )/rest_server.conf.dist" "$( pwd )/rest_server.conf"
ls -l "$( pwd )/rest_server.conf" || _quit "Unable to create rest_server.conf (copy of .dist file)"
. "$( pwd )/rest_server.conf"


_h2 "Enable autostart"
sudo echo "$( pwd )/$resticScript \$*" >$autostart && sudo chmod 755 $autostart \
        || _quit "Unable to create autostart $autostart ... it requires root permissions"

echo "INFO: file $autostart was created ... with content"
cat $autostart


_h2 'Add logrotation'
cat << EOLOG >$logrotation
$( pwd )/$logfile {
  rotate 7
  daily
  compress
  dateext
  dateformat __%Y-%m-%d

  # firstaction
  #   $autostart stop
  # endscript

  sharedscripts

  postrotate
    $autostart restart
  endscript
} 
EOLOG
ls -l $logrotation || _quit "unable to create logrotation file"
# cat /etc/logrotate.d/restic_server

_hr

echo "

========== INSTALLATION SUCCESSFUL! ==========

(1)
Have a look to the file 'rest_server.conf'.

(2)
Create a user to access a private repo with 'sudo ./useradmin.sh add [user]'

(3)
Then start the server with 'sudo ./rest_server.sh start'.

You can repeat the install.sh script to update the rest-server binary 
to the latest version.

Have a nice day!
"

# ------------------------------------------------------------
