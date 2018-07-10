#!/bin/bash
# nginx install

# 软件包
#  LuaJIT-2.0.5.tar.gz nginx-1.12.1.tar.gz   ngx_devel_kit-0.3.0.tag.gz   openssl-1.0.2l.tar.gz lua-nginx-module-0.10.9rc8.tar.gz  nginx_upstream_check_module-v1.12.1+.tar.gz  ngx_dynamic_upstream-0.1.6.tar.gz  pcre-8.41.tar.gz init.d.nginx nginx-1.12.1_install.sh


# workdir path_exist_status
workdir=`pwd`

# nginx版本号
#nginx_version=`ls nginx-1.*.tar.gz |awk -F '-|.tar' '{print $2}' | head -n 1`
nginx_version="1.12.1"

echo "begin install nginx..."

# 是否已经添加默认的环境变量
grep "^export PATH=" /etc/profile
path_exist_status=`echo $?`

# 不存在添加默认系统环境变量
if [ $path_exist_status != "0" ]; then
    echo "## PATH" >> /etc/profile
    echo export PATH=$PATH >> /etc/profile
fi
. /etc/profile

# 依赖安装
yum -y install zlib zlib-devel gd gd-devel perl
yum install -y bind-utils traceroute wget man sudo ntp ntpdate screen patch make gcc gcc-c++ flex bison zip unzip ftp net-tools --skip-broken 

if [ $? !=0 ]; then
    echo "依赖安装有错!"
fi

# 安装openssh
cd $workdir
tar -zxvf openssl-1.0.2l.tar.gz; cd openssl-1.0.2l
./config; make; make install
mv /usr/bin/openssl /usr/bin/openssl_1.0.1e-fips
ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
cd ../

ldconfig
if [ $? !=0 ]; then
    echo "install openssh failed!"
    exit 1
fi


# pcre安装
tar -zxvf pcre-8.41.tar.gz; cd pcre-8.41
./configure --enable-jit; make; make install
cd ../

if [ $? !=0 ]; then
    echo "install pcre failed!"
    exit 1
fi
ldconfig

# nginx_lua_module模块依赖的Lua环境
tar -zxvf LuaJIT-2.0.5.tar.gz
cd LuaJIT-2.0.5
make; make install
cd ../

ldconfig

# 添加lua lib

if [ ! $LUAJIT_LIB ]; then 
cat <<ENDOF >>/etc/profile
## Lua
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0
ENDOF
fi


source /etc/profile


# 解压相关tar包
cd $workdir
tar -zxvf lua-nginx-module-0.10.9rc8.tar.gz
tar -zxvf ngx_devel_kit-0.3.0.tag.gz
tar -zxvf ngx_dynamic_upstream-0.1.6.tar.gz


# 打上nginx_upstream_check_module 补丁
tar -zxvf nginx_upstream_check_module-v1.12.1+.tar.gz
tar -zxvf nginx-${nginx_version}.tar.gz
cd nginx-${nginx_version}
patch -p1 < $workdir/nginx_upstream_check_module-v1.12.1+/check_1.12.1+.patch

# 创建nginx用户跟组
groupadd -g 901 nginx
useradd nginx -M -u 901 -g 901 -s /sbin/nologin

# 配置nginx
./configure --prefix=/usr/local/nginx_${nginx_version} --user=nginx --group=nginx --with-http_stub_status_module --with-http_ssl_module --with-pcre=$workdir/pcre-8.41 --with-http_realip_module --with-http_image_filter_module --with-http_gzip_static_module --with-openssl=$workdir/openssl-1.0.2l --with-openssl-opt=enable-tlsext --add-module=$workdir/ngx_devel_kit-0.3.0 --add-module=$workdir/lua-nginx-module-0.10.9rc8 --add-module=$workdir/nginx_upstream_check_module-v1.12.1+ --add-module=$workdir/ngx_dynamic_upstream-0.1.6 --with-stream --with-stream_ssl_module
if [ $? !=0 ]; then
    echo "configure nginx failed!"
    exit 1
fi

make;
if [ $? !=0 ]; then
    echo "make nginx failed!"
    exit 1
fi

make install
if [ $? !=0 ]; then
    echo "make install nginx failed!"
    exit 1
fi

cd ../
ln -s /usr/local/nginx_${nginx_version} /usr/local/nginx
# 添加nginx环境变量
sed -i 's/^export PATH=.*$/&:\/usr\/local\/nginx\/sbin/g' /etc/profile
. /etc/profile


if [ ! -d "/etc/nginx" ]; then
	cp -r /usr/local/nginx_${nginx_version}/conf /etc/nginx
	mkdir /etc/nginx/conf.d
fi

mv /usr/local/nginx_${nginx_version}/conf /usr/local/nginx_${nginx_version}/conf_yl
ln -s /etc/nginx /usr/local/nginx_${nginx_version}/conf


## CentOS 6
uname -r| grep '2.6.'
if [ $? == 0 ]; then

cp init.d.nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
chkconfig nginx on

ldconfig
sleep 1
service nginx start
fi

## CentOS 7
uname -r| grep '3.10.'
if [ $? == 0 ]; then
cat <<ENDOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
ENDOF

systemctl enable nginx

ldconfig
sleep 1
systemctl start nginx.service
fi


echo "finish install nginx."



