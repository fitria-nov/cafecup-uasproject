export async function handler(context) {
  const { request, response, db } = context;

  if (request.method !== 'POST') {
    response.status = 405;
    return { message: 'Method Not Allowed' };
  }

  let body;
  try {
    body = await request.json();
  } catch (e) {
    response.status = 400;
    return { message: 'Invalid JSON' };
  }

  const midtrans = require('midtrans-client');

  // Setup Midtrans Snap
  const snap = new midtrans.Snap({
    isProduction: false,
    serverKey: 'SB-Mid-server-wzljIN_dIpgwfv2fp-cff548',
  });

  // Generate order ID jika tidak ada
  const orderId = body.order_id || 'ORDER-' + Date.now() + '-' + Math.floor(Math.random() * 1000);

  const parameter = {
    transaction_details: {
      order_id: orderId,
      gross_amount: body.amount || 10000,
    },
    customer_details: {
      first_name: body.name || 'Customer',
      email: body.email || 'customer@email.com',
      customer_id: body.user_id || 'anonymous',
    },
    item_details: [
      {
        id: 'item-1',
        price: body.amount || 10000,
        quantity: 1,
        name: body.item_name || 'Product',
      }
    ],
  };

  try {
    const transaction = await snap.createTransaction(parameter);

    // Simpan ke database
    await db.collection('payments').create({
      order_id: orderId,
      status: 'pending',
      amount: body.amount || 10000,
      user_id: body.user_id || 'anonymous',
      created: new Date().toISOString(),
    });

    response.status = 200;
    // Return 'token' bukan 'snapToken' untuk match dengan Flutter
    return {
      token: transaction.token,
      order_id: orderId,
      redirect_url: transaction.redirect_url
    };
  } catch (err) {
    console.error('❌ Failed to create transaction:', err);
    response.status = 500;
    return {
      message: 'Failed to create transaction',
      error: err.message
    };
  }
}
