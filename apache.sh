#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4系のインストール
・apache2.4.6or2.4.x
・mod_sslのインストール
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
            yum -y install https://centos7.iuscommunity.org/ius-release.rpm
            end_message

            #IUSリポジトリをデフォルトから外す
            start_message
            echo "IUSリポジトリをデフォルトから外します"
            cat >/etc/yum.repos.d/ius.repo <<'EOF'
[ius]
name=IUS Community Packages for Enterprise Linux 7 - $basearch
#baseurl=https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/$basearch
mirrorlist=https://mirrors.iuscommunity.org/mirrorlist?repo=ius-centos7&arch=$basearch&protocol=http
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY

[ius-debuginfo]
name=IUS Community Packages for Enterprise Linux 7 - $basearch - Debug
#baseurl=https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/$basearch/debuginfo
mirrorlist=https://mirrors.iuscommunity.org/mirrorlist?repo=ius-centos7-debuginfo&arch=$basearch&protocol=http
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY

[ius-source]
name=IUS Community Packages for Enterprise Linux 7 - $basearch - Source
#baseurl=https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/SRPMS
mirrorlist=https://mirrors.iuscommunity.org/mirrorlist?repo=ius-centos7-source&arch=source&protocol=http
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
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

        start_message

        echo "ファイルのバックアップ"
        echo ""
        cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

        echo "バージョンの非表示など"
        echo ""
        #sed -i -e "s|ServerName www.example.com:80|#ServerName www.example.com:80|" /etc/httpd/conf/httpd.conf
        sed -i -e "350i #バージョン非表示" /etc/httpd/conf/httpd.conf
        sed -i -e "351i ServerTokens ProductOnly" /etc/httpd/conf/httpd.conf
        sed -i -e "352i ServerSignature off \n" /etc/httpd/conf/httpd.conf

        #バーチャルホストの設定
        cat >/etc/httpd/conf.d/${domain}.conf <<'EOF'
<VirtualHost *:80>
        ServerName ${domain}
        ServerAlias www.${domain}
        DocumentRoot /var/www/html
        ErrorLog /var/log/httpd/error_log
        CustomLog /var/log/httpd/access_log combined env=!no_log

<Directory "/var/www/html/">
        AllowOverride All
        Require all granted
        #Options Includes ExecCGI FollowSymLinks
        #AllowOverride Options=ExecCGI,IncludesNOEXEC
</Directory>
</VirtualHost>
EOF
　　　　#sed関数でドメインを挿入


        #SSLの設定変更（2.4.xの場合http2を有効化）
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
