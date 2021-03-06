# WebServer
apacheのシェルスクリプト置き場、CentOS7専用となります。**centos7 minimal インストール** した状態で何もはいっていない状態で必要なファイルを実行してください

※自己責任で実行してください

## テスト環境
### conohaのVPS
* メモリ：512MB
* CPU：1コア
* SSD：20GB

### さくらのVPS
* メモリ：512MB
* CPU：1コア
* SSD：20GB

### さくらのクラウド
* メモリ：1GB
* CPU：1コア
* SSD：20GB

### IDCFクラウド
* メモリ：1GB
* CPU：1コア
* SSD：20GB

### Microsoft Azure
* メモリ：2GB
* CPU：1コア
* SSD：15GB

### 実行方法
SFTPなどでアップロードをして、rootユーザーもしくはsudo権限で実行
wgetを使用する場合は[環境構築スクリプトを公開してます](https://www.logw.jp/cloudserver/8886.html)を閲覧してください。
wgetがない場合は **yum -y install wget** でインストールしてください

**sh ファイル名.sh** ←同じ階層にある場合

**sh /home/ユーザー名/ファイル名.sh** ユーザー階層にある場合（rootユーザー実行時）

## 共通内容
* epelインストール
* gitのインストール
* システム更新
* mod_sslのインストール
* firewallのポート許可(80番、443番)
* gzip圧縮の設定
* centosユーザーの作成

**centosユーザーのパスワードはランダム生成になります。構築完了後にパスワードが表示されるのでメモするか、rootで変更してください** centosユーザーで作成、アップロードするファイルは **644** 、ディレクトリは **775** となります


## [apache.sh](https://github.com/site-lab/apache/blob/master/apache.sh)
### 実行内容
* ドメイン名の入力
* apache2.4.6 or 2.4.xのインストール

2.4.xの場合はiusリポジトリからのインストールとなります。iusリポジトリの場合はHTTP2通信が可能となります。
Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
HTTP2については、モジュールの有効可をしてあるため、各々でconfファイルに追記をしてください
参考サイト：https://www.logw.jp/server/8359.html

Apacheのみのインストールとなります。HHVMを使いたいなどの場合はこれを選択してください


## [apache_hhvm.sh](https://github.com/site-lab/apache/blob/master/apache_hhvm.sh)
### 実行内容
* apache2.4.6のインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
HTTP2については、モジュールの有効可をしてあるため、各々でconfファイルに追記をしてください
apache+hhvmの構築をしますDBは別途いれてください。FastCGIで実行となります。
参考サイト：https://www.logw.jp/server/8359.html


## [apache_php.sh](https://github.com/site-lab/apache/blob/master/apache_php.sh)
### 実行内容
* apache2.4系のインストール
* php7.3 ～ 7.4のインストール
* php7.3 ～ 7.4の必要モジュールインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **モジュール版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

**このスクリプトはインストールしたいPHPのバージョンを聞かれます。7.3～7.4のどれかをキーボードで選択していただきます。**

## [apache_php_fcgid.sh](https://github.com/site-lab/apache/blob/master/apache_php_fcgid.sh)
### 実行内容
* apache2.4系のインストール
* mod_sslのインストール
* php7.3～7.4のインストール
* php7.3～7.4の必要モジュールインストール


Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **FastCGI版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

**このスクリプトはインストールしたいPHPのバージョンを聞かれます。7.3～7.4のどれかをキーボードで選択していただきます。**


## [apache_php73.sh](https://github.com/site-lab/apache/blob/master/apache_php73.sh)
### 実行内容
* apache2.4.6のインストール
* mod_sslのインストール
* php7.3のインストール
* php7.3の必要モジュールインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **モジュール版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

## [apache_php74.sh](https://github.com/site-lab/apache/blob/master/apache_php74.sh)
### 実行内容
* apache2.4.6のインストール
* mod_sslのインストール
* php7.4のインストール
* php7.4の必要モジュールインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **モジュール版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。



## [apache_php73_fcgid.sh](https://github.com/site-lab/apache/blob/master/apache_php73_fcgid.sh)
### 実行内容
* apache2.4.6のインストール
* mod_sslのインストール
* php7.3のインストール
* php7.3の必要モジュールインストール


Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **FastCGI版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

## [apache_php74_fcgid.sh](https://github.com/site-lab/apache/blob/master/apache_php74_fcgid.sh)
### 実行内容
* apache2.4.6のインストール
* mod_sslのインストール
* php7.4のインストール
* php7.4の必要モジュールインストール


Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **FastCGI版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。


## [apache_pyenv.sh](https://github.com/site-lab/apache/blob/master/apache_pyenv.sh)
### 実行内容
* apache2.4.6のインストール
* mod_sslのインストール
* python3.7.3のインストール
* botleのインストール



## [openlitespeed.sh](https://github.com/site-lab/webserver/blob/master/openlitespeed.sh)
### 実行内容
* openlitespeedのインストール
* 初期設定：https://www.logw.jp/cloudserver/8545.html
* openlitespeed関係の記事：https://www.logw.jp/tag/litespeed
