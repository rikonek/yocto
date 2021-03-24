require recipes-core/images/core-image-minimal.bb

DISTRO_FEATURES_append = " wifi bluetooth bluez5"

IMAGE_INSTALL += " kernel-modules linux-firmware-brcm43430rpi0w"

IMAGE_INSTALL_append = " linux-firmware-bcm43430 wpa-supplicant"
IMAGE_INSTALL_append = " bluez5"

IMAGE_INSTALL_append = " vim mc helloworld"

