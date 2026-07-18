#!/bin/sh
# Cara pakai:
#   cd /path/ke/xuping-scanner
#   sh fix_signing_config.sh
#
# Backup otomatis dibuat sebagai android/app/build.gradle.bak
# Cek hasilnya: git diff android/app/build.gradle
# Batalkan kalau perlu: git checkout -- android/app/build.gradle

set -e
FILE="android/app/build.gradle"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi

if grep -q "XUPING_KEYSTORE_PATH" "$FILE"; then
  echo "Sudah pernah dipatch sebelumnya, tidak ada perubahan."
  exit 0
fi

cp "$FILE" "$FILE.bak"
echo "Backup dibuat: $FILE.bak"

sed -i '/^    buildTypes {$/i\
    signingConfigs {\
        debug {\
            if (System.getenv("XUPING_KEYSTORE_PATH") != null) {\
                storeFile file(System.getenv("XUPING_KEYSTORE_PATH"))\
                storePassword System.getenv("XUPING_KEYSTORE_PASSWORD")\
                keyAlias System.getenv("XUPING_KEY_ALIAS")\
                keyPassword System.getenv("XUPING_KEY_PASSWORD")\
            }\
        }\
    }' "$FILE"

sed -i '/^    buildTypes {$/a\
        debug {\
            signingConfig signingConfigs.debug\
        }' "$FILE"

echo "Selesai. Cek hasilnya dengan: git diff android/app/build.gradle"
