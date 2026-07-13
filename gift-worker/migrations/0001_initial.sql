CREATE TABLE IF NOT EXISTS gift_drafts (
  id TEXT PRIMARY KEY,
  quote_id TEXT NOT NULL,
  quote_ja TEXT NOT NULL,
  author TEXT NOT NULL,
  sender_note TEXT NOT NULL,
  background_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS gifts (
  id TEXT PRIMARY KEY,
  quote_id TEXT NOT NULL,
  quote_ja_snapshot TEXT NOT NULL,
  author_snapshot TEXT NOT NULL,
  sender_note TEXT NOT NULL,
  background_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  app_transaction_id_hash TEXT NOT NULL,
  transaction_id TEXT NOT NULL UNIQUE,
  idempotency_key TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'active',
  first_opened_at TEXT
);

CREATE TABLE IF NOT EXISTS gift_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  gift_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_gifts_expires_at ON gifts(expires_at);
CREATE INDEX IF NOT EXISTS idx_gift_drafts_expires_at ON gift_drafts(expires_at);
