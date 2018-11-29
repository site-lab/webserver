#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります

目的：システム更新+nginxのインストール
・apache2.4
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

#gitリポジトリのインストール
start_message
yum -y install git
end_message



# yum updateを実行
echo "yum updateを実行します"
echo ""

start_message
#yum -y update
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
yum  --enablerepo=nginx install nginx
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

cat <<EOF
http://IPアドレス
https://IPアドレス
で確認してみてください

ドキュメントルート(DR)は
となります。


EOF
