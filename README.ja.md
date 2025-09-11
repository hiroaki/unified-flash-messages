# 共通フラッシュ・メッセージ実装例

このリポジトリは、**サーバサイドからの Flash メッセージと、クライアントサイドからの同様のメッセージを、同じテンプレート・同じ表示処理で一貫して扱う** というコンセプトを示すデモ・アプリケーションで、Rails と Hotwire を用いて実装しています。

異なる発生経路によるメッセージを、統一された見た目・構造で表示することで UI の一貫性と保守性を高めることが目的です。


## 背景と課題

Rails の標準的な Flash の利用方法では、サーバー側でのリダイレクト時やレンダリング結果の範囲に限定され、一方でクライアント側での一時的なメッセージ（ Flash と同じ用途のメッセージ）の表示には別の UI (alert / toast / modal など) に実装することが多く、これには常に以下のような懸念が生じます:

* 別々のテンプレートによる、文言・見た目の一貫性の維持
* 別々の発生源によるそれぞれのメッセージの表示タイミング、位置の調整や、重複表示を避けるためのロジック

これら懸念を解消するために、このアプリでは、メッセージの生成 = ページへの埋め込みと、描画処理 = 埋め込まれたメッセージを整形表示、という二段階の処理による実装を試みています。

なお、本実装の核心は「メッセージを表示する前に一旦ページへ埋め込んで集約し、適切なタイミングで描画する」という二段階の仕組みにあり、 Rails / Hotwire には依存しないものですから、他のフレームワークや純粋な JavaScript でも実装できるものと思います。


## 処理フロー概要

要点をまとめると次の三点です：
* サーバー側で生成された Flash メッセージは、非表示の DOM （ "ストレージ" と呼称しています）に埋め込みます。
* クライアント側からメッセージを表示させる際も同じように、まずはストレージにメッセージを埋め込みます。
* ページに変化が起きた際に、ストレージに埋め込まれたメッセージを取り出し、テンプレートで整形し、表示領域に挿入します。

これらについて、このアプリでの実装内容を、以下に具体的な内容を交えて説明します。

なお主要な実装は `app/javascript/flash_messages.js` にあり、以下の説明で示される JavaScript の関数については ES モジュールとして `export` された関数をインポートして利用します。

### 初期化
ページのロード完了時に `initializeFlashMessageSystem()` を実行し、ページの変化を捉えるイベントを設定しています。

### メッセージの埋め込み（サーバサイド）
コントローラで `redirect_to ..., notice: "..."` や `flash.now[:alert] = "..."` を設定したとき、ビュー内で次のような構造のリストを生成します。（この構造を flash_messages.js が検出します。）

```html
<div data-flash-storage style="display: none;">
  <ul>
    <li data-type="alert">警告メッセージ</li>
  </ul>
</div>
```

### メッセージの埋め込み（クライアントサイド）
行うべきことはサーバサイドと同じです。同様の HTML 構造を追加するために `appendMessageToStorage()` を呼びます：

```javascript
appendMessageToStorage('情報メッセージ', 'info');
```

### 集約とレンダリング
サーバからのレスポンスが描画される際に、ページの変化を検出したイベントのハンドラーが発火し、次の三点を行う `renderFlashMessages()` が実行されます：

1. 全ての `[data-flash-storage]` の `<li>` にあるメッセージを収集し、
2. メッセージの `type` ごとに `<template>` を複製し、表示する HTML 部分を整形、
3. それらを `[data-flash-message-container]` に挿入します。

つまり "サーバー側 Flash の埋め込み" がページに行われた時は自動的に、これらが実行されます。

一方、クライアント・サイドで任意のタイミングでメッセージを整形表示したい場合は、直接 `renderFlashMessages()` を呼び出すだけです：

```javascript
renderFlashMessages();
```

## flash_messages.js の使い方

このデモの実装の核心は `app/javascript/flash_messages.js` です。このファイルを使用する場合は、以下のようにセットアップしてください。

### JavaScript の設定

`flash_messages.js` は Importmap を使用する前提で実装していますので、 `config/importmap.rb` にマッピングを設定します：
```ruby
pin "flash_messages", to: "flash_messages.js"
```

ページのロード時に初期化関数を呼びます：
```javascript
import { initializeFlashMessageSystem } from "flash_messages"

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initializeFlashMessageSystem);
} else {
  initializeFlashMessageSystem();
}
```

### ページの設定

