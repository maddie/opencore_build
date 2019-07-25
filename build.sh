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

  dir[0]=~/Downloads/OpenCore_Build/Lilu
  dir[1]=~/Downloads/OpenCore_Build/WhateverGreen
  dir[2]=~/Downloads/OpenCore_Build/AppleALC
  dir[3]=~/Downloads/OpenCore_Build/CPUFriend
  dir[4]=~/Downloads/OpenCore_Build/VirtualSMC

  pkg[0]=~/Downloads/OpenCore_Build/OpenCorePkg
  pkg[1]=~/Downloads/OpenCore_Build/AptioFixPkg
  pkg[2]=~/Downloads/OpenCore_Build/AppleSupportPkg
  pkg[3]=~/Downloads/OpenCore_Build/OpenCoreShell
  
  cd ~/Downloads/OpenCore_Build
  for i in "${repos[@]}"; do 
    git clone $i > /dev/null 2>&1 || exit 1
  done 

  cd ~/Downloads/OpenCore_Build/Lilu
  builddebug 

  for x in "${dir[@]}"
  do
    cp -r ~/Downloads/OpenCore_Build/Lilu/build/Debug/Lilu.kext $x
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
  echo "Copying compiled products into EFI Structure folder on your desktop."
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
  cp -r ~/Downloads/OpenCore_Build/OpenCoreShell/Binaries/RELEASE/Shell.efi ~/Desktop/CompletedBuilds/EFI/OC/Tools 
  cp -r ~/Downloads/OpenCore_Build/AppleSupportPkg/Binaries/RELEASE/*.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers 
  echo "All Done!"
}

lilucheck() {
  local REPO=Lilu
  cd ~/Downloads/OpenCore_Build/Lilu
  repocheck
  sleep 1
}

wegcheck() {
  local REPO=WhateverGreen
  cd ~/Downloads/OpenCore_Build/WhateverGreen
  repocheck
  sleep 1
}

alccheck() {
  local REPO=AppleALC
  cd ~/Downloads/OpenCore_Build/AppleALC
  repocheck
  sleep 1
}

cpucheck() {
  local REPO=CPUFriend
  cd ~/Downloads/OpenCore_Build/CPUFriend
  repocheck
  sleep 1
}

smccheck() {
  local REPO=VirtualSMC
  cd ~/Downloads/OpenCore_Build/VirtualSMC
  repocheck
  sleep 1
}

occheck() {
  local REPO=OpenCorePkg
  cd ~/Downloads/OpenCore_Build/OpenCorePkg
  pkgcheck
  sleep 1
}

aptiocheck() {
  local REPO=AptioFixPkg
  cd ~/Downloads/OpenCore_Build/AptioFixPkg
  pkgcheck
  sleep 1
}

supportcheck() {
  local REPO=AppleSupportPkg
  cd ~/Downloads/OpenCore_Build/AppleSupportPkg
  pkgcheck
  sleep 1
}

shellcheck() {
  local REPO=OpenCoreShell
  cd ~/Downloads/OpenCore_Build/OpenCoreShell
  pkgcheck
  sleep 1
}

if [ -d ~/Downloads/OpenCore_Build ]; then
  echo "Acidanthera's Repos already exist."
  echo "Checking if there is any updates to the repos."
  lilucheck
  wegcheck
  alccheck
  cpucheck
  smccheck
  occheck
  aptiocheck
  supportcheck
  shellcheck
  if [ ! -d ~/Desktop/CompletedBuilds ]; then
    echo "Missing CompletedBuilds folder on your desktop."
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