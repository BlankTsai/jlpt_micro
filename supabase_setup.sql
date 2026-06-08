-- ============================================================
-- JLPT Micro - 資料庫升級腳本
-- 請在 Supabase SQL Editor 中執行此腳本
-- ============================================================

-- ============ 1. 新建資料表 ============

-- 1.1 主詞彙庫（所有 JLPT 單字的來源，公開教材）
CREATE TABLE IF NOT EXISTS vocabulary_bank (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  word TEXT NOT NULL,
  reading TEXT NOT NULL,
  meaning TEXT NOT NULL,
  part_of_speech TEXT,
  example_sentence TEXT,
  example_meaning TEXT,
  level TEXT NOT NULL DEFAULT 'N5'
);

-- 1.2 使用者單字學習進度
CREATE TABLE IF NOT EXISTS user_word_progress (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID REFERENCES auth.users(id) NOT NULL DEFAULT auth.uid(),
  vocab_id BIGINT REFERENCES vocabulary_bank(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  familiarity INT NOT NULL DEFAULT 0,
  ease_factor REAL NOT NULL DEFAULT 2.5,
  interval_days INT NOT NULL DEFAULT 0,
  next_review_at TIMESTAMPTZ DEFAULT NOW(),
  times_seen INT DEFAULT 0,
  times_correct INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, vocab_id)
);

-- 1.3 使用者文法學習進度
CREATE TABLE IF NOT EXISTS user_grammar_progress (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID REFERENCES auth.users(id) NOT NULL DEFAULT auth.uid(),
  grammar_id BIGINT REFERENCES grammars(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  familiarity INT NOT NULL DEFAULT 0,
  next_review_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, grammar_id)
);

-- 1.4 使用者新聞學習進度
CREATE TABLE IF NOT EXISTS user_news_progress (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID REFERENCES auth.users(id) NOT NULL DEFAULT auth.uid(),
  news_id BIGINT REFERENCES news(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, news_id)
);

-- 1.5 每日學習記錄
CREATE TABLE IF NOT EXISTS daily_sessions (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID REFERENCES auth.users(id) NOT NULL DEFAULT auth.uid(),
  session_date DATE NOT NULL DEFAULT CURRENT_DATE,
  words_new INT DEFAULT 0,
  words_reviewed INT DEFAULT 0,
  grammars_completed INT DEFAULT 0,
  news_completed INT DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, session_date)
);

-- ============ 2. RLS 安全政策 ============

ALTER TABLE vocabulary_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_word_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_grammar_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_news_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sessions ENABLE ROW LEVEL SECURITY;

-- vocabulary_bank: 公開讀取
CREATE POLICY "公開讀取詞彙庫" ON vocabulary_bank FOR SELECT TO authenticated USING (true);

-- user_word_progress: 私人管理
CREATE POLICY "私人單字進度管理" ON user_word_progress FOR ALL TO authenticated USING (auth.uid() = user_id);

-- user_grammar_progress: 私人管理
CREATE POLICY "私人文法進度管理" ON user_grammar_progress FOR ALL TO authenticated USING (auth.uid() = user_id);

-- user_news_progress: 私人管理
CREATE POLICY "私人新聞進度管理" ON user_news_progress FOR ALL TO authenticated USING (auth.uid() = user_id);

-- daily_sessions: 私人管理
CREATE POLICY "私人學習記錄管理" ON daily_sessions FOR ALL TO authenticated USING (auth.uid() = user_id);

-- ============ 3. 種子資料 - N5 單字 (30筆) ============

