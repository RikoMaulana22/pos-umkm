/* eslint-disable @typescript-eslint/no-explicit-any */

// ===========================================
// PERUBAHAN 1: Impor fungsi v2 secara spesifik
// ===========================================
import { onCall, onRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";

// Impor v1 config (masih kita perlukan untuk mengambil server_key)
import * as functions from "firebase-functions";

import * as admin from "firebase-admin";
import * as midtransClient from "midtrans-client";
import cors = require("cors"); // Pakai import require untuk cors

// Inisialisasi Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// ===========================================
// PERUBAHAN 2: Tentukan region secara global
// ===========================================
setGlobalOptions({ region: "asia-southeast2" }); // (Misal: Jakarta)

// Inisialisasi CORS handler
const corsHandler = cors({origin: true});

// ===================================================================
// FUNGSI 1: DIPANGGIL OLEH APLIKASI FLUTTER (Sintaks v2)
// Tugas: Membuat link pembayaran di Midtrans
// ===================================================================
export const createPaymentRequest = onCall(async (request) => {
  // 1. Cek Autentikasi: Pastikan user sudah login
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Anda harus login untuk membuat pembayaran."
    );
  }

  // 2. Ambil data yang dikirim dari Flutter
  const data = request.data;
  const storeId = data.storeId;
  const packageName = data.packageName;
  const price = data.price;
  const userEmail = request.auth.token.email || "";
  const username = request.auth.token.name || "User";

  // 3. Ambil Server Key (dari v1 config)
  const serverKey = functions.config().midtrans.server_key;
  if (!serverKey) {
    throw new functions.https.HttpsError(
      "internal",
      "Konfigurasi server Midtrans tidak ditemukan."
    );
  }

  // 4. Inisialisasi Midtrans Snap
  const snap = new midtransClient.Snap({
    isProduction: false, // false untuk Sandbox, true untuk Production
    serverKey: serverKey,
  });

  // 5. Buat ID unik untuk pesanan ini
  const orderId = `UPGRADE-${storeId}-${packageName}-${Date.now()}`;

  // 6. Siapkan parameter transaksi
  const parameter: any = {
    transaction_details: {
      order_id: orderId,
      gross_amount: price,
    },
    customer_details: {
      email: userEmail,
      first_name: username,
    },
    item_details: [
      {
        id: packageName,
        price: price,
        quantity: 1,
        name: `Langganan POS UMKM - Paket ${packageName}`,
      },
    ],
    custom_field1: storeId,
    custom_field2: packageName,
  };

  try {
    // 7. Buat transaksi di Midtrans
    const transaction = await snap.createTransaction(parameter);

    // 8. Kirim kembali URL pembayaran ke aplikasi Flutter
    return {
      redirectUrl: transaction.redirect_url,
      token: transaction.token,
    };
  } catch (error: any) {
    console.error("Midtrans Error:", error.message);
    throw new functions.https.HttpsError(
      "internal",
      "Gagal membuat transaksi: " + error.message
    );
  }
});


// ===================================================================
// FUNGSI 2: DIPANGGIL OLEH SERVER MIDTRANS (WEBHOOK) (Sintaks v2)
// Tugas: Meng-update Firestore setelah pembayaran LUNAS
// ===================================================================
export const paymentWebhook = onRequest(async (req, res) => {
  // Gunakan CORS handler untuk pre-flight request
  corsHandler(req, res, async () => {
    try {
      // 1. Ambil Server Key (dari v1 config)
      const serverKey = functions.config().midtrans.server_key;
      if (!serverKey) {
        console.error("Midtrans Server Key not configured.");
        res.status(500).send("Server configuration error.");
        return;
      }

      // 2. Inisialisasi Midtrans Core API (untuk validasi)
      const apiClient = new midtransClient.CoreApi({
        isProduction: false,
        serverKey: serverKey,
      });

      // 3. Terima notifikasi dari Midtrans (ini adalah body JSON)
      const notificationJson = req.body;

      // 4. VALIDASI NOTIFIKASI (SANGAT PENTING!)
      const statusResponse = await apiClient.transaction.notification(
        notificationJson
      );

      const orderId = statusResponse.order_id;
      const transactionStatus = statusResponse.transaction_status;
      const fraudStatus = statusResponse.fraud_status;

      console.log(
        `Webhook received for Order ID: ${orderId}, 
         Status: ${transactionStatus}, 
         Fraud: ${fraudStatus}`
      );

      // 5. Cek apakah pembayaran LUNAS
      if (transactionStatus == "capture" || transactionStatus == "settlement") {
        if (fraudStatus == "accept") {
          // 6. Ambil info dari notifikasi
          const storeId = statusResponse.custom_field1;
          const packageName = statusResponse.custom_field2;
          const price = parseFloat(statusResponse.gross_amount);

          if (!storeId || !packageName) {
            console.error("Missing custom_field1 (storeId) in webhook.");
            res.status(400).send("Missing storeId.");
            return;
          }

          // 7. Hitung tanggal kedaluwarsa baru (30 hari dari sekarang)
          const newExpiryDate = new Date();
          newExpiryDate.setDate(newExpiryDate.getDate() + 30);

          // 8. Update dokumen 'stores' di Firestore
          const storeRef = db.collection("stores").doc(storeId);
          await storeRef.update({
            subscriptionPackage: packageName,
            subscriptionPrice: price,
            subscriptionExpiry: admin.firestore.Timestamp.fromDate(
              newExpiryDate
            ),
            isActive: true, // Pastikan toko aktif
          });

          console.log(`Store ${storeId} successfully upgraded to ${packageName}.`);
        }
      }

      // 9. Kirim balasan "OK" ke Midtrans
      res.status(200).send("Notification received successfully.");
    } catch (error: any) {
      console.error("Webhook Error:", error.message);
      res.status(500).send("Internal Server Error: " + error.message);
    }
  });
});