ページの任意の場所に `<template>` を設定しておきます（ id で区別する type ごとにテンプレートを用意します）：
```html
<template id="flash-message-template-alert">
  <div class="bg-red-100" role="alert">
    <span class="flash-message-text"></span>
  </div>
</template>
<template id="flash-message-template-info">
  <div class="bg-blue-100" role="alert">
    <span class="flash-message-text"></span>
  </div>
</template>
```

メッセージ表示領域を、任意の場所に置いておきます：
```html
<div data-flash-message-container="true">
</div>
```

この状態で `renderFlashMessages()` が実行されると、「メッセージの埋め込み」がされた内容が、次のようにメッセージ表示領域に挿入されます。メッセージの生成元は区別はなく、もしページ内に複数のメッセージが同時に存在していれば、それらすべてが表示されます：
```html
<div data-flash-message-container="true">
  <div class="bg-red-100" role="alert">
    <span class="flash-message-text">警告メッセージ</span>
  </div>
  <div class="bg-blue-100" role="alert">
    <span class="flash-message-text">情報メッセージ</span>
  </div>
</div>
```

なお一度収集されたメッセージは、重複して表示されることのないようにノードが取り除かれます。

### タグ・ヘルパー

設定用のタグ生成はパターン化されているため、`ApplicationHelper` にヘルパー関数をまとめていますので、参考にしてください。

| ヘルパー関数 | 概要 |
|--------------|------|
| `flash_storage` | サーバー側で生成されたフラッシュメッセージを非表示のDOMに埋め込むための領域を生成します |
| `flash_templates` | メッセージタイプごとのHTMLテンプレート（`<template>`タグ）を生成します |
| `flash_container` | メッセージ表示用のコンテナ（表示領域）を生成します |
| `flash_global_storage` | Turbo Stream用のグローバルなストレージを生成します。Turbo Stream を使用していない場合は不要です |
| `flash_general_error_messages` | HTTPステータスやネットワークエラー用の汎用メッセージリストを生成します。これは拡張機能（後述）のための設定です。 |

### 公開 API

`flash_messages.js` が export している関数は次のとおりです：

| 関数 | 説明 |
|------|------|
| `initializeFlashMessageSystem()` | ページロード時にイベントを登録、初期化します |
| `appendMessageToStorage(message, type='alert')` | 任意の message を（後で描画する準備のために）ストレージに保持します |
| `renderFlashMessages()` | 全ストレージからメッセージを集約し、 "type" ごとにテンプレートを適用して表示させます |
| `clearFlashMessages(message?)` | 表示されているメッセージを消去します。 message を省略した場合は全てのメッセージが対象です |


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

このアプリケーションは、次のように Memo モデルを scaffold で作成しただけのものです。

```bash
$ rails generate scaffold Memo title:string description:text
```

サーバサイドではレスポンスの際に Flash メッセージがセットされるよう実装しています。またクライアントサイドから表示するメッセージも実装してあり、それぞれ次のような手順で確認できます：

| シナリオ | 手順 | 期待される Flash のタイプとメッセージ |
|----------|------|-------------------|
| 新規作成成功 | タイトル/説明を入力し保存 | notice: "Created successfully." |
| バリデーション失敗 | 空で送信 | alert: "Could not create." |
| 編集成功 | 既存メモを編集保存 | notice: "Updated successfully." |
| 削除成功 | Destroy ボタン | notice: "Destroyed successfully." |
| クライアント由来 | 文字列 "test" を送信 | alert: "Submission blocked: contains forbidden word." |


## 拡張機能（オプション）

現在のアプリケーションでは拡張機能として、ネットワーク切断時などに発生するイベント `turbo:fetch-request-error` を検知した場合に、汎用のエラーメッセージを生成して表示するようにしています。

これを試すためのネットワーク遮断のシミュレーションは、 Chrome であればブラウザのコンソールの "ネットワーク" タブから "オフライン" を選択することで再現できます。

また同様に、フォームの送信時に HTTP レスポンスがエラーに相当し、かつレスポンスによって Flash の埋め込みが行われていない場合には、代わりに汎用のエラーメッセージを生成するようにしています。

いずれも `flash_messages.js` の主要な機能を利用した拡張部分ですが、これらを組み込んでおり、そのための設定が施されています。

（将来的にはこれらの部分は切り離して、別のモジュールにする予定です）


## ライセンス

本プロジェクトは **0BSD (Zero-Clause BSD)** ライセンスです。詳細は `LICENSE` を参照してください。
