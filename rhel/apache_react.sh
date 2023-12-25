#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。userユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4系のインストール
・2.4.x
・mod_sslのインストール
・userの作成
・Reactと連携

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

#user8系か確認
if [ -e /etc/redhat-release ]; then
    DIST="redhat"
    DIST_VER=`cat /etc/redhat-release | sed -e "s/.*\s\([0-9]\)\..*/\1/"`
    #DIST_VER=`cat /etc/redhat-release | perl -pe 's/.*release ([0-9.]+) .*/$1/' | cut -d "." -f 1`

    if [ $DIST = "redhat" ];then
      if [ $DIST_VER = "8" ] || [ $DIST_VER = "9" ];then

        #EPELリポジトリのインストール
        start_message
        dnf remove -y epel-release
        dnf -y install epel-release
        end_message

        #gitリポジトリのインストール
        start_message
        dnf -y install git
        end_message

        #SELinuxにHTTPの許可
        start_message
        echo "SELinuxにHTTPの許可をします"
        echo "setsebool -P httpd_can_network_connect 1"
        setsebool -P httpd_can_network_connect 1
        end_message


        #nodejsのインストール
        start_message
        echo "nodejsの確認"
        dnf module list nodejs
        echo "nodejsのインストール"
        dnf module install -y nodejs:20
        echo "nodejsの確認"
        node -v
        end_message

        #Reactのインストール
        start_message
        echo "Reactをインストールします"
        npx -y create-react-app /var/www/html
        end_message

        #forever のインストール
        start_message
        echo "npm install -g forever"
        npm install -g forever
        end_message

        # apacheのインストール
        start_message
        echo "apacheをインストールします"
        dnf  install -y httpd mod_ssl
        ls /etc/httpd/conf/
        echo "Apacheのバージョン確認"
        echo ""
        httpd -v
        echo ""
        end_message

        # apacheの設定変更
        start_message
        echo "apacheをインストールします"
        sed -i -e "151d" /etc/httpd/conf/httpd.conf
        sed -i -e "151i AllowOverride All" /etc/httpd/conf/httpd.conf
        sed -i -e "350i #バージョン非表示" /etc/httpd/conf/httpd.conf
        sed -i -e "351i ServerTokens ProductOnly" /etc/httpd/conf/httpd.conf
        sed -i -e "352i ServerSignature off \n" /etc/httpd/conf/httpd.conf
        sed -i -e "358i  ProxyRequests Off \n" /etc/httpd/conf/httpd.conf
        sed -i -e "360i  <Location /> \n" /etc/httpd/conf/httpd.conf
        sed -i -e "361i  ProxyPass http://localhost:3000/ \n" /etc/httpd/conf/httpd.conf
        sed -i -e "362i  ProxyPassReverse http://localhost:3000/ \n" /etc/httpd/conf/httpd.conf
        sed -i -e "363i  </Location> \n" /etc/httpd/conf/httpd.conf
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

        echo "ユーザーの作成をします"
        curl -OL https://buildree.com/download/common/user/centosonly.sh
        source ./centosonly.sh

        #コピー作成
        cp /root/pass.txt /home/unicorn/
        chown -R unicorn:nobody /home/unicorn
        end_message

        #所属グループ表示
        echo "所属グループを表示します"
        getent group apache
        end_message

        #所有者の変更
        start_message
        echo "ドキュメントルートの所有者をunicorn、グループをapacheにします"
        chown -R unicorn:apache /var/www/html
        end_message

        # apacheの起動
        echo "apacheを起動します"
        start_message
        systemctl start httpd.service

        # foreverの設定変更
        start_message
        cd /var/www/html
        echo "foreverで自動起動するようにします"
        /usr/local/lib/node_modules/forever/bin/forever start -c "npm start" ./
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
        http://IPアドレス or ドメイン名
        https://IPアドレス or ドメイン名
        で確認してみてください

        設定ファイルは
        /etc/httpd/conf.d/ドメイン名.conf
        となっています


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
        SSLのconfファイルに｢Protocols h2 http/1.1｣と追記してください
        https://www.logw.jp/server/8359.html

        例）
        <VirtualHost *:443>
            ServerName logw.jp
            ServerAlias www.logw.jp

            Protocols h2 http/1.1　←追加
            DocumentRoot /var/www/html


        <Directory /var/www/html/>
            AllowOverride All
            Require all granted
        </Directory>

        </VirtualHost>

        ドキュメントルートの所有者：unicorn
        グループ：apache
        になっているため、ユーザー名とグループの変更が必要な場合は変更してください

        503エラーの場合は一度更新をしてください。Reactの画面がでたら起動しております。
        ドキュメントルートで実行する場合は　forever start -c "npm start" ./　となります
EOF

        echo "unicornユーザーのパスワードは"${PASSWORD}"です。"
      else
        echo "RedHat系ではないため、このスクリプトは使えません。このスクリプトのインストール対象はRedHat8，9系です。"
      fi
    fi

else
  echo "このスクリプトのインストール対象はuser7です。user7以外は動きません。"
  cat <<EOF
  検証LinuxディストリビューションはDebian・Ubuntu・Fedora・Arch Linux（アーチ・リナックス）となります。
EOF
fi
exec $SHELL -l
