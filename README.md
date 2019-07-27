# opencore_build
Bash script to compile Opencore from source.

This script will git clone from the following sources:
- https://github.com/acidanthera/Lilu.git
- https://github.com/acidanthera/WhateverGreen.git
- https://github.com/acidanthera/AppleALC.git
- https://github.com/acidanthera/VirtualSMC.git
- https://github.com/acidanthera/OpenCorePkg.git
- https://github.com/acidanthera/AptioFixPkg.git
- https://github.com/acidanthera/AppleSupportPkg.git

This build script will check to see if you have all the required tools installed in order to compile these sources. If the required tools are not installed, it will prompt you to install them. Then it will compile the latest commits to the sources using xcodebuild, nasm, and mtoc. Once compile is complete a CompletedBuilds folder with the Opencore EFI structure will be produced with all the Drivers, kexts and tools will be placed in the CompletedBuilds folder on your Desktop. You may not need all of them, so make sure you remove any Drivers or Kext you do not need. "They are examples only. You have been WARNED!!!!" 
