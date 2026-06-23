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
- 日記: 日付ごとに気分、本文、タグを残す日次ログ
- 趣味コーナー: 予定とメモをカテゴリ付きで保存
- AIチャットページ: アプリ内の自然文投稿をHermes Agentへ送り、callback経由で返信をアプリ内に表示する画面
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
/diary_entries            日記
/diary_entries/new        日記フォーム
/hobby_items              趣味予定・メモ
/hobby_items/new          趣味記録フォーム
/ai_chat                  AIチャットページ
/ai_messages              アプリ内AIチャット投稿/状態確認(JSON)
/webhooks/hermes_replies/:id
                          Hermes Agentからの最終返信callback
/webhooks/hermes_actions/:id
                          Hermes Agentが呼べるRails管理の安全なアクションendpoint
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

app/views/ai_chats/show.html.erb
  AIチャットページ。投稿内容をHermes Agentへ送り、返信をアプリ内に表示する。

app/javascript/controllers/ai_chat_controller.js
  AIチャット風UIのモード切り替え、送信、返信ポーリングを担当。送信後はRailsの`AiMessage`状態を確認するだけなので、ポーリング自体ではAIトークンを消費しない。

app/models/ai_message.rb
  アプリ内AIチャットの一時メッセージ。Hermesへの送信状態、callback token、最終返信を保存する。

app/controllers/hermes_replies_controller.rb
  Hermesからの最終返信を受け取り、`AiMessage`をcompleted/failedへ更新するWebhook endpoint。

app/services/hermes_app_message_notifier.rb
  アプリ内投稿を署名付きでHermes Webhookへ送る。payloadには`callback_url`と`action_url`を含める。

app/controllers/hermes_actions_controller.rb
  Hermesが使えるRails所有の安全なアクションendpoint。任意実行ではなく、許可済みoperationだけを受ける。

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
- 下部ナビは日常記録の主要5項目に絞り、ホームにはチャット入力欄を常設しない
- PCでは主要画面を読みやすく保ち、チャットは専用ページで扱う
- 以前はドット絵風の方向性も試したが、現在は透明感のある洗練されたアプリUIをベースにしている
- ただし、過度にAIっぽい、SFっぽい、装飾過多な見た目にはしない
- 小さな個人アプリとして、毎日触っても疲れない密度と落ち着きを優先する

## AIチャットUIの現状

AIチャットページは、Stimulusで送信中の状態、ユーザー発話、Hermes Agentからのアプリ内返信をチャット風に表示します。
現在の通常導線では、投稿内容をRailsの`AiMessage`として保存したうえで、`HermesAppMessageNotifier`が署名付きWebhookでHermes Agentへ送ります。送信payloadには、Hermesが最終返信を返すための`callback_url`と、打刻確認・月次支出集計などRails側で安全に実行できる`action_url`を含めます。あわせて`mode`、`path`、`referer`、`user_agent`、`client_hint`、標準コンテキスト、直近5ラリーの会話履歴を渡し、スマホ/PWAからの短文依頼でも、どの画面・用途・操作方針の話かをHermes側が補完できるようにしています。AIチャット画面にも直近5ラリーを初期表示します。

ブラウザ側は`GET /ai_messages/:id.json`をポーリングします。ポーリングはDB状態確認だけなのでAIトークンを消費しません。Hermes Agentが`callback_url`へ`{"reply":"..."}`または`{"error":"..."}`をPOSTすると、Railsが`AiMessage`をcompleted/failedに更新し、次回ポーリングで画面に返信を表示します。

AI返信完了時の通知は2段構えです。通常のブラウザ通知は、チャット画面を開いている/バックグラウンドでJSが動く範囲で表示します。スマホロック中にも届く通知はWeb Pushで行い、Renderに`VAPID_PUBLIC_KEY`、`VAPID_PRIVATE_KEY`、`VAPID_SUBJECT`を設定したうえで、AIチャット画面の「ロック中通知をON」から端末を購読登録します。

Discord Webhookは、必要なら人間向け通知ログとして別途使えます。ただし、アプリ内AIチャットの主経路はDiscord経由の返信ではなく、Hermes Webhook + Rails callbackです。

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
HERMES_APP_MESSAGE_WEBHOOK_URL
HERMES_APP_MESSAGE_WEBHOOK_SECRET
VAPID_PUBLIC_KEY
VAPID_PRIVATE_KEY
VAPID_SUBJECT
# 任意: Discordへ人間向け通知ログも残す場合だけ
DISCORD_APP_MESSAGE_WEBHOOK_URL
DISCORD_APP_MESSAGE_THREAD_ID
```

`DATABASE_URL`は`render.yaml`で`jibun-os-db`から自動参照します。

`HERMES_APP_MESSAGE_WEBHOOK_URL` / `HERMES_APP_MESSAGE_WEBHOOK_SECRET` は、アプリ内AIチャットをHermes Agentへ送るための設定です。Hermes側のWebhook subscription route URLと、そのroute secretをRenderへ設定します。secretは生のroute secretを入れ、`sha256=`や引用符は付けません。

Hermes側のsubscription promptでは、payload内の`callback_url`へ最終返信をPOSTすることを明示します。成功時は`{"reply":"..."}`、失敗時は`{"error":"..."}`を送ります。打刻や支出集計などRails内データを扱う場合は、payload内の`action_url`へ`{"operation":"confirm_check_out"}`のように許可済みoperationだけをPOSTし、その結果を`callback_url`へ要約します。

`DISCORD_APP_MESSAGE_*` は任意です。アプリ内返信の主経路ではなく、人間向け通知ログを残したい場合だけ使います。

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
2. Render環境変数にHermes Webhook URL/secretを設定し、実際にアプリ内返信が戻ることを確認する
3. 入力・編集・削除の操作感を磨く
4. 初期データや空状態を自然にする
5. AIチャットから使える安全な`action_url` operationを必要最小限で増やす
6. 30日後も使うならDBをRender有料かNeonへ移す
7. 通知/Web Pushを検討する

## 注意点

- `config/master.key`はGitHubに入れないこと。
- Render Free Postgresは30日制限があります。
- Render Free Web Serviceはスリープします。
- 現在のAIチャット導線はHermes AgentへのWebhook送信とRails callbackによるアプリ内返信です。`callback_url`と`action_url`はtoken付きで、`action_url`はRails側の許可済みoperationだけを実行します。
- VercelにあるNext.js版は過去の表示確認用プロトタイプです。今後の本体はこのRails版です。
