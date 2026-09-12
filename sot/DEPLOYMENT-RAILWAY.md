# Panduan Deployment Railway — Crib Society Coffee

Panduan langkah demi langkah untuk deploy **Crib Society Coffee Backend & Database MySQL** ke platform **[Railway.com](https://railway.com)** dalam 1 Project.

---

## Arsitektur Deployment di Railway

Dalam 1 Project Railway, akan terdapat 2 Service:
1. **Service Database**: MySQL Database bawaan Railway.
2. **Service API**: Node.js Express REST API backend (di-deploy dari repository Git backend Anda).

---

## Langkah 1: Buat Project & Tambahkan Service Database MySQL

1. Buka dashboard [Railway.com](https://railway.com) dan login.
2. Klik tombol **`+ New Project`**.
3. Pilih **`Provision MySQL`**.
4. Tunggu beberapa detik hingga service MySQL berstatus **Active / Running**.
5. Klik pada Service MySQL yang baru dibuat, lalu buka tab **Variables** untuk melihat konfigurasi default (`MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`, `MYSQL_URL`).

---

## Langkah 2: Deploy Service API (Node.js)

1. Di dalam project yang sama di Railway, klik tombol **`+ New`** (atau `+ Add Service`).
2. Pilih **`GitHub Repo`** dan pilih repository project backend Anda (`backend`).
3. Railway akan otomatis mendeteksi project Node.js dan menjalankan `npm install` serta `npm start`.

---

## Langkah 3: Hubungkan Environment Variables API ke MySQL

Pada Service API (Node.js) di Railway:
1. Klik pada **Service API**.
2. Buka tab **Variables**.
3. Klik **`+ New Variable`** atau **`Add Reference`**:
   - Anda dapat menggunakan fitur **Railway Reference Variable** (otomatis mengambil dari Service MySQL):
     - `MYSQLHOST` = `${{MySQL.MYSQLHOST}}`
     - `MYSQLPORT` = `${{MySQL.MYSQLPORT}}`
     - `MYSQLUSER` = `${{MySQL.MYSQLUSER}}`
     - `MYSQLPASSWORD` = `${{MySQL.MYSQLPASSWORD}}`
     - `MYSQLDATABASE` = `${{MySQL.MYSQLDATABASE}}`
   - *Atau cukup tambahkan 1 variable URL*:
     - `DATABASE_URL` = `${{MySQL.MYSQL_URL}}`
4. Tambahkan juga environment variable pendukung untuk API:
   - `NODE_ENV` = `production`
   - `JWT_SECRET` = `cribsociety_super_secret_jwt_key_2026_production_ready` *(atau string rahasia Anda)*
   - `JWT_EXPIRES_IN` = `1d`
   - `CORS_ORIGIN` = `*` *(atau domain frontend Anda di Vercel/Netlify)*

---

## Langkah 4: Generate Domain Publik untuk API

1. Masih pada **Service API**, buka tab **Settings**.
2. Gulir ke bagian **Networking**.
3. Klik **`Generate Domain`** (contoh: `cribsociety-backend-production.up.railway.app`).
4. Sekarang API Anda aktif dan dapat diakses dari internet di domain tersebut!

---

## Langkah 5: Inisialisasi Database (Migrasi & Seed Data)

Untuk menjalankan skema database dan seed data awal (`users`, `categories`, `products`, `addons`, dll.) ke MySQL di Railway:

### Opsi A (Melalui Railway CLI dari Laptop Anda — Direkomendasikan)
1. Buka terminal di folder `backend`.
2. Login Railway CLI jika belum:
   ```bash
   railway login
   ```
3. Link ke project Railway Anda:
   ```bash
   railway link
   ```
4. Jalankan script inisialisasi database melalui Railway context:
   ```bash
   railway run npm run db:init
   ```

### Opsi B (Melalui Railway Web Terminal)
1. Klik pada **Service API** di dashboard Railway.
2. Buka tab **Deployments** > Klik deployment aktif > buka tab **Terminal** (atau tab Console).
3. Ketik perintah:
   ```bash
   npm run db:init
   ```
4. Tekan Enter. Output akan menampilkan:
   ```
   ✅ [DB Init] Database schema and seeds initialized successfully!
   ```

---

## Langkah 6: Verifikasi Hasil Deployment

Setelah database terinisialisasi dan domain aktif, Anda dapat menguji endpoint:

1. **Healthcheck**:
   ```http
   GET https://<domain-railway-anda>/api/v1/health
   ```
2. **Katalog Produk Publik**:
   ```http
   GET https://<domain-railway-anda>/api/v1/guest/menu
   ```
3. **Login Owner / Staff**:
   ```http
   POST https://<domain-railway-anda>/api/v1/auth/login
   Content-Type: application/json

   {
     "email": "owner@cribsociety.coffee",
     "password": "password123"
   }
   ```
