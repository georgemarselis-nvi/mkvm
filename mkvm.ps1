$ErrorActionPreference = "Stop"

$basefolder="D:\VirtualBox VM"
$vmname="Fedora 37-1-test"
$ostype="Fedora_64"
$cpus=4
$memory=16384
$vram=256
$date=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$filename="$basefolder\media\$vmname-$date.vdi"
$disksize=120000
$hostpath="D:\Downloads"
$medium="$hostpath\Fedora-Server-dvd-x86_64-37-1.7.iso"
$auto_mount_point="/mnt/downloads"
$paravirt_provider="default" # if set to default, under linux will still be set to KVM
$cpu_hotplug="off"
$bridgeadapter1="Intel(R) Ethernet Connection (2) I218-LM"
$additions_iso="C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"
$hostname="molly-test-1-$date"
$macaddress="080027C48B18"
$fqdn="$hostname.marsel.is"


try {
    # Delete the registered VM
    VBoxManage unregistervm $vmname --delete 2> $null
    # Delete the created VDI
    VBoxManage closemedium disk $filename --delete 2> $null

    # Note about the use of single quotes: PowerShell passes $variables as whole strings, so there is no need to quote them. If you want to re-create the commands, tho, the 

    # Register VM
    VBoxManage createvm --name=$vmname --ostype=$ostype --register --basefolder=$basefolder && Write-Output "VBoxManage createvm --name=`"$vmname`" --ostype=`"$ostype`" --register --basefolder=`"$basefolder`""

    # Give it EFI boot # EFI64 is required *only* for MacOS
    VBoxManage modifyvm $vmname --firmware="efi32" && Write-Output "VBoxManage modifyvm `"$vmname`" --firmware=`"efi32`""

    # Set mouse, keyboard and usb settings
    VBoxManage modifyvm $vmname --mouse="usb" --keyboard="usb" --clipboard-mode="bidirectional" --drag-and-drop="bidirectional" --monitor-count="1" --usb-ehci="off" --usb-ohci="off" --usb-xhci="on" && Write-Output "VBoxManage modifyvm `"$vmname`" --mouse=`"usb`" --keyboard=`"usb`" --clipboard-mode=`"bidirectional`" --drag-and-drop=`"bidirectional`" --monitor-count=`"1`" --usb-ehci=`"off`" --usb-ohci=`"off`" --usb-xhci=`"on`""

    # set video controler and video memory
    VBoxManage modifyvm $vmname --graphicscontroller="VMSVGA" --vram=$vram --accelerate-3d="on" --accelerate-2d-video="on" && Write-Output "VBoxManage modifyvm `"$vmname`" --graphicscontroller=`"VMSVGA`" --vram=`"$vram`" --accelerate-3d=`"on`" --accelerate-2d-video=`"on`""

    # Turn PAE off # we only need this if we are booting a 32-bit OS and need more than 4GB of RAM
    VBoxManage modifyvm $vmname --pae="off" --long-mode="off" && Write-Output "VBoxManage modifyvm `"$vmname`" --pae=`"off`" --long-mode=`"off`""

    # set memory and cpu cores # --cpu-hotplug=on
    VBoxManage modifyvm $vmname --cpus=$cpus --memory=$memory && Write-Output "VBoxManage modifyvm `"$vmname`" --cpus=`"$cpus`" --memory=`"$memory`"" # --cpu-hotplug="on"

    # Set bios parameters for VM # --triple-fault-reset=on do not apply
    # guesses so far: hpet=on, x2apic=on, iommu=intel-> automatic/none, 
    VBoxManage modifyvm $vmname --description="Work VM for NVI" --acpi="on" --ioapic="on" --cpu-profile="host" --hpet="on" --hwvirtex="on" --apic="on" --x2apic="on" --paravirt-provider=$paravirt_provider --nested-paging="on" --largepages="on" --vtx-vpid="on" --vtx-ux="on" --nested-hw-virt="off" --chipset="ich9" --iommu="intel" --tpm-type="2.0" --bios-apic="x2apic" --rtc-use-utc="on" && Write-Output " VBoxManage modifyvm `"$vmname`" --description=`"Work VM for NVI`" --acpi=`"on`" --ioapic=`"on`" --cpu-profile=`"host`" --hpet=`"on`" --hwvirtex=`"on`" --apic=`"on`" --x2apic=`"on`" --paravirt-provider=$paravirt_provider --nested-paging=`"on`" --largepages=`"on`" --vtx-vpid=`"on`" --vtx-ux=`"on`" --nested-hw-virt=`"off`" --chipset=`"ich9`" --iommu=`"intel`" --tpm-type=`"2.0`" --bios-apic=`"x2apic`"" 

    # Set the boot menu
    # VBoxManage modifyvm $vmname --bios-boot-menu="disabled"
    VBoxManage modifyvm $vmname --bios-boot-menu="menuonly"
    # VBoxManage modifyvm $vmname --bios-boot-menu="messageandmenu"

    # Spectre attacks, mitigatte 
    VBoxManage modifyvm $vmname --ibpb-on-vm-entry="on" --ibpb-on-vm-exit="on" --spec-ctrl="off" --l1d-flush-on-sched="off" --l1d-flush-on-vm-entry="off" --mds-clear-on-sched="off" --mds-clear-on-vm-entry="off" && Write-Output "VBoxManage modifyvm `"$vmname`" --ibpb-on-vm-entry=`"on`" --ibpb-on-vm-exit=`"on`" --spec-ctrl=`"off`" --l1d-flush-on-sched=`"off`" --l1d-flush-on-vm-entry=`"off`""

    # Disable all audio # regardless of whether you give --audio-controller or not, the default value is ac97. Furthermore, the --audio="none" is beind depreciated in the future.
    # i'm stucking it in now, so i can completely disable the audiot and we will see.
    VBoxManage modifyvm $vmname --audio="none" --audio-driver="none" --audio-controller="ac97" --audio-in="off" --audio-out="off" 2> $null && Write-Output "VBoxManage modifyvm `"$vmname`" --audio=`"none`" --audio-driver=`"none`" --audio-controller=`"ac97`" --audio-in=`"off`" --audio-out=`"off`""

    # Create a non-fixed, single, disk image
    VBoxManage createmedium disk --filename=$filename --size=$disksize --format="VDI" --variant="Standard" && Write-Output "VBoxManage createmedium disk --filename=`"$filename`" --size=`"$disksize`" --format=`"VDI`" --variant=`"Standard`""

    # Create an NVME controller for the disk
    VBoxManage storagectl $vmname --controller="NVMe" --add="pcie" --name="NVME Controller" --hostiocache="on" --bootable="on" && Write-Output "VBoxManage storagectl `"$vmname`" --controller=`"NVMe`" --add=`"pcie`" --name=`"NVME Controller`" --hostiocache=`"on`" --bootable=`"on`""

    # Create a SATA controller for the dvd
    VBoxManage storagectl $vmname --controller="IntelAhci" --add="sata" --name="SATA Controller" --portcount=1 --hostiocache="on" --bootable="on" && Write-Output "VBoxManage storagectl `"$vmname`" --controller=`"IntelAhci`" --add=`"sata`" --name=`"SATA Controller`" --portcount=1 --hostiocache=`"on`" --bootable=`"on`""

    # Attach the VDI image to the NVME controller
    VBoxManage storageattach $vmname --storagectl="NVME Controller" --device="0" --port="0" --type="hdd" --medium=$filename --nonrotational="on" && Write-Output "VBoxManage storageattach `"$vmname`" --storagectl=`"NVME Controller`" --device=`"0`" --port=`"0`" --type=`"hdd`" --medium=`"$filename --nonrotational=`"on`""

    # Attach the DVD boot image to the SATA controller
    VBoxManage storageattach $vmname --storagectl="SATA Controller" --device="0" --port="0" --type=dvddrive --medium=$medium && Write-Output "VBoxManage storageattach `"$vmname`" --storagectl=`"SATA Controller`" --device=`"0`" --port=`"0`" --type=`"dvddrive`" --medium=`"$medium`""

    # Set NIC1 to bridged # --nic-boot-prio1="1" -> 0 is the default, 1 is the highest, 3, 4 lower; order therefore is [ 1, 0, 2, 3, 4]
    # problem here for pxeboot could be --nic-promisc1="deny". Set to "allow-all" to test
    VBoxManage modifyvm $vmname --nic1="bridged"  --bridgeadapter1=$bridgeadapter1 --cable-connected1="on" --nic-boot-prio1="1" --nic-promisc1="deny" --mac-address1="$macaddress" && Write-Output "VBoxManage modifyvm `"$vmname`" --nic1=`"bridged`"  --bridgeadapter1=`"$bridgeadapter1`" --cable-connected1=`"on`" --nic-boot-prio1=`"1`" --nic-promisc1=`"deny`" --mac-address1=`"$macaddress`""

    # Set boot order: PXEboot from net, dvd, disk and none # --bios-pxe-debug=on
    VBoxManage modifyvm $vmname --boot1="net" --boot2="dvd" --boot3="disk" --boot4="none" && Write-Output "VBoxManage modifyvm `"$vmname`" --boot1=`"net`" --boot2=`"dvd`" --boot3=`"disk`" --boot4=`"none`" # --bios-pxe-debug=`"on`"" 

    # Set boot resolution to N
    # where N ->  Resolution
    #      0 ->  640 x  480
    #      1 ->  800 x  600
    #      2 -> 1024 x  768
    #      3 -> 1280 x 1024
    #      4 -> 1440 x  900
    #      5 -> 1920 x 1200
    VBoxManage setextradata $vmname VBoxInternal2/EfiGraphicsResolution 5 && Write-Output "VBoxManage setextradata `"$vmname`" VBoxInternal2/EfiGraphicsResolution 5"

    # Set a shared folder for initial file transfers
    VBoxManage sharedfolder add $vmname --name="downloads" --hostpath=$hostpath --automount --auto-mount-point=$auto_mount_point && Write-Output "VBoxManage sharedfolder add `"$vmname`" --name=`"downloads`" --hostpath=`"$hostpath`" --automount --auto-mount-point=`"$auto_mount_point`""

    # for the future
    # --teleporter-address=0.0.0.0 allows VBox to listen to *all* requests for teleportation. Limit as needed
    # --cpuid-portability-level=0 makes avilable all CPU features to the host? but there is no guaratnee what level presents what feature?
    # --teleporter-port="6000" Port 6000 is set by me, given in the manual as an example, but not official and/or standardized
    # VBoxManage modifyvm $vmname --teleporter="on" --teleporter-port="6000" --teleporter-address="0.0.0.0" --teleporter-password=******* --teleporter-password-file="/home/captaincrunch/password.txt" --cpuid-portability-level=0

    # start vm
    VBoxManage startvm $vmname #&& Write-Output "VBoxManage startvm `"$vmname`""

    # Unattended install
    # --user=vboxuser     , default
    # --password=changeme , default
    # --password-file=/home/gmarselis/unattended_install_password_file.txt : should contain only the password in cleartext . 
    #       Alternative: can use stdin to read the password from standard input

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
    # VBoxManage unattended install $vmname --iso="$medium" --user="gmarselis" --password="12345" --full-user-name="George Marselis" --install-additions --additions-iso="$additions_iso" --locale="en_US" --country="NO" --time-zone="UTC+1" --hostname="$fqdn" --language="en_US" --auxiliary-base-path="D:\kot"&& Write-Output "VBoxManage unattended install `"$vmname`" --iso=`"$medium`" --user=`"gmarselis`" --password=`"12345`" --full-user-name=`"George Marselis`" --install-additions --additions-iso=`"$additions_iso`" --locale=`"en_US`" --country=`"NO`" --time-zone=`"UTC+1`" --hostname=`"$fqdn`" --dry-run --language=`"en_US`""

    # Debian Buster
    VBoxManage unattended install $vmname --iso="D:\Downloads\debian-10.1.0-amd64-netinst.iso" --user="gmarselis" --password="12345" --full-user-name="George Marselis" --install-additions --additions-iso="$additions_iso" --locale="en_US" --country="NO" --time-zone="UTC+1" --hostname="$fqdn" --dry-run --language="en_US" && Write-Output "VBoxManage unattended install `"$vmname`" --iso=`"D:\Downloads\debian-10.1.0-amd64-netinst.iso`" --user=`"gmarselis`" --password=`"12345`" --full-user-name=`"George Marselis`" --install-additions --additions-iso=`"$additions_iso`" --locale=`"en_US`" --country=`"NO`" --time-zone=`"UTC+1`" --hostname=`"$fqdn`" --dry-run --language=`"en_US`""



    # Autostarting VM During Host System Boot
    # the "1" is set by me. There are no suggestions in the manual.
    # VBoxManage modifyvm $vmname --autostart-enabled="on" --autostart-delay="2"

} catch {
    Write-Output ""
}

# VBoxManage controlvm $vmname screenshotpng "$hostpath\$name_ScreenCapture_$date.png" "[0/1]" && "VBoxManage controlvm `"$vmname`"" screenshotpng `"$hostpath\$name_ScreenCapture_$date.png`" `"[0/1]`""

# VBoxManage controlvm <uuid | vmname> clipboard filetransfers <on | off>
#
# The VBoxManage controlvm vmname clipboard filetransfers command specifies if it is
# possible to transfer files through the clipboard between the host and VM, in the direction which
# is allowed. Valid values are off and on. The default value is off.
# This feature requires that the Oracle VM VirtualBox Guest Additions are installed in the VM

# The setcredentials command enables you to specify the credentials for remotely logging in
# to Windows VMs. See chapter 9.1, Automated Guest Logins, page 309.
# • username specifies the user name with which to log in to the Windows VM.
# • --passwordfile=<filename> specifies the file from which to obtain the password for
# username.
# The --passwordfile is mutually exclusive with the --password option.
# • --password=<password> specifies the password for username.
# The --password is mutually exclusive with the --passwordfile option.
# • --allowlocallogin specifies whether to enable or disable local logins. Valid values are
# on to enable local logins and off to disable local logins



