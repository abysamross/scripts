#!/bin/bash

arch=$1
action=$2
distro=$3
version=$4
flavor=$5
diskformat=$6
disknum=$7
mem=$8

# qemu=${HOME}/source/qemu/build/qemu-system-${arch}
qemu=qemu-system-${arch}

distdir=${HOME}/distros/arch/${arch}/${distro}
isodir=${distdir}/${version}/iso
isoname=${distro}-${version}-${flavor}-${arch}.iso
iso=${isodir}/${isoname}
diskdir=${HOME}/vmdisks
diskname=${distro}-${version}-${flavor}-${arch}-disk-${disknum}.${diskformat}
disk=${diskdir}/${diskname}
logdir=${HOME}/logs/qemu/${action}
logfile=${logdir}/${distro}-${version}-${flavor}-${arch}.log

# TODO: create vmdisk if file doesn't exist.

if [[ ! -f ${logfile} ]]; then
    touch ${logfile}
fi

if [[ ${action} == live ]]; then
${qemu} -machine s390-ccw-virtio \
    -cpu max,zpci=on,msa5-base=on \
    -serial telnet::4441,server \
    -display none \
    -m ${mem} \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-netdev \
    -device virtio-net-ccw,netdev=tap-netdev,id=tap-virtio-net-ccw0 \
    --cdrom ${iso} \
    -D ${logfile}
fi

### install VM ### {{{

if [[ ${action} == install ]]; then
${qemu} -machine s390-ccw-virtio \
    -cpu max,zpci=on,msa5-base=on \
    -serial telnet::4441,server \
    -display none \
    -m ${mem} \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-netdev \
    -device virtio-net-ccw,netdev=tap-netdev,id=tap-virtio-net-ccw0 \
    --cdrom ${iso} \
    -drive file=${disk},if=none,id=qcow2-drive,format=${diskformat},cache=none \
    -device virtio-blk-ccw,devno=fe.0.0001,drive=qcow2-drive,id=qcow2-virtio-blk-ccw0 \
    -D ${logfile}
fi

### end install VM ### }}}

### run VM  ### {{{

if [[ ${action} == run ]]; then
${qemu} -machine s390-ccw-virtio \
    -cpu max,zpci=on,msa5-base=on \
    -serial telnet::4441,server \
    -display none \
    -m ${mem} \
    -netdev tap,helper=/usr/local/libexec/qemu-bridge-helper,id=tap-netdev \
    -device virtio-net-ccw,netdev=tap-netdev,id=tap-virtio-net-ccw0 \
    --cdrom ${iso} \
    -drive file=${disk},if=none,id=qcow2-drive,format=${diskformat},cache=none \
    -device virtio-blk-ccw,devno=fe.0.0001,drive=qcow2-drive,id=qcow2-virtio-blk-ccw0,bootindex=1 \
    -D ${logfile}
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
## pci ## {{{
#
#    -device vfio-pci,host=0002:00:00.0,id=hostpci0 \
#    -device zpci,uid=0,fid=0,target=hostpci0,id=zpci0 \
#
# pci ## }}}
#
### end alternate/optional args ### }}}
