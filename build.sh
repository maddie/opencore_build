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

buildrelease() {
  xcodebuild -configuration Release > /dev/null 2>&1 || exit 1
}

builddebug() {
  xcodebuild -configuration Debug > /dev/null 2>&1 || exit 1
}

buildmactool() {
  ./macbuild.tool > /dev/null 2>&1 || exit 1
}

updaterepo() {
  if [ ! -d "$2" ]; then
    git clone "$1" -b "$3" --depth=1 "$2" || exit 1
  fi
  pushd "$2" >/dev/null
  git pull
  popd >/dev/null
}

repocheck() {
  if [ "`git log --pretty=%H ...refs/heads/master^ | head -n 1`" = "`git ls-remote origin -h refs/heads/master |cut -f1`" ] ; then
    status=0
  else
    status=1
  fi
  if [ $status = 0 ]; then
    echo "$REPO repo is up to date."
  elif [ $status = 1 ]; then
    echo "$REPO repo is not up to date."
    sleep 1
    git pull &>/dev/null || exit 1
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

  dir[0]=~/Downloads/OpenCore_Build/Lilu
  dir[1]=~/Downloads/OpenCore_Build/WhateverGreen
  dir[2]=~/Downloads/OpenCore_Build/AppleALC
  dir[3]=~/Downloads/OpenCore_Build/CPUFriend
  dir[4]=~/Downloads/OpenCore_Build/VirtualSMC

  pkg[0]=~/Downloads/OpenCore_Build/OpenCorePkg
  pkg[1]=~/Downloads/OpenCore_Build/AptioFixPkg
  pkg[2]=~/Downloads/OpenCore_Build/AppleSupportPkg

  cd ~/Downloads/OpenCore_Build
  for i in "${repos[@]}"; do 
    git clone $i > /dev/null 2>&1 || exit 1
  done 

  cd ~/Downloads/OpenCore_Build/Lilu
  echo "Building latest commited Debug version of Lilu"
  builddebug 

  for x in "${dir[@]}"; do
    cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext $x
    cd $x
    echo "Building latest commited Release version of $x"
    buildrelease
  done 

  for x in "${pkg[@]}"; do
    cd $x
    echo "Building latest commited Release version of $x"
    buildmactool
  done 
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

lilucheck() {
  local REPO=Lilu
  cd ~/Downloads/OpenCore_Build/Lilu
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    builddebug
    buildrelease
  fi
}

wegcheck() {
  local REPO=WhateverGreen
  cd ~/Downloads/OpenCore_Build/WhateverGreen
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    buildrelease
  fi
}

alccheck() {
  local REPO=AppleALC
  cd ~/Downloads/OpenCore_Build/AppleALC
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    buildrelease
  fi
}

cpucheck() {
  local REPO=CPUFriend
  cd ~/Downloads/OpenCore_Build/CPUFriend
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    buildrelease
  fi
}

smccheck() {
  local REPO=VirtualSMC
  cd ~/Downloads/OpenCore_Build/VirtualSMC
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    buildrelease
  fi
}

occheck() {
  local REPO=OpenCorePkg
  cd ~/Downloads/OpenCore_Build/OpenCorePkg
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    buildmactool
  fi
}

aptiocheck() {
  local REPO=AptioFixPkg
  cd ~/Downloads/OpenCore_Build/AptioFixPkg
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    buildmactool
  fi
}

supportcheck() {
  local REPO=AppleSupportPkg
  cd ~/Downloads/OpenCore_Build/AppleSupportPkg
  repocheck
  sleep 1
  if [ $status = 1 ]; then
    updaterepo $REPO master
    sleep 1
    buildmactool
  fi
}

if [ -d ~/Downloads/OpenCore_Build ]; then
  echo "Repo already exist."
  echo "Checking if there is any updates to repos."
  lilucheck
  wegcheck
  alccheck
  cpucheck
  smccheck
  occheck
  aptiocheck
  supportcheck
  if [ ! -d ~/Desktop/CompletedBuilds ]; then
    echo "Missing CompletedBuilds on your desktop."
    makeDirectories
    copyBuildProducts
  else
    echo "Updating Packages."
    makeDirectories
    copyBuildProducts
  fi
else
  mkdir ~/Downloads/OpenCore_Build
  cd ~/Downloads/OpenCore_Build
  repoClone
  makeDirectories
  copyBuildProducts
fi