const crypto = require('crypto');

const secretKey = process.env.STRIPE_SECRET_KEY || '';
const currency = (process.env.STRIPE_CURRENCY || process.env.PAYPAL_CURRENCY || 'eur').toLowerCase();
const successUrl = process.env.STRIPE_SUCCESS_URL || 'https://checkout.stripe.com/success';
const cancelUrl = process.env.STRIPE_CANCEL_URL || 'https://checkout.stripe.com/cancel';

function configured() {
  return Boolean(secretKey && secretKey.startsWith('sk_'));
}

async function stripeRequest(path, options = {}) {
  if (!configured()) {
    const error = new Error('Stripe no está configurado.');
    error.code = 'STRIPE_NOT_CONFIGURED';
    throw error;
  }
  const response = await fetch(`https://api.stripe.com${path}`, {
    ...options,
    signal: AbortSignal.timeout(8000),
    headers: {
      Authorization: `Bearer ${secretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      ...(options.headers || {}),
    },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(body?.error?.message || 'Stripe rechazó la operación.');
    error.status = response.status;
    error.body = body;
    throw error;
  }
  return body;
}

function params(values) {
  return new URLSearchParams(values).toString();
}

async function createCheckoutSession({ amount, reservationId, fieldName, userId }) {
  const amountCents = Math.round(Number(amount) * 100);
  const session = await stripeRequest('/v1/checkout/sessions', {
    method: 'POST',
    headers: { 'Idempotency-Key': crypto.randomUUID() },
    body: params({
      mode: 'payment',
      success_url: successUrl,
      cancel_url: cancelUrl,
      'line_items[0][price_data][currency]': currency,
      'line_items[0][price_data][product_data][name]': `Seña reserva ${fieldName}`,
      'line_items[0][price_data][unit_amount]': String(amountCents),
      'line_items[0][quantity]': '1',
      'metadata[reservation_id]': String(reservationId),
      'metadata[user_id]': String(userId),
      'payment_intent_data[metadata][reservation_id]': String(reservationId),
      'payment_intent_data[metadata][user_id]': String(userId),
    }),
  });
  if (!session.id || !session.url) throw new Error('Stripe no devolvió una URL de pago válida.');
  return { id: session.id, approvalUrl: session.url };
}

async function getCheckoutSession(sessionId) {
  return stripeRequest(`/v1/checkout/sessions/${encodeURIComponent(sessionId)}`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' },
  });
}

function verifyPaidSession(session, { amount, reservationId }) {
  return session.payment_status === 'paid' &&
    Number(session.amount_total) === Math.round(Number(amount) * 100) &&
    String(session.metadata?.reservation_id) === String(reservationId);
}

module.exports = { configured, currency, createCheckoutSession, getCheckoutSession, verifyPaidSession };
