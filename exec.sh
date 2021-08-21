#!/bin/bash
echo "Staring container"
unshare --fork --user --map-root-user --net --mount ./lib/entrypoint.sh &
sleep 1

echo "Starting slirp4netns"
slirp4netns --configure --disable-host-loopback --mtu=65520 $(cat ns-pid) --api-socket "slirp4netns.sock" tap-slirp &

sleep 5

echo "Configure port forwarding"
json='{"execute": "add_hostfwd", "arguments": {"proto": "tcp", "host_addr": "127.0.0.1", "host_port": 8081, "guest_port": 8081}}'
echo -n $json | nc -U slirp4netns.sock
