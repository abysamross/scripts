#!/bin/bash

arch=$1
action=$2
distro=$3
version=$4
flavor=$5
diskformat=$6
instance=$7
mem=$8

HOME=/home/abysamross
# qemu=${HOME}/source/qemu/build/qemu-system-${arch}
qemu=qemu-system-${arch}

distdir=${HOME}/distros/arch/${arch}/${distro}
isodir=${distdir}/${version}/iso
isoname=${distro}-${version}-${flavor}-${arch}.iso
iso=${isodir}/${isoname}
diskdir=${HOME}/vmdisks
diskname=${distro}-${version}-${flavor}-${arch}-disk-${instance}.${diskformat}
disk=${diskdir}/${diskname}
logdir=${HOME}/logs/qemu/${action}
logfile=${logdir}/${distro}-${version}-${flavor}-${arch}.log

# TODO: create vmdisk if file doesn't exist.

if [[ ! -f ${logfile} ]]; then
    touch ${logfile}
fi

### live VM ### {{{

if [[ ${action} == live ]]; then
    ${qemu} -machine s390-ccw-virtio \
    -cpu max,zpci=on,msa5-base=on \
    -serial telnet::4441,server \
    -display none \
    -m ${mem} \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-netdev0 \
    -device virtio-net-ccw,netdev=tap-netdev0,id=tap-virtio-net-ccw0 \
    --cdrom ${iso} \
    -D ${logfile}
fi

### end live VM ### }}}

### install VM ### {{{

if [[ ${action} == install ]]; then
    ${qemu} -name guest=${distro}-${version}-${flavor}-${arch}-${instance},debug-threads=on \
    \
    -machine s390-ccw-virtio,usb=off,dump-guest-core=off,memory-backend=s390.ram \
    -accel kvm \
    -cpu max,zpci=on \
    -smp 2,sockets=2,cores=1,threads=1 \
    \
    -m ${mem} \
    -object memory-backend-ram,id=s390.ram,size=${mem}M \
    -overcommit mem-lock=off \
    \
    -nodefaults \
    \
    -display none \
    -serial telnet::4441,server \
    \
    -rtc base=utc \
    \
    -no-shutdown \
    \
    -boot menu=on,strict=on \
    -kernel ${distdir}/${version}/boot/kernel.${distro} \
    -initrd ${distdir}/${version}/boot/initrd.${distro} \
    \
    -blockdev file,filename=${iso},node-name=blk_storage0,discard=unmap \
    -blockdev raw,file=blk_storage0,node-name=blk_format0 \
    -device virtio-scsi-ccw,id=virtio-scsi0,devno=fe.0.0008 \
    -device scsi-cd,bus=virtio-scsi0.0,channel=0,scsi-id=0,lun=0,device_id=drive-scsi-cd0,drive=blk_format0,id=scsi-cd0 \
    \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-netdev0,br=virbr0 \
    -device virtio-net-ccw,netdev=tap-netdev0,id=virtio-net0,devno=fe.0.0001 \
    \
    -blockdev file,filename=${disk},node-name=blk_storage1 \
    -blockdev qcow2,file=blk_storage1,node-name=blk_format1 \
    -device virtio-blk-ccw,devno=fe.0.0002,drive=blk_format1,id=virtio-blk0,bootindex=1 \
    \
    -device zpci,uid=0,fid=0,target=vfio-pci0,id=zpci0 \
    -device vfio-pci,host=0003:00:00.0,id=vfio-pci0 \
    \
    -device virtio-serial-ccw,id=virtio-serial0,devno=fe.0.0003 \
    -chardev stdio,id=char-stdio0,mux=on,server=on,wait=off \
    -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=char-stdio0,id=virtserial0,name=org.qemu.guest_agent.0 \
    \
    -device virtio-balloon-ccw,id=virtio-balloon0,devno=fe.0.0005 \
    \
    -object rng-random,id=rng-rand0,filename=/dev/urandom \
    -device virtio-rng-ccw,rng=rng-rand0,id=virtio-rng0,devno=fe.0.0004 \
    \
    -mon chardev=char-stdio0,id=virt-monitor,mode=control \
    \
    -audiodev id=virtaudio0,driver=none \
    \
    -msg timestamp=on \
    -D ${logfile}
fi

### end install VM ### }}}

### run VM  ### {{{

