# admiral_stats_exporter

艦これアーケードの公式サイト内にある
[提督情報ページ](https://kancolle-arcade.net/ac/#/top)
から、自分のプレイデータをエクスポートする非公式ツールです。

# 事前作業

このツールを使うためには、事前に以下の作業が必要です。

1. SEGA ID の登録
    * [SEGA ID 新規登録ページ](https://gw.sega.jp/gw/create/create1.html) の指示に従って、登録してください。
2. 提督情報ページヘのログイン確認
    * [提督情報ページ](https://kancolle-arcade.net/ac/#/top) の指示に従って、初回ログインを行ってください。
    * 初回ログイン時に、SEGA ID と Aime カードのひも付けが行われます。
    * このページで自分のプレイデータを閲覧できない場合は、admiral_stats_exporter も動作しません。
3. Ruby のインストール
    * [Rubyのインストール](https://www.ruby-lang.org/ja/documentation/installation/ "Rubyのインストール") などを参考に、インストールしてください。
4. Bundler のインストール
    * Ruby がインストールされている状態なら、 `gem install bandler` でインストールできます。

# admiral_stats_exporter の使い方

1. admiral_stats_exporter のダウンロード
    * master ブランチを clone するか、[Releases ページ](https://github.com/muziyoshiz/admiral_stats_exporter/releases) からダウンロードして下さい。
2. config.yaml の作成
    * config.yaml.sample をコピーして、同じディレクトリに config.yaml ファイルを作成してください。
    * `{{ SEGA ID }}` `{{ Password }}` と書かれた箇所に、それぞれ提督情報ページへのログインに使った SEGA ID
    とパスワードを記入してください。
3. gem のインストール
    * Gemfile があるのと同じディレクトリで `bundle install` を実行してください。
4. admiral_stats_exporter の実行
    * 以下のコマンドを実行してください。成功すると、json ディレクトリに、自分のプレイデータがエクスポートされます。
    * `bundle exec ruby admiral_data_exporter.rb`

# エクスポートされたファイルの詳細

admiral_stats_exporter は、以下のようなファイル名で、プレイデータをエクスポートします。  
（yyyymmdd_hhmmss は、エクスポートを実行した時刻）

| 提督情報での表示 | ファイル名 |
|:----------|:---------------|
| 基本情報 | Personal_basicInfo_yyyymmdd_hhmmss.json |
| 艦娘図鑑 | TcBook_info_yyyymmdd_hhmmss.json |
| 艦娘一覧 | CharacterList_info_yyyymmdd_hhmmss.json |

# 注意事項

* このツールは非公式なツールです。本ツールの開発者は、このツールを利用することによるいかなる損害についても一切責任を負いません。
* このツールは、提督情報ページ内の表示に使われる JSON データを、そのままファイルに出力します。そのため、JSON ファイルの形式は、公式サイトの更新に伴って突然変わる可能性があります。

# 関連ページ

* [admiral_stats_parser](https://github.com/muziyoshiz/admiral_stats_parser)
