$ErrorActionPreference = "Stop"

$basefolder="D:\VirtualBox VM"
$vmname="Fedora 37-1-test"
$ostype="Fedora_64"
$cpus=12
$memory=16384
$vram=256
$date=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$filename="$basefolder\media\$vmname-$date.vdi"
$disksize=120000
$hostpath="D:\Downloads"
$medium="$hostpath\Fedora-Server-dvd-x86_64-37-1.7.iso"
$auto_mount_point="/mnt/downloads"
$paravirt_provider="default" # if set to default, under linux will still be set to KVM
$dpu_hotplug="off"
$bridgeadapter1="Intel(R) Ethernet Connection (2) I218-LM"


# Delete the registered VM
VBoxManage unregistervm $vmname --delete 2> $null
# Delete the created VDI
VBoxManage closemedium disk $filename --delete 2> $null

# Note about the use of single quotes: PowerShell passes $variables as whole strings, so there is no need to quote them. If you want to re-create the commands, tho, the 

# Register VM
VBoxManage createvm --name=$vmname --ostype=$ostype --register --basefolder=$basefolder && Write-Output "VBoxManage createvm --name=`"$vmname`" --ostype=`"$ostype`" --register --basefolder=`"$basefolder`""

if ( $? -eq $False ) { throw "" }

# Give it EFI boot # EFI64 is required *only* for MacOS
VBoxManage modifyvm $vmname --firmware="efi32" && Write-Output "VBoxManage modifyvm `"$vmname`" --firmware=`"efi32`""

if ( $? -eq $False ) { throw "" }

# Set mouse, keyboard and usb settings
VBoxManage modifyvm $vmname --mouse="usb" --keyboard="usb" --clipboard-mode="bidirectional" --drag-and-drop="bidirectional" --monitor-count=1 --usb-ehci="off" --usb-ohci="off" --usb-xhci="on" && Write-Output "VBoxManage modifyvm `"$vmname`" --mouse=`"usb`" --keyboard=`"usb`" --clipboard-mode=`"bidirectional`" --drag-and-drop=`"bidirectional`" --monitor-count=1 --usb-ehci=`"off`" --usb-ohci=`"off`" --usb-xhci=`"on`""

if ( $? -eq $False ) { throw "" }

# set memory, video controler and video memory
VBoxManage modifyvm $vmname --graphicscontroller="VMSVGA" --memory=$memory --vram=$vram --accelerate-3d="on" --accelerate-2d-video="on" && Write-Output "VBoxManage modifyvm `"$vmname`" --graphicscontroller=`"VMSVGA`" --memory=$memory --vram=$vram --accelerate-3d=`"on`" --accelerate-2d-video=`"on`""

if ( $? -eq $False ) { throw "" }

# Disable all audio
VBoxManage modifyvm $vmname --audio-driver="none" --audio-in="off" --audio-out="off" && Write-Output "VBoxManage modifyvm `"$vmname`" --audio=`"none`" --audio-in=`"off`" --audio-out=`"off`""

if ( $? -eq $False ) { throw "" }

# Turn PAE off # we only need this if we are booting a 32-bit OS and need more than 4GB of RAM
VBoxManage modifyvm $vmname --pae="off" --long-mode="off" && Write-Output "VBoxManage modifyvm `"$vmname`" --pae=`"off`" --long-mode=`"off`""

if ( $? -eq $False ) { throw "" }

# Spectre attacks, mitigatte 
# VBoxManage modifyvm $vmname --ibpb-on-vm-entry="on" --ibpb-on-vm-exit="on" --spec-ctrl="on" --l1d-flush-on-sched="off" && Write-Output "VBoxManage modifyvm `"$vmname`" --ibpb-on-vm-entry=`"on`" --ibpb-on-vm-exit=`"on`" --spec-ctrl=`"on`" --l1d-flush-on-sched=`"off`""
# 

if ( $? -eq $False ) { throw "" }

# Parameters for VM --cpu-hotplug=$cpu_hotplug --cpu-profile=host 
VBoxManage modifyvm $vmname --description="Work VM for NVI" --ioapic="on" --acpi="on" --cpus=$cpus --hpet="o"n --hwvirtex="on" --apic="on" --x2apic="on" --paravirt-provider=$paravirt_provider --nested-paging="on" --largepages="on" --vtx-vpid="on" --vtxux="on" --chipset="ich9" --iommu="intel" --tpm-type="2.0" --bios-apic="x2apic" && Write-Output "VBoxManage modifyvm `"$vmname`" --description=`"Work VM for NVI`" --ioapic=`"on`" --acpi=`"on`" --cpus=12 --cpu-hotplug=`"$cpu_hotplug`" --cpu-profile=`"host`" --hpet=`"on`" --hwvirtex=`"on`" --apic=`"on`" --x2apic=`"on`" --paravirt-provider=$paravirt_provider --nested-paging=`"on`" --largepages=`"on`" --vtx-vpid=`"on`" --chipset=`"ich9`" --iommu=`"intel`" --tpm-type=`"2.0`" --bios-apic=`"x2apic`""

