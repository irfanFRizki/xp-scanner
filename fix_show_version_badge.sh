#!/bin/sh
# Cara pakai:
#   cd /path/ke/xuping-scanner
#   sh fix_show_version_badge.sh
#
# Backup otomatis dibuat sebagai www/index.html.bak3
# Cek hasilnya: git diff www/index.html
# Batalkan kalau perlu: git checkout -- www/index.html

set -e
FILE="www/index.html"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi

if grep -q "appVersionBadge" "$FILE"; then
  echo "Sudah pernah dipatch sebelumnya, tidak ada perubahan."
  exit 0
fi

cp "$FILE" "$FILE.bak3"
echo "Backup dibuat: $FILE.bak3"

# 1) Tambah badge versi kecil di bawah judul header (selalu terlihat)
sed -i 's|<h1>XUPING <span>SCANNER</span></h1>|<h1>XUPING <span>SCANNER</span> <span id="appVersionBadge" style="font-size:10px; color:var(--text-muted); font-weight:400; -webkit-text-fill-color:var(--text-muted); text-shadow:none;"></span></h1>|' "$FILE"

# 2) Isi teks badge itu begitu app dibuka
sed -i "/if (!getGasUrl()) openSettings();/i\\
  var elVersionBadge = document.getElementById('appVersionBadge');\\
  if (elVersionBadge) elVersionBadge.textContent = 'v' + APP_VERSION;\\
" "$FILE"

echo "Selesai. Cek hasilnya dengan: git diff www/index.html"
