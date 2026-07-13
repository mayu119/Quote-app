const corsHeaders = {
  "Access-Control-Allow-Origin": "https://mayu119.github.io",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Cache-Control": "no-store",
};

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
    try {
      const url = new URL(request.url);
      const parts = url.pathname.split("/").filter(Boolean);

      if (request.method === "POST" && url.pathname === "/v1/gifts/prepare") {
        return json(await prepare(request, env), 201);
      }
      if (request.method === "POST" && url.pathname === "/v1/gifts/issue") {
        return json(await issue(request, env), 201);
      }
      if (parts[0] === "v1" && parts[1] === "gifts" && parts[2]) {
        const id = parts[2];
        if (request.method === "GET" && parts.length === 3) return json(await getGift(id, env));
        if (request.method === "POST" && parts[3] === "opened") return json(await markOpened(id, env));
        if (request.method === "POST" && parts[3] === "report") return json(await reportGift(id, request, env), 201);
      }
      return json({ error: "not_found" }, 404);
    } catch (error) {
      const status = error.status || 500;
      return json({ error: status === 500 ? "server_error" : error.message }, status);
    }
  },
};

async function prepare(request, env) {
  const body = await request.json();
  const quoteJa = clean(body.quote_ja, 240);
  const author = clean(body.author, 80);
  const senderNote = clean(body.sender_note || "", 60);
  const background = clean(body.background_id, 80);
  const quoteID = clean(body.quote_id, 120);
  if (!quoteJa || !author || !background || !quoteID) throw httpError(400, "invalid_gift_content");
  if (/https?:\/\/|@|\+?\d[\d\s-]{7,}/i.test(senderNote)) throw httpError(400, "personal_contact_not_allowed");

  const now = new Date();
  const expires = new Date(now.getTime() + 10 * 60 * 1000);
  const draftID = randomID(18);
  await env.DB.prepare(`INSERT INTO gift_drafts
    (id, quote_id, quote_ja, author, sender_note, background_id, created_at, expires_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)`)
    .bind(draftID, quoteID, quoteJa, author, senderNote, background, now.toISOString(), expires.toISOString()).run();
  return { draft_id: draftID };
}

async function issue(request, env) {
  const body = await request.json();
  const draftID = clean(body.draft_id, 64);
  const transactionID = clean(body.transaction_id, 64);
  const signedTransaction = clean(body.signed_transaction, 16_000);
  const idempotencyKey = clean(body.idempotency_key, 80);
  if (!draftID || !transactionID || !signedTransaction || !idempotencyKey) throw httpError(400, "invalid_issue_request");

  const existing = await env.DB.prepare("SELECT id FROM gifts WHERE transaction_id = ? OR idempotency_key = ?")
    .bind(transactionID, idempotencyKey).first();
  if (existing) return { url: `${env.PUBLIC_GIFT_BASE_URL}/${existing.id}` };

  const draft = await env.DB.prepare("SELECT * FROM gift_drafts WHERE id = ?").bind(draftID).first();
  if (!draft || new Date(draft.expires_at) <= new Date()) throw httpError(410, "draft_expired");
  const verified = await verifyAppleTransaction(transactionID, signedTransaction, env);
  if (verified.productId !== env.PRODUCT_ID || verified.bundleId !== env.BUNDLE_ID || verified.revocationDate) {
    throw httpError(403, "purchase_not_valid");
  }

  const giftID = randomID(24);
  const now = new Date();
  const expires = new Date(now);
  expires.setUTCFullYear(expires.getUTCFullYear() + 1);
  const appTransactionHash = await sha256(String(verified.appTransactionId || transactionID));
  await env.DB.prepare(`INSERT INTO gifts
    (id, quote_id, quote_ja_snapshot, author_snapshot, sender_note, background_id, created_at, expires_at,
     app_transaction_id_hash, transaction_id, idempotency_key, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`)
    .bind(giftID, draft.quote_id, draft.quote_ja, draft.author, draft.sender_note, draft.background_id,
      now.toISOString(), expires.toISOString(), appTransactionHash, transactionID, idempotencyKey).run();
  await env.DB.prepare("DELETE FROM gift_drafts WHERE id = ?").bind(draftID).run();
  return { url: `${env.PUBLIC_GIFT_BASE_URL}/${giftID}` };
}

