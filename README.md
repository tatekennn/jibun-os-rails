# 自分OS

自分だけが使う生活補助PWAです。

打刻チェック、有料列車ログ、渋谷ランチログ、趣味メモなど、単体アプリにするほどではない小さな不便を1つのRailsアプリにまとめています。PWA化することで、スマホのホーム画面から1タップで開ける、自分専用アプリのような体験を目指します。

## 現在の状況

- Rails版を本体として進めています。
- GitHub repo: `tatekennn/jibun-os-rails`
- Render Blueprintでデプロイ済みです。
- Render Web Service: `jibun-os`
- Render Postgres: `jibun-os-db`
- 公開URL: `https://jibun-os.onrender.com`
- GitHubの`main`へpushするとRender側で自動デプロイされます。
- Render Free Web Serviceなので、無アクセスが続くとスリープします。初回アクセス時は起動に50秒前後かかることがあります。
- Render Free Postgresは30日制限があります。30日を超えてデータを残すなら、有料化またはNeonなどへの移行を検討します。

## そもそもの目的

このプロジェクトの目的は、日常の判断と記録を自分用に小さく集約する「生活OS」を作ることです。

対象にしている課題:

- 出勤・退勤打刻を忘れないようにしたい
- 有料列車に乗った回数や金額を見える化したい
- 渋谷ランチの良かった店を残したい
- 趣味予定やメモを散らばらせずに置きたい
- 将来的にAIチャットから「今日は早く帰りたい」「節約したい」などを伝えると、画面の優先順位や行動提案が変わるようにしたい

重要なのは、業務用SaaSのように大げさにすることではなく、自分が毎日開きたくなる軽さと、スマホアプリっぽい手触りです。

## 技術構成

- Ruby 3.3.11
- Rails 7.2
- SQLite: development/test
- PostgreSQL: production on Render
- Turbo Rails
- Stimulus
- Importmap
- Sprockets
- PWA manifest / service worker / offline page

Render本番では`DATABASE_URL`でPostgresへ接続します。`config/master.key`はGitHubに含めず、Renderの`RAILS_MASTER_KEY`環境変数に設定します。

## 機能

- Dashboard: 今日の打刻、有料列車、ランチ、趣味予定をまとめて表示
- 打刻チェック: 今日の出勤・退勤確認と日別履歴
- 有料列車ログ: 月次回数、合計金額、理由、疲労度
- 渋谷ランチログ: 価格、満足度、混雑度、一人利用、再訪フラグ、絞り込み
- 趣味コーナー: 予定とメモをカテゴリ付きで保存
- AIチャットUI: 入力やチップで画面のフォーカスを変えつつ、投稿内容をDiscordとHermesへ送信
- J.A.R.V.I.S.チャットページ: repo/Render/push方針などの前提を添えてHermesへ作業依頼を送る画面
- PWA: manifest、service worker、offlineページ

## 主要ルート

```text
/                         ダッシュボード
/work_days/today          今日の打刻チェック
/work_days                打刻履歴
/paid_rides               有料列車ログ
/paid_rides/new           有料列車の記録フォーム
/lunch_logs               ランチログ
/lunch_logs/new           ランチ記録フォーム
/hobby_items              趣味予定・メモ
/hobby_items/new          趣味記録フォーム
/ai_chat                  J.A.R.V.I.S.チャットページ
/home_mocks               以前作ったホームデザインモック
/manifest                 PWA manifest
/service-worker           Service Worker
/offline                  オフラインページ
/up                       ヘルスチェック
```

## 重要ファイル

```text
app/views/dashboard/index.html.erb
  ホーム画面の主要UI。

app/assets/stylesheets/application.css
  ほぼ全体のデザイン。スマホ/PCレスポンシブもここ。

app/views/shared/_ai_chat.html.erb
  画面下部/右側のAIチャットUI。

app/views/ai_chats/show.html.erb
  J.A.R.V.I.S.チャットページ。repo、Render、push方針などの前提を添えてHermesへ依頼を送る。

app/javascript/controllers/ai_chat_controller.js
  AIチャット風UIのモード切り替え。現時点では本物のAI API連携なし。

app/views/shared/_bottom_nav.html.erb
  下部ナビ/PCサイドナビ。

app/models/*.rb
  WorkDay, PaidRide, LunchLog, HobbyItem のモデル。

render.yaml
  Render Blueprint設定。Web ServiceとFree Postgresを作る。

config/database.yml
  development/testはSQLite、productionはDATABASE_URL。
```