if ( $? -eq $False ) { throw "" }

# Set NIC1 to bridged # ifconfig | awk -F: "/^en/  print $1 " for the name of the interface
VBoxManage modifyvm $vmname --nic1="bridged"  --bridgeadapter1=$bridgeadapter1 && Write-Output "VBoxManage modifyvm `"$vmname`" --nic1=`"bridged`" --bridgeadapter1=`"$bridgeadapter1`""

if ( $? -eq $False ) { throw "" }

# Create a non-fixed, single, disk image
VBoxManage createmedium disk --filename=$filename --size=$disksize --format="VDI" --variant="Standard" && Write-Output "VBoxManage createmedium disk --filename=`"$filename`" --size=`"$disksize`" --format=`"VDI`" --variant=`"Standard`""

if ( $? -eq $False ) { throw "" }

# Create an NVME controller for the disk
VBoxManage storagectl $vmname --controller="NVMe" --add="pcie" --name="NVME Controller" --hostiocache="on" --bootable="on" && Write-Output "VBoxManage storagectl `"$vmname`" --controller=`"NVMe`" --add=`"pcie`" --name=`"NVME Controller`" --hostiocache=`"on`" --bootable=`"on`""

if ( $? -eq $False ) { throw "" }

# Create a SATA controller for the dvd
VBoxManage storagectl $vmname --controller="IntelAhci" --add="sata" --name="SATA Controller" --portcount=1 --hostiocache="on" --bootable="on" && Write-Output "VBoxManage storagectl `"$vmname`" --controller=`"IntelAhci`" --add=`"sata`" --name=`"SATA Controller`" --portcount=1 --hostiocache=`"on`" --bootable=`"on`""

if ( $? -eq $False ) { throw "" }

# Attach the VDI image to the NVME controller
VBoxManage storageattach $vmname --storagectl="NVME Controller" --device=0 --port=0 --type="hdd" --medium=$filename --nonrotational="on" && Write-Output "VBoxManage storageattach `"$vmname`" --storagectl=`"NVME Controller`" --device=0 --port=0 --type=`"hdd`" --medium=`"$filename --nonrotational=`"on`""

if ( $? -eq $False ) { throw "" }

# Attach the DVD boot image to the SATA controller
VBoxManage storageattach $vmname --storagectl="SATA Controller" --device=0 --port=0 --type=dvddrive --medium=$medium && Write-Output "VBoxManage storageattach `"$vmname`" --storagectl=`"SATA Controller`" --device=0 --port=0 --type=dvddrive --medium=`"$medium`""

if ( $? -eq $False ) { throw "" }

# Set boot order: PXEboot from net, dvd, disk and none
VBoxManage modifyvm $vmname --boot1 "net" --boot2 "dvd" --boot3 "disk" --boot4 "none" && Write-Output "VBoxManage modifyvm `"$vmname`" --boot1 `"net`" --boot2 `"dvd`" --boot3 `"disk`" --boot4 `"none`""

if ( $? -eq $False ) { throw "" }


# Set boot resolution to N
# where N ->  Resolution
#      0 ->  640 x  480
#      1 ->  800 x  600
#      2 -> 1024 x  768
#      3 -> 1280 x 1024
#      4 -> 1440 x  900
#      5 -> 1920 x 1200
VBoxManage setextradata $vmname VBoxInternal2/EfiGraphicsResolution 5 && Write-Output "VBoxManage setextradata `"$vmname`" VBoxInternal2/EfiGraphicsResolution 5"

if ( $? -eq $False ) { throw "" }

# Set a shared folder for initial file transfers
VBoxManage sharedfolder add $vmname --name="downloads" --hostpath=$hostpath --automount --auto-mount-point=$auto_mount_point && Write-Output "VBoxManage sharedfolder add `"$vmname`" --name=`"downloads`" --hostpath=`"$hostpath`" --automount --auto-mount-point=`"$auto_mount_point`""

if ( $? -eq $False ) { throw "" }

# start vm
VBoxManage startvm $vmname #&& Write-Output "VBoxManage startvm "$vmname""
