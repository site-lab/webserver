# WebServer
WebServer関連のシェルスクリプト置き場、CentOS7専用となります。**centos7 minimal インストール** した状態で何もはいっていない状態で必要なファイルを実行してください
Apache+PHP、nginx+phpなどの環境構築シェルスクリプトです

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
* apache2.4.6のインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
HTTP2については、モジュールの有効可をしてあるため、各々でconfファイルに追記をしてください
参考サイト：https://www.logw.jp/server/8359.html

Apacheのみのインストールとなります。HHVMを使いたいなどの場合はこれを選択してください

## [apache24u.sh](https://github.com/site-lab/apache/blob/master/apache24u.sh)
### 実行内容
* iusリポジトリインストール
* apache2.4.xのインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
HTTP2については、モジュールの有効可をしてあるため、各々でconfファイルに追記をしてください
参考サイト：https://www.logw.jp/server/8359.html

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
* apache2.4.6のインストール
* php7.2 or 7.3のインストール
* php7.2 or 7.3の必要モジュールインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **モジュール版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

このスクリプトはインストールしたいPHPのバージョンを聞かれます。7.2か7.3かをキーボードで選択していただきます。

## [apache24u_php.sh](https://github.com/site-lab/apache/blob/master/apache24u_php.sh)
### 実行内容
* apache2.4.6のインストール
* php7.2 or 7.3のインストール
* php7.2 or 7.3の必要モジュールインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **モジュール版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

このスクリプトはインストールしたいPHPのバージョンを聞かれます。7.2か7.3かをキーボードで選択していただきます。



## [apache_php72.sh](https://github.com/site-lab/apache/blob/master/apache_php72.sh)
### 実行内容
* apache2.4.6のインストール
* php7.2のインストール
* php7.2の必要モジュールインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **モジュール版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

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

## [apache_php72_fcgid.sh](https://github.com/site-lab/apache/blob/master/apache_php72_fcgid.sh)
### 実行内容
* apache2.4.6のインストール
* mod_sslのインストール
* php7.2のインストール
* php7.2の必要モジュールインストール

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています
PHP7は **FastCGI版** となります。
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

## [apache_pyenv.sh](https://github.com/site-lab/apache/blob/master/apache_pyenv.sh)
### 実行内容
* apache2.4.6のインストール
* mod_sslのインストール
* python3.6.7のインストール
* botleのインストール



## [nginx.sh](https://github.com/site-lab/apache/blob/master/nginx.sh)
### 実行内容
* nginxのインストール

## [nginx_php.sh](https://github.com/site-lab/apache/blob/master/nginx_php.sh)
### 実行内容
* nginxのインストール
* PHP7.2 or 7.3を選択してインストール


## [nginx_apache.sh](https://github.com/site-lab/apache/blob/master/nginx_apache.sh)
### 実行内容
* nginxのインストール
* apache2.4.6のインストール
* HTTPSへのリダイレクト設定可（一部ファイル編集してください）
* リバースプロキシ設定済み



## [nginx_php72.sh](https://github.com/site-lab/apache/blob/master/nginx_php72.sh)
### 実行内容
* nginxのインストール
* php7.2のインストール
* php7.2の必要モジュールインストール

PHP7は **FastCGI版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

## [nginx_php72_socket.sh](https://github.com/site-lab/apache/blob/master/nginx_php72_socket.sh)
### 実行内容
* nginxのインストール
* php7.2の必要モジュールインストール
* HTTPSへのリダイレクト設定可（一部ファイル編集してください）

PHP7は **FastCGI版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。


## [nginx_php73.sh](https://github.com/site-lab/apache/blob/master/nginx_php73.sh)
### 実行内容
* nginxのインストール
* php7.3のインストール
* php7.3の必要モジュールインストール
* HTTPSへのリダイレクト設定可（一部ファイル編集してください）

PHP7は **FastCGI版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。

## [nginx_php73_socket.sh](https://github.com/site-lab/apache/blob/master/nginx_php73_socket.sh)
### 実行内容
* nginxのインストール
* php7.3のインストール
* php7.3の必要モジュールインストール
* HTTPSへのリダイレクト設定可（一部ファイル編集してください）

PHP7は **FastCGI版** となります。
データベースは自分でインストールしていただく形になります。データベースも含めてインストールしたい場合は[LAMP](https://github.com/site-lab/lamp)リポジトリからインストールしてください。



## [nginx_nodejs.sh](https://github.com/site-lab/apache/blob/master/nginx_nodejs.sh)
### 実行内容
* nginxのインストール
* node.jsのインストール
* Expressのインストール
* HTTPSへのリダイレクト設定可（一部ファイル編集してください）

nginx+node.jsです。nginxでリバースプロキシをしてます。

## [nginx_ndenv.sh](https://github.com/site-lab/apache/blob/master/nginx_ndenv.sh)
### 実行内容
* nginxのインストール
* node.jsのインストール
* Expressのインストール
* HTTPSへのリダイレクト設定可（一部ファイル編集してください）

nginx+node.jsです。nginxでリバースプロキシをしてます。ndenvで動かします


## [nginx_go.sh](https://github.com/site-lab/apache/blob/master/nginx_go.sh)
### 実行内容
* nginxのインストール
* go言語のインストール
* Expressのインストール
* HTTPSへのリダイレクト設定可（一部ファイル編集してください）

nginx+go言語です。nginxでリバースプロキシをしてます。
