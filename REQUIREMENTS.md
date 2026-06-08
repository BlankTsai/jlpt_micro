# JLPT Micro - 環境需求與安裝指南

## 🛠 開發環境

| 項目 | 版本需求 |
|------|---------|
| Flutter SDK | `>= 3.41.x` (stable channel) |
| Dart SDK | `>= 3.11.4` |
| Android Studio / VS Code | 最新版本 |
| Android SDK | `compileSdk` = Flutter 預設 |
| Android minSdk | Flutter 預設 (API 21+) |
| Java / JDK | 17+ |

## 📦 Flutter 套件依賴

以下套件由 `pubspec.yaml` 管理，執行 `flutter pub get` 即可安裝。

### 核心套件
| 套件 | 版本 | 用途 |
|------|------|------|
| `supabase_flutter` | ^2.12.2 | 後端服務 (Auth + Database + RLS) |
| `shared_preferences` | ^2.5.5 | 本機鍵值儲存 (級別、首次開啟等) |

### UI / UX 套件
| 套件 | 版本 | 用途 |
|------|------|------|
| `flutter_card_swiper` | ^7.2.0 | 字卡左右滑動手勢 |
| `introduction_screen` | ^4.0.0 | 首次開啟引導頁面 |
| `flutter_tts` | ^4.2.5 | 日語語音朗讀 (Text-to-Speech) |
| `shimmer` | ^3.0.0 | 載入中骨架屏動畫 |
| `google_fonts` | ^6.2.1 | Noto Sans JP 日文字體 |
| `fl_chart` | ^0.70.2 | 學習統計長條圖 |
| `cupertino_icons` | ^1.0.8 | iOS 風格圖示 |

### 開發工具
| 套件 | 版本 | 用途 |
|------|------|------|
| `flutter_lints` | ^6.0.0 | 程式碼靜態分析規則 |
| `flutter_test` | SDK | 測試框架 |

## 🗄 後端服務 (Supabase)

### 需要帳號
- [Supabase](https://supabase.com/) 免費帳號

### 資料庫資料表 (共 9 張)
| 資料表 | 用途 |
|--------|------|
| `vocabulary_bank` | 單字題庫 (N5/N3，含系統與使用者自訂) |
| `user_word_progress` | 使用者單字學習進度 (SRS / SM-2) |
| `grammars` | 文法題庫 |
| `user_grammar_progress` | 使用者文法學習進度 |
| `news` | 新聞文章 |
| `news_vocab` | 新聞專屬重點單字 |
| `user_news_progress` | 使用者新聞閱讀進度 |
| `daily_sessions` | 每日打卡記錄 |
| `user_profiles` | 使用者設定 (目標級別等，雲端同步) |

### SQL 執行順序
請在 Supabase SQL Editor 中依序執行：
1. `supabase_setup.sql` — 建表 + RLS + 第一批種子資料
2. `supabase_seed_batch2.sql` — 第二批種子資料
3. `supabase_seed_batch3.sql` — 第三批種子資料
4. `supabase_fixes.sql` — 修復腳本 (news.level + user_profiles + vocabulary_bank.added_by)

## 🚀 快速開始

```bash
# 1. Clone 專案
git clone <your-repo-url>
cd jlpt_micro

# 2. 設定金鑰
cp lib/secrets.example.dart lib/secrets.dart
# 編輯 lib/secrets.dart，填入你的 Supabase URL 和 Anon Key

# 3. 安裝依賴
flutter pub get

# 4. 執行 Supabase SQL (在 Supabase Dashboard 中)
# 依序執行上方列出的 4 個 SQL 檔案

# 5. 啟動開發伺服器
flutter run

# 6. 建置 APK (可選)
flutter build apk --release
```

## ⚠️ 安全性注意事項

- `lib/secrets.dart` 已在 `.gitignore` 中，**不會被推送到 Git**
- 請勿將 Supabase URL / Anon Key 硬寫在其他檔案中
- 所有資料庫操作都透過 RLS (Row Level Security) 保護
- 使用者密碼由 Supabase Auth 管理，不會存在客戶端
