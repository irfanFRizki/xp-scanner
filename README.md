# XUPING Scanner (Android)

Aplikasi Android untuk cari kode kanonik Packing List XUPING berdasarkan
kode supplier — bisa diketik manual atau di-scan pakai kamera HP.
Contoh: scan `X001237323` → muncul kode `0121260200`.

Data diambil **live** dari Google Sheet yang sama dengan web app GAS yang
sudah ada, lewat fungsi `getKodeBySupplierRef()` yang sudah kamu punya.

---

## Langkah 1 — Tambahkan endpoint JSON di Apps Script

1. Buka project Apps Script (Code.gs) yang sekarang.
2. Buka file `GAS_PATCH_doGet.gs.txt` di folder ini.
3. **Ganti** fungsi `doGet(e)` yang lama di Code.gs dengan isi file
   tersebut (jangan sampai ada 2 fungsi `doGet` — hapus yang lama).
   > **Penting (v1.0.10+):** Patch ini sekarang juga mencari **kode kanonik langsung** (kolom kode/Code), bukan cuma kode supplier di kolom refD/refE. Setelah update patch, **deploy ulang Web App** (New version → Deploy) supaya perubahan aktif.
4. Simpan, lalu **Deploy → Manage deployments → Edit (pensil) → New version**
   pada deployment web app yang sudah ada (atau buat baru):
   - Execute as: **Me**
   - Who has access: **Anyone**
5. Salin URL yang berakhiran `/exec`. Ini yang nanti dimasukkan ke
   pengaturan (ikon ⚙) di aplikasi Android.

Cek cepat: buka di browser
`https://script.google.com/macros/s/XXXXX/exec?action=lookup&kode=X001237323&callback=test`
— harus muncul teks `test({"success":true,...})`.

## Langkah 2 — Push project ini ke GitHub

Dari folder ini:

```bash
git init
git add .
git commit -m "Init XUPING Scanner Android app"
git branch -M main
git remote add origin https://github.com/USERNAME/xuping-scanner.git
git push -u origin main
```

## Langkah 3 — Ambil APK dari GitHub Actions

Begitu di-push, workflow `.github/workflows/build-apk.yml` otomatis jalan:
1. Buka tab **Actions** di repo GitHub.
2. Tunggu run selesai (±3-5 menit).
3. Buka run tersebut → bagian **Artifacts** → download
   `xuping-scanner-debug-apk.zip` → isinya `app-debug.apk`.
