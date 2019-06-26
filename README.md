# opencore_build
Bash script to build Opencore from source.

# Required tools installed before running this script
- xcode commandline tools
- nasm
- mtoc
- python 3

This script will git clone from the following sources:
https://github.com/acidanthera/Lilu.git
https://github.com/acidanthera/WhateverGreen.git
https://github.com/acidanthera/AppleALC.git
https://github.com/acidanthera/VirtualSMC.git
https://github.com/acidanthera/OpenCorePkg.git
https://github.com/acidanthera/AptioFixPkg.git
https://github.com/acidanthera/AppleSupportPkg.git

It will build the sources using xcodebuild, nasm, mtoc and python 3. Once build is complete a CompletedBuilds folder with the Opencore EFI structure will be produced with all the Drivers, kexts and example config.plist and ACPI SSDT examples will be placed in their respective folders. You may not need all of them, so make sure you remove any Driver, Kext and ACPI SSDT example you do not need. "They are examples only. You have been WARNED!!!!" 
