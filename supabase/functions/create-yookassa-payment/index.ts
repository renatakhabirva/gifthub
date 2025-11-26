// functions/create-yookassa-payment/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

// Старт функции
serve(async (req) => {
  try {
    const { amount, currency, description, return_url } = await req.json()

    if (!amount || !currency || !description || !return_url) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400 }
      )
    }

    const shopId = Deno.env.get('YOOKASSA_SHOP_ID')
    const apiKey = Deno.env.get('YOOKASSA_API_KEY')

    if (!shopId || !apiKey) {
      return new Response(JSON.stringify({ error: 'Missing API credentials' }), {
        status: 500,
      })
    }

    const response = await fetch('https://api.yookassa.ru/v3/payments', {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(`${shopId}:${apiKey}`),
        'Content-Type': 'application/json',
        'Idempotence-Key': crypto.randomUUID(),
      },
      body: JSON.stringify({
        amount: {
          value: amount,
          currency: currency,
        },
        capture: true,
        confirmation: {
          type: 'redirect',
          return_url: return_url,
        },
        description: description,
      }),
    })

    const data = await response.json()

    if (!response.ok) {
      return new Response(JSON.stringify({ error: data }), {
        status: response.status,
      })
    }

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Yookassa Error:', err)
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), {
      status: 500,
    })
  }
})
