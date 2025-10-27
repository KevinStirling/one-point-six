#!/bin/bash
set -e

# === TODO ===
# === Provide README info on how to run this script ===
# === Add flag to point to a target dir for the install ===
# === Add flag / option for pre-isntalled matchbot mod, etc. ===

# === CONFIG ===
BASE_DIR="$(pwd)"
INSTALL_DIR="$BASE_DIR/cs16"
STEAMCMD_DIR="$BASE_DIR/steamcmd"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

mkdir -p "$STEAMCMD_DIR" "$INSTALL_DIR"
cd "$STEAMCMD_DIR"

echo "[*] Installing SteamCMD into $STEAMCMD_DIR..."
wget -qO steamcmd_linux.tar.gz "$STEAMCMD_URL"
tar -xzf steamcmd_linux.tar.gz

echo "[*] Installing CS 1.6 from steam_legacy branch into $INSTALL_DIR..."
./steamcmd.sh +force_install_dir "$INSTALL_DIR" \
  +login anonymous \
  +app_set_config 90 mod cstrike \
  +app_update 90 -beta steam_legacy validate \
  +quit

cd "$INSTALL_DIR"

# === ReHLDS ===
echo "[*] Downloading ReHLDS release 3.14.0.857..."
REHLDS_URL="https://github.com/rehlds/ReHLDS/releases/download/3.14.0.857/rehlds-bin-3.14.0.857.zip"
curl -sL "$REHLDS_URL" -o rehlds.zip
unzip -o rehlds.zip -d rehlds_tmp
cp -r rehlds_tmp/* ./
rm -rf rehlds_tmp rehlds.zip

# === ReGameDLL_CS ===
echo "[*] Downloading ReGameDLL_CS release 5.28.0.756..."
REGAMEDLL_URL="https://github.com/rehlds/ReGameDLL_CS/releases/download/5.28.0.756/regamedll-bin-5.28.0.756.zip"
curl -sL "$REGAMEDLL_URL" -o regamedll.zip
mkdir -p cstrike/dlls
unzip -o regamedll.zip -d regamedll_tmp
cp regamedll_tmp/*.so cstrike/dlls/
rm -rf regamedll_tmp regamedll.zip

# === Metamod-r ===
echo "[*] Downloading Metamod-r release 1.3.0.149..."
METAMOD_URL="https://github.com/rehlds/Metamod-R/releases/download/1.3.0.149/metamod-bin-1.3.0.149.zip"
curl -sL "$METAMOD_URL" -o metamod.zip
mkdir -p cstrike/addons/metamod/dlls
unzip -o metamod.zip -d metamod_tmp
cp metamod_tmp/metamod_i386.so cstrike/addons/metamod/dlls/metamod.so
rm -rf metamod_tmp metamod.zip

# === MatchBot ===
echo "[*] Downloading MatchBot..."
MATCHBOT_URL="https://github.com/SmileYzn/MatchBot/releases/download/1.0.4/linux32.zip"
curl -sL "$MATCHBOT_URL" -o matchbot.zip
unzip -o matchbot.zip -d matchbot_tmp
cp -r matchbot_tmp/* cstrike/
rm -rf matchbot_tmp matchbot.zip

# Ensure plugins.ini exists and add MatchBot plugin
mkdir -p cstrike/addons/metamod
if [ ! -f cstrike/addons/metamod/plugins.ini ]; then
  echo "" > cstrike/addons/metamod/plugins.ini
fi
echo "linux addons/matchbot/dlls/matchbot_mm_i386.so" >> cstrike/addons/metamod/plugins.ini

# === liblist.gam update ===
echo "[*] Updating liblist.gam with Metamod path..."
LIBLIST_PATH="$INSTALL_DIR/cstrike/liblist.gam"
TMP_LIBLIST="$(mktemp)"

mkdir -p "$(dirname "$LIBLIST_PATH")"
touch "$LIBLIST_PATH"

FOUND=0
while IFS= read -r line || [ -n "$line" ]; do
  clean_line="${line//$'\r'/}"
  if [[ "$clean_line" =~ ^[[:space:]]*gamedll_linux ]]; then
    echo 'gamedll_linux "addons/metamod/dlls/metamod.so"' >> "$TMP_LIBLIST"
    FOUND=1
    echo "[DEBUG] replaced: $clean_line"
    continue
  fi
  echo "$clean_line" >> "$TMP_LIBLIST"
  echo "[DEBUG] wrote: $clean_line"
done < "$LIBLIST_PATH"

if [ $FOUND -eq 0 ]; then
  echo 'gamedll_linux "addons/metamod/dlls/metamod.so"' >> "$TMP_LIBLIST"
fi

mv "$TMP_LIBLIST" "$LIBLIST_PATH"

# === Copy Steam SDK for plugin support ===
echo "[*] Copying steamclient.so to SDK32 mount point..."
mkdir -p "$BASE_DIR/sdk32"
cp "$STEAMCMD_DIR/linux32/steamclient.so" "$BASE_DIR/sdk32/"

echo "[✔] All done. Your CS 1.6 server is installed at: $INSTALL_DIR"
