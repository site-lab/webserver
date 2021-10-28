#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4系のインストール
・apache2.4系
・mod_sslのインストール
・centosユーザーの作成
・pyenvのインストール
・bottleとの連携

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
        yum -y install git zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel gcc python-devel libffi-devel
        end_message



        # yum updateを実行
        echo "yum updateを実行します"
        wget wget https://www.logw.jp/download/shell/common/system/update.sh
        source ./update.sh

        # apacheのインストール
        wget wget https://www.logw.jp/download/shell/common/system/apache.sh
        source ./apache.sh

        #モジュールの読み込み
        sed -i -e "353i LoadModule wsgi_module modules/mod_wsgi-py39.cpython-39-x86_64-linux-gnu.so \n" /etc/httpd/conf/httpd.conf
        sed -i -e "354i WSGIScriptAlias / /var/www/html/adapter.wsgi \n" /etc/httpd/conf/httpd.conf


        #pyenvの設定
        echo "pythonのインストールをします"
        wget wget https://www.logw.jp/download/shell/common/system/pyenv.sh
        source ./pyenv.sh

        #mod_wsgiのインストール
        start_message
        echo "mod_wsgiのインストール"
        pip install mod-wsgi
        end_message

        #インストール場所を調べる
        start_message
        echo "インストール場所を調べます"
        pip show mod-wsgi
        ls -all /usr/local/pyenv/versions/3.9.5/lib/python3.9/site-packages/mod_wsgi/server/
        end_message

        #ファイルのコピー
        start_message
        echo "ファイルをコピーします"
        cp  /usr/local/pyenv/versions/3.9.5/lib/python3.9/site-packages/mod_wsgi/server/mod_wsgi-py39.cpython-39-x86_64-linux-gnu.so /etc/httpd/modules/
        echo "ファイルの確認"
        ls /etc/httpd/modules/
        end_message

        #botleのインストール
        start_message
        echo "botleのインストール"
        pip install bottle
        cp /usr/local/pyenv/versions/3.9.5/lib/python3.9/site-packages/bottle.py /var/www/html/
        end_message

        #wsgiファイル
        start_message
        cat >/var/www/html/adapter.wsgi <<'EOF'
import sys, os
dirpath = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dirpath)
os.chdir(dirpath)
import bottle
import index
application = bottle.default_app()
EOF
        end_message

        #pythonファイル
        start_message
        cat >/var/www/html/index.py <<'EOF'
from bottle import route, run, template
from bottle import TEMPLATE_PATH

@route('/')
def index():
    return ("BuildreeによりApacheとbottleの連携！")

if __name__ == '__main__':
    run(host='0.0.0.0', port=8081, debug=True, reloader=True)
EOF
        end_message


        #ユーザー作成
        wget wget https://www.logw.jp/download/shell/common/user/useradd.sh
        source ./useradd.sh
        
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
