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

**sh start.sh** ←同じ階層にある場合

**sh /home/ユーザー名/start.sh** ユーザー階層にある場合（rootユーザー実行時）

## [apache.sh](https://github.com/site-lab/apache/blob/master/apache.sh)
* epelインストール
* gitのインストール
* システム更新
* apache2.4.6のインストール
* mod_sslのインストール
* firewallのポート許可(80番、443番)

## [apache_php72.sh](https://github.com/site-lab/apache/blob/master/apache_php72.sh)
* epelインストール
* gitのインストール
* システム更新
* apache2.4.6のインストール
* mod_sslのインストール
* php7.2のインストール
* firewallのポート許可(80番、443番)