4. Kirim APK itu ke HP (WA/Drive/kabel), install (aktifkan "Install dari
   sumber tidak dikenal" kalau diminta).

## Langkah 4 — Pertama kali buka app di HP

1. Buka app, tap ikon ⚙ di pojok kanan atas.
2. Paste URL `/exec` dari Langkah 1, tap **Simpan**.
3. Coba ketik kode atau tap **Scan Barcode / QR**.

---

## Struktur project

```
xuping-scanner/
├── www/index.html          ← seluruh UI + logic app (tema gelap sama seperti web app kamu)
├── android/                 ← project Android native (Capacitor)
├── capacitor.config.json
├── package.json
├── GAS_PATCH_doGet.gs.txt   ← kode yang perlu ditempel ke Code.gs
└── .github/workflows/build-apk.yml  ← build APK otomatis di GitHub
```

## Kenapa pakai JSONP, bukan fetch() biasa?

Apps Script Web App tidak mengirim header CORS, jadi `fetch()` biasa dari
app native akan diblokir browser/webview. JSONP (lewat tag `<script>`)
tidak kena aturan CORS sama sekali, jadi ini cara paling stabil untuk
manggil GAS dari luar (APK, web lain, dsb) tanpa perlu server tambahan.

## Fitur update aplikasi langsung dari dalam app

Ada tombol **"Update Sekarang"** yang muncul otomatis (banner hijau di atas)
kalau ada versi baru di GitHub Releases. Alurnya: cek versi terbaru → download
APK di background (dengan progress %) → langsung buka installer sistem
Android. User cuma perlu tap "Install" sekali di layar installer — tidak
perlu buka browser/file manager manual.

**Catatan penting soal keamanan Android:** Android TIDAK mengizinkan app
mana pun meng-install APK secara diam-diam tanpa konfirmasi user — ini
proteksi sistem, tidak bisa dilewati (juga oleh Play Store sendiri kalau
app diinstall dari luar Play Store). Jadi "sekali tap" di sini maksudnya
mengurangi langkah manual (tidak perlu browser/file manager), bukan
menghilangkan sama sekali dialog konfirmasi install dari Android.

### Cara rilis versi baru (supaya fitur update ini jalan)

1. Buka `www/index.html`, cari baris:
   ```js
   var APP_VERSION = '1.0.0';
   ```
   Naikkan sesuai versi baru, misal `'1.1.0'`.
2. Commit & push seperti biasa:
   ```bash
   git add .
   git commit -m "Rilis v1.1.0"
   git push
   ```
3. **Buat tag versi** — ini yang memicu GitHub Actions membuat Release
   resmi (bukan cuma artifact biasa):
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
4. Tunggu tab **Actions** selesai (~3-5 menit) → otomatis muncul di tab
   **Releases** repo kamu, lengkap dengan file `.apk` terlampir.
5. Buka app versi lama di HP → banner update muncul otomatis (app cek
   diam-diam tiap dibuka) → tap **Update Sekarang**.

### Setup sekali di app (wajib sebelum fitur ini bisa jalan)

Buka ikon ⚙ di app → isi **"Repo GitHub"** dengan format `owner/nama-repo`
(mis. `irfanFRizki/xp-scanner`) → Simpan. Tanpa ini, app tidak tahu ke
repo mana harus cek update.

### Kalau muncul "Aktifkan izin Install app tidak dikenal"

Ini juga proteksi Android — sekali diaktifkan (Settings akan otomatis
terbuka ke halaman yang tepat), update berikutnya tidak akan diminta lagi.

## Fitur bagikan hasil (WhatsApp / Telegram / SMS)

Tombol **📤 Bagikan Hasil** di kartu hasil akan membuka share sheet asli
Android (lewat plugin `@capacitor/share`) yang otomatis menampilkan semua
app terinstall — WhatsApp, Telegram, SMS, Email, dll — tinggal pilih.

Kalau plugin native gagal (mis. dijalankan di browser biasa), otomatis
fallback ke Web Share API browser, dan kalau itu juga tidak ada, muncul
menu manual dengan tombol langsung ke WhatsApp/Telegram/SMS atau salin teks.

Format teks yang dibagikan:
```
*DATA TERLAMPIR*
----------------------------
Kode         : *0111220026*
Descripsi : XP KLG NURI 0.8/45cm kkt O MAS
Url             : https://.../0111220026.jpg
XP - 08 AIR 2022
XP - 03 LCL 2026
XP - 04 LCL 2026
----------------------------
*TERIMA KASIH*
```
Tanda `*teks*` adalah format bold WhatsApp/Telegram bawaan (tidak perlu
plugin tambahan untuk itu).

**Penting:** karena ada plugin native baru (`@capacitor/share`), setelah
`git pull`/timpa file project ini, jalankan ulang `npm install` sebelum
push supaya `package-lock.json` ikut ter-update — atau langsung push saja,
GitHub Actions akan `npm install` otomatis dari `package.json`.

## Fitur foto (sheet "Link foto")

Kolom A di sheet **Link foto** dibaca sebagai kode kanonik, lalu URL foto
diambil otomatis dari kolom lain di baris yang sama (mis. kolom E) — tidak
perlu hardcode nomor kolom, backend otomatis mendeteksi sel mana yang berisi
URL (`http...`, `.jpg`, `.png`, dll).

Kalau kode tidak ditemukan di sheet foto, atau link fotonya rusak/404, app
tetap menampilkan kode & deskripsi seperti biasa — cuma bagian foto yang
menampilkan pesan "Foto tidak tersedia" / "Gagal memuat foto". **Tap foto
untuk buka fullscreen — dukung pinch-zoom (dua jari) dan double-tap zoom.**

## Pencarian kode (v1.0.10+)

Kotak pencarian sekarang menerima:
- **Kode supplier** (seperti sebelumnya: `X/2024`, `X001237323`, dll)
- **Kode kanonik barang** (kolom kode/Code di sheet, mis. `0121260200`)

Hasil pencarian akan menampilkan kode kanonik, deskripsi, PL+Tahun, dan foto
(jika tersedia).

## Build APK release (bertanda tangan, buat upload ke Play Store)

Workflow di atas cuma build **debug APK** (cukup untuk install manual/testing).
Kalau nanti butuh release APK bertanda tangan, bilang saja — perlu setup
keystore + secrets tambahan di GitHub.

## Catatan lain

- Icon app masih default Capacitor — kalau mau custom, ganti file di
  `android/app/src/main/res/mipmap-*/ic_launcher*.png` (atau pakai
  `@capacitor/assets` untuk generate otomatis dari 1 file PNG).
- Riwayat pencarian & URL Web App disimpan lokal di HP (localStorage),
  tidak dikirim ke mana-mana.
