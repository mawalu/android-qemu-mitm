# QEMU, Android and mitmproxy template

A simple script that runs an Android-x86 QEMU VM within a network namespace and configures mitmproxy to inspect http(s) traffic. Usernamespaces are used, no root required.

## Requirements

 * QEMU
 * mitmproxy
 * slirp4netns

## Usage

Create a new Android-x86 image and complete the installer:

```bash
$ qemu-img create -f qcow2 "android.img" 4G
$ qemu-system-x86_64 -enable-kvm -vga std \
    -m 2048 -smp 2 -cpu host \
    -net nic,model=e1000 -net user \
    -cdrom "android-x68.iso" \
    -hda "android.img" \ # image name is currently hardcoded
    -boot d \
    -monitor stdio
```

Start the VM and the network namespace:

```bash
$ ./exec.sh
$ nsenter --preserve-credentials -U -m -n -t $(cat ns-pid) # enter the network ns 
$ adb connect 192.168.1.128 # ip also currently hardcoded
```

In the Android WIFI settings configure a static config. IP should be `192.168.1.128` and gateway `192.168.1.1`.

The mitmproxy webinterface can be reached at `http://localhost:8081` on the host.

## Intercepting https

In many cases Frida can be used to bypass cert verification in apps. I wrote a bit about this [here](https://snippets.martinwagner.co/2021-08-21/mitmproxy-qemu)
but searching for "Frida TLS bypass" should also yield good results.
