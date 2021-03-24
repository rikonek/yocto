FILESEXTRAPATHS_prepend := "${THISDIR}/linux-firmware:"

SRC_URI += "file://brcmfmac43430-sdio.raspberrypi,model-zero-w.txt"

do_install_append () {
    install -m 0644 ${WORKDIR}/brcmfmac43430-sdio.raspberrypi,model-zero-w.txt ${D}/lib/firmware/brcm/brcmfmac43430-sdio.raspberrypi,model-zero-w.txt
}

# NOTE: Use "=+" instead of "+=". Otherwise, the file is placed into the linux-firmware package.
PACKAGES =+ "${PN}-brcm43430rpi0w"

FILES_${PN}-brcm43430rpi0w = "/lib/firmware/brcm/brcmfmac43430-sdio.raspberrypi,model-zero-w.txt"
