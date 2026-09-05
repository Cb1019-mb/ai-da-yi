-- ============================================================
-- 智能穿搭搭配 App — SQLite 数据库结构
-- 纯本地单机，无账号体系
-- ============================================================

PRAGMA foreign_keys = ON;

-- 个人档案（单机自用，通常只有一行）
CREATE TABLE IF NOT EXISTS user_profile (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  gender       TEXT NOT NULL CHECK (gender IN ('male','female')),
  height_cm    REAL,          -- 身高
  weight_kg    REAL,          -- 体重
  shoulder_cm  REAL,          -- 肩宽
  chest_cm     REAL,          -- 胸围
  waist_cm     REAL,          -- 腰围
  hip_cm       REAL,          -- 臀围
  body_type    TEXT,          -- 判型结果（可手动修正）
  skin_season  TEXT,          -- 肤色四季型：春/夏/秋/冬
  style_pref   TEXT,          -- 风格偏好（JSON 数组）
  taboo        TEXT           -- 禁忌（JSON 数组）
);

-- 品类树（分性别）
CREATE TABLE IF NOT EXISTS category (
  id        INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES category(id),
  gender    TEXT NOT NULL CHECK (gender IN ('male','female','unisex')),
  name      TEXT NOT NULL,
  sort      INTEGER DEFAULT 0
);

-- 风格库（分性别）
CREATE TABLE IF NOT EXISTS style (
  id             INTEGER PRIMARY KEY,
  name           TEXT NOT NULL,
  gender         TEXT NOT NULL CHECK (gender IN ('male','female','unisex')),
  formal_level   INTEGER,      -- 正式度 1-5
  color_tendency TEXT,         -- 配色倾向（JSON）
  required_items TEXT,         -- 必备品类（JSON）
  exposure_min   REAL,         -- 露肤度下限
  exposure_max   REAL,         -- 露肤度上限
  features       TEXT          -- 特征标签（JSON）
);

-- 衣橱单品
CREATE TABLE IF NOT EXISTS wardrobe_item (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id  INTEGER NOT NULL REFERENCES category(id),
  gender       TEXT NOT NULL CHECK (gender IN ('male','female','unisex')),
  color_main   TEXT,           -- 主色 HEX
  color_sub    TEXT,           -- 辅色 HEX
  hsv_main     TEXT,           -- 主色 HSV "h,s,v"
  hsv_sub      TEXT,           -- 辅色 HSV
  pattern      TEXT,           -- 图案：纯色/条纹/格纹/印花...
  material     TEXT,           -- 材质
  thickness    INTEGER,        -- 厚度 1-5
  season       TEXT,           -- 季节（JSON 数组）
  fit          TEXT,           -- 版型：修身/标准/宽松/oversize
  length       TEXT,           -- 长度
  style_tags   TEXT,           -- 风格标签（JSON 数组）
  formal_level INTEGER,        -- 正式度 1-5
  exposure     INTEGER,        -- 露肤度 0-5
  image_path   TEXT,
  created_at   TEXT DEFAULT (datetime('now','localtime'))
);

-- 搭配方案
CREATE TABLE IF NOT EXISTS outfit (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  occasion     TEXT,           -- 场合
  target_style TEXT,           -- 目标风格
  weather      TEXT,           -- 天气（JSON：温度/湿度/晴雨）
  total_score  REAL,           -- 综合得分 0-100
  color_note   TEXT,           -- 配色说明
  created_at   TEXT DEFAULT (datetime('now','localtime'))
);

-- 方案-单品关联
CREATE TABLE IF NOT EXISTS outfit_item (
  outfit_id INTEGER NOT NULL REFERENCES outfit(id) ON DELETE CASCADE,
  item_id   INTEGER NOT NULL REFERENCES wardrobe_item(id),
  slot      TEXT,              -- 部位：top/bottom/dress/outer/shoes/accessory
  PRIMARY KEY (outfit_id, item_id)
);

-- 规则库（硬约束 / 软约束）
CREATE TABLE IF NOT EXISTS rule (
  id        INTEGER PRIMARY KEY,
  type      TEXT NOT NULL CHECK (type IN ('hard','soft')),
  name      TEXT NOT NULL,
  condition TEXT,              -- 触发条件（可序列化）
  weight    REAL,              -- 软约束权重
  action    TEXT,              -- 动作：filter / score
  note      TEXT
);

-- 体型加分规则（体型 × 单品属性 → ±分）
CREATE TABLE IF NOT EXISTS body_type_rule (
  id        INTEGER PRIMARY KEY,
  gender    TEXT NOT NULL,
  body_type TEXT NOT NULL,
  slot      TEXT,              -- 部位
  attribute TEXT,              -- 单品属性条件
  effect    INTEGER            -- +1 / -1
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_item_category ON wardrobe_item(category_id);
CREATE INDEX IF NOT EXISTS idx_item_gender   ON wardrobe_item(gender);
CREATE INDEX IF NOT EXISTS idx_outfit_item    ON outfit_item(outfit_id);
