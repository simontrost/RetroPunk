#!/bin/bash
# RetroPunk - GRUB2 Theme Installer
# inspired by Vimix install.sh

ROOT_UID=0
THEME_DIR="/usr/share/grub/themes"
THEME_NAME="RetroPunk"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${THEME_NAME}"

MAX_DELAY=20

# COLORS
CDEF=" \033[0m"
CCIN=" \033[0;36m"
CGSC=" \033[0;32m"
CRER=" \033[0;31m"
CWAR=" \033[0;33m"
b_CDEF=" \033[1;37m"
b_CCIN=" \033[1;36m"
b_CGSC=" \033[1;32m"
b_CRER=" \033[1;31m"
b_CWAR=" \033[1;33m"

prompt () {
  case ${1} in
    "-s"|"--success") echo -e "${b_CGSC}${@/-s/}${CDEF}";;
    "-e"|"--error")   echo -e "${b_CRER}${@/-e/}${CDEF}";;
    "-w"|"--warning") echo -e "${b_CWAR}${@/-w/}${CDEF}";;
    "-i"|"--info")    echo -e "${b_CCIN}${@/-i/}${CDEF}";;
    *) echo -e "$@";;
  esac
}

has_command() { command -v "$1" >/dev/null 2>&1; }

show_usage() {
  cat <<EOF
Usage: sudo ./install.sh [--install] [--remove]
  --install   Install and set ${THEME_NAME} as the default GRUB theme.
  --remove    Remove ${THEME_NAME} and restore GRUB default (backup is kept).
If no parameter is given, --install is used.
Expected structure: ${THEME_NAME}/(theme.txt, background.png, *.pf2, LICENSE)
EOF
}

ACTION="install"
[[ "$1" == "--remove" ]] && ACTION="remove"
[[ "$1" == "-h" || "$1" == "--help" ]] && { show_usage; exit 0; }

prompt -s "\n\t****************************\n\t*  ${THEME_NAME} - GRUB2 Theme  *\n\t****************************"

prompt -w "\nChecking for root access...\n"

if [ "$UID" -ne "$ROOT_UID" ]; then
  prompt -e "\n [ Error ] -> Please run this script as root (sudo)."
  read -p "[ trusted ] Enter root password: " -t${MAX_DELAY} -s
  [[ -n "$REPLY" ]] && {
    echo
    sudo -S <<< "$REPLY" "$0" "$1"
    exit $?
  } || {
    prompt "\n Operation canceled. Bye."
    exit 1
  }
fi

GRUB_DEFAULT_FILE="/etc/default/grub"
GRUB_DEFAULT_BAK="/etc/default/grub.bak"
TARGET_DIR="${THEME_DIR}/${THEME_NAME}"

if [[ "$ACTION" == "remove" ]]; then
  prompt -i "\nRemoving ${THEME_NAME}...\n"

  if [[ -d "${TARGET_DIR}" ]]; then
    rm -rf "${TARGET_DIR}"
    prompt -s "Theme folder deleted: ${TARGET_DIR}"
  else
    prompt -w "Theme folder not found: ${TARGET_DIR}"
  fi

  if grep -q '^GRUB_THEME=' "${GRUB_DEFAULT_FILE}"; then
    cp -an "${GRUB_DEFAULT_FILE}" "${GRUB_DEFAULT_BAK}"
    sed -i '/^GRUB_THEME=/d' "${GRUB_DEFAULT_FILE}"
    prompt -s "Removed GRUB_THEME entry (backup created: ${GRUB_DEFAULT_BAK})"
  else
    prompt -i "No GRUB_THEME entry found."
  fi

  prompt -i "Updating GRUB configuration..."
  if has_command update-grub; then
    update-grub
  elif has_command grub-mkconfig; then
    grub-mkconfig -o /boot/grub/grub.cfg
  elif has_command grub2-mkconfig; then
    if has_command zypper; then
      grub2-mkconfig -o /boot/grub2/grub.cfg
    elif has_command dnf; then
      grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    fi
  fi

  prompt -s "\n\t          ***************\n\t          *  All done!  *\n\t          ***************\n"
  exit 0
fi

# --- INSTALL ---

prompt -i "\nChecking source files...\n"
if [[ ! -d "${SRC_DIR}" ]]; then
  prompt -e "Source folder not found: ${SRC_DIR}"
  show_usage
  exit 1
fi

required_files=( "theme.txt" "background.png" )
missing=0
for f in "${required_files[@]}"; do
  if [[ ! -f "${SRC_DIR}/${f}" ]]; then
    prompt -e "Missing: ${f}"
    missing=1
  fi
done

if ! ls "${SRC_DIR}"/*.pf2 >/dev/null 2>&1; then
  prompt -w "Note: No .pf2 font found in ${SRC_DIR}. (theme.txt references a pixel font.)"
fi
[[ $missing -eq 1 ]] && { prompt -e "Required files missing. Aborting."; exit 1; }

prompt -i "\nPreparing theme directory...\n"
[[ -d "${TARGET_DIR}" ]] && rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

prompt -i "Installing ${THEME_NAME} into ${TARGET_DIR}...\n"
cp -a "${SRC_DIR}/." "${TARGET_DIR}/"

prompt -i "\nSetting ${THEME_NAME} as default theme...\n"
cp -an "${GRUB_DEFAULT_FILE}" "${GRUB_DEFAULT_BAK}"
grep -q '^GRUB_THEME=' "${GRUB_DEFAULT_FILE}" && sed -i '/^GRUB_THEME=/d' "${GRUB_DEFAULT_FILE}"
echo "GRUB_THEME=\"${TARGET_DIR}/theme.txt\"" >> "${GRUB_DEFAULT_FILE}"
prompt -s "GRUB_THEME set in ${GRUB_DEFAULT_FILE} (backup: ${GRUB_DEFAULT_BAK})"

prompt -i "Updating GRUB configuration..."
if has_command update-grub; then
  update-grub
elif has_command grub-mkconfig; then
  grub-mkconfig -o /boot/grub/grub.cfg
elif has_command grub2-mkconfig; then
  if has_command zypper; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
  elif has_command dnf; then
    grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
  fi
fi

prompt -s "\n\t          ***************\n\t          *  All done!  *\n\t          ***************\n"

