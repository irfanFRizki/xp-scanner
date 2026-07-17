#!/bin/sh
# Cara pakai:
#   cd /path/ke/xuping-scanner
#   sh fix_update_private_repo.sh
#
# Backup otomatis dibuat sebagai www/index.html.bak
# Setelah jalan, cek hasilnya dengan: git diff www/index.html
# Kalau ada yang aneh: git checkout -- www/index.html

set -e
FILE="www/index.html"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi

cp "$FILE" "$FILE.bak"
echo "Backup dibuat: $FILE.bak"

# 1) Hapus field "Repo GitHub" di modal Pengaturan (sudah tidak perlu,
#    repo & token sekarang disimpan di Script Properties GAS)
sed -i '/<label>Repo GitHub untuk update/,/<input id="inputRepo"/d' "$FILE"
sed -i 's|margin:-4px 0 14px；|margin:14px 0;|' "$FILE" 2>/dev/null || true
sed -i 's/margin:-4px 0 14px;/margin:14px 0;/' "$FILE"

# 2) Hapus deklarasi STORAGE_KEY_REPO
sed -i "/var STORAGE_KEY_REPO = 'xuping_gh_repo';/d" "$FILE"

# 3) Hapus fungsi getRepo/setRepo
sed -i "/function getRepo(){ return localStorage.getItem(STORAGE_KEY_REPO) || ''; }/d" "$FILE"
sed -i "/function setRepo(r){ localStorage.setItem(STORAGE_KEY_REPO, r); }/d" "$FILE"

# 4) Hapus baris inputRepo di openSettings & btnSaveSettings
sed -i "/\$('inputRepo').value = getRepo();/d" "$FILE"
sed -i "/setRepo(\$('inputRepo').value.trim());/d" "$FILE"

# 5) Ganti isi checkForUpdate (dari fetch langsung ke GitHub -> lewat proxy
#    GAS) — hapus fungsi lama dari baris "async function checkForUpdate"
#    sampai SEBELUM "function arrayBufferToBase64" (yang itu tidak diubah),
#    lalu sisipkan fungsi baru sebelum arrayBufferToBase64.
sed -i '/async function checkForUpdate(silent){/,/function arrayBufferToBase64(buffer){/{/function arrayBufferToBase64(buffer){/!d}' "$FILE"

sed -i '/function arrayBufferToBase64(buffer){/i\
  // Bungkus jsonpRequest jadi Promise supaya enak dipakai dengan async/await\
  function jsonpRequestAsync(gasUrl, params, timeoutMs){\
    return new Promise(function(resolve, reject){\
      jsonpRequest(gasUrl, params, function(err, data){\
        if (err) reject(err); else resolve(data);\
      }, timeoutMs);\
    });\
  }\
\
  async function checkForUpdate(silent){\
    var gasUrl = getGasUrl();\
    if (!gasUrl){\
      if (!silent) setStatus("URL Web App belum diatur. Buka \\u2699 Pengaturan dulu.", "err");\
      return;\
    }\
    try {\
      var data = await jsonpRequestAsync(gasUrl, { action: "checkUpdate" }, 20000);\
      if (!data || !data.success) throw new Error((data \&\& data.error) || "tidak diketahui");\
      if (isNewerVersion(data.tag, APP_VERSION)){\
        latestVersionInfo = { tag: data.tag, apkUrl: data.apkUrl, size: data.size };\
        showUpdateBanner(data.tag);\
        if (!silent) setStatus("Update v" + data.tag.replace(/^v/i,"") + " tersedia.", "ok");\
      } else {\
        hideUpdateBanner();\
        if (!silent) setStatus("Aplikasi sudah versi terbaru (v" + APP_VERSION + ").", "ok");\
      }\
    } catch (err){\
      if (!silent) setStatus("Gagal cek update: " + err.message, "err");\
    }\
  }\
' "$FILE"

# 6) Ganti isi doUpdate — hapus dari "async function doUpdate" sampai
#    SEBELUM baris addEventListener btnDoUpdate, lalu sisipkan versi baru
#    yang refresh link update dulu sebelum download.
sed -i "/async function doUpdate(){/,/\$('btnDoUpdate').addEventListener/{/\$('btnDoUpdate').addEventListener/!d}" "$FILE"

sed -i "/\$('btnDoUpdate').addEventListener/i\\
  async function doUpdate(){\\
    var Plugins = window.Capacitor \&\& window.Capacitor.Plugins;\\
    if (!Plugins || !Plugins.ApkInstaller || !Plugins.Filesystem){\\
      setStatus('Fitur update cuma jalan di APK terpasang, bukan di browser.', 'err');\\
      return;\\
    }\\
    try {\\
      var perm = await Plugins.ApkInstaller.canInstall();\\
      if (!perm.allowed){\\
        setLoadingStatus('Minta izin \"Install app tidak dikenal\"...');\\
        await Plugins.ApkInstaller.requestInstallPermission();\\
        setStatus('Aktifkan izin \"Izinkan dari sumber ini\" di layar yang terbuka, lalu tap Update Sekarang lagi.', 'err');\\
        return;\\
      }\\
      setLoadingStatus('Menyiapkan link download...');\\
      await checkForUpdate(true);\\
      if (!latestVersionInfo){ setStatus('Gagal menyiapkan link update. Coba cek update lagi.', 'err'); return; }\\
      setLoadingStatus('Mengunduh update 0%...');\\
      var buffer = await downloadWithProgress(latestVersionInfo.apkUrl, function(pct){\\
        setLoadingStatus('Mengunduh update ' + pct + '%...');\\
      });\\
      setLoadingStatus('Menyimpan file APK...');\\
      var base64 = arrayBufferToBase64(buffer);\\
      var fileName = 'xuping-update.apk';\\
      await Plugins.Filesystem.writeFile({ path: fileName, data: base64, directory: 'CACHE' });\\
      var uriRes = await Plugins.Filesystem.getUri({ path: fileName, directory: 'CACHE' });\\
      setLoadingStatus('Membuka installer...');\\
      await Plugins.ApkInstaller.install({ path: uriRes.uri });\\
      setStatus('Installer dibuka - ikuti langkah install di layar.', 'ok');\\
      hideUpdateBanner();\\
    } catch (err){\\
      setStatus('Update gagal: ' + err.message, 'err');\\
    }\\
  }\\
" "$FILE"

echo "Selesai. Cek hasilnya dengan: git diff www/index.html"
