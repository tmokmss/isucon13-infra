# 定型作業の手順書
## 準備
これは十分前もって済ませる:

* リポジトリの作成 (app, infra) **Privateで作ること！**
  * infraは以前のリポジトリからファイルをコピーする
    * テンプレートのタグを作っておこう
    * `git pull git@github.com:tmokmss/isucon13-infra.git -b tagxx`
* リポジトリをローカルにpull
  * defender, userの設定を忘れずに行う
* AWSアカウントにクーポン適用
  * https://us-east-1.console.aws.amazon.com/billing/home?region=ap-northeast-1#/credits

これはコンテスト直前に実施する:

* AWSアカウントにログイン https://aws.amazon.com/console/
* ターミナルのウィンドウ配置
  * メトリクス監視 (同時に見えるようにする)
    * isu1-3
  * ssh portforwarding
    * これは tunnel-manager使うなら1枚で良い
  * 開発
    * isu1 (infra/webapp)
    * isu2 (infra)
    * isu3
  * ターミナルにタブ名をつけておく (isu1,isu2,isu3)
* GoLand開く

## AWSにデプロイ
* https://ap-northeast-1.console.aws.amazon.com/cloudformation/home?region=ap-northeast-1#/stacks/create
* インスタンスのIPをここに書いておこう

```
# global
isu1: 
isu2: 
isu3: 

# local
isu1: 
isu2: 
isu3: 
```

## ssh/config設定
ローカル端末の設定。各インスタンスのグローバルIPアドレスはデプロイ後にマネコンで確認する。

```sh
code ~/.ssh/config

Host isu1
  HostName x.x.x.x
  User isucon

Host isu2
  HostName x.x.x.x
  User isucon

Host isu3
  HostName x.x.x.x
  User isucon
```

## 1台目セットアップ
まずは `ssh isu1` で接続。

## SSH鍵を作成 (インスタンス間の接続およびGitHub権限のため)
インスタンスには運営も入れるらしいので、使い捨ての鍵を作ろう

```sh
ssh-keygen -t ed25519 -C "isucon@example.com"
cat ~/.ssh/id_ed25519.pub >> ./.ssh/authorized_keys
cat ~/.ssh/id_ed25519.pub
vim ~/.ssh/config

# 以下を追加

Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
```

作った公開鍵は https://github.com/settings/ssh/new に登録する。

ついでにgitユーザーの設定:

```sh
git config --global user.email "tmokmss@users.noreply.github.com"
git config --global user.name "tmokmss"
```

### リポジトリのセットアップ
まずインフラの方から。bashの設定を変えたりするため。

```sh
git clone git@github.com:tmokmss/isucon13-infra.git
make init
git checkout .bashrc .inputrc
make apply
source ~/.bashrc
bind -f ~/.inputrc

git add .
gcm "init"
g push
```

次に app

```sh
# アプリのルートディレクトリに移動
cd webapp
git init
g add .
gcm "init"
gco -b main
git remote add origin git@github.com:tmokmss/isucon13-app.git
git push -f --set-upstream origin main

# ローカル側は git pull --rebase する
```

再度インフラに戻る。バージョン管理したいファイルを見つけて、Makefileに追加する。例:

```sh
# appのサービス定義
sudo systemctl list-unit-files | grep isu
sudo systemctl cat isupipe.go

# nginx conf
nginx -V 2>&1 | grep --colour conf
```

* ~/env.sh
* /etc/nginx/sites-enabled/isuxxx.conf

その後push

```sh
make init
g add .
gcm "add"
g push
```

### /etc/hostsの編集
ローカルIPはAWSマネコンから確認

```sh
sudo vim /etc/hosts

172.31.36.145 isu1
172.31.44.153 isu2
172.31.38.255 isu3
```

## 他インスタンスのセットアップ
これはMacから実行

```sh
scp -r isu1:~/.ssh/. isu2:~/.ssh
scp -r isu1:~/.ssh/. isu3:~/.ssh
```

端末にログインしてもろもろ:

```sh
ssh isu2

git config --global user.email "tmokmss@users.noreply.github.com"
git config --global user.name "tmokmss"

mv webapp webapp_bak
git clone git@github.com:tmokmss/isucon13-app.git webapp
git clone git@github.com:tmokmss/isucon13-infra.git

cd isucon13-infra
make init
git checkout .bashrc .inputrc
make apply

sudo vim /etc/hosts
# 上の通りに編集
```

これにて基本のセットアップは完了です。

## ソロISUCON 道標
具体的なコマンドはこちらに: https://github.com/tmokmss/isucon13-infra

1. 環境のセットアップ
   1. プロビジョニング
   2. ssh鍵の作成、GitHubに公開鍵登録
   3. インフラリポジトリのpull
   4. アプリリポジトリの作成･push
2. 初期ベンチマーク回す
3. 環境の確認
   1. 各サーバーのスペック
   2. ミドルウェア
      1. DB
      2. リバースプロキシ
      3. Goのライブラリ
   3. サービスの起動方法
   4. 各種confの位置
4. ルールの確認
5. 脳死改善
   1. DBとアプリのサーバーを分離 とりあえず2台使う
   2. mitigations=off
   3. mysql速度特化に skip-log-bin, skip-name-resolve, flush_log_at_trx, performance_schema=OFF
   4. mysqlConfig.InterpolateParams = true
   5. nginx http=1.1, keepalive
6. ログ仕込む
   1. slow query
   2. alp用のアクセスログ
7. ベンチマーク回す (ここまで1時間でできていれば最高！)
   1. htopで各サーバーのCPU使用率を監視
   2. アプリとDBどちらがボトルネックかを確認
8.  (DBなら)
   1. DDL修正
       1. slow query見ながらインデックスを貼る
   2. DB分割
      1. テーブル間でトランザクションなければ分割可能
9.  (アプリなら) 
    1. N+1解消
    2. オンメモリ化
    3. バルクインサート

## 終盤
1. 各種ロギングを無効化
   1. nginx
   2. slow query
   3. app logger
   4. app profiler
2. ルールをみて追試の内容を確認する
   1. 特に再起動処理！ initializeが叩かれる前提の実装になっていないか要確認
   2. フロントエンドからも一通り触ってみる