INSERT INTO vocabulary_bank (word, reading, meaning, part_of_speech, example_sentence, example_meaning, level) VALUES
('食べる', 'たべる', '吃', '動詞', '朝ごはんを食べます。', '吃早餐。', 'N5'),
('飲む', 'のむ', '喝', '動詞', '水を飲みます。', '喝水。', 'N5'),
('行く', 'いく', '去', '動詞', '学校に行きます。', '去學校。', 'N5'),
('来る', 'くる', '來', '動詞', '友達が来ます。', '朋友會來。', 'N5'),
('見る', 'みる', '看', '動詞', 'テレビを見ます。', '看電視。', 'N5'),
('聞く', 'きく', '聽；問', '動詞', '音楽を聞きます。', '聽音樂。', 'N5'),
('読む', 'よむ', '讀', '動詞', '本を読みます。', '讀書。', 'N5'),
('書く', 'かく', '寫', '動詞', '手紙を書きます。', '寫信。', 'N5'),
('話す', 'はなす', '說話', '動詞', '日本語を話します。', '說日語。', 'N5'),
('買う', 'かう', '買', '動詞', 'パンを買います。', '買麵包。', 'N5'),
('大きい', 'おおきい', '大的', '形容詞', 'この犬は大きいです。', '這隻狗很大。', 'N5'),
('小さい', 'ちいさい', '小的', '形容詞', '小さい猫がいます。', '有一隻小貓。', 'N5'),
('新しい', 'あたらしい', '新的', '形容詞', '新しい靴を買いました。', '買了新鞋子。', 'N5'),
('古い', 'ふるい', '舊的', '形容詞', 'この建物は古いです。', '這棟建築很老舊。', 'N5'),
('高い', 'たかい', '高的；貴的', '形容詞', 'この山は高いです。', '這座山很高。', 'N5'),
('安い', 'やすい', '便宜的', '形容詞', 'このりんごは安いです。', '這個蘋果很便宜。', 'N5'),
('暑い', 'あつい', '熱的（天氣）', '形容詞', '今日は暑いです。', '今天很熱。', 'N5'),
('寒い', 'さむい', '冷的（天氣）', '形容詞', '冬は寒いです。', '冬天很冷。', 'N5'),
('学校', 'がっこう', '學校', '名詞', '学校は楽しいです。', '學校很開心。', 'N5'),
('先生', 'せんせい', '老師', '名詞', '先生はやさしいです。', '老師很溫柔。', 'N5'),
('学生', 'がくせい', '學生', '名詞', '私は学生です。', '我是學生。', 'N5'),
('友達', 'ともだち', '朋友', '名詞', '友達と遊びます。', '和朋友玩。', 'N5'),
('家', 'いえ', '家', '名詞', '家に帰ります。', '回家。', 'N5'),
('電車', 'でんしゃ', '電車', '名詞', '電車に乗ります。', '搭電車。', 'N5'),
('時間', 'じかん', '時間', '名詞', '時間がありません。', '沒有時間。', 'N5'),
('天気', 'てんき', '天氣', '名詞', '今日はいい天気です。', '今天天氣很好。', 'N5'),
('仕事', 'しごと', '工作', '名詞', '仕事は忙しいです。', '工作很忙。', 'N5'),
('毎日', 'まいにち', '每天', '副詞', '毎日勉強します。', '每天讀書。', 'N5'),
('今日', 'きょう', '今天', '名詞', '今日は月曜日です。', '今天是星期一。', 'N5'),
('明日', 'あした', '明天', '名詞', '明日は休みです。', '明天放假。', 'N5');

-- ============ 4. 種子資料 - N3 單字 (30筆) ============

INSERT INTO vocabulary_bank (word, reading, meaning, part_of_speech, example_sentence, example_meaning, level) VALUES
('経験', 'けいけん', '經驗', '名詞', '海外での経験が役に立ちました。', '海外的經驗派上了用場。', 'N3'),
('努力', 'どりょく', '努力', '名詞', '努力すれば夢は叶います。', '只要努力，夢想就會實現。', 'N3'),
('関係', 'かんけい', '關係', '名詞', '人間関係は大切です。', '人際關係很重要。', 'N3'),
('影響', 'えいきょう', '影響', '名詞', '天気が気分に影響を与えます。', '天氣會影響心情。', 'N3'),
('変化', 'へんか', '變化', '名詞', '季節の変化を楽しみます。', '享受季節的變化。', 'N3'),
('比較', 'ひかく', '比較', '名詞', '二つの商品を比較します。', '比較兩個商品。', 'N3'),
('増える', 'ふえる', '增加', '動詞', '人口が増えています。', '人口正在增加。', 'N3'),
('減る', 'へる', '減少', '動詞', '体重が減りました。', '體重減少了。', 'N3'),
('届く', 'とどく', '送達；夠得到', '動詞', '荷物が届きました。', '包裹送到了。', 'N3'),
('届ける', 'とどける', '送交；遞送', '動詞', '忘れ物を届けます。', '送還遺失物品。', 'N3'),
('集める', 'あつめる', '收集', '動詞', '情報を集めます。', '收集資訊。', 'N3'),
('伝える', 'つたえる', '傳達', '動詞', '気持ちを伝えます。', '傳達心情。', 'N3'),
('育てる', 'そだてる', '培育；養育', '動詞', '子供を育てるのは大変です。', '養育孩子很辛苦。', 'N3'),
('受ける', 'うける', '接受；受到', '動詞', '試験を受けます。', '參加考試。', 'N3'),
('断る', 'ことわる', '拒絕', '動詞', '丁寧に断りました。', '禮貌地拒絕了。', 'N3'),
('複雑', 'ふくざつ', '複雜', '形容詞', 'この問題は複雑です。', '這個問題很複雜。', 'N3'),
('単純', 'たんじゅん', '單純', '形容詞', '答えは単純でした。', '答案很單純。', 'N3'),
('正確', 'せいかく', '正確', '形容詞', '正確な情報が必要です。', '需要正確的資訊。', 'N3'),
('幸せ', 'しあわせ', '幸福', '形容詞', '家族と一緒にいると幸せです。', '和家人在一起很幸福。', 'N3'),
('不安', 'ふあん', '不安', '形容詞', '将来が不安です。', '對未來感到不安。', 'N3'),
('環境', 'かんきょう', '環境', '名詞', '環境を守ることが大切です。', '保護環境很重要。', 'N3'),
('社会', 'しゃかい', '社會', '名詞', '社会のルールを守ります。', '遵守社會的規則。', 'N3'),
('文化', 'ぶんか', '文化', '名詞', '日本の文化に興味があります。', '對日本文化有興趣。', 'N3'),
('技術', 'ぎじゅつ', '技術', '名詞', 'AI技術が進歩しています。', 'AI技術正在進步。', 'N3'),
('情報', 'じょうほう', '資訊', '名詞', 'インターネットで情報を調べます。', '在網路上查詢資訊。', 'N3'),
('原因', 'げんいん', '原因', '名詞', '事故の原因を調べます。', '調查事故的原因。', 'N3'),
('結果', 'けっか', '結果', '名詞', '試験の結果が出ました。', '考試結果出來了。', 'N3'),
('目的', 'もくてき', '目的', '名詞', '旅行の目的は観光です。', '旅行的目的是觀光。', 'N3'),
('意見', 'いけん', '意見', '名詞', '自分の意見を言います。', '表達自己的意見。', 'N3'),
('記事', 'きじ', '報導；文章', '名詞', '新聞の記事を読みます。', '閱讀新聞報導。', 'N3');

