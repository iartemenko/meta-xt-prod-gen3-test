FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend := "${THISDIR}/../../inc:"
FILESEXTRAPATHS_prepend := "${THISDIR}/../../recipes-domx:"

SRC_URI = " \
    repo://github.com/xen-troops/manifests;protocol=https;branch=master;manifest=prod_gen3_test/domd.xml;scmdata=keep \
"

XT_QUIRK_UNPACK_SRC_URI += " \
    file://meta-xt-prod-extra;subdir=repo \
    file://meta-xt-prod-vgpu;subdir=repo \
    file://xt_shared_env.inc;subdir=repo/meta-xt-prod-extra/inc \
"

XT_QUIRK_BB_ADD_LAYER += " \
    meta-xt-prod-extra \
    meta-xt-prod-vgpu \
    meta-clang \
"

XT_BB_IMAGE_TARGET = "core-image-weston"

SRC_URI_append = " \
    git://github.com/kraj/meta-clang.git;destsuffix=repo/meta-clang;branch=krogoth \
"

################################################################################
# Renesas R-Car
################################################################################

XT_QUIRK_PATCH_SRC_URI_rcar = "\
    file://${S}/meta-renesas/meta-rcar-gen3/docs/sample/patch/patch-for-linaro-gcc/0001-rcar-gen3-add-readme-for-building-with-Linaro-Gcc.patch;patchdir=meta-renesas \
"

XT_BB_LOCAL_CONF_FILE_rcar = "meta-xt-prod-extra/doc/local.conf.rcar-domd-image-weston"
XT_BB_LAYERS_FILE_rcar = "meta-xt-prod-extra/doc/bblayers.conf.rcar-domd-image-weston"

# Path to proprietary graphic modules pre built binaries.
# Uncomment line below and set proper path.
#XT_RCAR_EVAPROPRIETARY_DIR = ""

GLES_VERSION_rcar = "1.9"

configure_versions_rcar() {
    local local_conf="${S}/build/conf/local.conf"

    cd ${S}
    base_update_conf_value ${local_conf} PREFERRED_VERSION_xen "4.10.0+git\%"
    base_update_conf_value ${local_conf} PREFERRED_VERSION_u-boot_rcar "v2015.04\%"
    if [ -z ${XT_RCAR_EVAPROPRIETARY_DIR} ];then
        base_update_conf_value ${local_conf} PREFERRED_VERSION_gles-user-module ${GLES_VERSION}
        base_update_conf_value ${local_conf} PREFERRED_VERSION_gles-kernel-module ${GLES_VERSION}
        base_update_conf_value ${local_conf} PREFERRED_VERSION_gles-module-egl-headers ${GLES_VERSION}
    else
        base_update_conf_value ${local_conf} PREFERRED_PROVIDER_virtual/libgles2 "rcar-proprietary-graphic"
        base_update_conf_value ${local_conf} PREFERRED_PROVIDER_virtual/egl "rcar-proprietary-graphic"
        base_set_conf_value ${local_conf} PREFERRED_PROVIDER_kernel-module-pvrsrvkm "rcar-proprietary-graphic"
        base_set_conf_value ${local_conf} PREFERRED_PROVIDER_kernel-module-dc-linuxfb "rcar-proprietary-graphic"
        base_set_conf_value ${local_conf} PREFERRED_PROVIDER_kernel-module-gles "rcar-proprietary-graphic"
        base_set_conf_value ${local_conf} PREFERRED_PROVIDER_gles-user-module "rcar-proprietary-graphic"
        base_add_conf_value ${local_conf} BBMASK "meta-xt-images-vgpu/recipes-graphics/gles-module/"
        base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-extra/recipes-graphics/gles-module/"
        base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-vgpu/recipes-graphics/gles-module/"
        base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-vgpu/recipes-graphics/mesa/"
        base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-vgpu/recipes-graphics/wayland/"
        base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-vgpu/recipes-kernel/kernel-module-gles/"
        base_add_conf_value ${local_conf} BBMASK "meta-renesas/meta-rcar-gen3/recipes-kernel/kernel-module-gles/"
        base_add_conf_value ${local_conf} BBMASK "meta-renesas/meta-rcar-gen3/recipes-graphics/gles-module/"
        xt_unpack_proprietary
    fi

    # HACK: force ipk instead of rpm b/c it makes troubles to PVR UM build otherwise
    base_update_conf_value ${local_conf} PACKAGE_CLASSES "package_ipk"

    # FIXME: normally bitbake fails with error if there are bbappends w/o recipes
    # which is the case for agl-demo-platform's recipe-platform while building
    # agl-image-weston: due to AGL's Yocto configuration recipe-platform is only
    # added to bblayers if building agl-demo-platform, thus making bitbake to
    # fail if this recipe is absent. Workaround this by allowing bbappends without
    # corresponding recipies.
    base_update_conf_value ${local_conf} BB_DANGLINGAPPENDS_WARNONLY "yes"

    # override console specified by default by the meta-rcar-gen3
    # to be hypervisor's one
    base_update_conf_value ${local_conf} SERIAL_CONSOLE "115200 hvc0"

    # set default timezone to Las Vegas
    base_update_conf_value ${local_conf} DEFAULT_TIMEZONE "US/Pacific"
}

python do_configure_append_rcar() {
    bb.build.exec_func("configure_versions_rcar", d)
}

do_install_append () {
    local LAYERDIR=${TOPDIR}/../meta-xt-prod-gen3-test
    find ${LAYERDIR}/doc -iname "u-boot-env*" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt \; || true
    find ${LAYERDIR}/doc -iname "mk_sdcard_image.sh" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt \; \
    -exec cp -f {} ${DEPLOY_DIR} \; || true
}