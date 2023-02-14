#!/bin/bash

BASEFOLDER="/home/gmarselis/VirtualBox VMs"
VMNAME="Fedora 37-1-test"
OSTYPE="Fedora_64"
CPUS=2
MEMORY=16384
VRAM=256
DATE="$(date --iso)"
FILENAME="${BASEFOLDER}/media/${VMNAME}-$date.vdi"
DISKSIZE=120000
HOSTPATH='/home/gmarselis/Downloads'
MEDIUM="$HOSTPATH/Fedora-Server-dvd-x86_64-37-1.7.iso"
AUTO_MOUNT_POINT="/mnt/downloads"
PARAVIRT_PROVIDER="kvm" # if set to default, under linux will still be set to KVM
CPU_HOTPLUG="off"
BRIDGEADAPTER1="$(ifconfig | awk -F: '/^en/ { print $1 }')"
ADDITIONS_ISO="/home/gmarselis/Downloads/VBoxGuestAdditions_7.0.6.iso"
HOSTNAME="molly-test-1-$date"
MACADDRESS="080027C48B18"
FQDN="$HOSTNAME.marsel.is"
SHUTDOWNTIMEOUT="5"


# Delete the registered VM
/usr/bin/VBoxManage unregistervm "${VMNAME}" --delete 2> /dev/null
# Delete the created VDI
vboxmanage closemedium disk "${FILENAME}" --delete 2> /dev/null

# Register VM
/usr/bin/VBoxManage createvm --name="${VMNAME}" --ostype="${OSTYPE}" --register --basefolder="${BASEFOLDER}" \
	&& echo "/usr/bin/VBoxManage createvm --name=\"${VMNAME}\" --ostype=\"${OSTYPE}\" --register --basefolder=\"${BASEFOLDER}\""
[[ $? -gt 0 ]] && exit

# Give it EFI boot # EFI64 is required *only* for MacOS
/usr/bin/VBoxManage modifyvm "${VMNAME}" --firmware="efi32" \
	&& echo "/usr/bin/VBoxManage modifyvm \""${VMNAME}"\" --firmware=\"efi32\""
[[ $? -gt 0 ]] && exit

# Set mouse, keyboard and usb settings
/usr/bin/VBoxManage modifyvm "${VMNAME}" --mouse="usb" --keyboard="usb" --clipboard-mode="bidirectional" --drag-and-drop="bidirectional" --monitor-count="1" --usb-ehci="off" --usb-ohci="off" --usb-xhci="on" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --mouse=\"usb\" --keyboard=\"usb\" --clipboard-mode=\"bidirectional\" --drag-and-drop=\"bidirectional\" --monitor-count=\"1\" --usb-ehci=\"off\" --usb-ohci=\"off\" --usb-xhci=\"on\""
[[ $? -gt 0 ]] && exit

# set video controler and video memory
/usr/bin/VBoxManage modifyvm "${VMNAME}" --graphicscontroller="VMSVGA" --vram="${VRAM}" --accelerate-3d="on" --accelerate-2d-video="on" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --graphicscontroller=\"VMSVGA\" --vram=\"${VRAM}\" --accelerate-3d=\"on\" --accelerate-2d-video=\"on\""
[[ $? -gt 0 ]] && exit

# Turn PAE off # we only need this if we are booting a 32-bit OS and need more than 4GB of RAM
/usr/bin/VBoxManage modifyvm "${VMNAME}" --pae="off" --long-mode="off" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --pae=\"off\" --long-mode=\"off\""
[[ $? -gt 0 ]] && exit


# set memory and cpu cores # --cpu-hotplug=on
/usr/bin/VBoxManage modifyvm "${VMNAME}" --cpus="${CPUS}" --memory="${MEMORY}" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --cpus=\"${CPUS}\" --memory=\"${MEMORY}\"" # --cpu-hotplug="on"
[[ $? -gt 0 ]] && exit

# Set bios parameters for VM # --triple-fault-reset=on do not apply
# guesses so far: hpet=on, x2apic=on, iommu=intel-> automatic/none, 
/usr/bin/VBoxManage modifyvm "${VMNAME}" --description="Work VM for NVI" --acpi="on" --ioapic="on" --cpu-profile="host" --hpet="on" --hwvirtex="on" --apic="on" --x2apic="on" --paravirt-provider="${PARAVIRT_PROVIDER}" --nested-paging="on" --largepages="on" --vtx-vpid="on" --vtx-ux="on" --nested-hw-virt="off" --chipset="ich9" --iommu="intel" --tpm-type="2.0" --bios-apic="x2apic" --rtc-use-utc="on" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --description=\"Work VM for NVI\" --acpi=\"on\" --ioapic=\"on\" --cpu-profile=\"host\" --hpet=\"on\" --hwvirtex=\"on\" --apic=\"on\" --x2apic=\"on\" --paravirt-provider=\"${PARAVIRT_PROVIDER}\" --nested-paging=\"on\" --largepages=\"on\" --vtx-vpid=\"on\" --vtx-ux=\"on\" --nested-hw-virt=\"off\" --chipset=\"ich9\" --iommu=\"intel\" --tpm-type=\"2.0\" --bios-apic=\"x2apic\" --rtc-use-utc=\"on\""

