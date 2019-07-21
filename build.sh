#!/bin/bash

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
  sudo mkdir -p /usr//bin || exit 1
  sudo mv nasm*/nasm /usr//bin/ || exit 1
  sudo mv nasm*/ndisasm /usr//bin/ || exit 1
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
  sudo mkdir -p /usr//bin || exit 1
  sudo cp mtoc /usr//bin/mtoc || exit 1
  sudo mv mtoc /usr//bin/mtoc.NEW || exit 1
  popd >/dev/null
fi

updaterepo() {
  if [ ! -d "$2" ]; then
    git clone "$1" -b "$3" --depth=1 "$2" || exit 1
  fi
  pushd "$2" >/dev/null
  git pull
  popd >/dev/null
}

repocheck() {
  local repos[0]=~/Downloads/OpenCore_Build/Lilu
  local repos[1]=~/Downloads/OpenCore_Build/WhateverGreen
  local repos[2]=~/Downloads/OpenCore_Build/AppleALC
  local repos[3]=~/Downloads/OpenCore_Build/CPUFriend
  local repos[4]=~/Downloads/OpenCore_Build/VirtualSMC
  local repos[5]=~/Downloads/OpenCore_Build/OpenCorePkg
  local repos[6]=~/Downloads/OpenCore_Build/AptioFixPkg
  local repos[7]=~/Downloads/OpenCore_Build/AppleSupportPkg

  local name[0]=Lilu
  local name[1]=WhateverGreen
  local name[2]=AppleALC
  local name[3]=CPUFriend
  local name[4]=VirtualSMC
  local name[5]=OpenCorePkg
  local name[6]=AptioFixPkg
  local name[7]=AppleSupportPkg

  for i in "${repos[@]}"; 
  do
    cd $i
    if [ -z "$(git status --porcelain)" ]; then
      status=0
    else 
      status=1
    fi
  done
  for x in "${name[@]}"; do
    if [ $status = 0 ]; then
      echo "$x repo is up to date."
    elif [ $status = 1 ]; then
      echo "$x repo is not up to date."
      sleep 1
      updaterepo &>/dev/null || exit 1
    fi
  done
}

repoClone() {
  echo "Cloning acidanthera's Repos."
  sleep 1
  repos[0]=https://github.com/acidanthera/Lilu.git
  repos[1]=https://github.com/acidanthera/WhateverGreen.git
  repos[2]=https://github.com/acidanthera/AppleALC.git
  repos[3]=https://github.com/acidanthera/CPUFriend.git
  repos[4]=https://github.com/acidanthera/VirtualSMC.git
  repos[5]=https://github.com/acidanthera/OpenCorePkg.git
  repos[6]=https://github.com/acidanthera/AptioFixPkg.git
  repos[7]=https://github.com/acidanthera/AppleSupportPkg.git

  cd ~/Downloads/OpenCore_Build
  for i in "${repos[@]}"; do git clone $i; done > /dev/null 2>&1 || exit 1
}

buildPackages() {
  cd ~/Downloads/OpenCore_Build/Lilu
  echo "Building latest committed Debug version of Lilu."
  xcodebuild -configuration Debug > /dev/null 2>&1 || exit 1
  echo "Building latest committed Release version of Lilu."
  xcodebuild -configuration Release > /dev/null 2>&1 || exit 1
  cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/AppleALC  || exit 1
  cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/VirtualSMC || exit 1
  cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/WhateverGreen || exit 1
  cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext ~/Downloads/OpenCore_Build/CPUFriend || exit 1
  cd ~/Downloads/OpenCore_Build/AppleALC
  echo "Building latest committed Release version of AppleALC."
  xcodebuild -configuration Release > /dev/null 2>&1 || exit 1
  cd ~/Downloads/OpenCore_Build/VirtualSMC
  echo "Building latest committed Release version of VirtualSMC."
  xcodebuild -configuration Release > /dev/null 2>&1 || exit 1
  cd ~/Downloads/OpenCore_Build/WhateverGreen
  echo "Building latest committed Release version of WhateverGreen."
  xcodebuild -configuration Release > /dev/null 2>&1 || exit 1
  cd ~/Downloads/OpenCore_Build/CPUFriend
  echo "Building latest committed Release version of CPUFriend."
  xcodebuild -configuration Release > /dev/null 2>&1 || exit 1
  cd ~/Downloads/OpenCore_Build/OpenCorePkg
  echo "Building latest committed Release version of Opencore."
  ./macbuild.tool > /dev/null 2>&1 || exit 1
  cd ~/Downloads/OpenCore_Build/AptioFixPkg
  echo "Building latest committed Release version of AptioFixPkg."
  ./macbuild.tool > /dev/null 2>&1 || exit 1
  cd ~/Downloads/OpenCore_Build/AppleSupportPkg
  echo "Building latest committed Release version of AppleSupportPkg."
  ./macbuild.tool > /dev/null 2>&1 || exit 1
}

