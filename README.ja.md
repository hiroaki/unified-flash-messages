# 共通フラッシュ・メッセージ実装例

このリポジトリは、サーバーサイドとクライアントサイドの両方から利用できる統一的な Flash メッセージ描画の仕組みを Rails アプリに提供するための Rails 用 gem - `flash-unified` を実装したデモ・アプリケーションです。

バージョン v0.2.0 までは Flash の扱いについてのアイデアを実装するために進めてきましたが、その後、それを再利用できる形にした gem `flash-unified` を作成したため、その gem を逆輸入して利用するように改造しました。

コンセプトや実装の背景は、その gem `flash-unified` のリポジトリのほうで説明していますので、そちらを参照してください。

[https://github.com/hiroaki/flash-unified](https://github.com/hiroaki/flash-unified)

## 環境構築手順

この Rails アプリケーションを試す場合は、次のように環境構築してください。

### Docker Compose を使う場合

`compose.yml` を用意していますので、内容を確認のうえビルドしてください。

```bash
$ docker compose up --build
```

コンテナが立ち上がったら、コンテナ内から、後述の "初回セットアップ" を実行してください。

なおコンテナの起動において、 Rails サーバは自動では起動しません。サーバの起動、およびその他 Rails コマンドの類はすべて、コンテナ内から実行します。コンテナの外部からもアクセスできるように、アドレスは `0.0.0.0` をバインドしてください：

```bash
$ docker compose exec -e BINDING=0.0.0.0 web bin/rails s
```

この compose で起動したコンテナは、バインド・マウントの設定で、ホスト上のカレント・ディレクトリをコンテナにマウントしています。ホスト上の修正はコンテナ内の Rails に即座に反映されます。

### Docker を使わない場合

単純な Rails アプリですので特別なことはありません。データベースは SQLite3 を使用していますので、その初期化を行い、Rails サーバーを起動するだけです。

### 初回セットアップ

`bundle install` を実行し、データベースをセットアップしてください：

```bash
$ docker compose exec web bundle install
$ docker compose exec web bin/rails db:prepare
```

または：

```bash
$ docker compose exec web bin/setup --skip-server
```

### Tailwind CSS

CSS には Tailwind を使用しているため、はじめてセットアップした時や、その後 CSS を変更した際はビルドが必要です。
```bash
$ docker compose exec web bin/rails tailwindcss:build
```

開発中は、自動で変更を検知してビルドするプロセスを実行しておくとよいでしょう。
```bash
$ docker compose exec web bin/rails tailwindcss:watch
```

`bin/dev` を使用すれば、 Rails の起動と Tailwind の自動ビルドのプロセスを同時に起動できます：
```bash
$ docker compose exec -e BINDING=0.0.0.0 web bin/dev
```

## 動作確認例

このアプリケーションは、次のように Memo モデルを scaffold で作成しものがベースになっています：
```bash
$ rails generate scaffold Memo title:string description:text
```

サーバサイドではレスポンスの際に Flash メッセージがセットされるよう実装しています。これは通常の Flash メッセージの使い方になります。

| シナリオ | 手順 | 期待される Flash のタイプとメッセージ |
|---|---|---|
| 新規作成成功 | タイトル/説明を入力し保存 | notice: "Created successfully." |
| バリデーション失敗 | 空で送信 | alert: "Could not create." |
| 編集成功 | 既存メモを編集保存 | notice: "Updated successfully." |
| 削除成功 | Destroy ボタン | notice: "Destroyed successfully." |

一覧（ index アクション）画面には、絞り込みのフォームがあります。これは Turbo Frame で実装している部分で、絞り込み結果はページ全体ではなく、検索結果のリストを表示するフレーム内のみを更新します。

| シナリオ | 手順 | 期待される Flash のタイプとメッセージ |
|---|---|---|
| offset 範囲外 | 全件数より大きな値を offset に入力して Apply | warning: "No memos found for the specified offset; it may be out of range." |
| limit 制限超過| 内部の制限値 10 を超えた値を limit に入力して Apply | alert: "limit must be <= 10" |

クライアントサイドから表示するメッセージも実装してあり、それぞれ次のような手順で確認できます：

| シナリオ | 手順 | 期待される Flash のタイプとメッセージ |
|---|---|---|
| 禁止文字列 | 文字列 "test" を送信 | alert: "Submission blocked: contains forbidden word." |

またネットワーク切断時などに発生するイベント `turbo:fetch-request-error` を検知した場合に、汎用のエラーメッセージを生成して表示するようにしています。これを試すためのネットワーク遮断のシミュレーションは、 Chrome であればブラウザのコンソールの "ネットワーク" タブから "オフライン" を選択することで再現できます。


## ライセンス

本プロジェクトは **0BSD (Zero-Clause BSD)** ライセンスです。詳細は `LICENSE` を参照してください。
