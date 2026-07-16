#!/bin/sh
# Cara pakai:
#   cd /path/ke/xuping-scanner
#   sh fix_back_button.sh
#
# Backup otomatis dibuat dulu sebagai www/index.html.bak
# Setelah jalan, cek hasilnya dengan: git diff www/index.html
# Kalau ada yang aneh, batalkan dengan: git checkout -- www/index.html

set -e
FILE="www/index.html"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi

cp "$FILE" "$FILE.bak"
echo "Backup dibuat: $FILE.bak"

# 1) Tambah tombol "Kembali ke daftar" di result card
sed -i '/<div id="resultCard" class="result-card">/a\
      <button class="btn btn-outline" id="btnBackToList" style="display:none; width:100%; justify-content:center; margin-bottom:12px;">\&larr; Kembali ke daftar</button>' "$FILE"

# 2) Deklarasi elBtnBack + lastMultiContext sebelum showSingleResult
sed -i '/function showSingleResult(item, ref){/i\
  var elBtnBack = document.getElementById("btnBackToList");\
  var lastMultiContext = null;\
' "$FILE"

# 3) Update tampilan tombol back di akhir showSingleResult (setelah currentShareItem = item;)
sed -i "/currentShareItem = item;/a\\
\\
    if (lastMultiContext) {\\
      elBtnBack.style.display = 'flex';\\
      elBtnBack.textContent = '\\\\u2190 Kembali ke daftar (' + lastMultiContext.list.length + ' hasil)';\\
    } else {\\
      elBtnBack.style.display = 'none';\\
    }" "$FILE"

# 4) Tambah event listener tombol back sebelum showMultiResult didefinisikan
sed -i '/function showMultiResult(list, ref){/i\
  elBtnBack.addEventListener("click", function () {\
    if (lastMultiContext) showMultiResult(lastMultiContext.list, lastMultiContext.ref);\
  });\
' "$FILE"

# 5) Sembunyikan tombol back tiap kali showMultiResult dipanggil ulang
sed -i '/function showMultiResult(list, ref){/a\
    elBtnBack.style.display = "none";' "$FILE"

# 6) Reset tombol back + lastMultiContext saat clearResult
sed -i '/function clearResult(){/a\
    elBtnBack.style.display = "none";\
    lastMultiContext = null;' "$FILE"

# 7) Simpan konteks daftar multi-hasil di doLookup
sed -i '/if (list.length === 1){/a\
        lastMultiContext = null;' "$FILE"

sed -i '/showMultiResult(list, refCode);/i\
        lastMultiContext = { list: list, ref: refCode };' "$FILE"

echo "Selesai. Cek hasilnya dengan: git diff www/index.html"
