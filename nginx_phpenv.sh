#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

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
        yum -y install git gcc make libxml2 libxml2-devel openssl openssl-devel libcurl libcurl-devel libjpeg-devel libpng-devel libmcrypt-devel readline-devel libtidy-devel libxslt-devel libicu-devel gcc-c++ patch re2c　libmcrypt libmcrypt-devel sqlite-devel oniguruma oniguruma-devel autoconf
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

        #mod_sslのインストール
        start_message
        yum -y install mod_ssl
        end_message

        start_message
        echo "yum updateを実行します"
        echo "yum update"
        yum -y update
        end_message

        #nginxの設定ファイルを作成
        start_message
        echo "nginxのインストールファイルを作成します"
        cat >/etc/yum.repos.d/nginx.repo <<'EOF'
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF
        end_message

        #nginxのインストール
        start_message
        yum  -y --enablerepo=nginx install nginx
        end_message

        #SSLの設定ファイルに変更
        start_message
        echo "ファイルのコピー"
        cp -p /etc/pki/tls/certs/localhost.crt /etc/nginx
        cp -p /etc/pki/tls/private/localhost.key /etc/nginx/

        #バージョン非表示
        sed -i -e "30a \     #バージョン非表示" /etc/nginx/nginx.conf
        sed -i -e "31a \     server_tokens off;\n" /etc/nginx/nginx.conf
        cat /etc/nginx/nginx.conf

        echo "ファイルを変更"
        mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bk
        cat >/etc/nginx/conf.d/default.conf <<'EOF'
server {
    listen       80;
    server_name  localhost;
    #return 301 https://$http_host$request_uri;

    #gzip
       gzip on;
       gzip_types image/png image/gif image/jpeg text/javascript text/css;
       gzip_min_length 1000;
       gzip_proxied any;
       gunzip on;


    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    location ~ \.php$ {
        root           /usr/share/nginx/html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}


server {
    listen 443 ssl http2;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    #mod_sslのオレオレ証明書を使用
    ssl_certificate /etc/nginx/localhost.crt;
    ssl_certificate_key /etc/nginx/localhost.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
    #ssl_prefer_server_ciphers on;
    #ssl_ciphers 'kEECDH+ECDSA+AES128 kEECDH+ECDSA+AES256 kEECDH+AES128 kEECDH+AES256 kEDH+AES128 kEDH+AES256 DES-CBC3-SHA +SHA !DH !aNULL !eNULL !LOW !kECDH !DSS !MD5 !EXP !PSK !SRP !CAMELLIA !SEED';
    ssl_session_cache    shared:SSL:10m;
    ssl_session_timeout  10m;

    #gzip
       gzip on;
       gzip_types image/png image/gif image/jpeg text/javascript text/css;
       gzip_min_length 1000;
       gzip_proxied any;
       gunzip on;


    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    location ~ \.php$ {
        root   /usr/share/nginx/html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
EOF
        end_message


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
        #start_message
        #echo "Apacheと連携できるようにします"
        #sed -i -e '1i configure_option "--with-apxs2" "/usr/bin/apxs"' /usr/local/phpenv/plugins/php-build/share/php-build/definitions/7.3.17
        #echo "設定確認"
        #cat /usr/local/phpenv/plugins/php-build/share/php-build/definitions/7.3.17
        #end_message


        #phpの確認とインストール
        start_message
        echo "phpenvのインストール phpenv install -l"
        phpenv install -l
        echo "php7.3.19のインストール"
        phpenv install 7.3.19
        echo "php7.3.19をglobalに設定"
        phpenv global 7.3.19
        end_message

        #php-fpmのファイル変更
        start_message
        echo "www.confの置き換え"
        mkdir /etc/php-fpm.d
        cp /usr/local/phpenv/versions/7.3.19/etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf
        sed -i -e "s|user = nobody|user = nginx|" /etc/php-fpm.d/www.conf
        sed -i -e "s|group = nobody|group = nginx|" /etc/php-fpm.d/www.conf
        echo "バックアップとる"

        end_message

        # phpinfoの作成
        start_message
        echo "phpinfoを作成します"
        touch /usr/share/nginx/html/info.php
        echo '<?php phpinfo(); ?>' >> /usr/share/nginx/html/info.php
        cat /usr/share/nginx/html/info.php
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
        getent group nginx
        end_message

        #所有者の変更
        start_message
        echo "ドキュメントルートの所有者をcentos、グループをnginxにします"
        chown -R centos:nginx /usr/share/nginx/html
        end_message

        #php-fpmの起動
        start_message
        echo "php-fpmの起動"
        echo ""
        cp /tmp/php-build/source/7.3.19/sapi/fpm/php-fpm.service /etc/systemd/system/php-fpm.service
        systemctl start php-fpm
        systemctl status php-fpm
        end_message


        #nginxの起動
        start_message
        echo "nginxの起動"
        echo ""
        systemctl start nginx
        systemctl status nginx
        end_message

        #自動起動の設定
        start_message
        systemctl enable nginx
        systemctl enable php-fpm
        systemctl list-unit-files --type=service | grep nginx
        systemctl list-unit-files --type=service | grep php-fpm
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

        PHP7.4にも対応しております。

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
