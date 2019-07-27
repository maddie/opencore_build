#!/bin/bash

BUILD_DIR="${HOME}/Downloads/OpenCore_Build"
FINAL_DIR="${HOME}/Desktop/CompletedBuilds"

length=${#BUILD_DIR} # macOS's older bash needs temp variable, as just -1 won't work
[[ "${BUILD_DIR}" == */ ]] && BUILD_DIR="${BUILD_DIR:0:length-1}" # remove trailing slash
length=${#FINAL_DIR}
[[ "${FINAL_DIR}" == */ ]] && FINAL_DIR="${FINAL_DIR:0:length-1}"

check=$((xcode-\select --install) 2>&1)
str="xcode-select: note: install requested for command line developer tools"

prompt() {
  echo "$1"
  if [ "$FORCE_INSTALL" != "1" ]; then
    read -p "Enter [Y]es to continue: " v
    if [ "$v" != "Y" ] && [ "$v" != "y" ]; then
      exit 1
    fi
  fi
}

while [[ "$check" == "$str" ]];
do
  osascript -e 'tell app "System Events" to display dialog "xcode command-line tools missing." buttons "OK" default button 1 with title "xcode command-line tools"'
  exit;  
done

if [ "$(nasm -v)" = "" ] || [ "$(nasm -v | grep Apple)" != "" ]; then
  echo "Missing or incompatible nasm!"
  echo "Download the latest nasm from http://www.nasm.us/pub/nasm/releasebuilds/"
  prompt "Install last tested version automatically?"
  pushd /tmp >/dev/null
  rm -rf nasm-mac64.zip
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/nasm-mac64.zip" || exit 1
  nasmzip=$(cat nasm-mac64.zip)
  rm -rf nasm-*
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/${nasmzip}" || exit 1
  unzip -q "${nasmzip}" nasm*/nasm nasm*/ndisasm || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo mv nasm*/nasm /usr/local/bin/ || exit 1
  sudo mv nasm*/ndisasm /usr/local/bin/ || exit 1
  rm -rf "${nasmzip}" nasm-*
  popd >/dev/null
fi

if [ "$(which mtoc.NEW)" == "" ] || [ "$(which mtoc)" == "" ]; then
  echo "Missing mtoc or mtoc.NEW!"
  echo "To build mtoc follow: https://github.com/tianocore/tianocore.github.io/wiki/Xcode#mac-os-x-xcode"
  prompt "Install prebuilt mtoc and mtoc.NEW automatically?"
  pushd /tmp >/dev/null
  rm -f mtoc mtoc-mac64.zip
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/mtoc-mac64.zip" || exit 1
  unzip -q mtoc-mac64.zip mtoc || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo cp mtoc /usr/local/bin/mtoc || exit 1
  sudo mv mtoc /usr/local/bin/mtoc.NEW || exit 1
  popd >/dev/null
fi

buildrelease() {
  local name=$(pwd)
  local result=${name##*/}
  if [ result == "Lilu" ]
  then
    name=Lilu
  elif [ result == "WhateverGree"n ]
  then
    name=WhateverGreen
  elif [ result == "CPUFriend" ]
  then
    name=CPUFriend
  elif [ result == "AppleALC" ]
  then
    name=AppleALC
  elif [ result == "VirtualSMC" ]
  then
    name=VirtualSMC
  fi
  echo "Compiling the latest commited Release version of $result."
  xcodebuild -configuration Release > /dev/null 2>&1 || exit 1
}

builddebug() {
  local name=$(pwd)
  local result=${name##*/}
  if [ result == "Lilu" ]
  then
    name=Lilu
  elif [ result == "WhateverGree"n ]
  then
    name=WhateverGreen
  elif [ result == "CPUFriend" ]
  then
    name=CPUFriend
  elif [ result == "AppleALC" ]
  then
    name=AppleALC
  elif [ result == "VirtualSMC" ]
  then
    name=VirtualSMC
  fi
  echo "Compiling the latest commited Debug version of $result."
  xcodebuild -configuration Debug > /dev/null 2>&1 || exit 1
}

buildmactool() {
  local name=$(pwd)
  local result=${name##*/}
  if [ result == "OpenCorePkg" ]
  then
    name=OpenCorePkg
  elif [ result == "AptioFixPkg" ]
  then
    name=AptioFixPkg
  elif [ result == "AppleSupportPkg" ]
  then
    name=AppleSupportPkg
  elif [ result == "OpenCoreShell" ]
  then
    name=OpenCoreShell
  fi
  echo "Compiling the latest commited Release and Debug version of $result."
  ./macbuild.tool > /dev/null 2>&1 || exit 1
}

updaterepo() {
  if [ ! -d "$2" ]; then
    git clone "$1" -b "$3" --depth=1 "$2" || exit 1
  fi
  pushd "$2" >/dev/null
  echo "Updating Repo"
  git pull
  popd >/dev/null
}

repocheck() {
  local name=$(pwd)
  local result=${name##*/}
  if [ result == "Lilu" ]
  then
    name=Lilu
  elif [ result == "WhateverGree"n ]
  then
    name=WhateverGreen
  elif [ result == "CPUFriend" ]
  then
    name=CPUFriend
  elif [ result == "AppleALC" ]
  then
    name=AppleALC
  elif [ result == "VirtualSMC" ]
  then
    name=VirtualSMC
  fi
  localoutput="$(git log --pretty=%H ...refs/heads/master^ | head -n 1)"
  remoteoutput="$(git ls-remote origin -h refs/heads/master |cut -f1)"

  if [ "$localoutput" = "$remoteoutput" ] ; then
    local status=0
  else
    local status=1
  fi
  if [ $status = 0 ]; then
    echo "$result repo is up to date."
  elif [ $status = 1 ]; then
    echo "$result repo is not up to date."
    sleep 1
    echo "Updating Repo"
    git pull > /dev/null 2>&1 || exit 1
    builddebug 
    buildrelease
  fi
}

pkgcheck() {
  local name=$(pwd)
  local result=${name##*/}
  if [ result == "OpenCorePkg" ]
  then
    name=OpenCorePkg
  elif [ result == "AptioFixPkg" ]
  then
    name=AptioFixPkg
  elif [ result == "AppleSupportPkg" ]
  then
    name=AppleSupportPkg
  elif [ result == "OpenCoreShell" ]
  then
    name=OpenCoreShell
  fi
  localoutput="$(git log --pretty=%H ...refs/heads/master^ | head -n 1)"
  remoteoutput="$(git ls-remote origin -h refs/heads/master |cut -f1)"

  if [ "$localoutput" = "$remoteoutput" ] ; then
    local status=0
  else
    local status=1
  fi
  if [ $status = 0 ]; then
    echo "$result repo is up to date."
  elif [ $status = 1 ]; then
    echo "$result repo is not up to date."
    sleep 1
    echo "Updating Repo"
    git pull > /dev/null 2>&1 || exit 1
    buildmactool
  fi
}

repoClone() {
  echo "Cloning acidanthera's Repos."
  repos[0]=https://github.com/acidanthera/Lilu.git
  repos[1]=https://github.com/acidanthera/WhateverGreen.git
  repos[2]=https://github.com/acidanthera/AppleALC.git
  repos[3]=https://github.com/acidanthera/CPUFriend.git
  repos[4]=https://github.com/acidanthera/VirtualSMC.git
  repos[5]=https://github.com/acidanthera/OpenCorePkg.git
  repos[6]=https://github.com/acidanthera/AptioFixPkg.git
  repos[7]=https://github.com/acidanthera/AppleSupportPkg.git
  repos[8]=https://github.com/acidanthera/OpenCoreShell.git

  dir[0]="${BUILD_DIR}/Lilu"
  dir[1]="${BUILD_DIR}/WhateverGreen"
  dir[2]="${BUILD_DIR}/AppleALC"
  dir[3]="${BUILD_DIR}/CPUFriend"
  dir[4]="${BUILD_DIR}/VirtualSMC"

  pkg[0]="${BUILD_DIR}/OpenCorePkg"
  pkg[1]="${BUILD_DIR}/AptioFixPkg"
  pkg[2]="${BUILD_DIR}/AppleSupportPkg"
  pkg[3]="${BUILD_DIR}/OpenCoreShell"
  
  cd "${BUILD_DIR}/"
  for i in "${repos[@]}"; do 
    git clone $i > /dev/null 2>&1 || exit 1
  done 

  cd "${BUILD_DIR}/Lilu"
  builddebug 

  for x in "${dir[@]}"
  do
    cp -r "${BUILD_DIR}/Lilu/build/Debug/Lilu.kext" $x
    cd $x
    buildrelease
  done 

  for x in "${pkg[@]}"
  do
    cd $x
    buildmactool
  done 
}

makeDirectories() {
    if [ ! -d "${FINAL_DIR}/" ]; then
    echo "Creating Opencore EFI structure in ${FINAL_DIR}}."
    mkdir "${FINAL_DIR}/"
  else
    echo "Updating current CompletedBuilds folder."
    rm -rf "${FINAL_DIR}/"
    mkdir "${FINAL_DIR}/"
  fi
}

copyBuildProducts() {
  echo "Copying compiled products into EFI Structure folder in ${FINAL_DIR}."
  cp "${BUILD_DIR}"/OpenCorePkg/Binaries/RELEASE/OpenCore-*-RELEASE.zip "${FINAL_DIR}/" 
  cd "${FINAL_DIR}/"
  unzip *.zip > /dev/null 2>&1 || exit 1
  rm -rf *.zip
  cp -r "${BUILD_DIR}/Lilu/build/Release/Lilu.kext" "${FINAL_DIR}/EFI/OC/Kexts" 
  cp -r "${BUILD_DIR}/AppleALC/build/Release/AppleALC.kext" "${FINAL_DIR}/EFI/OC/Kexts" 
  cp -r "${BUILD_DIR}"/VirtualSMC/build/Release/*.kext "${FINAL_DIR}/EFI/OC/Kexts" 
  cp -r "${BUILD_DIR}/WhateverGreen/build/Release/WhateverGreen.kext" "${FINAL_DIR}/EFI/OC/Kexts" 
  cp -r "${BUILD_DIR}/CPUFriend/build/Release/CPUFriend.kext" "${FINAL_DIR}/EFI/OC/Kexts" 
  cp -r "${BUILD_DIR}/VirtualSMC/EfiDriver/VirtualSmc.efi" "${FINAL_DIR}/EFI/OC/Drivers" 
  cp -r "${BUILD_DIR}/AptioFixPkg/Binaries/RELEASE/AptioInputFix.efi" "${FINAL_DIR}/EFI/OC/Drivers" 
  cp -r "${BUILD_DIR}/AptioFixPkg/Binaries/RELEASE/AptioMemoryFix.efi" "${FINAL_DIR}/EFI/OC/Drivers" 
  cp -r "${BUILD_DIR}/AptioFixPkg/Binaries/RELEASE/CleanNvram.efi" "${FINAL_DIR}/EFI/OC/Tools" 
  cp -r "${BUILD_DIR}/AptioFixPkg/Binaries/RELEASE/VerifyMsrE2.efi" "${FINAL_DIR}/EFI/OC/Tools"
  cp -r "${BUILD_DIR}/OpenCoreShell/Binaries/RELEASE/Shell.efi" "${FINAL_DIR}/EFI/OC/Tools" 
  cp -r "${BUILD_DIR}"/AppleSupportPkg/Binaries/RELEASE/*.efi "${FINAL_DIR}/EFI/OC/Drivers" 
  echo "All Done!"
}

lilucheck() {
  cd "${BUILD_DIR}/Lilu"
  repocheck
  sleep 1
}

wegcheck() {
  cd "${BUILD_DIR}/WhateverGreen"
  repocheck
  sleep 1
}

alccheck() {
  cd "${BUILD_DIR}/AppleALC"
  repocheck
  sleep 1
}

cpucheck() {
  cd "${BUILD_DIR}/CPUFriend"
  repocheck
  sleep 1
}

smccheck() {
  cd "${BUILD_DIR}/VirtualSMC"
  repocheck
  sleep 1
}

occheck() {
  cd "${BUILD_DIR}/OpenCorePkg"
  pkgcheck
  sleep 1
}

aptiocheck() {
  cd "${BUILD_DIR}/AptioFixPkg"
  pkgcheck
  sleep 1
}

supportcheck() {
  cd "${BUILD_DIR}/AppleSupportPkg"
  pkgcheck
  sleep 1
}

shellcheck() {
  cd "${BUILD_DIR}/OpenCoreShell"
  pkgcheck
  sleep 1
}

liluclone() {
  local dir[0]="${BUILD_DIR}/Lilu"
  local dir[1]="${BUILD_DIR}/WhateverGreen"
  local dir[2]="${BUILD_DIR}/AppleALC"
  local dir[3]="${BUILD_DIR}/CPUFriend"
  local dir[4]="${BUILD_DIR}/VirtualSMC"

  cd "${BUILD_DIR}/"
  echo "Cloning Lilu repo."
  git clone https://github.com/acidanthera/Lilu.git > /dev/null 2>&1 || exit 1
  cd "${BUILD_DIR}/Lilu"
  builddebug
  buildrelease
  for x in "${dir[@]}"
  do
    cp -r "${BUILD_DIR}/Lilu/build/Debug/Lilu.kext" $x
    cd $x
  done
  sleep 1
}

wegclone() {
  cd "${BUILD_DIR}/"
  echo "Cloning WhateverGreen repo."
  git clone https://github.com/acidanthera/WhateverGreen.git > /dev/null 2>&1 || exit 1
  cp -r "${BUILD_DIR}/Lilu/build/Debug/Lilu.kext" "${BUILD_DIR}/WhateverGreen"
  cd "${BUILD_DIR}/WhateverGreen"
  buildrelease
  sleep 1
}

alcclone() {
  cd "${BUILD_DIR}/"
  echo "Cloning AppleALC repo."
  git clone https://github.com/acidanthera/AppleALC.git > /dev/null 2>&1 || exit 1
  cp -r "${BUILD_DIR}/Lilu/build/Debug/Lilu.kext" "${BUILD_DIR}/AppleALC"
  cd "${BUILD_DIR}/AppleALC"
  buildrelease
  sleep 1
}

cpuclone() {
  cd "${BUILD_DIR}/"
  echo "Cloning CPUFriend repo."
  git clone https://github.com/acidanthera/CPUFriend.git > /dev/null 2>&1 || exit 1
  cp -r "${BUILD_DIR}/Lilu/build/Debug/Lilu.kext" "${BUILD_DIR}/CPUFriend"
  cd "${BUILD_DIR}/CPUFriend"
  buildrelease
  sleep 1
}

smcclone() {
  cd "${BUILD_DIR}/"
  echo "Cloning VirtualSMC repo."
  git clone https://github.com/acidanthera/VirtualSMC.git > /dev/null 2>&1 || exit 1
  cp -r "${BUILD_DIR}/Lilu/build/Debug/Lilu.kext" "${BUILD_DIR}/VirtualSMC"
  cd "${BUILD_DIR}/VirtualSMC"
  buildrelease
  sleep 1
}

occlone() {
  cd "${BUILD_DIR}/"
  echo "Cloning OpenCore repo."
  git clone https://github.com/acidanthera/OpenCorePkg.gitt > /dev/null 2>&1 || exit 1
  cd "${BUILD_DIR}/OpenCorePkg"
  buildmactool
  sleep 1
}

aptioclone() {
  cd "${BUILD_DIR}/"
  echo "Cloning AptioFix repo."
  git clone https://github.com/acidanthera/AptioFixPkg.git > /dev/null 2>&1 || exit 1
  cd "${BUILD_DIR}/AptioFixPkg"
  buildmactool
  sleep 1
}

supportclone() {
  cd "${BUILD_DIR}/"
  echo "Cloning AppleSupport repo."
  git clone https://github.com/acidanthera/AppleSupportPkg.git > /dev/null 2>&1 || exit 1
  cd "${BUILD_DIR}/AppleSupportPkg"
  buildmactool
  sleep 1
}

shellclone() {
  cd "${BUILD_DIR}/"
  echo "Cloning OpenCoreShell repo."
  git clone https://github.com/acidanthera/OpenCoreShell.git > /dev/null 2>&1 || exit 1
  cd "${BUILD_DIR}/OpenCoreShell"
  buildmactool
  sleep 1
}

buildfoldercheck() {
  if [ ! -d "${FINAL_DIR}/" ]; then
    echo "Missing ${FINAL_DIR} folder."
    makeDirectories
    copyBuildProducts
  else
    echo "Updating Packages."
    makeDirectories
    copyBuildProducts
  fi
}

if [ -d "${BUILD_DIR}/" ]; then
  echo "Acidanthera's Repos already exist."
  if [ ! -d "${BUILD_DIR}/Lilu" ]; then
    echo "Missing Lilu repo folder."
    liluclone
  else
    echo "Lilu repo exist, checking for updates."
    lilucheck
  fi

  if [ ! -d "${BUILD_DIR}/WhateverGreen" ]; then
    echo "Missing WhateverGreen repo folder."
    wegclone
  else
    echo "WhateverGreen repo exist, checking for updates."
    cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/WhateverGreen
    wegcheck
  fi

  if [ ! -d "${BUILD_DIR}/AppleALC" ]; then
    echo "Missing AppleALC repo folder."
    alcclone
  else
    echo "AppleALC repo exist, checking for updates."
    cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/AppleALC
    alccheck
  fi
  
  if [ ! -d "${BUILD_DIR}/CPUFriend" ]; then
    echo "Missing CPUFriend repo folder."
    cpuclone
  else
    echo "CPUFriend repo exist, checking for updates."
    cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/CPUFriend
    cpucheck
  fi

  if [ ! -d "${BUILD_DIR}/VirtualSMC" ]; then
    echo "Missing VirtualSMC repo folder."
    smcclone
  else
    echo "VirtualSMC repo exist, checking for updates."
    cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/VirtualSMC
    smccheck
  fi

  if [ ! -d "${BUILD_DIR}/OpenCorePkg" ]; then
    echo "Missing OpenCorePkg repo folder."
    occlone
  else
    echo "OpenCorePkg repo exist, checking for updates."
    occheck
  fi

  if [ ! -d "${BUILD_DIR}/AptioFixPkg" ]; then
    echo "Missing AptioFixPkg repo folder."
    aptioclone
  else
    echo "AptioFixPkg repo exist, checking for updates."
    aptiocheck
  fi

  if [ ! -d "${BUILD_DIR}/AppleSupportPkg" ]; then
    echo "Missing AppleSupportPkg repo folder."
    supportclone
  else
    echo "AppleSupportPkg repo exist, checking for updates."
    supportcheck
  fi

  if [ ! -d "${BUILD_DIR}/OpenCoreShell" ]; then
    echo "Missing OpenCoreShell repo folder."
    shellclone
  else
    echo "OpenCoreShell repo exist, checking for updates."
    shellcheck
  fi

  buildfoldercheck
else
  mkdir "${BUILD_DIR}/"
  cd "${BUILD_DIR}/"
  repoClone
  makeDirectories
  copyBuildProducts
fi
