const crypto = require('crypto');

const clientId = process.env.PAYPAL_CLIENT_ID || '';
const clientSecret = process.env.PAYPAL_CLIENT_SECRET || '';
const environment = (process.env.PAYPAL_ENVIRONMENT || 'sandbox').toLowerCase();
const baseUrl = environment === 'live'
  ? 'https://api-m.paypal.com'
  : 'https://api-m.sandbox.paypal.com';
const currency = (process.env.PAYPAL_CURRENCY || 'EUR').toUpperCase();

function configured() {
  const placeholders = new Set(['tu_client_id', 'tu_client_secret', 'your_client_id', 'your_client_secret']);
  return Boolean(clientId && clientSecret && !placeholders.has(clientId) && !placeholders.has(clientSecret));
}

async function paypalRequest(path, options = {}) {
  if (!configured()) {
    const error = new Error('PayPal no está configurado.');
    error.code = 'PAYPAL_NOT_CONFIGURED';
    throw error;
  }
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    signal: AbortSignal.timeout(8000),
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(body.message || 'PayPal rechazó la operación.');
    error.status = response.status;
    error.body = body;
    throw error;
  }
  return body;
}

async function accessToken() {
  if (!configured()) {
    const error = new Error('PayPal no está configurado.');
    error.code = 'PAYPAL_NOT_CONFIGURED';
    throw error;
  }
  const basic = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const response = await fetch(`${baseUrl}/v1/oauth2/token`, {
    method: 'POST',
    signal: AbortSignal.timeout(8000),
    headers: {
      Authorization: `Basic ${basic}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || !body.access_token) {
    const error = new Error('No se pudo autenticar con PayPal.');
    error.status = response.status;
    throw error;
  }
  return body.access_token;
}

async function api(path, options = {}) {
  const token = await accessToken();
  return paypalRequest(path, {
    ...options,
    headers: { Authorization: `Bearer ${token}`, ...(options.headers || {}) },
  });
}

async function createOrder({ amount, reservationId, fieldName, userId }) {
  const order = await api('/v2/checkout/orders', {
    method: 'POST',
    headers: { 'PayPal-Request-Id': crypto.randomUUID() },
    body: JSON.stringify({
      intent: 'CAPTURE',
      purchase_units: [{
        reference_id: String(reservationId),
        custom_id: `reserva:${reservationId}:usuario:${userId}`,
        description: `Seña reserva ${fieldName}`.slice(0, 127),
        amount: { currency_code: currency, value: Number(amount).toFixed(2) },
      }],
      application_context: { user_action: 'PAY_NOW' },
    }),
  });
  const approval = (order.links || []).find((link) => link.rel === 'approve');
  if (!order.id || !approval || !approval.href) {
    throw new Error('PayPal no devolvió una URL de aprobación válida.');
  }
  return { id: order.id, approvalUrl: approval.href };
}

async function captureOrder(orderId) {
  return api(`/v2/checkout/orders/${encodeURIComponent(orderId)}/capture`, {
    method: 'POST',
    headers: { 'PayPal-Request-Id': crypto.randomUUID() },
    body: '{}',
  });
}

async function getOrder(orderId) {
  return api(`/v2/checkout/orders/${encodeURIComponent(orderId)}`);
}

module.exports = { configured, currency, createOrder, captureOrder, getOrder };
