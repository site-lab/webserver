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

#プロンプトをechoを使って表示
echo -n "ドメイン名を入力してください":
#入力を受付、その入力を「domain」に代入
read domain
#結果を表示
echo $domain



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

sed -i -e "350i #バージョン非表示" /etc/httpd/conf/httpd.conf
sed -i -e "351i ServerTokens ProductOnly" /etc/httpd/conf/httpd.conf
sed -i -e "352i ServerSignature off \n" /etc/httpd/conf/httpd.conf

#バーチャルホストの設定
cat >/etc/httpd/conf.d/${domain}.conf <<'EOF'
<VirtualHost *:80>
ServerName ドメイン名
ServerAlias www.ドメイン名
DocumentRoot /var/www/html
ErrorLog /var/log/httpd/error_log
CustomLog /var/log/httpd/access_log combined env=!no_log

<Directory "/var/www/html/">
AllowOverride All
Require all granted
#Options Includes ExecCGI FollowSymLinks
</Directory>
</VirtualHost>
EOF

#sed関数でドメインを挿入
sed -i -e "s|ServerName ドメイン名|ServerName ${domain}|" /etc/httpd/conf.d/${domain}.conf
sed -i -e "s|ServerAlias www.ドメイン名|ServerAlias www.${domain}|" /etc/httpd/conf.d/${domain}.conf


#SSLの設定変更
echo "ファイルのバックアップ"
echo ""
mv /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf.bk

cat >/etc/httpd/conf.modules.d/00-mpm.conf <<'EOF'
# Select the MPM module which should be used by uncommenting exactly
# one of the following LoadModule lines:

# prefork MPM: Implements a non-threaded, pre-forking web server
# See: http://httpd.apache.org/docs/2.4/mod/prefork.html
#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so

# worker MPM: Multi-Processing Module implementing a hybrid
# multi-threaded multi-process web server
# See: http://httpd.apache.org/docs/2.4/mod/worker.html
#
#LoadModule mpm_worker_module modules/mod_mpm_worker.so

# event MPM: A variant of the worker MPM with the goal of consuming
# threads only for connections with active processing
# See: http://httpd.apache.org/docs/2.4/mod/event.html
#
LoadModule mpm_event_module modules/mod_mpm_event.so
EOF


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
ITEM_LIST="PHP7.2 PHP7.3"

select selection in $ITEM_LIST
do
  if [ $selection = "PHP7.2" ]; then
    # php7系のインストール
    echo "phpをインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php72 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break
  elif [ $selection = "PHP7.3" ]; then
    # php7系のインストール
    echo "phpをインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php73 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql
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


# phpinfoの作成
start_message
touch /var/www/html/info.php
echo '<?php phpinfo(); ?>' >> /var/www/html/info.php
cat /var/www/html/info.php
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

ドキュメントルートの所有者：グループは｢root｣になっているため、ユーザー名とグループを変更してください
EOF
exec $SHELL -l
