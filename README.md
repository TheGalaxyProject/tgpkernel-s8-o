# TGPKernel S8

![TGPKernel Logo](https://github.com/TheGalaxyProject/tgpkernel-s8/blob/tw70/build/logo.png?raw=true)

A Custom Kernel for Samsung Galaxy S8 / S8+

The main purpose of this Kernel is to have a stock-like Kernel that runs on S8 and S8E
variants, but capable of running S8E and S8 Port Firmwares.

* XDA Unified S8 / S8+ Forum: http://forum.xda-developers.com/showthread.php?t=3654423
* Grifo Development Forum: https://forum.grifodev.ch/thread/96


Compiled using my own built custom toolchain

* URL: https://github.com/djb77/aarch64-cortex_a53-linux-gnueabi

## How to use
Adjust the toolchain path in build.sh and Makefile to match the path on your system. 

Run build.sh and follow the prompts, alternatively you can use a command line:

-	./build.sh 0  will perform Clean Workspace
-	./build.sh 00 will perform Clean CCACHE
-	./build.sh 1  will perform Build TGPKernel boot.img for S8
-	./build.sh 2  will perform Build TGPKernel boot.img for S8+
-	./build.sh 3  will perform Build TGPKernel boot.img for S8 + S8+
-	./build.sh 4  will perform Build TGPKernel boot.img and .zip for S8
-	./build.sh 5  will perform Build TGPKernel boot.img and .zip for S8+
-	./build.sh 6  will perform Build TGPKernel boot.img and .zip for S8 + S8+ (Seperate)
-	./build.sh 7  will perform Build TGPKernel boot.img and .zip for S8 + S8+ (All-In-One)

When finished, the new .img and / or .zip file will be created in the output directory.

If Java is installed, the .zip files will be automatically signed.


## Credit and Thanks to the following:
- Samsung Open Source Release Center for the Source code (http://opensource.samsung.com)
- The Linux Kernel Archive for the Linux Patches (https://www.kernel.org)
- @Tkkg1994 for all his help and numerous code samples from his source
- @osm0sis for Android Image Kitchen
- @Chainfire for the Deep Sleep Fix from SuperSU
- @morogoku for MTweaks and lots of help and commits
- @farovitus for lots of help and Spectrum Profiles
- @arter97, @lyapota, @kylothow and others for their commits

