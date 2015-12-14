#!/bin/bash

clear

export bashUrl=https://raw.githubusercontent.com/lanshunfang/free-server/master/
export self="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/$0"

# get global utils
globalUtilStoreDir=/opt
mkdir -p ${globalUtilStoreDir}
chmod 755 ${globalUtilStoreDir}
cd ${globalUtilStoreDir}
# prepare global functions
rm -f .global-utils.sh
wget --no-cache ${bashUrl}/utils/.global-utils.sh
source .global-utils.sh

enforceInstallOnUbuntu

if [[ $UID -ne 0 ]]; then
    echo "$0 must be run as root"
    exit 1
fi

echoS "apt-get update and install required tools"
warnNoEnterReturnKey
apt-get update -y > /dev/null

catchError=$(apt-get install -y gawk 2>&1 >${loggerStdoutFile})

exitOnError "${catchError}"

catchError=$(apt-get install -y curl 2>&1 >${loggerStdoutFile})

exitOnError "${catchError}"

echoS "Migrate obsolete installation"
cd ${globalUtilStoreDir}
rm -f migrate.sh

catchError=$(downloadFileToFolder ${bashUrl}/setup-tools/migrate.sh ${globalUtilStoreDir}/ 2>&1 >${loggerStdoutFile})
exitOnError "${catchError}"

chmod 755 ./migrate.sh >${loggerStdoutFile}
./migrate.sh >${loggerStdoutFile}

echoS "Init Env"
warnNoEnterReturnKey

if [[ -d ${freeServerRoot} ]]; then
    echoS "Old free-server installation detected. Script is going to perform Save Upgrading in 5 seconds.\
     Press Ctrl+C to cancel"
    sleep 5

    echoS "Removing Old free-server installation"

    # restore backed up config files
    if [[ -d ${configDirBackup} ]]; then
        echoS "Old backed up config files found in ${configDirBackup}. \
        This is not correct. You should move it to other place or just delete it before proceed. Exit"
        exit 0
    fi

    # move current config files to a save place if has

    mv ${configDir} ${configDirBackup}

    rm -rf ${freeServerRoot}

fi

echoS "Create Folder scaffold"

wget --no-cache -qO- ${baseUrlSetup}/init-folders.sh | /bin/bash


echoS "Getting and processing utility package"
warnNoEnterReturnKey

downloadFileToFolder ${bashUrl}/setup-tools/download-files.sh ${freeServerRootTmp}
chmod 755 ${freeServerRootTmp}/download-files.sh
${freeServerRootTmp}/download-files.sh

echoS "Installing NodeJS and NPM"
warnNoEnterReturnKey

catchError=$(${freeServerRootTmp}/install-node.sh 2>&1 >${loggerStdoutFile})

exitOnError "${catchError}"


echoS "Installing and initing Shadowsocks"
warnNoEnterReturnKey

catchError=$(${freeServerRootTmp}/install-shadowsocks.sh 2>&1 >${loggerStdoutFile})

exitOnError "${catchError}"

echoS "Installing SPDY Proxy"
warnNoEnterReturnKey

#${freeServerRootTmp}/install-spdy.sh
catchError=$(${freeServerRootTmp}/install-spdy-nghttpx-squid.sh 2>&1 >${loggerStdoutFile})

exitOnError "${catchError}"

echoS "Installing IPSec/IKEv2 VPN (for IOS)"

catchError=$(${freeServerRootTmp}/install-ipsec-ikev2.sh 2>&1 >${loggerStdoutFile})

exitOnError "${catchError}"

#echoS "Installing and Initiating Free Server Cluster for multiple IPs/Domains/Servers with same Login Credentials support"
#
#${freeServerRootTmp}/install-cluster.sh

# restore backed up config files
if [ -d ${configDirBackup} ]; then
    cp -rn ${configDir}/* ${configDirBackup}
    rm -rf ${configDir}
    mv ${configDirBackup} ${configDir}
fi

echoS "Restart and Init Everything in need"

catchError=$(${freeServerRootTmp}/init.sh 2>&1 >${loggerStdoutFile})

exitOnError "${catchError}"

echoS "All done. Create user example: \n\n\
\
Shadowsocks+SPDY+IPSec: ${freeServerRoot}/createuser User Pass ShadowsocksPort SPDYPort \n\n\
\
Shadowsocks Only: ${freeServerRoot}/createuser-shadowsocks Port Pass \n\n\
\
SPDY Only: ${freeServerRoot}/createuser-spdy-nghttpx-squid User Pass Port \n\n\
\
IPSec Only: ${freeServerRoot}/createuser-ipsec User Pass \n\n\
\
"

echoS "\x1b[46m Next step: \x1b[0m\n\n\
1. Create a user: ${freeServerRoot}/createuser USERNAME PASSWORD ShadowsocksPort SPDYPort
2. Config Chrome or other client. Tutorial is here: https://github.com/lanshunfang/free-server#how-to-setup-clients
"

echoS "Note that, the IpSec PSK(Secret) is located: \x1b[46m ${ipsecSecFile} \x1b[0m. You may want to reedit the PSK field."
# remove self
rm -f "$self"




