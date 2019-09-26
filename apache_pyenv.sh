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
        #モジュールの読み込み
        sed -i -e "358i LoadModule wsgi_module modules/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so \n" /etc/httpd/conf/httpd.conf
        sed -i -e "359i WSGIScriptAlias / /var/www/html/adapter.wsgi \n" /etc/httpd/conf/httpd.conf


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

        #pyenvの設定
        start_message
        echo "gitでpyenvをクーロンします"
        git clone git://github.com/yyuu/pyenv.git /usr/local/pyenv
        git clone git://github.com/yyuu/pyenv-virtualenv.git /usr/local/pyenv/plugins/pyenv-virtualenv
        end_message

        #pyenvのインストール
        start_message
        echo "起動時に読み込まれるようにします"
        cat >/etc/profile.d/pyenv.sh <<'EOF'
export PYENV_ROOT="/usr/local/pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
eval "$(pyenv init -)"
EOF

        source /etc/profile.d/pyenv.sh
        end_message

        #pythonの確認
        start_message
        echo "pythonのリスト確認"
        pyenv install --list
        echo "python3.7.3のインストール"
        env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.7.3
        echo "pythonの設定を変更"
        pyenv global 3.7.3
        end_message

        #pythonの確認
        start_message
        echo "pythonの位置を確認"
        which python
        echo "pythonのバージョン確認"
        python --version
        end_message

        #pipのアップグレード
        start_message
        echo "pipのアップグレード"
        pip install --upgrade pip
        end_message

        #mod_wsgiのインストール
        start_message
        echo "mod_wsgiのインストール"
        pip install mod-wsgi
        end_message

        #インストール場所を調べる
        start_message
        echo "インストール場所を調べます"
        pip show mod-wsgi
        ls -all /usr/local/pyenv/versions/3.7.3/lib/python3.7/site-packages/mod_wsgi/server/
        end_message

        #ファイルのコピー
        start_message
        echo "ファイルをコピーします"
        cp  /usr/local/pyenv/versions/3.7.3/lib/python3.7/site-packages/mod_wsgi/server/mod_wsgi-py37.cpython-37m-x86_64-linux-gnu.so /etc/httpd/modules/
        echo "ファイルの確認"
        ls /etc/httpd/modules/
        end_message

        #botleのインストール
        start_message
        echo "botleのインストール"
        pip install bottle
        cp /usr/local/pyenv/versions/3.7.3/lib/python3.7/site-packages/bottle.py /var/www/html/
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
    return ("環境構築スクリプトによりApacheとbottleの連携！")

if __name__ == '__main__':
    run(host='0.0.0.0', port=8081, debug=True, reloader=True)
EOF
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
