#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4系のインストール
・apache2.4
・mod_sslのインストール
・centosユーザーの作成
・phpenvのインストール

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

#CentOS7か確認
if [ -e /etc/redhat-release ]; then
    DIST="redhat"
    DIST_VER=`cat /etc/redhat-release | sed -e "s/.*\s\([0-9]\)\..*/\1/"`
    #DIST_VER=`cat /etc/redhat-release | perl -pe 's/.*release ([0-9.]+) .*/$1/' | cut -d "." -f 1`

    if [ $DIST = "redhat" ];then
      if [ $DIST_VER = "7" ];then
        #EPELリポジトリのインストール
        start_message
        yum remove -y epel-release
        yum -y install epel-release
        end_message

        #必要なパッケージのインストール
        start_message
        yum -y install bzip2 bzip2-devel
        yum -y install git gcc make libxml2 libxml2-devel openssl openssl-devel libcurl libcurl-devel libjpeg-devel libpng-devel libmcrypt-devel readline-devel libtidy-devel libxslt-devel libicu-devel gcc-c++ patch re2c　libmcrypt libmcrypt-devel autoconf
        end_message


        #PHPに必要なモジュールをインストール
        start_message
        echo "libzip0.11のインストール"
        wget http://packages.psychotic.ninja/7/plus/x86_64/RPMS/libzip-0.11.2-6.el7.psychotic.x86_64.rpm
        rpm -Uvh libzip-0.11.2-6.el7.psychotic.x86_64.rpm
        echo "インストールされているか確認をする"
        echo "yum list installed | grep libzip"
        yum list installed | grep libzip

        echo "libzip-devel-0.11のインストール"
        wget http://packages.psychotic.ninja/7/plus/x86_64/RPMS/libzip-devel-0.11.2-6.el7.psychotic.x86_64.rpm
        rpm -Uvh libzip-devel-0.11.2-6.el7.psychotic.x86_64.rpm
        echo "インストールされているか確認をする"
        echo "yum list installed | grep libzip"
        yum list installed | grep libzip
        which apxs

        end_message



        start_message
        echo "yum updateを実行します"
        echo "yum update"
        yum -y update
        end_message

        # apacheのインストール
        echo "apacheをインストールします"
        echo ""

        start_message
        yum -y install httpd
        yum -y install openldap-devel expat-devel
        yum -y install httpd-devel mod_ssl



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


        #phpenvのインストール
        start_message
        echo "起動時に読み込まれるようにします"
        cat >/etc/profile.d/phpenv.sh <<'EOF'
export PATH=/usr/local/phpenv/bin:$PATH
export PHPENV_ROOT=/usr/local/phpenv
EOF

        source /etc/profile.d/phpenv.sh
        end_message

        #phpenvの取得
        start_message
        echo "gitでphpenvをクーロンします"
        echo "gcurl -L https://raw.github.com/CHH/phpenv/master/bin/phpenv-install.sh | bash"
        curl -L https://raw.github.com/CHH/phpenv/master/bin/phpenv-install.sh | bash
        echo "ディレクトリの作成"
        echo "git clone https://github.com/php-build/php-build.git /usr/local/phpenv/plugins/php-build"
        git clone https://github.com/php-build/php-build.git /usr/local/phpenv/plugins/php-build
        end_message

        #環境変数を通す
        start_message
        echo "環境変数を通す"
        echo 'eval "$(phpenv init -)"' >> /etc/profile.d/phpenv.sh
        echo "ソース環境を反映"
        echo "source /etc/profile.d/phpenv.sh"
        source /etc/profile.d/phpenv.sh
        end_message

        #Apacheと連携できるように設定
        start_message
        echo "Apacheと連携できるようにします"
        sed -i -e '1i configure_option "--with-apxs2" "/usr/bin/apxs"' /usr/local/phpenv/plugins/php-build/share/php-build/definitions/7.3.17
        echo "設定確認"
        cat /usr/local/phpenv/plugins/php-build/share/php-build/definitions/7.3.17
        end_message


        #phpの確認とインストール
        start_message
        echo "phpenvのインストール phpenv install -l"
        phpenv install -l
        echo "php7.3.17のインストール"
        phpenv install 7.3.17
        echo "php7.3.17をglobalに設定"
        phpenv global 7.3.17
        end_message


        #apacheと連携
        start_message
        cat >/etc/httpd/conf.d/php.conf <<'EOF'
LoadModule php7_module /usr/lib64/httpd/modules/libphp7.so

AddType application/x-httpd-php .php
DirectoryIndex index.php
EOF
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
        http://IPアドレス
        https://IPアドレス
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

        ドキュメントルートの所有者：centos
        グループ：apache
        になっているため、ユーザー名とグループの変更が必要な場合は変更してください
EOF

        echo "centosユーザーのパスワードは"${PASSWORD}"です。"
      else
        echo "CentOS7ではないため、このスクリプトは使えません。このスクリプトのインストール対象はCentOS7です。"
      fi
    fi

else
  echo "このスクリプトのインストール対象はCentOS7です。CentOS7以外は動きません。"
  cat <<EOF
  検証LinuxディストリビューションはDebian・Ubuntu・Fedora・Arch Linux（アーチ・リナックス）となります。
EOF
fi
exec $SHELL -l