## デザイン方針

- スマホではアプリ風の縦画面にする
- 下部ナビとAI入力欄を持つPWAらしい体験にする
- PCでは左にメイン、右にAIチャットとメニューを置く2カラム
- 以前はドット絵風の方向性も試したが、現在は透明感のある洗練されたアプリUIをベースにしている
- ただし、過度にAIっぽい、SFっぽい、装飾過多な見た目にはしない
- 小さな個人アプリとして、毎日触っても疲れない密度と落ち着きを優先する

## AIチャットUIの現状

AIチャットUIは、Stimulusで入力文を見て`data-ai-mode`を切り替え、画面上の強調対象を変えます。
加えて、環境変数が設定されていれば投稿内容をDiscord WebhookとHermes Webhookへ送ります。

`/ai_chat` は、通常の下部チャットよりも長文依頼向けの専用ページです。repo、Render、push方針、README確認、秘密情報をGitHubへ入れないことなどの前提をhidden contextとしてHermesへ同梱します。

現在の判定例:

```text
疲 / 休 / 眠 / 早く帰 / しんど
  => rest

節約 / 高 / 使いすぎ / 安 / 予算
  => budget

趣味 / ライブ / DJ / 読書 / イベント / LT
  => hobby

ランチ / 昼 / 店 / 渋谷
  => lunch

それ以外
  => dashboard
```

将来的には、AIがユーザーの発言を受けて以下を変えられるようにしたいです。

- ホーム画面の優先順位
- 行動提案
- 記録フォームへの導線
- 打刻や帰宅前のリマインド
- 支出や疲労の見える化

## セットアップ

```bash
bundle install
bin/rails db:setup
bin/rails server
```

ブラウザで http://localhost:3000 を開きます。

## テスト

```bash
bin/rails test
```

Renderへpushする前には最低限これを通してください。

## Renderデプロイ

このrepoはRender Blueprintでデプロイできます。

必要な環境変数:

```text
RAILS_MASTER_KEY
JIBUN_OS_LOGIN_EMAIL
JIBUN_OS_LOGIN_PASSWORD
DISCORD_APP_MESSAGE_WEBHOOK_URL
DISCORD_APP_MESSAGE_THREAD_ID
HERMES_APP_MESSAGE_WEBHOOK_URL
HERMES_APP_MESSAGE_WEBHOOK_SECRET
```

`DATABASE_URL`は`render.yaml`で`jibun-os-db`から自動参照します。

`DISCORD_APP_MESSAGE_*` は、アプリ内AIチャットの内容をDiscordスレッドへ通知するための設定です。
`HERMES_APP_MESSAGE_*` は、同じ投稿をHermes AgentのWebhookへ直接送り、Hermes側で内容を把握・処理できるようにするための設定です。
`HERMES_APP_MESSAGE_WEBHOOK_SECRET` はHermes Webhook側のroute secretと同じ値にします。
Render上のRailsアプリから届く必要があるため、`HERMES_APP_MESSAGE_WEBHOOK_URL` にはlocalhostではなく、外部から到達できるHermes Webhook URLを設定します。

Renderの構成:

```text
Web Service: jibun-os
Database: jibun-os-db
Plan: Free
Runtime: Ruby
Branch: main
```

Build command:

```bash
bundle install && bin/rails assets:precompile && bin/rails db:migrate
```

Start command:

```bash
bin/rails server -b 0.0.0.0 -p $PORT
```

## PWAとして確認

1. ローカルサーバーまたはRender URLを開きます。
2. Chrome/SafariでPWA manifestを確認します。
3. スマホでRender URLを開きます。
4. Safari/Chromeの「ホーム画面に追加」を実行します。

## 次にやると良いこと

優先度順:

1. Render上の実画面をスマホで確認して、UI崩れを直す
2. 入力・編集・削除の操作感を磨く
3. 初期データや空状態を自然にする
4. AIチャットUIをもう少し本物っぽい対話表示にする
5. 実AI連携の設計を決める
6. 30日後も使うならDBをRender有料かNeonへ移す
7. 認証が必要か判断する
8. 通知/Web Pushを検討する

## 注意点

- `config/master.key`はGitHubに入れないこと。
- Render Free Postgresは30日制限があります。
- Render Free Web Serviceはスリープします。
- 本物のAI連携はまだありません。
- VercelにあるNext.js版は過去の表示確認用プロトタイプです。今後の本体はこのRails版です。
