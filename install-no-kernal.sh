#!/bin/bash -e
# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Run within rescue mode on Linode to install ZeroShell:
# - First drive would be used for ZeroShell, 1GB required
# - Second drive would be used for temp files, 4GB required

ZEROSHELL="3.6.0"
KERNEL="4.6.5"

ZEROSHELL_DISK="/media/sda"
INSTALL_DISK="/media/sdb"
LOG="$INSTALL_DISK/install.log"
ISO_DISK="/media/iso"

KERNEL_FOLDER="linux-$KERNEL"
KERNEL_FILE="$KERNEL_FOLDER.tar.gz"
KERNEL_URL="http://www.kernel.org/pub/linux/kernel/v4.x/$KERNEL_FILE"
KERNEL_CONFIG=".config"
KERNEL_ZEROSHELL_CONFIG="zeroshell.kernel.config"

ISO_FILE="ZeroShell-$ZEROSHELL.iso"
ISO_URL="http://www.zeroshell.net/listing/$ISO_FILE"

# Useful scripts to show progress, not portable to other scrips
echo "Starting $ISO_FILE installation" | tee "$LOG"
function rsync_progress() {
  DESCRIPTION="$1"
  FROM="$2"
  TO="$3"
  LINES="$(find "$FROM" | wc --lines)"

  echo | tee --append "$LOG"
  echo "$DESCRIPTION" | tee --append "$LOG"
  rsync --archive "$FROM" "$TO" | pv --line-mode --size "$LINES" >> "$LOG"
}
function untar_progress() {
  DESCRIPTION="$1"
  FILE="$2"

  echo | tee --append "$LOG"
  echo "$DESCRIPTION" | tee --append "$LOG"
  pv "$FILE" | tar --extract --keep-old-files --gunzip --file - >> "$LOG"
}

echo "Make sure that both disks are mounted" | tee --append "$LOG"
mountpoint "$ZEROSHELL_DISK" || mount "$ZEROSHELL_DISK" >> "$LOG"
mountpoint "$INSTALL_DISK" || mount "$INSTALL_DISK" >> "$LOG"

rsync_progress "Save all the installation files for later reuse" \
"./" "$INSTALL_DISK"

echo "Download live CD, continue previous download" | tee --append "$LOG"
cd "$INSTALL_DISK"
wget --no-check-certificate --continue "$ISO_URL"

echo "Mount as read-only partition" | tee --append "$LOG"
mountpoint "$ISO_DISK" || (mkdir "$ISO_DISK" && mount "$ISO_FILE" "$ISO_DISK") >> "$LOG"

cd "$ZEROSHELL_DISK"
untar_progress "Unpack root parition" "$ISO_DISK/isolinux/rootfs"

rsync_progress "Unpack the rest of cdrom into rw partition" \
"$ISO_DISK/" "$ZEROSHELL_DISK/cdrom/"
