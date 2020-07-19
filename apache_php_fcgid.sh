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
#yum -y update
end_message

# apacheのインストール
echo "apacheをインストールします"
echo ""

PS3="インストールしたいPHPのバージョンを選んでください > "
ITEM_LIST="apache2.4.6 apache2.4.x"

select selection in $ITEM_LIST

do
  if [ $selection = "apache2.4.6" ]; then
    # apache2.4.6のインストール
    echo "apache2.4.6をインストールします"
    echo ""
    start_message
    yum -y install httpd
    yum -y install openldap-devel expat-devel
    yum -y install httpd-devel mod_ssl
    end_message
    break
  elif [ $selection = "apache2.4.x" ]; then
    # 2.4.ｘのインストール
    #IUSリポジトリのインストール
    start_message
    echo "IUSリポジトリをインストールします"
    yum -y install https://repo.ius.io/ius-release-el7.rpm
    end_message

    #IUSリポジトリをデフォルトから外す
    start_message
    echo "IUSリポジトリをデフォルトから外します"
    cat >/etc/yum.repos.d/ius.repo <<'EOF'
[ius]
name = IUS for Enterprise Linux 7 - $basearch
baseurl = https://repo.ius.io/7/$basearch/
enabled = 1
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-debuginfo]
name = IUS for Enterprise Linux 7 - $basearch - Debug
baseurl = https://repo.ius.io/7/$basearch/debug/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-source]
name = IUS for Enterprise Linux 7 - Source
baseurl = https://repo.ius.io/7/src/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7
EOF
    end_message

    #Nghttp2のインストール
    start_message
    echo "Nghttp2のインストール"
    yum --enablerepo=epel -y install nghttp2
    end_message

    #mailcapのインストール
    start_message
    echo "mailcapのインストール"
    yum -y install mailcap
    end_message


    # apacheのインストール
    echo "apacheをインストールします"
    echo ""

    start_message
    yum -y --enablerepo=ius install httpd24u
    yum -y install openldap-devel expat-devel
    yum -y --enablerepo=ius install httpd24u-devel httpd24u-mod_ssl
    break
  else
    echo "どちらかを選択してください"
  fi
done

#mod_fcgidのインストール
start_message
yum -y install mod_fcgid
end_message


echo "ファイルのバックアップ"
echo ""
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

echo "htaccess有効化した状態のconfファイルを作成します"
echo ""

sed -i -e "s|Options Indexes FollowSymLinks|Options FollowSymLinks ExecCGI|" /etc/httpd/conf/httpd.conf
sed -i -e "145i #FastCGI追記" /etc/httpd/conf/httpd.conf
sed -i -e "146i AddHandler fcgid-script .php" /etc/httpd/conf/httpd.conf
sed -i -e "147i FCGIWrapper /usr/bin/php-cgi .php \n" /etc/httpd/conf/httpd.conf
sed -i -e "155d" /etc/httpd/conf/httpd.conf
sed -i -e "155i AllowOverride All" /etc/httpd/conf/httpd.conf
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

#デフォルトのファイルを無効
start_message
echo "php.confを無効化します"
echo "mv /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf.del"

mv /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf.del
end_message

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