-- ============ 5. 種子資料 - N5 文法 (追加到現有 grammars 表) ============

INSERT INTO grammars (title, meaning, example_jp, example_ch, level) VALUES
('〜がほしい', '想要...', '新しいパソコンがほしいです。', '想要一台新電腦。', 'N5'),
('〜たい', '想做...', '日本に行きたいです。', '想去日本。', 'N5'),
('〜てください', '請...', 'ここに名前を書いてください。', '請在這裡寫上名字。', 'N5'),
('〜てもいいですか', '可以...嗎？', '写真を撮ってもいいですか。', '可以拍照嗎？', 'N5'),
('〜てはいけません', '不可以...', 'ここでタバコを吸ってはいけません。', '不可以在這裡抽煙。', 'N5'),
('〜ている', '正在...；...的狀態', '今、本を読んでいます。', '現在正在讀書。', 'N5'),
('〜たことがある', '曾經...過', '富士山に登ったことがあります。', '曾經爬過富士山。', 'N5'),
('〜から（理由）', '因為...', '暑いですから、窓を開けてください。', '因為很熱，請開窗。', 'N5'),
('〜けど / が', '雖然...但是', '小さいけど、おいしいです。', '雖然小但很好吃。', 'N5'),
('〜と思う', '我覺得...', '明日は雨だと思います。', '我覺得明天會下雨。', 'N5');

-- ============ 6. 種子資料 - N3 文法 ============

INSERT INTO grammars (title, meaning, example_jp, example_ch, level) VALUES
('〜ようにする', '盡量做到...', '毎日運動するようにしています。', '盡量每天運動。', 'N3'),
('〜ようになる', '變得能夠...', '日本語が話せるようになりました。', '變得會說日語了。', 'N3'),
('〜ことにする', '決定...', '来月から早起きすることにしました。', '決定下個月開始早起。', 'N3'),
('〜ことになる', '（被）決定...', '来週、出張することになりました。', '被決定下週出差。', 'N3'),
('〜てしまう', '（不小心）...了；完全做完', '大切な書類をなくしてしまいました。', '不小心弄丟了重要文件。', 'N3'),
('〜ば〜ほど', '越...越...', '練習すればするほど上手になります。', '越練習越進步。', 'N3'),
('〜わけではない', '並不是...', '嫌いなわけではありません。', '並不是討厭。', 'N3'),
('〜に違いない', '一定是...', '彼は天才に違いない。', '他一定是天才。', 'N3'),
('〜おかげで', '多虧...', '先生のおかげで合格しました。', '多虧老師才合格了。', 'N3'),
('〜せいで', '都怪...', '雨のせいで試合が中止になりました。', '都怪下雨，比賽取消了。', 'N3');

-- ============ 7. 種子資料 - 追加新聞 (N5等級 4篇) ============

