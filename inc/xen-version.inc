
################################################################################
# Following inc file defines XEN version and needed glue info to get it
# built with the current yocto version
################################################################################
require ../meta-xt-images-domx/recipes-extended/xen/xen-4.13-thud.inc

SRC_URI = "git://github.com/xen-troops/xen.git;protocol=https;branch=xen-4.13rc-migration"
SRCREV = "d5c4a329eb1f0225e046695b8c247517bbbd41b4"