async function getGift(id, env) {
  const gift = await env.DB.prepare("SELECT * FROM gifts WHERE id = ?").bind(id).first();
  if (!gift) throw httpError(404, "gift_not_found");
  if (gift.status !== "active") throw httpError(410, `gift_${gift.status}`);
  if (new Date(gift.expires_at) <= new Date()) {
    await env.DB.prepare("UPDATE gifts SET status = 'expired' WHERE id = ?").bind(id).run();
    throw httpError(410, "gift_expired");
  }
  return {
    id: gift.id,
    quote_id: gift.quote_id,
    quote_ja: gift.quote_ja_snapshot,
    author: gift.author_snapshot,
    sender_note: gift.sender_note,
    background_id: gift.background_id,
    created_at: gift.created_at,
    expires_at: gift.expires_at,
    status: gift.status,
  };
}

async function markOpened(id, env) {
  await env.DB.prepare("UPDATE gifts SET first_opened_at = COALESCE(first_opened_at, ?) WHERE id = ? AND status = 'active'")
    .bind(new Date().toISOString(), id).run();
  return { ok: true };
}

async function reportGift(id, request, env) {
  const gift = await env.DB.prepare("SELECT id FROM gifts WHERE id = ?").bind(id).first();
  if (!gift) throw httpError(404, "gift_not_found");
  const body = await request.json();
  const reason = clean(body.reason || "inappropriate_note", 120);
  await env.DB.prepare("INSERT INTO gift_reports (gift_id, reason, created_at) VALUES (?, ?, ?)")
    .bind(id, reason, new Date().toISOString()).run();
  return { ok: true };
}

async function verifyAppleTransaction(transactionID, clientJWS, env) {
  const untrusted = decodeJWSPayload(clientJWS);
  if (String(untrusted.transactionId || "") !== transactionID) throw httpError(403, "transaction_mismatch");
  const token = await appleServerToken(env);
  const endpoints = untrusted.environment === "Production"
    ? ["https://api.storekit.itunes.apple.com", "https://api.storekit-sandbox.itunes.apple.com"]
    : ["https://api.storekit-sandbox.itunes.apple.com", "https://api.storekit.itunes.apple.com"];
  for (const base of endpoints) {
    const response = await fetch(`${base}/inApps/v1/transactions/${encodeURIComponent(transactionID)}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (response.ok) {
      const data = await response.json();
      return decodeJWSPayload(data.signedTransactionInfo);
    }
    if (response.status !== 404) throw httpError(502, "apple_verification_failed");
  }
  throw httpError(403, "transaction_not_found");
}

async function appleServerToken(env) {
  if (!env.APPLE_KEY_P8 || !env.APPLE_KEY_ID || !env.APPLE_ISSUER_ID) throw httpError(503, "apple_server_credentials_missing");
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "ES256", kid: env.APPLE_KEY_ID, typ: "JWT" }));
  const payload = base64url(JSON.stringify({
    iss: env.APPLE_ISSUER_ID, iat: now, exp: now + 300,
    aud: "appstoreconnect-v1", bid: env.BUNDLE_ID,
  }));
  const key = await crypto.subtle.importKey("pkcs8", pemToBytes(env.APPLE_KEY_P8), { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(`${header}.${payload}`));
  return `${header}.${payload}.${base64urlBytes(new Uint8Array(signature))}`;
}

function decodeJWSPayload(jws) {
  const part = String(jws || "").split(".")[1];
  if (!part) throw httpError(400, "invalid_signed_transaction");
  return JSON.parse(new TextDecoder().decode(base64urlToBytes(part)));
}

function clean(value, max) { return String(value || "").trim().slice(0, max); }
function randomID(bytes) { const data = crypto.getRandomValues(new Uint8Array(bytes)); return base64urlBytes(data); }
function base64url(text) { return base64urlBytes(new TextEncoder().encode(text)); }
function base64urlBytes(bytes) {
  let binary = ""; for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function base64urlToBytes(value) {
  const padded = value.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((value.length + 3) % 4);
  const binary = atob(padded); return Uint8Array.from(binary, c => c.charCodeAt(0));
}
function pemToBytes(pem) { return base64urlToBytes(pem.replace(/-----[^-]+-----|\s/g, "").replace(/\+/g, "-").replace(/\//g, "_")); }
async function sha256(value) { return [...new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)))].map(b => b.toString(16).padStart(2, "0")).join(""); }
function httpError(status, message) { const error = new Error(message); error.status = status; return error; }
function json(value, status = 200) { return new Response(JSON.stringify(value), { status, headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" } }); }
