#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります

目的：システム更新+apache2.4.6+php7系のインストール
・apache2.4
・mod_sslのインストール
・PHP7系のインストール

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
echo "yum updateを実行します"
echo ""

start_message
yum -y update
end_message

# apacheのインストール
echo "apacheをインストールします"
echo ""

start_message
yum -y install httpd
yum -y install openldap-devel expat-devel
yum -y install httpd-devel mod_ssl

echo "ファイルのバックアップ"
echo ""
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

echo "htaccess有効化した状態のconfファイルを作成します"
echo ""

sed -i -e "151d" /etc/httpd/conf/httpd.conf
sed -i -e "151i AllowOverride All" /etc/httpd/conf/httpd.conf
sed -i -e "350i #バージョン非表示" /etc/httpd/conf/httpd.conf
sed -i -e "351i ServerTokens ProductOnly" /etc/httpd/conf/httpd.conf
sed -i -e "352i ServerSignature off \n" /etc/httpd/conf/httpd.conf


#SSLの設定変更
echo "ファイルのバックアップ"
echo ""
cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf.bk


ls /etc/httpd/conf/
echo "Apacheのバージョン確認"
echo ""
httpd -v
echo ""
end_message

#gzip圧縮の設定
cat >/etc/httpd/conf.d/gzip.conf <<'EOF'
SetOutputFilter DEFLATE
BrowserMatch ^Mozilla/4 gzip-only-text/html
BrowserMatch ^Mozilla/4\.0[678] no-gzip
BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
SetEnvIfNoCase Request_URI\.(?:gif|jpe?g|png)$ no-gzip dont-vary
Header append Vary User-Agent env=!dont-var
EOF

PS3="インストールしたいPHPのバージョンを選んでください > "
ITEM_LIST="PHP7.3 PHP7.4"

select selection in $ITEM_LIST
do
  if [ $selection = "PHP7.3" ]; then
    # php7系のインストール
    echo "php7.3をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php73 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break

  elif [ $selection = "PHP7.4" ]; then
    # php7系のインストール
    echo "php7.4をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php74 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break

  else
    echo "どちらかを選択してください"
  fi
done

#php.iniの設定変更
start_message
echo "phpのバージョンを非表示にします"
echo "sed -i -e s|expose_php = On|expose_php = Off| /etc/php.ini"
sed -i -e "s|expose_php = On|expose_php = Off|" /etc/php.ini
echo "phpのタイムゾーンを変更"
echo "sed -i -e s|;date.timezone =|date.timezone = Asia/Tokyo| /etc/php.ini"
sed -i -e "s|;date.timezone =|date.timezone = Asia/Tokyo|" /etc/php.ini
end_message

# phpinfoの作成
start_message
touch /var/www/html/info.php
echo '<?php phpinfo(); ?>' >> /var/www/html/info.php
cat /var/www/html/info.php
end_message

#ユーザー作成
start_message
echo "centosユーザーを作成します"
USERNAME='centos'
PASSWORD=$(more /dev/urandom  | tr -d -c '[:alnum:]' | fold -w 10 | head -1)

useradd -m -G apache -s /bin/bash "${USERNAME}"
echo "${PASSWORD}" | passwd --stdin "${USERNAME}"
echo "パスワードは"${PASSWORD}"です。"

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
