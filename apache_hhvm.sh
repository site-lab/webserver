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
・hhvmのインストール
・centosユーザーの作成

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

        #必要ライブラリのインストール
        start_message
        yum -y install cpp gcc-c++ cmake git psmisc {binutils,boost,jemalloc,numactl}-devel \
{ImageMagick,sqlite,tbb,bzip2,openldap,readline,elfutils-libelf,gmp,lz4,pcre}-devel \
lib{xslt,event,yaml,vpx,png,zip,icu,mcrypt,memcached,cap,dwarf}-devel \
{unixODBC,expat,mariadb}-devel lib{edit,curl,xml2,xslt}-devel \
glog-devel oniguruma-devel ocaml gperf enca libjpeg-turbo-devel openssl-devel \
mariadb mariadb-server make libc-client mod_fcgid
        end_message


        # yum updateを実行
        echo "yum updateを実行します"
        echo ""

        start_message
        yum -y update
        end_message

        # hhvmのインストール
        start_message
        echo "hhvmをインストールします"
        echo ""
        rpm -Uvh http://mirrors.linuxeye.com/hhvm-repo/7/x86_64/hhvm-3.15.3-1.el7.centos.x86_64.rpm
        hhvm --version
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

        #SSLの設定変更（http2を有効化）
        echo "ファイルのバックアップ"
        echo ""
        cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf.bk

        sed -i -e "s|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|" /etc/httpd/conf.modules.d/00-mpm.conf
        sed -i -e "s|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|" /etc/httpd/conf.modules.d/00-mpm.conf

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

        #スクリプト作成
        cat >/usr/local/bin/php-wrapper <<'EOF'
#!/bin/sh
export PHP_FCGI_MAX_REQUESTS=10000
export PHP_FCGI_CHILDREN=0
exec /usr/bin/php-cgi
EOF

        #権限変更
        start_message
        echo "権限を変更"
        chown apache /usr/local/bin/php-wrapper
        chmod u+x /usr/local/bin/php-wrapper
        end_message

        #/var/runを再起動後も実行
        start_message
        echo "再起動後に/var/run/hhvmが消えてしまうので実行されるようにする"
        cat >/etc/tmpfiles.d/www.conf <<'EOF'
d /var/run/hhvm 0700 apache apache
EOF
        end_message

        #hhvmの実行者を変更
        start_message
        echp "hhvmの実行者をapacheに変更します"
        cat >/etc/systemd/system/hhvm.service <<'EOF'
[Unit]
Description=HHVM HipHop Virtual Machine (FCGI)

[Service]
ExecStart=/usr/local/bin/hhvm --config /etc/hhvm/server.ini --user apache --mode daemon -vServer.Type=fastcgi -vServer.Port=9001

[Install]
WantedBy=multi-user.target
EOF
        end_message
        #デーモンリロード
        systemctl daemon-reload

        # phpinfoの作成
        start_message
        touch /var/www/html/info.php
        echo '<?hh phpinfo();' >> /var/www/html/info.php
        cat /var/www/html/info.php
        touch /var/www/html/.hhconfig
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
        echo "apacheとHHVMを起動します"
        start_message
        systemctl start httpd.service
        systemctl start hhvm.service

        echo "apacheのステータス確認"
        systemctl status httpd.service
        systemctl status hhvm.service
        end_message

        #自動起動の設定
        start_message
        systemctl enable httpd
        systemctl enable hhvm
        systemctl list-unit-files --type=service | grep httpd
        systemctl list-unit-files --type=service | grep hhvm
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
        503エラーになるはずです。その場合はシステム再起動してください
        shutdown -r now もしくはrebootで再起動できます。その後ページが見れるようになります

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
