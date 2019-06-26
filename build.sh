#!/bin/bash

prompt() {
  echo "$1"
  if [ "$FORCE_INSTALL" != "1" ]; then
    read -p "Enter [Y]es to continue: " v
    if [ "$v" != "Y" ] && [ "$v" != "y" ]; then
      exit 1
    fi
  fi
}

if [ "$(which clang)" = "" ] || [ "$(which git)" = "" ] || [ "$(clang -v 2>&1 | grep "no developer")" != "" ] || [ "$(git -v 2>&1 | grep "no developer")" != "" ]; then
  echo "Missing Xcode tools, please install them!"
  exit 1
fi

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

cd /tmp
mkdir BuildingAllTheShit
cd BuildingAllTheShit
echo "Cloning Vit9696's Repos."
git clone https://github.com/acidanthera/Lilu.git > /dev/null 2>&1
git clone https://github.com/acidanthera/WhateverGreen.git > /dev/null 2>&1
git clone https://github.com/acidanthera/AppleALC.git > /dev/null 2>&1
git clone https://github.com/acidanthera/VirtualSMC.git > /dev/null 2>&1
git clone https://github.com/acidanthera/OpenCorePkg.git > /dev/null 2>&1
git clone https://github.com/acidanthera/AptioFixPkg.git > /dev/null 2>&1
git clone https://github.com/acidanthera/AppleSupportPkg.git > /dev/null 2>&1
cd Lilu
echo "Building Debug version of Lilu."
xcodebuild -configuration Debug > /dev/null 2>&1
echo "Building Release version of Lilu."
xcodebuild -configuration Release > /dev/null 2>&1
cd /tmp/BuildingAllTheShit
echo "Copying Debug version of Lilu into AppleALC, VirutalSMC and WhateverGreen repos!"
cp -r Lilu/build/Debug/Lilu.kext AppleALC/ 
cp -r Lilu/build/Debug/Lilu.kext VirtualSMC/
cp -r Lilu/build/Debug/Lilu.kext WhateverGreen/
cd AppleALC
echo "Building Release version of AppleALC."
xcodebuild -configuration Release > /dev/null 2>&1
cd /tmp/BuildingAllTheShit
cd VirtualSMC
echo "Building Release version of VirtualSMC."
xcodebuild -configuration Release > /dev/null 2>&1
cd /tmp/BuildingAllTheShit
cd WhateverGreen
echo "Building Release version of WhateverGreen."
xcodebuild -configuration Release > /dev/null 2>&1
cd /tmp/BuildingAllTheShit
cd OpenCorePkg
echo "Building latest build of Opencore."
./macbuild.tool > /dev/null 2>&1
cd /tmp/BuildingAllTheShit
cd AptioFixPkg
echo "Building latest build of AptioFixPkg."
./macbuild.tool > /dev/null 2>&1
cd /tmp/BuildingAllTheShit
cd AppleSupportPkg
echo "Building latest build of AppleSupportPkg."
./macbuild.tool > /dev/null 2>&1
cd /tmp/BuildingAllTheShit
echo "Creating Opencore EFI structure."
mkdir ~/Desktop/CompletedBuilds
mkdir ~/Desktop/CompletedBuilds/EFI
mkdir ~/Desktop/CompletedBuilds/EFI/BOOT
mkdir ~/Desktop/CompletedBuilds/EFI/OC
mkdir ~/Desktop/CompletedBuilds/EFI/OC/ACPI
mkdir ~/Desktop/CompletedBuilds/EFI/OC/Drivers
mkdir ~/Desktop/CompletedBuilds/EFI/OC/Kexts
mkdir ~/Desktop/CompletedBuilds/EFI/OC/Tools
mkdir ~/Desktop/CompletedBuilds/Documents
cp -r /tmp/BuildingAllTheShit/Lilu/build/Release/Lilu.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/AppleALC/build/Release/AppleALC.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/VirtualSMC/build/Release/package/Kexts/*.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/WhateverGreen/build/Release/WhateverGreen.kext ~/Desktop/CompletedBuilds/EFI/OC/Kexts > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/VirtualSMC/build/Release/package/Drivers/VirtualSmc.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/AptioFixPkg/Binaries/RELEASE/AptioInputFix.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/AptioFixPkg/Binaries/RELEASE/AptioMemoryFix.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/AptioFixPkg/Binaries/RELEASE/CleanNvram.efi ~/Desktop/CompletedBuilds/EFI/OC/Tools > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/AptioFixPkg/Binaries/RELEASE/VerifyMsrE2.efi ~/Desktop/CompletedBuilds/EFI/OC/Tools > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/AppleSupportPkg/Binaries/RELEASE/*.efi ~/Desktop/CompletedBuilds/EFI/OC/Drivers > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/OpenCorePkg/Binaries/RELEASE/OpenCore.efi ~/Desktop/CompletedBuilds/EFI/OC > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/OpenCorePkg/Binaries/RELEASE/BOOTx64.efi ~/Desktop/CompletedBuilds/EFI/BOOT > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/OpenCorePkg/Docs/Configuration.pdf ~/Desktop/CompletedBuilds/Documents > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/OpenCorePkg/Docs/SampleFull.plist ~/Desktop/CompletedBuilds/EFI/OC/Sample_config.plist > /dev/null 2>&1
cp -r /tmp/BuildingAllTheShit/OpenCorePkg/Docs/AcpiSamples/*.dsl ~/Desktop/CompletedBuilds/EFI/OC/ACPI > /dev/null 2>&1
echo "Cleaning Up"
rm -rf /tmp/BuildingAllTheShit > /dev/null 2>&1
echo "All Done!"