#!/bin/sh
# Cara pakai:
#   cd /path/ke/xuping-scanner
#   sh fix_update_public_repo.sh
#
# Backup otomatis dibuat sebagai www/index.html.bak2
# Cek hasilnya: git diff www/index.html
# Batalkan kalau perlu: git checkout -- www/index.html

set -e
FILE="www/index.html"

if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan. Jalankan script ini dari folder xuping-scanner."
  exit 1
fi

cp "$FILE" "$FILE.bak2"
echo "Backup dibuat: $FILE.bak2"

# 1) Tambah kembali field "Repo GitHub" di modal Pengaturan
sed -i "s|<input id=\"inputGasUrl\" type=\"text\" placeholder=\"https://script.google.com/macros/s/XXXXX/exec\">|<input id=\"inputGasUrl\" type=\"text\" placeholder=\"https://script.google.com/macros/s/XXXXX/exec\">\n\n    <label>Repo GitHub untuk update (format: owner/nama-repo)</label>\n    <input id=\"inputRepo\" type=\"text\" placeholder=\"irfanFRizki/xp-scanner\">|" "$FILE"

# 2) Tambah kembali konstanta STORAGE_KEY_REPO
sed -i "/var STORAGE_KEY_HISTORY = 'xuping_history';/a\\
  var STORAGE_KEY_REPO = 'xuping_gh_repo';" "$FILE"

# 3) Tambah kembali getRepo/setRepo setelah setGasUrl
sed -i "/function setGasUrl(u){ localStorage.setItem(STORAGE_KEY_URL, u); }/a\\
\\
  function getRepo(){ return localStorage.getItem(STORAGE_KEY_REPO) || ''; }\\
  function setRepo(r){ localStorage.setItem(STORAGE_KEY_REPO, r); }" "$FILE"

# 4) Isi ulang inputRepo di openSettings
sed -i "/\$('inputGasUrl').value = getGasUrl();/a\\
    \$('inputRepo').value = getRepo();" "$FILE"

# 5) Simpan inputRepo di btnSaveSettings
sed -i "/setGasUrl(\$('inputGasUrl').value.trim());/a\\
    setRepo(\$('inputRepo').value.trim());" "$FILE"

# 6) Ganti checkForUpdate + doUpdate: dari versi proxy GAS -> versi fetch
#    langsung ke GitHub (untuk repo PUBLIC, tidak perlu token/proxy).
#    Hapus dari "Bungkus jsonpRequest jadi Promise" sampai SEBELUM
#    "function arrayBufferToBase64", lalu sisipkan versi baru.
sed -i '/\/\/ Bungkus jsonpRequest jadi Promise/,/function arrayBufferToBase64(buffer){/{/function arrayBufferToBase64(buffer){/!d}' "$FILE"

sed -i '/function arrayBufferToBase64(buffer){/i\
  async function checkForUpdate(silent){\
    var repo = getRepo();\
    if (!repo){\
      if (!silent) setStatus("Isi dulu Repo GitHub di menu Pengaturan.", "err");\
      return;\
    }\
    try {\
      var res = await fetch("https://api.github.com/repos/" + repo + "/releases/latest");\
      if (!res.ok) throw new Error("Repo/release tidak ditemukan (HTTP " + res.status + ")");\
      var data = await res.json();\
      var tag = (data.tag_name || "").trim();\
      var asset = (data.assets || []).find(function(a){ return /\\.apk$/i.test(a.name); });\
      if (!tag || !asset) throw new Error("Release ada tapi tidak ada file .apk terlampir");\
      if (isNewerVersion(tag, APP_VERSION)){\
        latestVersionInfo = { tag: tag, apkUrl: asset.browser_download_url, size: asset.size };\
        showUpdateBanner(tag);\
        if (!silent) setStatus("Update v" + tag.replace(/^v/i,"") + " tersedia.", "ok");\
      } else {\
        hideUpdateBanner();\
        if (!silent) setStatus("Aplikasi sudah versi terbaru (v" + APP_VERSION + ").", "ok");\
      }\
    } catch (err){\
      if (!silent) setStatus("Gagal cek update: " + err.message, "err");\
    }\
  }\
' "$FILE"

sed -i "/async function doUpdate(){/,/\$('btnDoUpdate').addEventListener/{/\$('btnDoUpdate').addEventListener/!d}" "$FILE"

sed -i "/\$('btnDoUpdate').addEventListener/i\\
  async function doUpdate(){\\
    if (!latestVersionInfo){ setStatus('Belum ada info update. Cek update dulu.', 'err'); return; }\\
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
