# opencore_build
Bash script to compile Opencore, common drivers and kexts that are used with OpenCore from source.

## This script will git clone from the following sources:
- [Lilu](https://github.com/acidanthera/Lilu.git)
- [WhateverGreen](https://github.com/acidanthera/WhateverGreen.git)
- [AppleALC](https://github.com/acidanthera/AppleALC.git)
- [VirtualSMC](https://github.com/acidanthera/VirtualSMC.git)
- [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg.git)
- [AptioFixPkg](https://github.com/acidanthera/AptioFixPkg.git)
- [AppleSupportPkg](https://github.com/acidanthera/AppleSupportPkg.git)
- [OpenCoreShell](https://github.com/acidanthera/OpenCoreShell.git)

This build script will check to see if you have all the required tools installed in order to compile these sources. If the required tools are not installed, it will prompt you to install them. Then it will compile the latest commits to the sources using xcodebuild, nasm, and mtoc. Once compile is complete a CompletedBuilds folder with the Opencore EFI structure will be produced with all the Drivers, kexts and tools will be placed in the CompletedBuilds folder on your Desktop. You may not need all of them, so make sure you remove any Drivers or Kext you do not need. "They are examples only. You have been WARNED!!!!" 

## This script will create the following folder structure on your Desktop:
```
|--CompletedBuilds
|   |--Docs
|   |   |--AcpiSamples
|   |   |   |--SSDT-AWAC.dsl
|   |   |   |--SSDT-EC-USBX.dsl
|   |   |   |--SSDT-EC.dsl
|   |   |   |--SSDT-EHCx_OFF.dsl
|   |   |   |--SSDT-PLUG.dsl
|   |   |   |--SSDT-SBUS-MCHC.dsl
|   |   |--Changelog.md
|   |   |--Configuration.pdf
|   |   |--Differences.pdf
|   |   |--Sample.plist
|   |   |--SampleFull.plist
|   |--EFI
|   |   |--BOOT
|   |   |   |--BOOTx64.efi
|   |   |--OC
|   |   |   |--ACPI
|   |   |   |--Drivers
|   |   |   |   |--ApfsDriverLoader.efi
|   |   |   |   |--AppleGenericInput.efi
|   |   |   |   |--AppleUiSupport.efi
|   |   |   |   |--AptioMemoryFix.efi
|   |   |   |   |--UsbKbDxe.efi
|   |   |   |   |--VBoxHfs.efi
|   |   |   |   |--VirtualSmc.efi
|   |   |   |--Kexts
|   |   |   |   |--AppleALC.kext
|   |   |   |   |--CPUFriend.kext
|   |   |   |   |--Lilu.kext
|   |   |   |   |--SMCBatteryManager.kext
|   |   |   |   |--SMCLightSensor.kext
|   |   |   |   |--SMCProcessor.kext
|   |   |   |   |--SMCSuperIO.kext
|   |   |   |   |--VirtualSMC.kext
|   |   |   |   |--WhateverGreen.kext
|   |   |   |--OpenCore.efi
|   |   |   |--Tools
|   |   |   |   |--CleanNvram.efi
|   |   |   |   |--Shell.efi
|   |   |   |   |--VerifyMsrE2.efi
|   |--Utilities
|   |   |--BootInstall
|   |   |   |--boot
|   |   |   |--boot0af
|   |   |   |--boot1f32
|   |   |   |--BootInstall.command
|   |   |   |--README.md
|   |   |--CreateVault
|   |   |   |--create_vault.sh
|   |   |   |--RsaTool
|   |   |   |--sign.command
|   |   |--LogoutHook
|   |   |   |--LogoutHook.command
|   |   |   |--nvram.mojave
|   |   |   |--README.md
|   |   |--Recovery
|   |   |   |--obtain_recovery.php
|   |   |   |--recovery_urls.txt
```