# Set the boot menu
# /usr/bin/VBoxManage modifyvm "${VMNAME} --bios-boot-menu="disabled"
# /usr/bin/VBoxManage modifyvm "${VMNAME}" --bios-boot-menu="menuonly"
/usr/bin/VBoxManage modifyvm "${VMNAME}" --bios-boot-menu="messageandmenu"

# Spectre attacks, mitigatte 
/usr/bin/VBoxManage modifyvm "${VMNAME}" --ibpb-on-vm-entry="on" --ibpb-on-vm-exit="on" --spec-ctrl="on" --l1d-flush-on-sched="off" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --ibpb-on-vm-entry=\"on\" --ibpb-on-vm-exit=\"on\" --spec-ctrl=\"on\" --l1d-flush-on-sched=\"off\""
[[ $? -gt 0 ]] && exit

# Disable all audio # regardless of whether you give --audio-controller or not, the default value is ac97. Furthermore, the --audio="none" is beind depreciated in the future.
# i'm stucking it in now, so i can completely disable the audiot and we will see.
/usr/bin/VBoxManage modifyvm "${VMNAME}" --audio="none" --audio-driver="none" --audio-controller="ac97" --audio-in="off" --audio-out="off" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --audio=\"none\" --audio-driver=\"none\" --audio-controller=\"ac97\" --audio-in=\"off\" --audio-out=\"off\""
[[ $? -gt 0 ]] && exit

# Create a non-fixed, single, disk image
/usr/bin/VBoxManage createmedium disk --filename="${FILENAME}" --size="${DISKSIZE}" --format="VDI" --variant="Standard" \
	&& echo "/usr/bin/VBoxManage createmedium disk --filename=\"${FILENAME}\" --size=\"${DISKSIZE}\" --format=\"VDI\" --variant=\"Standard\""
[[ $? -gt 0 ]] && exit

# Create an NVME controller for the disk
/usr/bin/VBoxManage storagectl "${VMNAME}" --controller="NVMe" --add="pcie" --name="NVME Controller" --hostiocache="on" --bootable="on" \
	&& echo "/usr/bin/VBoxManage storagectl \"${VMNAME}\" --controller=\"NVMe\" --add=\"pcie\" --name=\"NVME Controller\" --hostiocache=\"on\" --bootable=\"on\""
[[ $? -gt 0 ]] && exit

# Create a SATA controller for the dvd
/usr/bin/VBoxManage storagectl "${VMNAME}" --controller="IntelAhci" --add="sata" --name="SATA Controller" --portcount="1" --hostiocache="on" --bootable="on" \
	&& echo "/usr/bin/VBoxManage storagectl \"${VMNAME}\" --controller=\"IntelAhci\" --add=\"sata\" --name=\"SATA Controller\" --portcount=\"1\" --hostiocache=\"on\" --bootable=\"on\""
[[ $? -gt 0 ]] && exit

# Attach the VDI image to the NVME controller
/usr/bin/VBoxManage storageattach "${VMNAME}" --storagectl="NVME Controller" --device="0" --port="0" --type="hdd" --medium="${FILENAME}" --nonrotational="on" \
	&& echo "/usr/bin/VBoxManage storageattach "${VMNAME}" --storagectl=\"NVME Controller\" --device=\"0\" --port=\"0\" --type=\"hdd\" --medium=\"${FILENAME}\" --nonrotational=\"on\""
[[ $? -gt 0 ]] && exit

# Attach the DVD boot image to the SATA controller
/usr/bin/VBoxManage storageattach "${VMNAME}" --storagectl="SATA Controller" --device="0" --port="0" --type="dvddrive" --medium="${MEDIUM}" \
	&& echo "/usr/bin/VBoxManage storageattach \"${VMNAME}\" --storagectl=\"SATA Controller\" --device=\"0\" --port=\"0\" --type=\"dvddrive\" --medium=\"${MEDIUM}\""
[[ $? -gt 0 ]] && exit

# Set NIC1 to bridged # ifconfig | awk -F: '/^en/ { print $1 }' for the name of the interface
# --nic-boot-prio1="1" -> 0 is the default, 1 is the highest, 3, 4 lower; order therefore is [ 1, 0, 2, 3, 4]
/usr/bin/VBoxManage modifyvm "${VMNAME}" --nic1="bridged"  --bridgeadapter1="${BRIDGEADAPTER1}" --cable-connected1="on" --nic-boot-prio1="1" --nic-promisc1="deny" --mac-address1="$MACADDRESS" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --nic1=\"bridged\"  --bridgeadapter1=\"${BRIDGEADAPTER1}\" --cable-connected1=\"on\" --nic-boot-prio1=\"1\" --nic-promisc1=\"deny\" --mac-address1=\"$MACADDRESS\""
[[ $? -gt 0 ]] && exit

