#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります

目的：システム更新+apache2.4系+php7系のインストール
・apache2.4系
・mod_sslのインストール
・PHP8系のインストール

COMMENT


start_message(){
echo ""
echo "======================開始======================"
echo ""
}

end_message(){
echo ""
echo "======================完了======================"
echo ""
}




#EPELリポジトリのインストール
start_message
yum remove -y epel-release
yum -y install epel-release
end_message

#Remiリポジトリのインストール
start_message
yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum -y install yum-utils
end_message


#gitリポジトリのインストール
start_message
yum -y install git
end_message



# yum updateを実行
wget wget https://www.logw.jp/download/shell/common/system/update.sh
source ./update.sh

# apacheのインストール
wget wget https://www.logw.jp/download/shell/common/system/apache.sh
source ./apache.sh

# PHPのインストール
wget wget https://www.logw.jp/download/shell/common/system/php.sh
source ./php.sh


#ユーザー作成
wget wget https://www.logw.jp/download/shell/common/user/useradd.sh
source ./useradd.sh

#所属グループ表示
echo "所属グループを表示します"
getent group apache
end_message

#所有者の変更
start_message
echo "ドキュメントルートの所有者をcentos、グループをapacheにします"
chown -R centos:apache /var/www/html
end_message

# apacheの起動
echo "apacheを起動します"
start_message
systemctl start httpd.service

echo "apacheのステータス確認"
systemctl status httpd.service
end_message

#自動起動の設定
start_message
systemctl enable httpd
systemctl list-unit-files --type=service | grep httpd
end_message


#firewallのポート許可
echo "http(80番)とhttps(443番)の許可をしてます"
start_message
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
echo ""
echo "保存して有効化"
echo ""
firewall-cmd --reload

echo ""
echo "設定を表示"
echo ""
firewall-cmd --list-all
end_message

umask 0002

cat <<EOF

http://IPアドレス/info.php
https://IPアドレス/info.php
で確認してみてください

ドキュメントルート(DR)は
/var/www/html
となります。

htaccessはドキュメントルートのみ有効化しています

有効化の確認

https://www.logw.jp/server/7452.html
vi /var/www/html/.htaccess
-----------------
AuthType Basic
AuthName hoge
Require valid-user
-----------------

ダイアログがでればhtaccessが有効かされた状態となります。

●HTTP2について
このApacheはHTTP/2に非対応となります。ApacheでHTTP2を使う場合は2.4.17以降が必要となります。


これにて終了です

ドキュメントルートの所有者：centos
グループ：apache
になっているため、ユーザー名とグループの変更が必要な場合は変更してください
EOF
exec $SHELL -l
