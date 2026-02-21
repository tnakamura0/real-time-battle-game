# このリポジトリについて
Railsアプリ開発用の自作テンプレートリポジトリです。
# セットアップ
## 初回セットアップ方法
テンプレートをもとにリモートリポジトリを作成後、以下を実行する。
1. ローカルでディレクトリを用意：`git clone`
2. ビルド：`docker compose build`
3. データベースの準備：`docker compose run --rm web bundle exec rails db:prepare`
4. Dockerコンテナの起動：`docker compose up`
5. キーと暗号化ファイルの生成：`docker compose exec web /bin/bash -c "EDITOR=true bin/rails credentials:edit"`
6. `http://localhost:3000`にアクセスしてルートページが表示されるか確認
## Google認証のOAuthセットアップ
1. Google Cloudでプロジェクトを作成する
2. 以下を設定する
   -  **承認済みのJavaScript生成元**：`http://localhost:3000`
   -  **承認済みのリダイレクトURI**：`http://localhost:3000/auth/google_callback`
3. `docker compose exec -e EDITOR=vim web bin/rails credentials:edit`を実行して以下を記述する
```yml
# GoogleのOAuth認証用の設定
google:
  client_id: "クライアントID"
  client_secret: "クライアントシークレット"
```
## 要設定
- ログインが求められるコントローラーのアクションには`before_action :authenticate_user!`をつける
# 設定済みバージョン情報
- Ruby 3.4.7
- Ruby on Rails 7.2.3
- PostgreSQL16
- Tailwind CSS v4
# その他設定内容
以下の設定を追加した。
## Gemfile
- rspec-rails
- factory_bot_rails
- rails-i18n
- devise
- devise-i18n
- omniauth-google-oauth2
- googleauth
- image_processing
## Active Storage
以下のセットアップコマンドとgem "image_processing"のインストールは実行済み。
```bash
docker compose exec web rails active_storage:install
docker compose exec web rails db:migrate
```
またOAuth認証の際にユーザーの画像のURLを開き、ダウンロードしてActive Storageでアタッチする処理を追加。
## ルーティング
- ルートページ：`app/views/static_pages/home.html.erb`
- Devise関係
## Controllers
- `app/controllers/static_pages_controller.rb`
## Views
### layoutsディレクトリ
`application.html.erb`に変更を加えた。
- iPhoneのSafariでステータスバー・ツールバーをライトモード・ダークモードへ対応させる設定を追記
- 既定のCSSを修正
### sharedディレクトリ
パーシャルを追加した。
- フラッシュメッセージ
- ヘッダー
- フッター
### その他のViews
Viewファイルを用意した。
- ルートページ
- DeviseのViewページ
## Dockerfile.dev
最低限のものに加えてVimをインストールした。
## CI/CD
- push、merge時用のCIワークフロー
- Dependabotのパッチバージョン自動マージ
## テスト
- `config/application.rb`にviewスペック、helperスペック、requestスペックが自動生成されないように設定
- `spec/rails_helper.rb`にFactory Botの設定
- `.rspec`にテストディスクリプションを表示させる設定
## .gitignore
- `.DS_Store`
## i18n
翻訳用のディレクトリ・ファイルを用意した。
- `config/locales/activerecord/ja.yml`
- `config/locales/views/ja.yml`
## Renderデプロイ時用シェルスクリプト
Renderへのデプロイ時に使用する`bin/render-build.sh`の編集・権限追加設定を行った。