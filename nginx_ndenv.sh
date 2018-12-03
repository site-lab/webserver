#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります

目的：システム更新+nginxのインストール
・nginx
・mod_sslのインストール

COMMENT

echo "インストールスクリプトを開始します"
echo "このスクリプトのインストール対象はCentOS7です。"
echo ""

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

#gitなど必要な物をインストール
start_message
yum install -y gcc gcc-c++ make git openssl-devel zlib-devel readline-devel sqlite-devel bzip2-devel
end_message

#mod_sslのインストール
start_message
yum -y install mod_ssl
end_message

# yum updateを実行
echo "yum updateを実行します"
echo ""

start_message
#yum -y update
end_message

#nodeのインストール
start_message
echo "gitからndenvをダウンロード"
echo "git clone https://github.com/riywo/ndenv.git"
git clone https://github.com/riywo/ndenv.git
echo "/usr/local/へコピー"
echo ""
cp -R ndenv/ /usr/local/
ls /usr/local/
echo "プラグインディレクトリの作成とインストール"
echo ""
echo "/usr/local/ndenv/plugins"
mkdir /usr/local/ndenv/plugins
echo "git clone https://github.com/riywo/node-build.git"
git clone https://github.com/riywo/node-build.git
cp -R node-build/ /usr/local/ndenv/plugins/node-build

cat >/etc/profile.d/ndenv.sh <<'EOF'
export NDENV_ROOT=/usr/local/ndenv
export PATH="$NDENV_ROOT/bin:$PATH"
eval "$(ndenv init -)"
EOF

echo "設定反映"
echo ""
echo "source /etc/profile.d/ndenv.sh"
#source /etc/profile.d/ndenv.sh

#パス確認
echo "パス確認"
which ndenv
end_message

#nodejsのインストール
start_message
echo "インストールできるバージョンの一覧を確認"
ndenv install -l
echo "v11.3.0をインストール"
echo ""
ndenv install v11.3.0
echo "グローバル環境を11.3.0に設定"
echo ""
ndenv global v11.3.0
echo "バージョン表示"
echo ""
node -v
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
        proxy_pass   http://127.0.0.1:3000;
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
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

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
        proxy_pass   http://127.0.0.1:3000;
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
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
EOF
end_message

#Expressのインストールのインストール
start_message
echo "Expressのインストールとドキュメントルートへのコピー"
npm install express

echo "Expressをドキュメントルートへコピー"
cp -R node_modules/ /usr/share/nginx/html
end_message



#node.jsのファイル作成
cat >/usr/share/nginx/html/app.js <<'EOF'
var express = require('express');
        var app = express();

        app.get('/', function (req, res) {
        res.send('Hello World!');
        });

        app.listen(3000, function () {
        console.log("Web server start of port 3000");
        });
EOF

#foreverのインストールのインストール
start_message
echo "foreversのインストール"
npm install -g forever

echo "node.jsを永続起動"
forever start /usr/share/nginx/html/app.js
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
systemctl list-unit-files --type=service | grep nginx
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

exec $SHELL -l


cat <<EOF
http://IPアドレス
https://IPアドレス
で確認してみてください

ドキュメントルート(DR)は
/usr/share/nginx/html;
となります。

---------------------------------------
httpsリダイレクトについて
/etc/nginx/conf.d/default.conf
#return 301 https://$http_host$request_uri;
↑
コメントを外せばそのままリダイレクトになります。
---------------------------------------
EOF
