# Apache
シェルスクリプト置き場、CentOS7専用となります。**centos7 minimal インストール** した状態で何もはいっていない状態で必要なファイルを実行してください
Apache+PHPなどの環境構築シェルスクリプトです
※自己責任で実行してください

## 実行環境
* conohaのVPS
* メモリ：512MB
* CPU：1コア
* SSD：20GB

### 実行方法
SFTPなどでアップロードをして、rootユーザーもしくはsudo権限で実行
wgetを使用する場合は[環境構築スクリプトを公開してます](https://www.logw.jp/cloudserver/8886.html)を閲覧してください。

**sh ファイル名.sh** ←同じ階層にある場合

**sh /home/ユーザー名/ファイル名.sh** ユーザー階層にある場合（rootユーザー実行時）

## [apache.sh](https://github.com/site-lab/apache/blob/master/apache.sh)
* epelインストール
* gitのインストール
* システム更新
* apache2.4.6のインストール
* mod_sslのインストール
* firewallのポート許可(80番、443番)
* gzip圧縮の設定

Apacheはドキュメントルートのみhtaccessの有効化された状態となります。
gzipは/etc/httpd/conf.d/gzip.conf　にて設定が記述されています

## [apache_php72.sh](https://github.com/site-lab/apache/blob/master/apache_php72.sh)
* epelインストール
* gitのインストール
* システム更新
* apache2.4.6のインストール
* mod_sslのインストール
* php7.2のインストール
* php7.2の必要モジュールインストール
* firewallのポート許可(80番、443番)
