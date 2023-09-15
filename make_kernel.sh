#!/bin/bash


## get kernel

kernel_url=`curl -s https://www.kernel.org/ | grep -Eo 'https://[^ >]+.tar.xz' | head -n 1`
kernel_file=`basename $kernel_url`

echo "File found: "$kernel_file
echo "Kernel URL: "$kernel_url
curl -s "$kernel_url" -o $HOME/Documents/$kernel_file
if [ -f "$HOME/Documents/$kernel_file" ]; then
  echo "Kernel properly downloaded"
  step="1"
else
  echo "Kernel missing... error"
  exit 0
fi

## unpack kernel
tar -xf "$HOME/Documents/$kernel_file"

## removing kernel (compressed file)
rm "$HOME/Documents/$kernel_file"

## checking kernel folder
kernel_folder=`echo $kernel_file | sed 's/.tar.xz//'`
echo "Kernel folder: "$kernel_folder

## let's start
cd "$kernel_folder"
cp -v /boot/config-$(uname -r) .config
# don't know why
scripts/config --disable DEBUG_INFO
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
scripts/config --undefine GDB_SCRIPTS
scripts/config --undefine DEBUG_INFO_SPLIT
scripts/config --undefine DEBUG_INFO_REDUCED
scripts/config --undefine DEBUG_INFO_COMPRESSED
scripts/config --set-val  DEBUG_INFO_NONE       y
scripts/config --set-val  DEBUG_INFO_DWARF5     n
scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT

## Patching
patch -p1 < ~/Documents/GitHub/Kernel_VM/patch/acso.patch
#cp "$HOME/Documents/GitHub/Kernel_VM/patch/svm.c" arch/x86/kvm/svm/svm.c
#cp "$HOME/Documents/GitHub/Kernel_VM/patch/vmx.c" arch/x86/kvm/vmx/vmx.c
#patch arch/x86/kvm/svm/svm.c < ~/Documents/GitHub/Kernel_VM/patch/svm.patch
#patch arch/x86/kvm/vmx/vmx.c < ~/Documents/GitHub/Kernel_VM/patch/vmx.patch

## compile
#make olddefconfig
fakeroot make olddefconfig INSTALL_MOD_STRIP=1 -j $(getconf _NPROCESSORS_ONLN) bindeb-pkg LOCALVERSION=-scoony KDEB_PKGVERSION=$(make kernelversion)-1
