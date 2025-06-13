import dotenv from 'dotenv';
import express from 'express';
import midtransClient from 'midtrans-client';
import PocketBase from 'pocketbase';

dotenv.config();

const pb = new PocketBase('http://127.0.0.1:8090');
const app = express();
const port = process.env.PORT || 3000;

// Konfigurasi Midtrans Client
const snap = new midtransClient.Snap({
  isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY,
});

// Middleware parsing JSON
app.use(express.json());

// Autentikasi admin PocketBase
async function authenticatePocketBase() {
  try {
    await pb.collection('users').authWithPassword(
      process.env.POCKETBASE_USER_EMAIL,
      process.env.POCKETBASE_USER_PASSWORD
    );
    console.log('✅ PocketBase user authenticated');
  } catch (error) {
    console.error('❌ PocketBase user authentication failed:', error.response || error.message);
    process.exit(1);
  }
}
// Endpoint untuk membuat Snap token
app.post('/create-transaction', async (req, res) => {
  try {
    const { order_id, amount, user_id } = req.body;

    if (!order_id || !amount || !user_id) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const orders = await pb.collection('orders').getList(1, 1, {
      filter: `order_id = "${order_id}" && user_id = "${user_id}"`,
    });

    if (orders.items.length === 0) {
      return res.status(404).json({ error: 'Order not found or unauthorized' });
    }

    const order = orders.items[0];
    if (order.total_amount !== amount) {
      return res.status(400).json({ error: 'Amount mismatch' });
    }

    const parameter = {
      transaction_details: {
        order_id,
        gross_amount: amount,
      },
      customer_details: {
        first_name: user_id,
        email: `${user_id}@example.com`,
      },
      enabled_payments: ['credit_card', 'gopay', 'shopeepay', 'bank_transfer'],
      expiry: {
        duration: 15,
        unit: 'minutes',
      },
    };

    const transaction = await snap.createTransaction(parameter);
    res.status(200).json({ token: transaction.token });
  } catch (error) {
    console.error('Error creating transaction:', error);
    res.status(500).json({ error: 'Failed to create transaction' });
  }
});

// Endpoint notifikasi dari Midtrans
app.post('/notification', async (req, res) => {
  try {
    const notification = req.body;
    const status = await snap.transaction.notification(notification);

    const { order_id, transaction_status, gross_amount } = status;
    let orderStatus;

    switch (transaction_status) {
      case 'capture':
      case 'settlement':
        orderStatus = 'completed';
        break;
      case 'pending':
        orderStatus = 'pending';
        break;
      default:
        orderStatus = 'failed';
    }

    const orders = await pb.collection('orders').getList(1, 1, {
      filter: `order_id = "${order_id}"`,
    });

    if (orders.items.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orders.items[0];

    await pb.collection('orders').update(order.id, {
      status: orderStatus,
      ...(orderStatus === 'completed' && {
        estimatedTime: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
      }),
    });

    await pb.collection('payments').create({
      payment_id: `PAY${Date.now()}`,
      order_id: order.id,
      user_id: order.user_id,
      transaction_id: status.transaction_id,
      amount: parseFloat(gross_amount),
      status: orderStatus,
      payment_method: status.payment_type || 'unknown',
      created_at: new Date().toISOString(),
    });

    res.status(200).json({ status: 'success' });
  } catch (error) {
    console.error('Error in notification:', error);
    res.status(500).json({ error: 'Failed to process notification' });
  }
});

// Jalankan server
authenticatePocketBase().then(() => {
  app.listen(port, () => {
    console.log(`🚀 Server running at http://localhost:${port}`);
  });
});