# Set boot order: PXEboot from net, dvd, disk and none # --bios-pxe-debug="on"
/usr/bin/VBoxManage modifyvm "${VMNAME}" --boot1 "net" --boot2 "dvd" --boot3 "disk" --boot4 "none" \
	&& echo "/usr/bin/VBoxManage modifyvm \"${VMNAME}\" --boot1 \"net\" --boot2 \"dvd\" --boot3 \"disk\" --boot4 \"none\""
[[ $? -gt 0 ]] && exit


# Set boot resolution to N
# where N ->  Resolution
#      0 ->  640 x  480
#      1 ->  800 x  600
#      2 -> 1024 x  768
#      3 -> 1280 x 1024
#      4 -> 1440 x  900
#      5 -> 1920 x 1200
/usr/bin/VBoxManage setextradata "${VMNAME}" VBoxInternal2/EfiGraphicsResolution "5" \
	&& echo "/usr/bin/VBoxManage setextradata \"${VMNAME}\" VBoxInternal2/EfiGraphicsResolution \"5\""
[[ $? -gt 0 ]] && exit

# Set a shared folder for initial file transfers
/usr/bin/VBoxManage sharedfolder add "${VMNAME}" --name="downloads" --hostpath="${HOSTPATH}" --automount --auto-mount-point="${AUTO_MOUNT_POINT}" \
	&& echo "/usr/bin/VBoxManage sharedfolder add \"${VMNAME}\" --name=\"downloads\" --hostpath=\"${HOSTPATH}\" --automount --auto-mount-point=\"${AUTO_MOUNT_POINT}\""
[[ $? -gt 0 ]] && exit

# for future use
    # --teleporter-address=0.0.0.0 allows VBox to listen to *all* requests for teleportation. Limit as needed
    # --cpuid-portability-level=0 makes avilable all CPU features to the host? but there is no guaratnee what level presents what feature?
    # --teleporter-port="6000" Port 6000 is set by me, given in the manual as an example, but not official and/or standardized
    # VBoxManage modifyvm $vmname --teleporter="on" --teleporter-port="6000" --teleporter-address="0.0.0.0" --teleporter-password=******* --teleporter-password-file="/home/captaincrunch/password.txt" --cpuid-portability-level=0

# start vm, to test settings
/usr/bin/VBoxManage startvm "${VMNAME}" #&& echo "/usr/bin/VBoxManage startvm \"${VMNAME}\""
sleep ${SHUTDOWNTIMEOUT}
# terminate VM
/usr/bin/VBoxManage controlvm "${VMNAME}" poweroff

# Unattended Debian and debian-like systems install
    # VBoxManage unattended detect <--iso=install-iso> [--machine-readable]
    # Detects the guest operating system (OS) on the specified installation ISO and displays the result.
    # This can be used as input when creating a VM for the ISO to be installed in.

    # --package-selection-adjustment="minimal"  --image-index="number" --script-template="file" --post-install-template="file" --post-install-command="command" --extra-install-kernel-parameters="params" 

    # --auxiliary-base-path="path"  # useful only for Debian
    # Running VBoxManage unattended install creates (always?) four files in the Virtual Box file folder:
    # Unattended-<GUID>-aux-iso.viso
    # Unattended-<GUID>-grub.cfg
    # Unattended-<GUID>-preseed.cfg
    # Unattended-<GUID>-vboxpostinstall.sh

    # Fedora 37
    # VBoxManage unattended install "${VMNAME}" --iso="$medium" --user="gmarselis" --password="12345" --full-user-name="George Marselis" --install-additions --additions-iso="$additions_iso" --locale="en_US" --country="NO" --time-zone="UTC+1" --hostname="$fqdn" --language="en_US" --auxiliary-base-path="D:\kot"&& echo "VBoxManage unattended install `"$vmname`" --iso=`"$medium`" --user=`"gmarselis`" --password=`"12345`" --full-user-name=`"George Marselis`" --install-additions --additions-iso=`"$additions_iso`" --locale=`"en_US`" --country=`"NO`" --time-zone=`"UTC+1`" --hostname=`"$fqdn`" --dry-run --language=`"en_US`""

    # Debian Buster
    #/usr/bin/VBoxManage unattended install "${VMNAME}" --iso="/home/gmarselis/Downloads/debian-11.6.0-amd64-netinst.iso" --user="gmarselis" --password="12345" --full-user-name="George Marselis" --install-additions --additions-iso="${ADDITIONS_ISO}" --locale="en_US" --country="NO" --time-zone="UTC+1" --hostname="$fqdn" --dry-run --language="en_US" && echo "/usr/bin/VBoxManage unattended install \"${VMNAME}\" --iso=\"/home/gmarselis/Downloads/debian-11.6.0-amd64-netinst.iso\" --user=\"gmarselis\" --password=\"12345\" --full-user-name=\"George Marselis\" --install-additions --additions-iso=\"${ADDITIONS_ISO}\" --locale=\"en_US\" --country=\"NO\" --time-zone=\"UTC+1\" --hostname=\"${FQDN}\" --dry-run --language=\"en_US\""


# Autostarting VM During Host System Boot
    # the "1" is set by me. There are no suggestions in the manual.
    # VBoxManage modifyvm $vmname --autostart-enabled="on" --autostart-delay="2"
