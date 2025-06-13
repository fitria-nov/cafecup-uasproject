const midtrans = require("midtrans-client")

export async function handler(context) {
  const { request, response, db } = context

  // Add CORS headers
  response.headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Content-Type": "application/json",
  }

  // Handle preflight requests
  if (request.method === "OPTIONS") {
    response.status = 200
    return {}
  }

  if (request.method !== "POST") {
    response.status = 405
    return { message: "Method Not Allowed" }
  }

  let body
  try {
    body = await request.json()
  } catch (e) {
    console.error("JSON parsing error:", e)
    response.status = 400
    return { message: "Invalid JSON" }
  }

  // Validate required fields
  if (!body.amount || !body.order_id) {
    response.status = 400
    return { message: "Missing required fields: amount, order_id" }
  }

  try {
    // Setup Midtrans Snap
    const snap = new midtrans.Snap({
      isProduction: false,
      serverKey: process.env.MIDTRANS_SERVER_KEY || "SB-Mid-server-wzljIN_dIpgwfv2fp-cff548",
    })

    // Generate order ID if not provided
    const orderId = body.order_id || "ORDER-" + Date.now() + "-" + Math.floor(Math.random() * 1000)

    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: Number.parseInt(body.amount),
      },
      customer_details: {
        first_name: body.name || "Customer",
        email: body.email || "customer@email.com",
        customer_id: body.user_id || "anonymous",
      },
      item_details: [
        {
          id: "item-1",
          price: Number.parseInt(body.amount),
          quantity: 1,
          name: body.item_name || "Product",
        },
      ],
    }

    console.log("Creating transaction with parameter:", JSON.stringify(parameter, null, 2))

    const transaction = await snap.createTransaction(parameter)

    // Save to database if db is available
    if (db) {
      try {
        await db.collection("payments").create({
          order_id: orderId,
          status: "pending",
          amount: Number.parseInt(body.amount),
          user_id: body.user_id || "anonymous",
          created: new Date().toISOString(),
        })
      } catch (dbError) {
        console.error("Database save error:", dbError)
        // Don't fail the transaction if DB save fails
      }
    }

    response.status = 200
    return {
      token: transaction.token,
      order_id: orderId,
      redirect_url: transaction.redirect_url,
    }
  } catch (err) {
    console.error("❌ Failed to create transaction:", err)
    response.status = 500
    return {
      message: "Failed to create transaction",
      error: err.message,
      details: err.response?.data || "No additional details",
    }
  }
}
