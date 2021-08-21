#!/bin/bash
HOST_TAP_IP="192.168.1.1"
VM_IP="192.168.1.128"
VM_DISK="android.img"

sysctl -w net.ipv4.ip_forward=1
echo $$ > ns-pid
mount -t tmpfs tmpfs /run

echo "Creating VM tap device"
ip tuntap add dev tap-vm mode tap
ip addr add dev tap-vm "$HOST_TAP_IP/24"
ip addr add dev lo "127.0.0.1/8"
ip link set dev tap-vm up

echo "Configuring NAT"
sleep 2

iptables -t nat -A POSTROUTING -o tap-slirp -j MASQUERADE
iptables -t nat -A PREROUTING -s "$VM_IP" -p tcp --dport 80 -j DNAT --to-destination "$HOST_TAP_IP:8080"
iptables -t nat -A PREROUTING -s "$VM_IP" -p tcp --dport 443 -j DNAT --to-destination "$HOST_TAP_IP:8080"

iptables -t nat -L
ip addr
ip route

echo "Staring proxy"
mitmweb --mode transparent --showhost --web-host 0.0.0.0 --no-web-open-browser &

echo "Starting VM"
# https://github.com/rexim/qemu-android-x86-runner
qemu-system-x86_64 -enable-kvm -vga std \
  -m 2048 -smp 2 -cpu host \
  -net nic,macaddr="DE:AD:BE:EF:A0:BA",model=virtio \
  -nic tap,ifname=tap-vm,script=no,downscript=no \
  -hda "$VM_DISK" \
  -monitor stdio

