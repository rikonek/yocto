# Yocto + Raspberry PI

## Instalacja zależności

```bash
sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev xterm bmap-tools
```

## Pobranie Yocto i meta-raspberrypi

```bash
cd ~
git clone -b gatesgarth --depth=1 http://git.yoctoproject.org/git/poky
cd ~/poky
git clone -b gatesgarth --depth=1 git://git.yoctoproject.org/meta-raspberrypi
source oe-init-build-env
```

### Edycja konfiguracji

Edycja `~/poky/build/conf/bblayers.conf`
```bash
# ~/poky/build
bitbake-layers remove-layer ../meta-yocto-bsp #usunięcie meta-yocto-bsp, BSP dla Raspberry Pi znajduje się w meta-raspberrypi
bitbake-layers add-layer ../meta-raspberrypi #dodanie meta-raspberrypi
```

Dodajemy do konfiguracji następujące ustawienia
```bash
vim ~/poky/build/conf/local.conf
```
```diff
+MACHINE = "raspberrypi0-wifi"
+BB_NUMBER_THREADS = "4"
+PARALLEL_MAKE = "-j 4"
+ENABLE_UART = "1"
+INHERIT += "extrausers"
+EXTRA_USERS_PARAMS = "usermod -P nowe_haslo root;"
```
- MACHINE - Warianty RPI które można ustawić dostępne są w `~/poky/meta-raspberrypi/conf/machine`
- TMPDIR - folder dla plików tymczasowych
- DL_DIR - folder dla pobranych plików, jeżeli konfiguracja jest współdzielona na kilka projektów, dobrze jest utworzyć wspólny folder dla pobranych
- BB_NUMBER_THREADS, PARALLEL_MAKE - Ustawiamy ilość wątków wykorzystywanych do kompilacji
- ENABLE_UART - włączenie UART
- RPI_USE_U_BOOT - użycie bootloader'a u-boot
- INHERIT, EXTRA_USERS_PARAMS - zmiana hasla root

## Własna warstwa

Własne warstwy pozwalają na tworzenie różnych konfiguracji zawierających różne pakiety.

### Utworzenie

Tworzymy warstwę i dodajemy ją do `~/poky/build/conf/bblayers.conf`
```bash
# ~/poky/build
bitbake-layers create-layer ../meta-myrpi
bitbake-layers add-layer ../meta-myrpi
```

### Konfiguracja

Kreator utworzył plik konfiguracyjny w którym nie trzeba nic zmieniać.

```bash
vim ~/poky/meta-myrpi/conf/layer.conf
```
```diff
# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"

# We have recipes-* directories, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "meta-myrpi"
BBFILE_PATTERN_meta-myrpi = "^${LAYERDIR}/"
BBFILE_PRIORITY_meta-myrpi = "6"

LAYERDEPENDS_meta-myrpi = "core"
LAYERSERIES_COMPAT_meta-myrpi = "gatesgarth"
```
- BBPATH - dodaje bieżący katalog warstwy do BBPATH, który używany jest przez bitbake podczas kompilacji
- BBFILES - dodaje pliki do receptur podczas kompilacji
- LAYERSERIES_COMPAT_ - określa minimalną wersję poky z którą tworzona warstwa jest kompatybilna

### Receptury

#### Pakiety

```bash
mkdir -p ~/poky/meta-myrpi/recipes-core/images
vim ~/poky/meta-myrpi/recipes-core/images/myrpi-image.bb
```
```diff
+require recipes-core/images/core-image-minimal.bb
+
+IMAGE_INSTALL_append = " vim mc"
```

#### Interfejs

```bash
mkdir -p ~/poky/meta-myrpi/recipes-core/init-ifupdown/init-ifupdown-1.0
vim ~/poky/meta-myrpi/recipes-core/init-ifupdown/init-ifupdown_1.0.bbappend
```
```diff
+FILESEXTRAPATHS_prepend := "${THISDIR}:"
```

```vim
cp ~/poky/meta/recipes-core/init-ifupdown/init-ifupdown-1.0/interfaces ~/poky/meta-myrpi/recipes-core/init-ifupdown/interfaces
vim ~/poky/meta-myrpi/recipes-core/init-ifupdown/interfaces
```
```diff
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# Wireless interfaces
+auto wlan0
-iface wlan0 inet dhcp
+iface wlan0 inet static
+	address 192.168.0.200
+	netmask 255.255.255.0
+	network 192.168.0.0
+	gateway 192.168.0.1
	wireless_mode managed
	wireless_essid any
	wpa-driver wext
	wpa-conf /etc/wpa_supplicant.conf

iface atml0 inet dhcp

# Wired or wireless interfaces
auto eth0
iface eth0 inet dhcp
iface eth1 inet dhcp

# Ethernet/RNDIS gadget (g_ether)
# ... or on host side, usbnet and random hwaddr
iface usb0 inet static
	address 192.168.7.2
	netmask 255.255.255.0
	network 192.168.7.0
	gateway 192.168.7.1

# Bluetooth networking
iface bnep0 inet dhcp
```

