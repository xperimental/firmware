This is the router firmware for Freifunk Bielefeld.

Build Commands:

<pre>
svn co svn://svn.openwrt.org/openwrt/branches/attitude_adjustment openwrt
cd openwrt

./scripts/feeds update -a
./scripts/feeds install -a

./scripts/feeds uninstall kmod-batman-adv

git clone https://github.com/freifunk-bielefeld/firmware.git
cp -rf firmware/package/* package/
cp -rf firmware/files ./
rm -rf firmware

make defconfig
make menuconfig
</pre>

Now select the right Target System and Target Profile:
For the TL-WR841ND:
* Target System => Atheros AR7xxx/AR9xxx
* Target Profile => TP-LINK TL-WR841ND

For the DIR-300:
* Target System => <*> AR231x/AR5312
* Target Profile => <*> Default

Many other routers have not been tested yet
but may work. Give it a try! :-)

<pre>
make
</pre>

The firmware images are now in the "bin"-folder.
* Use "openwrt-[chip]-[model]-squashfs-firmware.bin" for the initial flash.
* Use "openwrt-[chip]-[model]-squashfs-sysupgrade.bin" for futher updates.