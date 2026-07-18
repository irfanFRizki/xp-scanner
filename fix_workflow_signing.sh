#!/bin/sh
# Cara pakai:
#   cd /path/ke/xuping-scanner
#   sh fix_workflow_signing.sh
#
# Backup otomatis dibuat sebagai .github/workflows/build-apk.yml.bak
# Cek hasilnya: git diff .github/workflows/build-apk.yml
# Batalkan kalau perlu: git checkout -- .github/workflows/build-apk.yml

set -e
FILE=".github/workflows/build-apk.yml"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi

if grep -q "HAS_SIGNING" "$FILE"; then
  echo "Sudah pernah dipatch sebelumnya, tidak ada perubahan."
  exit 0
fi

cp "$FILE" "$FILE.bak"
echo "Backup dibuat: $FILE.bak"

# 1) Tambah env HAS_SIGNING di level job (bukan di level step) — supaya
#    aman dipakai di kondisi "if:" tanpa kena error "Unrecognized named-value: secrets"
sed -i '/^    runs-on: ubuntu-latest$/a\
    env:\
      HAS_SIGNING: ${{ secrets.XUPING_KEYSTORE_BASE64 != '"'"''"'"' }}' "$FILE"

# 2) Sisipkan step decode keystore sebelum step "Build debug APK"
sed -i '/^      - name: Build debug APK$/i\
      - name: Decode signing keystore (kalau secret sudah diset)\
        if: ${{ env.HAS_SIGNING == '"'"'true'"'"' }}\
        run: |\
          echo "${{ secrets.XUPING_KEYSTORE_BASE64 }}" | base64 -d > android/app/xuping-scanner.keystore\
          echo "XUPING_KEYSTORE_PATH=$(pwd)/android/app/xuping-scanner.keystore" >> $GITHUB_ENV\
          echo "XUPING_KEYSTORE_PASSWORD=${{ secrets.XUPING_KEYSTORE_PASSWORD }}" >> $GITHUB_ENV\
          echo "XUPING_KEY_ALIAS=${{ secrets.XUPING_KEY_ALIAS }}" >> $GITHUB_ENV\
          echo "XUPING_KEY_PASSWORD=${{ secrets.XUPING_KEY_PASSWORD }}" >> $GITHUB_ENV\
' "$FILE"

echo "Selesai. Cek hasilnya dengan: git diff .github/workflows/build-apk.yml"
