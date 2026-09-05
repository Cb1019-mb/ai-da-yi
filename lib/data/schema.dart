/// 建表语句（与 docs/schema.sql 保持一致）
const List<String> schemaStatements = [
  'PRAGMA foreign_keys = ON',
  '''
CREATE TABLE IF NOT EXISTS user_profile (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  gender       TEXT NOT NULL CHECK (gender IN ('male','female')),
  height_cm    REAL,
  weight_kg    REAL,
  shoulder_cm  REAL,
  chest_cm     REAL,
  waist_cm     REAL,
  hip_cm       REAL,
  body_type    TEXT,
  skin_season  TEXT,
  style_pref   TEXT,
  taboo        TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS category (
  id        INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES category(id),
  gender    TEXT NOT NULL CHECK (gender IN ('male','female','unisex')),
  name      TEXT NOT NULL,
  sort      INTEGER DEFAULT 0
)''',
  '''
CREATE TABLE IF NOT EXISTS style (
  id             INTEGER PRIMARY KEY,
  name           TEXT NOT NULL,
  gender         TEXT NOT NULL CHECK (gender IN ('male','female','unisex')),
  formal_level   INTEGER,
  color_tendency TEXT,
  required_items TEXT,
  exposure_min   REAL,
  exposure_max   REAL,
  features       TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS wardrobe_item (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id   INTEGER REFERENCES category(id),
  category_name TEXT,
  slot          TEXT,
  gender        TEXT NOT NULL CHECK (gender IN ('male','female','unisex')),
  color_main    TEXT,
  color_sub     TEXT,
  hsv_main      TEXT,
  hsv_sub       TEXT,
  pattern       TEXT,
  material      TEXT,
  thickness     INTEGER,
  season        TEXT,
  fit           TEXT,
  length        TEXT,
  style_tags    TEXT,
  formal_level  INTEGER,
  exposure      INTEGER,
  image_path    TEXT,
  created_at    TEXT DEFAULT (datetime('now','localtime'))
)''',
  '''
CREATE TABLE IF NOT EXISTS outfit (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  occasion     TEXT,
  target_style TEXT,
  weather      TEXT,
  total_score  REAL,
  color_note   TEXT,
  snapshot     TEXT,
  created_at   TEXT DEFAULT (datetime('now','localtime'))
)''',
  '''
CREATE TABLE IF NOT EXISTS outfit_item (
  outfit_id INTEGER NOT NULL REFERENCES outfit(id) ON DELETE CASCADE,
  item_id   INTEGER NOT NULL REFERENCES wardrobe_item(id),
  slot      TEXT,
  PRIMARY KEY (outfit_id, item_id)
)''',
  '''
CREATE TABLE IF NOT EXISTS rule (
  id        INTEGER PRIMARY KEY,
  type      TEXT NOT NULL CHECK (type IN ('hard','soft')),
  name      TEXT NOT NULL,
  condition TEXT,
  weight    REAL,
  action    TEXT,
  note      TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS body_type_rule (
  id        INTEGER PRIMARY KEY,
  gender    TEXT NOT NULL,
  body_type TEXT NOT NULL,
  slot      TEXT,
  attribute TEXT,
  effect    INTEGER
)''',
  'CREATE INDEX IF NOT EXISTS idx_item_category ON wardrobe_item(category_id)',
  'CREATE INDEX IF NOT EXISTS idx_item_gender   ON wardrobe_item(gender)',
  'CREATE INDEX IF NOT EXISTS idx_outfit_item    ON outfit_item(outfit_id)',
];
