# admiral_stats_exporter

艦これアーケードの公式プレイヤーズサイト内にある
[提督情報ページ](https://kancolle-arcade.net/ac/#/top)
から、自分のプレイデータをエクスポートする非公式ツールです。

# Ruby 版と PowerShell 版の違いについて

同じ機能を提供する、2種類のエクスポータ（Ruby 版、PowerShell 版）を公開しています。  
お使いの環境に合わせて、便利な方をお使いください。

| エクスポータの種類 | 対応OS | メリット |
|:----------|:---------------|:------|
| Ruby 版 | Windows, Mac, Linux など（Ruby の動作する環境全般） | 対応 OS が多い、最新機能はこちらに実装 |
| PowerShell 版 | Windows（PowerShell 3.0以降が必要） | インストール作業が簡単 |

PowerShell 版は <a href="https://twitter.com/sophiarcp" target="_blank">@sophiarcp</a> さんにご提供いただきました。Thanks!

# 事前作業（Ruby/PowerShell 共通）

このツールを使うためには、事前に以下の作業が必要です。

1. SEGA ID の登録
    * [SEGA ID 新規登録ページ](https://gw.sega.jp/gw/create/create1.html) の指示に従って、登録してください。
2. 公式プレイヤーズサイト（提督情報ページ）ヘのログイン確認
    * [提督情報ページ](https://kancolle-arcade.net/ac/#/top) の指示に従って、初回ログインを行ってください。
    * 初回ログイン時に、SEGA ID と Aime カードのひも付けが行われます。
    * このページで自分のプレイデータを閲覧できない場合は、admiral_stats_exporter も動作しません。

# Ruby 版

## Ruby 版のインストール手順

### 1. Ruby のインストール

admiral_stats_exporter を動かすには、Ruby が必要です。  

Windows ユーザで、Ruby をインストールしたことがない場合は、以下の手順をお勧めします。

- [RubyInstaller のダウンロードページ](http://rubyinstaller.org/downloads) から "Ruby 2.3.1" または "Ruby 2.3.1 (x64)" をダウンロード
- ダウンロードしたファイル（rubyinstaller-2.3.1.exe または rubyinstaller-2.3.1-x64.exe）を実行
- インストール中に出てくる「Ruby の実行ファイルへ環境変数 PATH を設定する」のチェックボックスを ON にする

### 2. Bundler のインストール

コマンドプロンプト、またはコンソールを開いて、以下のコマンドを実行してください。  
Ruby がインストールされて、パスが通っていれば、実行できるはずです。

```
gem install bundler
```

### 3. admiral_stats_exporter のダウンロード

[Releases ページ](https://github.com/muziyoshiz/admiral_stats_exporter/releases) から zip ファイルをダウンロードして、好きな場所に解凍して下さい。

git を使える場合は master ブランチを clone しても OK です。

### 4. 必要なライブラリのダウンロード

コマンドプロンプト、またはコンソールを開いて、admiral_stats_exporter を解凍したディレクトリに移動してください。  
そして、以下のコマンドを実行してください。

```
bundle install
```

### 5. config.yaml の作成

config.yaml.sample （Windows の場合は config.yaml.sample.dos）をコピーして、同じディレクトリに config.yaml ファイルを作成してください。

そして、`{{ SEGA ID }}` `{{ Password }}` と書かれた箇所に、公式プレイヤーズサイトへのログインに使った SEGA IDとパスワードを記入してください。

```
login:
  id: SEGAID
  password: PASSWORD
output:
  dir: ./json
```

## Ruby 版の実行

admiral_stats_exporter.rb のあるディレクトリで、以下のコマンドを実行してください。  
実行に成功すると、 `json/コマンドの実行日時` ディレクトリに、最新のプレイデータがエクスポートされます。  

```
bundle exec ruby admiral_stats_exporter.rb
```

# PowerShell 版

## PowerShell 版のインストール手順

### 1. PowerShell のインストール（古い OS の場合のみ）

Invoke-* コマンド実行のため、Windows PowerShell 3.0 以降が必要です。Windows 8, 10 は PowerShell 3.0 以上のため、問題ありません。

Windows 7 は古い PowerShell がインストールされている場合があります。その場合は、以下のページなどを参考に、PowerShell 3.0 以上をインストールしてください。

- [PowerShell/Windows7にPowerShell4.0をインストールする手順 - Windowsと暮らす](http://win.just4fun.biz/PowerShell/Windows7%E3%81%ABPowerShell4.0%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%99%E3%82%8B%E6%89%8B%E9%A0%86.html#ka15a7db "PowerShell/Windows7にPowerShell4.0をインストールする手順 - Windowsと暮らす")

### 2. admiral_stats_exporter のダウンロード

[Releases ページ](https://github.com/muziyoshiz/admiral_stats_exporter/releases) から zip ファイルをダウンロードして、好きな場所に解凍して下さい。

git を使える場合は master ブランチを clone しても OK です。

### 3. 設定ファイルの作成（初回実行時のみ）

admiral_stats_exporter_ps.ps1 を右クリックしてメニューを表示し、「PowerShellで実行」をクリックします。

初回実行時のみ認証情報登録ダイアログが表示されるので、プレイヤーズサイトの [提督情報ページ](https://kancolle-arcade.net/ac/#/top) のID/パスワードを入力してください。
同フォルダの cred.xml にID/パスワードが記録されます。

認証情報を間違えて登録した場合は、同フォルダの cred.xml を削除して実行し、改めて認証情報を登録してください。

## PowerShell 版の実行

admiral_stats_exporter_ps.ps1 を右クリックしてメニューを表示し、「PowerShellで実行」をクリックします。  
実行に成功すると、 `json/コマンドの実行日時` ディレクトリに、最新のプレイデータがエクスポートされます。

# エクスポートされたファイルの詳細（Ruby/PowerShell 共通）

admiral_stats_exporter は、以下のようなファイル名で、プレイデータをエクスポートします。  
これらのファイルを、<a href="https://www.admiral-stats.com/" target="_blank">Admiral Stats</a> の<a href="https://www.admiral-stats.com/import" target="_blank">「インポート」ページ</a>からアップロードしてください。

| 提督情報での表示 | ファイル名 |
|:----------|:---------------|
| 基本情報 | Personal_basicInfo_yyyymmdd_hhmmss.json |
| 艦娘図鑑 | TcBook_info_yyyymmdd_hhmmss.json |
| 艦娘一覧 | CharacterList_info_yyyymmdd_hhmmss.json |
| 装備図鑑 | EquipBook_info_yyyymmdd_hhmmss.json |
| 装備一覧 | EquipList_info_yyyymmdd_hhmmss.json |
| 海域情報 | Area_captureInfo_yyyymmdd_hhmmss.json |
| 任務一覧 | Quest_info_yyyymmdd_hhmmss.json |

※ yyyymmdd_hhmmss は、エクスポートを実行した時刻

# 注意事項

* このツールは非公式なツールです。本ツールの開発者は、このツールを利用することによるいかなる損害についても一切責任を負いません。
* このツールは、提督情報ページ内の表示に使われる JSON データを、そのままファイルに出力します。そのため、JSON ファイルの形式は、公式サイトの更新に伴って突然変わる可能性があります。

# 関連ページ

* [Admiral Stats](https://www.admiral-stats.com/)
* [admiral_stats_parser](https://github.com/muziyoshiz/admiral_stats_parser)
