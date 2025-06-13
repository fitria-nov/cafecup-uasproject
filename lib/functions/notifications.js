export async function handler(context) {
  const { request, response, db } = context;

  if (request.method !== 'POST') {
    response.status = 405;
    return { message: 'Method Not Allowed' };
  }

  let payload;
  try {
    payload = await request.json();
  } catch (e) {
    response.status = 400;
    return { message: 'Invalid JSON payload' };
  }

  console.log('🔔 Midtrans notification received:', payload);

  // Ambil order_id dari payload (sesuaikan jika struktur berbeda)
  const orderId = payload.order_id || payload.transaction_id;
  if (!orderId) {
    response.status = 400;
    return { message: 'order_id missing in payload' };
  }

  // Proses update status pembayaran di koleksi 'payments'
  try {
    // Cari record pembayaran berdasarkan order_id
    const record = await db.collection('payments').getFirstListItem(`order_id="${orderId}"`);

    // Update status dan simpan payload mentah untuk audit/log
    await db.collection('payments').update(record.id, {
      status: payload.transaction_status || 'unknown',
      raw_response: JSON.stringify(payload),
      updated: new Date().toISOString()
    });

    response.status = 200;
    return { message: 'Notification processed successfully' };
  } catch (error) {
    console.error('❌ Error updating payment record:', error);
    response.status = 500;
    return { message: 'Internal Server Error' };
  }
}
