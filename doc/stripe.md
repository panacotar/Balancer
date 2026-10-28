# Stripe

Use Stripe test mode. Put the values in `.env`, then restart the app.

## API keys

In the [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys), open **Developers → API keys** while **Test mode** is on.

- `STRIPE_PUBLISHABLE_KEY` is the publishable key (`pk_test_...`).
- `STRIPE_SECRET_KEY` is the secret key (`sk_test_...`).

A pledge still completes when the buyer returns from Checkout. The webhook is what records the pledge if they close the browser first.

## Webhook secret

`STRIPE_WEBHOOK_SECRET` is not an API key. It is the signing secret for `POST /stripe/webhook`.

For local development, install the [Stripe CLI](https://docs.stripe.com/stripe-cli), then forward events to the port the app is using:

```sh
stripe login
stripe listen --forward-to localhost:3000/stripe/webhook
```

The CLI prints a secret that starts with `whsec_`. Set that as `STRIPE_WEBHOOK_SECRET` and restart Rails. Leave `stripe listen` running while you pay.

For a public site, open **Developers → Webhooks**, add `https://YOUR_DOMAIN/stripe/webhook`, and subscribe to `checkout.session.completed`. Copy that endpoint's signing secret into `.env`.

Test card: `4242 4242 4242 4242`, any future expiry, any CVC, any postal code.