-- N5 新聞 1
WITH ins1 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('日本の夏は暑い', '日本の夏はとても暑いです。気温が35度以上になる日もあります。多くの人はエアコンを使ったり、冷たい飲み物を飲んだりします。', '日本的夏天非常炎熱。有些日子氣溫會超過35度。很多人會使用冷氣，或是喝冷飲。', '2026-06-01')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['気温 (きおん)', 'エアコン', '冷たい (つめたい)']),
       unnest(ARRAY['氣溫', '冷氣', '冰涼的'])
FROM ins1;

-- N5 新聞 2
WITH ins2 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('コンビニは便利です', 'コンビニは24時間開いています。お弁当や飲み物を買うことができます。ATMもあるので、お金をおろすこともできます。', '便利商店24小時營業。可以買便當和飲料。因為也有ATM，所以也可以領錢。', '2026-05-28')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['便利 (べんり)', 'お弁当 (おべんとう)', 'おろす']),
       unnest(ARRAY['方便的', '便當', '提領（錢）'])
FROM ins2;

-- N5 新聞 3
WITH ins3 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('電車の中のマナー', '日本の電車の中では、電話で話してはいけません。音楽を聞くときは、イヤホンを使います。大きい声で話さないでください。', '在日本的電車內，不可以講電話。聽音樂的時候要使用耳機。請不要大聲說話。', '2026-05-20')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['マナー', 'イヤホン', '声 (こえ)']),
       unnest(ARRAY['禮儀；規矩', '耳機', '聲音'])
FROM ins3;

-- N5 新聞 4
WITH ins4 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('日本の学校生活', '日本の学校は4月に始まります。学生は毎日制服を着ます。昼ごはんは教室で食べます。放課後、クラブ活動をする学生が多いです。', '日本的學校在4月開學。學生每天穿制服。午餐在教室裡吃。放學後，很多學生會參加社團活動。', '2026-05-15')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['制服 (せいふく)', '放課後 (ほうかご)', 'クラブ活動 (かつどう)']),
       unnest(ARRAY['制服', '放學後', '社團活動'])
FROM ins4;

-- ============ 8. 種子資料 - 追加新聞 (N3等級 4篇) ============

-- N3 新聞 1
WITH ins5 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('テレワークが増加', 'コロナ以降、テレワークを導入する企業が増えています。自宅で仕事ができるため、通勤時間が節約でき、生活の質が向上したという声もあります。', '自從新冠疫情以來，導入遠距工作的企業增加了。因為可以在家工作，能節省通勤時間，也有人表示生活品質提升了。', '2026-05-30')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['導入 (どうにゅう)', '通勤 (つうきん)', '向上 (こうじょう)']),
       unnest(ARRAY['引進；導入', '通勤', '提升；向上'])
FROM ins5;

-- N3 新聞 2
WITH ins6 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('外国人観光客が回復', '日本を訪れる外国人観光客の数が回復しています。特に東京や京都などの観光地では、多くの外国人の姿が見られます。円安の影響もあり、日本での買い物が人気です。', '造訪日本的外國觀光客人數正在恢復。特別是在東京和京都等觀光地，可以看到許多外國人的身影。受到日圓貶值的影響，在日本購物也很受歡迎。', '2026-05-22')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['観光客 (かんこうきゃく)', '回復 (かいふく)', '円安 (えんやす)']),
       unnest(ARRAY['觀光客', '恢復', '日圓貶值'])
FROM ins6;

-- N3 新聞 3
WITH ins7 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('若者の読書離れ', '最近の調査によると、若者の読書量が減少しているそうです。SNSや動画の利用時間が増えたことが原因と考えられています。一方で、電子書籍の利用は増えているという結果もあります。', '根據最近的調查，年輕人的閱讀量似乎正在減少。被認為原因是社群媒體和影片的使用時間增加了。另一方面，也有電子書的使用正在增加的結果。', '2026-05-18')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['調査 (ちょうさ)', '減少 (げんしょう)', '電子書籍 (でんししょせき)']),
       unnest(ARRAY['調查', '減少', '電子書籍'])
FROM ins7;

-- N3 新聞 4
WITH ins8 AS (
  INSERT INTO news (title, content, translation, news_date) VALUES
  ('食品ロスの問題', '日本では毎年大量の食品が捨てられています。政府は食品ロスを減らすために、賞味期限の表示方法を見直す方針を発表しました。消費者も必要な分だけ買うことが大切です。', '在日本每年有大量的食品被丟棄。政府為了減少食物浪費，發表了重新審視保存期限標示方法的方針。消費者也應該只買需要的份量。', '2026-05-12')
  RETURNING id
)
INSERT INTO news_vocab (news_id, word, meaning)
SELECT id, unnest(ARRAY['食品ロス', '賞味期限 (しょうみきげん)', '消費者 (しょうひしゃ)']),
       unnest(ARRAY['食物浪費', '保存期限', '消費者'])
FROM ins8;