```bash
mkdir -p ~/poky/meta-myrpi/recipes-connectivity/wpa-supplicant
vim ~/poky/meta-myrpi/recipes-connectivity/wpa-supplicant/wpa-supplicant_2.9.bbappend
```
```diff
+FILESEXTRAPATHS_prepend := "${THISDIR}:"
```

```bash
cp ~/poky/meta/recipes-connectivity/wpa-supplicant/wpa-supplicant/wpa_supplicant.conf-sane ~/poky/meta-myrpi/recipes-connectivity/wpa-supplicant/wpa_supplicant.conf-sane
vim ~/poky/meta-myrpi/recipes-connectivity/wpa-supplicant/wpa_supplicant.conf-sane
```
```diff
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1

network={
-        key_mgmt=NONE
+        ssid="nazwa_sieci"
+        psk="haslo"
}
```

## Warstwa z "Hello world"

### Utworzenie

Tworzymy warstwę i dodajemy ją do `~/poky/build/conf/bblayers.conf`
```bash
# ~/poky/build
bitbake-layers create-layer ../meta-helloworld
bitbake-layers add-layer ../meta-helloworld
```

### Konfiguracja

```bash
mkdir -p ~/poky/meta-helloworld/recipes-app/helloworld/files
vim ~/poky/meta-helloworld/recipes-app/helloworld/helloworld_1.0.bb
```
```diff
+DESCRIPTION = "Hello, World application"
+LICENSE = "MIT"
+LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
+S = "${WORKDIR}"
+SRC_URI = "file://helloworld.c"
+do_compile() {
+    ${CC} ${CFLAGS} ${LDFLAGS} helloworld.c -o helloworld
+}
+do_install() {
+    install -d ${D}${bindir}
+    install -m 0755 helloworld ${D}${bindir}
+}
```

- LIC_FILES_CHKSUM - Wskazuje na plik z folderu ~/poky/meta/files/common-licenses/
- S - Source dir

Wszystkie zadania (funkcje) opisane są na stronie https://www.yoctoproject.org/docs/latest/mega-manual/mega-manual.html#ref-tasks-build

- do_build - domyślne zadanie, wywołuje wszystkie zadania
- do_compile - kompiluje kod źródłowy, wykonuje się w folderze ${B}
- do_configure - konfiguruje źródła, wykonuje się w folderze ${B}
- do_fetch - pobiera źródła z SRC_URI do katalogu wskazywanego przez DL_DIR
- do_install - kopiuje pliki które mają trafić do pakietów do ${D}
- do_package - rozdziela pliki dostarczone ${D} na wiele pakietów
- do_patch - aplikuje patche

### Kod źródłowy

```bash
vim ~/poky/meta-helloworld/recipes-app/helloworld/files/helloworld.c
```
```diff
+#include <stdio.h>
+int main() {
+	printf("Hello, World! Yocto project\n");
+	return 0;
+}
```

### Dodanie programu do obrazu

```bash
vim ~/poky/meta-myrpi/recipes-core/images/myrpi-image.bb
```
```diff
+IMAGE_INSTALL_append = " helloworld"
```

## Kompilacja

```bash
cd ~/poky
source oe-init-build-env
bitbake myrpi-image
```

Pliki wynikowe znajdą się w `~/poky/build/tmp/deploy/images`

## Wgranie na kartę SD

Odmontować partycje karty SD
```bash
lsblk
umount /dev/mmcblk0p1
umount /dev/mmcblk0p2
```

Wgrać obraz na kartę SD
```bash
sudo bmaptool copy ~/poky/build/tmp/deploy/images/raspberrypi0-wifi/myrpi-image-raspberrypi0-wifi.wic.bz2 /dev/mmcblk0
```

## Różne polecenia

```bash
bitbake -c cleanall nazwa_pakietu #wyczyszczenie pakietu
bitbake -c devshell nazwa_pakietu #uruchomienie powłoki deweloperskiej
bitbake -c compile nazwa_pakietu #wykonanie zadania compile
bitbake -c populate_sdk core-image-base #budowanie SDK dla core-image-base
bitbake myrpi-image -e | grep ^IMAGE_INSTALL #sprawdzenie zmiennych do budowania
```
