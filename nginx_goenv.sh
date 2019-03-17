#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+nginxのインストール
・nginx
・mod_sslのインストール
・centosユーザーの作成
・golangのインストール

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

    if [ $DIST = "redhat" ];then
      if [ $DIST_VER = "7" ];then
        #EPELリポジトリのインストール
        start_message
        yum remove -y epel-release
        yum -y install epel-release
        end_message

        #gitリポジトリのインストール
        start_message
        yum -y install git
        end_message

        #mod_sslのインストール
        start_message
        yum -y install mod_ssl
        end_message


        # yum updateを実行
        echo "yum updateを実行します"
        echo ""

        start_message
        yum -y update
        end_message

        #goenvの設定をする
        start_message
        git clone https://github.com/syndbg/goenv.git /usr/local/goenv
        cat >/etc/profile.d/goenv.sh <<'EOF'
export GOENV_ROOT="/usr/local/goenv"
export PATH="${GOENV_ROOT}/bin:${PATH}"
eval "$(goenv init -)"
EOF
        #ソース反映
        source /etc/profile.d/goenv.sh


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

        #go言語のインストール
        start_message
        echo "Go言語のリストを表示"
        goenv install --list

        echo "Go言語1.11.0をインストール"
        goenv install 1.11.0

        echo "Go言語1.11.0を適用"
        goenv global 1.11.0

        echo "Go言語のバージョン表示"
        go version
        end_message

        #nginxのインストール
        start_message
        echo "nginxのインストール"
        yum  -y --enablerepo=nginx install nginx
        end_message

        #SSLの設定ファイルに変更
        start_message
        echo "SSLファイルのコピー"
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
        index  index.go index.html index.htm;
        proxy_pass      http://127.0.0.1:9000;
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
           index  index.go index.html index.htm;
           proxy_pass      http://127.0.0.1:9000;
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

        #サンプルファイル作成
        start_message
        echo "サンプルファイルの作成"
        cat > /usr/share/nginx/html/index.go <<'EOF'
package main

import (
    "fmt"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "こんにちは！世界！！")
}

func main() {
        http.HandleFunc("/", handler)
        http.ListenAndServe(":9000", nil)
}
EOF
        cat /usr/share/nginx/html/index.go
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



        #nginxの起動
        start_message
        echo "nginxの起動"
        echo ""
        systemctl start nginx
        systemctl status nginx
        end_message

        #実行
        start_message
        echo "ビルドします"
        echo "go build  /usr/share/nginx/html/index.go"
        cd /usr/share/nginx/html/
        go build  index.go
        ./index &

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

        umask 0002

        #所有者の変更
        start_message
        echo "ドキュメントルートの所有者をcentos、グループをnginxにします"
        chown -R centos:nginx /usr/share/nginx/html
        end_message


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


        ドキュメントルートの所有者：centos
        グループ：nginx
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
