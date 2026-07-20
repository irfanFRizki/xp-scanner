#!/bin/sh
# Cara pakai:
#   1. Taruh 3 file ini di folder yang SAMA: fix_auto_download_update.sh,
#      newblock_var.txt, newblock_main.txt
#   2. cd /path/ke/xuping-scanner
#   3. sh fix_auto_download_update.sh
#
# Backup otomatis: www/index.html.bak4
# Cek hasil: git diff www/index.html
# Batalkan: git checkout -- www/index.html

set -e
FILE="www/index.html"
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi
if [ ! -f "$DIR/newblock_var.txt" ] || [ ! -f "$DIR/newblock_main.txt" ]; then
  echo "File newblock_var.txt / newblock_main.txt tidak ditemukan di folder yang sama dengan script ini."
  exit 1
fi

if grep -q "autoDownloadUpdate" "$FILE"; then
  echo "Sudah pernah dipatch sebelumnya, tidak ada perubahan."
  exit 0
fi

cp "$FILE" "$FILE.bak4"
echo "Backup dibuat: $FILE.bak4"

# 1) Ganti baris deklarasi variabel banner (range 1 baris start s.d. 1 baris
#    end yang sama persis -> baca ganti dari newblock_var.txt)
sed -i "/var elUpdateBanner = \$('updateBanner');/,/var latestVersionInfo = null; \/\/ { tag, apkUrl }/{
  /var elUpdateBanner = \$('updateBanner');/{
    r $DIR/newblock_var.txt
  }
  d
}" "$FILE"

# 2) Ganti seluruh blok fungsi (showUpdateBanner ... event bindings) dengan
#    isi newblock_main.txt
sed -i "/  function showUpdateBanner(tag){/,/\$('btnCheckUpdate').addEventListener('click', function(){ checkForUpdate(false); });/{
  /  function showUpdateBanner(tag){/{
    r $DIR/newblock_main.txt
  }
  d
}" "$FILE"

echo "Selesai. Cek hasilnya dengan: git diff www/index.html"
