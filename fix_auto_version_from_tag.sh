#!/bin/sh
# Cara pakai:
#   cd /path/ke/xuping-scanner
#   sh fix_auto_version_from_tag.sh
#
# Backup otomatis dibuat sebagai .github/workflows/build-apk.yml.bak2
# Cek hasilnya: git diff .github/workflows/build-apk.yml
# Batalkan kalau perlu: git checkout -- .github/workflows/build-apk.yml

set -e
FILE=".github/workflows/build-apk.yml"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi

if grep -q "Set app version dari tag git" "$FILE"; then
  echo "Sudah pernah dipatch sebelumnya, tidak ada perubahan."
  exit 0
fi

cp "$FILE" "$FILE.bak2"
echo "Backup dibuat: $FILE.bak2"

# Sisipkan step ini SEBELUM "Sync Capacitor" — supaya APP_VERSION di
# www/index.html sudah benar sebelum di-copy ke aset Android. Cuma jalan
# kalau build dipicu oleh push tag versi (v1.2.3), sehingga versi yang
# tertanam di APK OTOMATIS sama persis dengan tag GitHub Release —
# tidak perlu lagi ingat-ingat naikkan APP_VERSION manual sebelum tag.
sed -i "/^      - name: Sync Capacitor$/i\\
      - name: Set app version dari tag git (kalau build dari tag)\\
        if: startsWith(github.ref, 'refs/tags/v')\\
        run: |\\
          VERSION=\"\${GITHUB_REF_NAME#v}\"\\
          sed -i \"s/var APP_VERSION = '[^']*';/var APP_VERSION = '\${VERSION}';/\" www/index.html\\
          echo \"APP_VERSION diset otomatis ke \${VERSION}\"\\
" "$FILE"

echo "Selesai. Cek hasilnya dengan: git diff .github/workflows/build-apk.yml"
