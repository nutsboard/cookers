TOP="${PWD}"
PATH_KERNEL="${PWD}/linux-imx"
PATH_UBOOT="${PWD}/uboot-imx"
LINUX_ROOTFS=lede-omap-default-rootfs.tar.gz

export PATH="${PATH_UBOOT}/tools:${PATH}"
export ARCH=arm
export CROSS_COMPILE="${PWD}/toolchain/bin/arm-linux-gnueabihf-"

# TARGET support: nutsboard pistachio series
IMX_PATH="./mnt"
MODULE=$(basename $BASH_SOURCE)
CPU_TYPE=$(echo $MODULE | awk -F. '{print $3}')
CPU_MODULE=$(echo $MODULE | awk -F. '{print $4}')
DISPLAY=$(echo $MODULE | awk -F. '{print $5}')


if [[ "$CPU_TYPE" == "nutsboard" ]]; then
    if [[ "$CPU_MODULE" == "pistachio" ]]; then
        UBOOT_CONFIG='mx6_pistachio_defconfig'
        KERNEL_IMAGE='zImage'
        KERNEL_CONFIG='nutsboard_imx_defconfig'
        DTB_TARGET='imx6q-pistachio.dtb'
    elif [[ "$CPU_MODULE" == "pistachio-lite" ]]; then
        UBOOT_CONFIG='mx6_pistachio-lite_defconfig'
        KERNEL_IMAGE='zImage'
        KERNEL_CONFIG='nutsboard_imx_defconfig'
        DTB_TARGET='imx6q-pistachio-lite.dtb'
    fi
fi

recipe() {
    local TMP_PWD="${PWD}"

    case "${PWD}" in
        "${PATH_KERNEL}"*)
            cd "${PATH_KERNEL}"
            make "$@" menuconfig || return $?
            ;;
        *)
            echo -e "Error: outside the project" >&2
            return 1
            ;;
    esac

    cd "${TMP_PWD}"
}

heat() {
    local TMP_PWD="${PWD}"
    case "${PWD}" in
        "${TOP}")
            cd "${TMP_PWD}"
            cd ${PATH_UBOOT} && heat "$@" || return $?
            cd ${PATH_KERNEL} && heat "$@" || return $?
            cd "${TMP_PWD}"
            ;;
        "${PATH_KERNEL}"*)
            cd "${PATH_KERNEL}"
            make "$@" $KERNEL_IMAGE || return $?
            make "$@" modules || return $?
            make "$@" $DTB_TARGET || return $?
            rm -rf ./modules
            make modules_install INSTALL_MOD_PATH=./modules/
            ;;
        "${PATH_UBOOT}"*)
            cd "${PATH_UBOOT}"
            make "$@" || return $?
            ;;
        *)
            echo -e "Error: outside the project" >&2
            return 1
            ;;
    esac

    cd "${TMP_PWD}"
}

cook() {
    local TMP_PWD="${PWD}"

    case "${PWD}" in
        "${TOP}")
            cd ${PATH_UBOOT} && cook "$@" || return $?
            cd ${PATH_KERNEL} && cook "$@" || return $?
            ;;
        "${PATH_KERNEL}"*)
            cd "${PATH_KERNEL}"
            make "$@" $KERNEL_CONFIG || return $?
            heat "$@" || return $?
            ;;
        "${PATH_UBOOT}"*)
            cd "${PATH_UBOOT}"
            make "$@" $UBOOT_CONFIG || return $?
            heat "$@" || return $?
            ;;
        *)
            echo -e "Error: outside the project" >&2
            return 1
            ;;
    esac

    cd "${TMP_PWD}"
}

throw() {
    local TMP_PWD="${PWD}"

    case "${PWD}" in
        "${TOP}")
            rm -rf out
            cd ${PATH_UBOOT} && throw "$@" || return $?
            cd ${PATH_KERNEL} && throw "$@" || return $?
            ;;
        "${PATH_KERNEL}"*)
            cd "${PATH_KERNEL}"
            make "$@" distclean || return $?
            ;;
        "${PATH_UBOOT}"*)
            cd "${PATH_UBOOT}"
            make "$@" distclean || return $?
            ;;
        *)
            echo -e "Error: outside the project" >&2
            return 1
            ;;
    esac

    cd "${TMP_PWD}"
}

flashcard() {
  local TMP_PWD="${PWD}"

  cd "${TOP}"
  sudo -E cookers/flashcard "$@" $CPU_MODULE
  cd "${TMP_PWD}"
}