makeDirectories() {
    if [ ! -d ~/Desktop/CompletedBuilds ]; then
    echo "Creating Opencore EFI structure on your desktop."
    mkdir ~/Desktop/CompletedBuilds
  else
    echo "Updating current CompletedBuilds folder on your desktop."
    rm -rf ~/Desktop/CompletedBuilds
    mkdir ~/Desktop/CompletedBuilds
  fi
}

copyBuildProducts() {
  echo "Copying Built Products into EFI Structure folder on your desktop."
  cp ~/Downloads/OpenCore_Build/OpenCorePkg/Binaries/RELEASE/OpenCore-*-RELEASE.zip ~/Desktop/CompletedBuilds/ 
  cd ~/Desktop/CompletedBuilds
  unzip *.zip > /dev/null 2>&1 || exit 1
  rm -rf *.zip
  cp -r ~/Downloads/OpenCore_Build/Lilu/build/Release/Lilu.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts 
  cp -r ~/Downloads/OpenCore_Build/AppleALC/build/Release/AppleALC.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts 
  cp -r ~/Downloads/OpenCore_Build/VirtualSMC/build/Release/package/Kexts/*.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts 
  cp -r ~/Downloads/OpenCore_Build/WhateverGreen/build/Release/WhateverGreen.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts 
  cp -r ~/Downloads/OpenCore_Build/CPUFriend/build/Release/CPUFriend.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts 
  cp -r ~/Downloads/OpenCore_Build/VirtualSMC/build/Release/package/Drivers/VirtualSmc.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers 
  cp -r ~/Downloads/OpenCore_Build/AptioFixPkg/Binaries/RELEASE/AptioInputFix.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers 
  cp -r ~/Downloads/OpenCore_Build/AptioFixPkg/Binaries/RELEASE/AptioMemoryFix.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers 
  cp -r ~/Downloads/OpenCore_Build/AptioFixPkg/Binaries/RELEASE/CleanNvram.efi ~/Desktop/CompletedBuilds/EFI/OC/Tools 
  cp -r ~/Downloads/OpenCore_Build/AptioFixPkg/Binaries/RELEASE/VerifyMsrE2.efi ~/Desktop/CompletedBuilds/EFI/OC/Tools 
  cp -r ~/Downloads/OpenCore_Build/AppleSupportPkg/Binaries/RELEASE/*.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers 
  echo "All Done!"
}

if [ -d ~/Downloads/OpenCore_Build ]; then
  echo "Repo already exist."
  echo "Checking if there is any updates to repos."
  repocheck
  sleep 1
    if [ $status = 1 ]; then
      echo "Building Updated Packages."
      buildPackages
      makeDirectories
      copyBuildProducts
    elif [ ! -d ~/Desktop/CompletedBuilds ]; then
      echo "Missing CompletedBuilds on your desktop."
      makeDirectories
      copyBuildProducts
    else
      echo "You are already up-to-date. No need to rebuild packages."
      echo "All Done!"
    fi
else
  mkdir ~/Downloads/OpenCore_Build
  cd ~/Downloads/OpenCore_Build
  repoClone
  buildPackages
  makeDirectories
  copyBuildProducts
fi