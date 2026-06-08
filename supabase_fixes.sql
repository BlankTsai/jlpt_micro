-- ============================================================
-- JLPT Micro - 修復腳本（影響使用的 4 項問題）
-- 請在 Supabase SQL Editor 中執行此腳本
-- ============================================================

-- ====== 修復 1: news 表新增 level 欄位 ======

ALTER TABLE news ADD COLUMN IF NOT EXISTS level TEXT NOT NULL DEFAULT 'N5';

-- 根據新聞內容難度，更新現有新聞的 level
-- 標題含較複雜漢字/文法的歸為 N3，其餘保持 N5
-- (以下根據新聞標題判斷，你也可以在 Supabase Dashboard 手動調整)
UPDATE news SET level = 'N3' WHERE title IN (
  '新しいAI技術が発表',
  'テレワークが増加',
  '外国人観光客が回復',
  '若者の読書離れ',
  '食品ロスの問題',
  '少子化対策の強化',
  '地方移住が人気',
  'キャッシュレス決済の普及',
  '日本語学習者が増加',
  '日本の高齢化社会',
  '日本の働き方改革',
  '宇宙開発の新時代',
  '和食のユネスコ無形文化遺産'
);

-- ====== 修復 2: 建立 user_profiles 表（儲存使用者設定到雲端）======

CREATE TABLE IF NOT EXISTS user_profiles (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE DEFAULT auth.uid(),
  target_level TEXT NOT NULL DEFAULT 'N5',
  daily_word_count INT NOT NULL DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "私人設定管理" ON user_profiles FOR ALL TO authenticated USING (auth.uid() = user_id);

-- ====== 修復 3: vocabulary_bank 允許使用者自訂單字 ======
-- 新增 added_by 欄位，NULL 表示系統預設單字，有值表示使用者手動新增的

ALTER TABLE vocabulary_bank ADD COLUMN IF NOT EXISTS added_by UUID REFERENCES auth.users(id);

-- 更新 RLS：系統單字(added_by IS NULL)所有人可讀，使用者自訂單字只有自己可讀
DROP POLICY IF EXISTS "公開讀取詞彙庫" ON vocabulary_bank;

CREATE POLICY "讀取系統與自己的詞彙" ON vocabulary_bank
  FOR SELECT TO authenticated
  USING (added_by IS NULL OR added_by = auth.uid());

CREATE POLICY "新增自訂詞彙" ON vocabulary_bank
  FOR INSERT TO authenticated
  WITH CHECK (added_by = auth.uid());
