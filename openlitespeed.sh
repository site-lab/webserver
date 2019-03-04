#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+openlitespeedのインストール
・openlitespeed
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

	#groupinstall baseのインストール
        start_message
	yum -y groupinstall base
	yum -y groupinstall development
	yum -y groupinstall network-tools
        end_message

	#リポジトリの追加
        start_message
	rpm -Uvh http://rpms.litespeedtech.com/centos/litespeed-repo-1.1-1.el7.noarch.rpm
        end_message

	#openlitespeedのインストール
        start_message
	yum -y install openlitespeed
        end_message


        #所属グループ表示
        echo "所属グループを表示します"
        getent group nobody
        end_message


        # WEBサーバーの起動
        echo "openlitespeedを起動します"
        start_message
        service lsws start

        echo "WEBサーバーのステータス確認"
        systemctl status lsws
        end_message

        #自動起動の設定
        start_message
        systemctl enable lsws
        systemctl list-unit-files --type=service | grep lsws
        end_message


        #firewallのポート許可
	echo "http(80番)とhttps(443番)と管理画面(7080)の許可をしてます"
        start_message
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
	firewall-cmd --permanent --add-port=7080/tcp
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
        http://IPアドレス:7080
        https://IPアドレス:7080
        で確認してみてください。管理画面が表示されます
        ※conohaやAWS,GCPは管理画面から7080のポートを許可してください
        
        ログインID：admin
        パスワード：123456
        
        パスワードの変更などは初期設定を見るか、
        ----------------------------
        /usr/local/lsws/admin/misc/admpass.sh
        （略）
        User name [admin]: ＜推測されにくいユーザー名＞
        （略）
        Password: ＜強度の高いパスワード＞
        Retype password:
        ----------------------------
        として変更して下さい
        
        ○初期設定
        初期では8088がデフォルトのポートになっているため、変更が必要になります
        https://www.logw.jp/cloudserver/8545.html
        の管理画面でポート変更の手順でやってください
        
        ○OpenliteSpeedの設定について
        LiteSpeedの設定については
        https://www.logw.jp/tag/litespeed
        を見て下さい
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