if [[ ${action} == run ]]; then
    # strace
    ${qemu} -name guest=${distro}-${version}-${flavor}-${arch}-${instance},debug-threads=on \
    \
    -machine s390-ccw-virtio,usb=off,dump-guest-core=off,memory-backend=s390.ram \
    -accel kvm \
    -cpu max,zpci=on \
    -smp 2,sockets=2,cores=1,threads=1 \
    \
    -m ${mem} \
    -object memory-backend-ram,id=s390.ram,size=${mem}M \
    -overcommit mem-lock=off \
    \
    -display none \
    -serial telnet::4441,server \
    \
    -rtc base=utc \
    -no-shutdown \
    -boot menu=on,strict=on \
    \
    -device virtio-scsi-ccw,id=virtio-scsi0,devno=fe.0.0008 \
    -device scsi-cd,bus=virtio-scsi0.0,channel=0,scsi-id=0,lun=0,device_id=drive-scsi-cd0,id=scsi-cd0 \
    \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-netdev0,br=virbr0 \
    -device virtio-net-ccw,netdev=tap-netdev0,id=virtio-net0,devno=fe.0.0001 \
    \
    -blockdev file,filename=${disk},node-name=blk_storage0 \
    -blockdev qcow2,file=blk_storage0,node-name=blk_format0 \
    -device virtio-blk-ccw,devno=fe.0.0002,drive=blk_format0,id=virtio-blk0,bootindex=1 \
    \
    -device virtio-serial-ccw,id=virtio-serial0,devno=fe.0.0003 \
    -chardev stdio,id=char-stdio0,mux=on,signal=on,server=on,wait=off \
    -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=char-stdio0,id=virtserial0,name=org.qemu.guest_agent.0 \
    \
    -device virtio-balloon-ccw,id=virtio-balloon0,devno=fe.0.0005 \
    \
    -object rng-random,id=rng-rand0,filename=/dev/urandom \
    -device virtio-rng-ccw,rng=rng-rand0,id=virtio-rng0,devno=fe.0.0004 \
    \
    -mon chardev=char-stdio0,id=virt-monitor,mode=control \
    \
    -audiodev id=virtaudio0,driver=none \
    \
    -device zpci,uid=0,fid=0,target=vfio-pci0,id=zpci0 \
    -device vfio-pci,host=0000:00:00.1,id=vfio-pci0,vf-token=e3f6d79f-afd5-499f-b0da-811a2c3207a0 \
    -msg timestamp=on \
    -D ${logfile}
fi

### end run VM  ### }}}

### alternate/optional args ### {{{
#
## Attach GDB ## {{{
    # \
    # -s \
    # -S \
    # \
## Attach GDB ## }}}
#
## Guest Network ## {{{
#
#    -netdev bridge,id=bridge-net-dev \
#    -device virtio-net-ccw,netdev=bridge-net-dev,id=virtio-net0 \
#
#    -netdev tap,fd=33,id=hostnet0,vhost=on,vhostfd=35 \
#    -device virtio-net-ccw,netdev=hostnet0,id=net0,mac=52:54:00:6a:02:04,devno=fe.0.0001 \
#
## Guest Network ## }}}
#
## boot files ## {{{
#
# -kernel ${distdir}/${version}/boot/kernel.${distro} \
# -initrd ${distdir}/${version}/boot/initrd.${distro} \
#
# end boot files ## }}}
#
## Guest Disk ## {{{
#
#   -blockdev file,filename=${iso},node-name=blk_storage0 \
#   -blockdev raw,file=blk_storage0,node-name=blk_format0 \
#   -device virtio-scsi-ccw,id=virtio-scsi0,devno=fe.0.0008 \
#   -device scsi-cd,bus=virtio-scsi0.0,channel=0,scsi-id=0,lun=0,device_id=drive-scsi-cd0,drive=blk_format0,id=scsi-cd0 \
#
#   -blockdev {"driver":"file","filename":"/var/lib/libvirt/images/ubuntu-vm-disk.img","node-name":"libvirt-2-storage","auto-read-only":true,"discard":"unmap"} \
#   -blockdev {"node-name":"libvirt-2-format","read-only":false,"discard":"unmap","driver":"qcow2","file":"libvirt-2-storage","backing":null} \
#   -device virtio-blk-ccw,devno=fe.0.0000,drive=libvirt-2-format,id=virtio-disk0,bootindex=1 \
#
#   -drive file=${disk},if=none,id=qcow2-drive,format=${diskformat},cache=none \
#   -device virtio-blk-ccw,devno=fe.0.0002,drive=blk_format0,id=virtio-blk0 \
#
## Guest Disk ## }}}
#
## Guest pci ## {{{
#
#    -device vfio-pci,host=0002:00:00.0,id=hostpci0 \
#    -device zpci,uid=0,fid=0,target=hostpci0,id=zpci0 \
#
# Guest pci ## }}}
#
## Guest scsi CD ## {{{
#
#   -device virtio-scsi-ccw,id=virtio-scsi0,devno=fe.0.0000 \
#   -device scsi-cd,bus=virtio-scsi0.0,channel=0,scsi-id=0,lun=0,device_id=drive-scsi-cd0,id=scsi-cd0 \
#
## Guest scsi CD ## }}}
#
## Guest serial port ## {{{
#
#   -device virtio-serial-ccw,id=virtio-serial0,devno=fe.0.0002 \
#   -chardev socket,id=char-virtserial0,server=on,wait=off \
#   -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=char-virtserial0,id=virtserial0,name=org.qemu.guest_agent.0 \
#
## Guest serial port ## }}}
#
## Qemu Monitor ## {{{
#
#   -chardev socket,id=charmonitor,fd=32,server=on,wait=off \
#   -mon chardev=charmonitor,id=monitor,mode=control \
#
## Qemu Monitor ## }}}
#
## Guest /dev/sclpconsole Console ## {{{
#
#   -chardev pty,id=char-virtconsole1 \
#   -device sclpconsole,chardev=char-virtconsole0,id=virtconsole0 \
#
## Guest /dev/sclpconsole Console ## }}}
#
## Guest Audiodev ## {{{
#
#   -audiodev {"id":"audio1","driver":"none"} \
#
## Guest Audiodev ## }}}
#
### end alternate/optional args ### }}}
