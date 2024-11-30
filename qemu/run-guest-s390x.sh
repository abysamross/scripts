#!/bin/bash

HOME=/home/abysamross/
arch=s390x
action=$1
distro=$2
version=$3
flavor=$4
diskformat=$5
disknum=$6
mem=$7

qemu=${HOME}/source/qemu/build/qemu-system-${arch}
# qemu=qemu-system-${arch}

distdir=${HOME}/distros/arch/${arch}/${distro}
isodir=${distdir}/${version}/iso
isoname=${distro}-${version}-${flavor}-${arch}.iso
iso=${isodir}/${isoname}
diskdir=${HOME}/vmdisks
diskname=${distro}-${version}-${flavor}-${arch}-disk-${disknum}.${diskformat}
disk=${diskdir}/${diskname}
logdir=${HOME}/qlogs/${action}
logfile=${logfile}/${distro}-${version}-${flavor}-${arch}.log

if [[ ${action} == install ]]; then
${qemu} -machine s390-ccw-virtio \
    -cpu max,zpci=on,msa5-base=off \
    -serial telnet::4441,server \
    -display none \
    -m ${mem} \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-net-dev \
    -device virtio-net-ccw,netdev=tap-net-dev,id=virtio-net0 \
    --cdrom ${iso} \
    -drive file=${disk},if=none,id=drive-virtio-disk0,format=${diskformat},cache=none \
    -device vfio-pci,host=0002:00:00.0,id=hostpci0 \
    -device zpci,uid=0,fid=0,target=hostpci0,id=zpci0 \
    -D ${logfile}
fi

### run VM  ### {{{

if [[ ${action} == run ]]; then
${qemu} -machine s390-ccw-virtio \
    -cpu max,zpci=on,msa5-base=off \
    -serial telnet::4441,server \
    -display none \
    -m ${mem} \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-net-dev \
    -device virtio-net-ccw,netdev=tap-net-dev,id=virtio-net0 \
    -drive file=${disk},if=none,id=drive-virtio-disk0,format=${diskformat},cache=none \
    -device virtio-blk-ccw,devno=fe.0.0001,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 \
    -D ${logfile}
#    -device vfio-pci,host=0003:00:00.0,id=hostpci0 \
#    -device zpci,uid=0,fid=0,target=hostpci0,id=zpci0 \
fi

### end run VM  ### }}}

### alternate/optional args ### {{{
#
## network ## {{{
#
# -netdev bridge,id=bridge-net-dev \
# -device virtio-net-ccw,netdev=bridge-net-dev,id=virtio-net0 \
#
## end network ## }}}
#
## boot files ## {{{
#
# -kernel ${distdir}/${version}/boot/kernel.${distro} \
# -initrd ${distdir}/${version}/boot/initrd.${distro} \
#
# end boot files ## }}}
#
## disk ## {{{
#
# -drive file=${disk},if=none,id=drive-virtio-disk0,format=${diskformat},cache=none \
# -device virtio-blk-ccw,devno=fe.0.0001,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1,scsi=off
#
## disk ## }}}
#
### end alternate/optional args ### }}}
