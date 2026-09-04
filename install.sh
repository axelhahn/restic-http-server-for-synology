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
# ======================================================================

set -e

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

# GitHub release base URL
urlBase="https://github.com/restic/rest-server/releases/download"
resticVersion=

resticLink=rest-server

resticScript=rest_server.sh
autostart=/usr/local/etc/rc.d/$resticScript
logrotation=/etc/logrotate.d/restic_server

# ---------------------------------------------------------------------
# ERROR HANDLING
# ---------------------------------------------------------------------
fail() {
    echo "ERROR: $*"
    exit 1
}

# ---------------------------------------------------------------------
# ARCH DETECTION
# Maps uname -m → rest-server binary naming
# ---------------------------------------------------------------------
get_arch() {
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
            fail "Unsupported architecture: $(uname -m)"
            ;;
    esac
}

# ------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------

function _quit(){
        echo CRITICAL ERROR: $*
        exit 1
}

function _h2(){
        echo
        echo "--- $*"
}

function _getLocalVersion(){
        # test -x $resticLink/rest_server && $resticLink/rest_server -V | cut -f 2 -d ' '

        # works in v0.10.0
        # $resticLink/rest-server -V 2>/dev/null | cut -f 2 -d ' '

        # works in v0.14.0
        # $resticLink/rest-server -v 2>/dev/null | cut -f 4 -d ' '

        ls -1 | grep "rest-server_[0-9].*_" | cut -f 2 -d '_' | sort -n | tail -1
}

# ---------------------------------------------------------------------
# GET LATEST VERSION FROM GITHUB
# (simple HTML scrape, no API dependency)
# ---------------------------------------------------------------------
function _getRemoteVersion() {
	curl -s https://api.github.com/repos/restic/rest-server/releases/latest |
    grep '"tag_name"' |
    cut -d '"' -f4 |
    sed 's/^v//'
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

echo "
========== INSTALL RESTIC SERVER ==========
"
cd $( dirname $0 ) || _quit "cannot change directory ..."

# Detect CPU architecture
arch=$(get_arch)
echo "[INFO] architecture: $arch"

localversion=$( _getLocalVersion )
resticVersion=$( _getRemoteVersion )
echo "
[INFO] local version : $localversion
[INFO] remote version: $resticVersion"

test -z "$resticVersion" && _quit "Unable to detect remote version from $urlBase"

if [ "$resticVersion" = "$localversion" ]; then
    echo "       --> Versions are equal"
else 
    echo "       --> Installation or update is needed"
fi
echo

urlRestic="${urlBase}/v${resticVersion}/rest-server_${resticVersion}_${arch}.tar.gz"
dlFile=$( basename $urlRestic )
resticDir=rest-server_${resticVersion}_${arch}

echo "[INFO] download URL: $urlRestic"

_h2 "Download"
if [ -f $dlFile ]; then
        echo "SKIP download"
else
        wget -O ${dlFile}.running -S $urlRestic \
                && mv ${dlFile}.running ${dlFile}
fi
test -f $dlFile || _quit "Download failed."


_h2 "Extract ${dlFile}"
tar -xzf ${dlFile} || _quit "Extraction failed."
ls -ld $resticDir || _quit "Extraction was done ... but expected dir $resticDir does not exist. I am confused :-/"


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
$(pwd )/$logfile {
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


echo "

========== INSTALLATION SUCCESSFUL! ==========

(1)
Have a look to the file 'rest_server.conf'.

(2)
Create a user to access a private repo with 'sudo ./useradmin.sh add [user]'

(3)
Then start the server with 'sudo ./rest_server.sh start'.

"

# ------------------------------------------------------------
