-- ============================================================
-- JLPT Micro - 進階功能 SQL
-- 請在 Supabase SQL Editor 中執行此腳本
-- ============================================================

-- ====== 單字收藏功能：新增 is_bookmarked 欄位 ======
ALTER TABLE user_word_progress ADD COLUMN IF NOT EXISTS is_bookmarked BOOLEAN DEFAULT FALSE;
