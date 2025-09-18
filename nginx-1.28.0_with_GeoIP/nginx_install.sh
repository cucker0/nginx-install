#!/bin/bash
# nginx install script
# author: song yanlin
# email: hanxiao2100@qq.com

# 软件包
# nginx-1.28.0.tar.gz libmaxminddb-1.12.2.tar.gz ngx_http_geoip2_module-3.4.tar.gz openssl-3.5.3.tar.xz pcre2-10.46.tar.bz2 GeoLite2-ASN_20250917.tar.gz GeoLite2-City_20250912.mmdb.tar.xz GeoLite2-Country_20250916.tar.gz


# nginx: http://nginx.org/en/download.html
# LuaJIT: http://luajit.org
# openssl: https://www.openssl.org/source
# pcre: http://www.pcre.org
# libmaxminddb: https://github.com/maxmind/libmaxminddb
# ngx_http_geoip2_module: https://github.com/leev/ngx_http_geoip2_module


# workdir path_exist_status
workdir=`pwd`
GeoLiteDatabase_DIR="/usr/share/GeoIP"

# 软件版本号
#NGINX_VERSION=`ls nginx-1.*.tar.gz |awk -F '-|.tar' '{print $2}' | head -n 1`
NGINX_VERSION="1.28.0"
OPENSSL_VERSION="3.5.3"
# PCRE2 VERSION
#PCRE_VERSION="10.46"
LIBMAXMINDDB_VERSION="1.12.2"
GEOIP2_VERSION="3.4"
GeoLite2_ASN_VERSION="20250917"
GeoLite2_City_VERSION="20250912"
GeoLite2_Country_VERSION="20250916"


function system_path_config() {
    # 系统环境变量配置与重载
    grep "^export PATH=" /etc/profile
    if [ $? != 0 ]; then # 不存在添加默认系统环境变量
        echo "## PATH" >> /etc/profile
        echo export PATH=$PATH >> /etc/profile
    fi
    . /etc/profile # 重启系统环境变量
}

function library_dynamic_config() {
    # ld.so动态链接库配置与重载
    cat <<ENDOF > /etc/ld.so.conf
include ld.so.conf.d/*.conf
/usr/local/lib
/usr/local/lib64
/lib
/lib64
/usr/lib
/usr/lib64

ENDOF

# 重载ld.so配置
ldconfig
}

function install_dependent_components() {
    # 安装依赖组件
    yum -y install zlib zlib-devel gd gd-devel perl pcre2 pcre2-devel
    yum -y install bind-utils traceroute wget man sudo ntp ntpdate screen patch make gcc gcc-c++ flex bison zip unzip ftp net-tools --skip-broken
    if [ $? != 0 ]; then
        echo "依赖组件安装有错!"
    fi
}

function rpm_install() {
    # rpm包安装器
    # $1: rpm包名
    if [ -n "$1" ]; then
        yum -y install $1
    else
        echo "没有传入rpm包名，使用方法：rpm_install 包名"
    fi
}

function check_dependent_components_install_status() {
    # 检查依赖组件安装是否成功
    rpm -qa |grep zlib-
    if [ $? != 0 ]; then
        rpm_install zlib
    fi
    rpm -qa |grep zlib-devel-
    if [ $? != 0 ]; then
        rpm_install zlib-devel
    fi
    rpm -qa |grep gd-
    if [ $? != 0 ]; then
        rpm_install gd
    fi
    rpm -qa |grep gd-devel-
    if [ $? != 0 ]; then
        rpm_install gd-devel
    fi
    rpm -qa |grep perl-
    if [ $? != 0 ]; then
        rpm_install perl
    fi

    install_dependent_components
}

function libmaxminddb_install() {
    # 安装libmaxminddb
    cd ${workdir}
    tar -zxvf libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz; cd libmaxminddb-${LIBMAXMINDDB_VERSION}
    ./configure --prefix=/usr/local/libmaxminddb_${LIBMAXMINDDB_VERSION}; 
    make; 
    make install
    
    echo "/usr/local/libmaxminddb_${LIBMAXMINDDB_VERSION}/lib" >> /etc/ld.so.conf
    ldconfig
}

function openssl_install() {
    # 安装openssl
    openssl version |grep ${OPENSSL_VERSION}
    if [ $? == 0 ]; then # opensll已经安装
        echo "OpenSSL ${OPENSSL_VERSION} already install"
        return
    fi
    
    yum -y install perl-FindBin perl-IPC-Cmd perl-File-Compare perl-File-Copy perl-CPAN perl-Time-Piece perl-Pod-Html --skip-broken
    cd ${workdir}
    tar -Jxf openssl-${OPENSSL_VERSION}.tar.xz; cd openssl-${OPENSSL_VERSION}
    ./config --prefix=/usr/local/openssl_${OPENSSL_VERSION}; 
    make; 
    #make install;
    #mv /usr/bin/openssl /usr/bin/openssl_1.0.1e-fips
    #ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
    cd ../
    #echo "/usr/local/openssl_${OPENSSL_VERSION}" >> /etc/ld.so.conf

    ldconfig
    if [ $? != 0 ]; then
        echo "install openssl failed!"
        exit 1
    fi
}

function pcre_install() {
    # 安装pcre
    pcretest -C |grep ${PCRE_VERSION}
    if [ $? == 0 ]; then # pcre已经安装
        echo "pcre2-${PCRE_VERSION} already install"
        return
    fi

    cd ${workdir}
    tar -jxf pcre2-${PCRE_VERSION}.tar.bz2; cd pcre2-${PCRE_VERSION}
    ./configure --enable-jit; make; 
    #make install
    cd ../

    if [ $? != 0 ]; then
        echo "install pcre failed!"
        exit 1
    else
        echo "install pcre success."
    fi
    ldconfig
}


function before_nginx_install() {
    # nginx安装前准备工作
    # 解压相关tar包
    cd ${workdir}
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz
    tar -zxvf ngx_http_geoip2_module-${GEOIP2_VERSION}.tar.gz


    # 创建nginx用户和组
    groupadd -g 901 nginx
    useradd nginx -M -u 901 -g 901 -s /sbin/nologin
}

function nginx_install() {
    # 编译安装nginx
    # 依赖步骤 install_dependent_components、openssl_install、pcre_install、before_nginx_install

    nginx -v |grep ${NGINX_VERSION}
    if [ $? == 0 ]; then # nginx已经安装
        echo "nginx-${NGINX_VERSION} already install."
        exit 0
    fi

    # nginx安装环境配置
    NGINX_INSTALL_PACKAGE_DECOMPRESSION_DIR=${workdir}/nginx-${NGINX_VERSION}
    if [ -d "${NGINX_INSTALL_PACKAGE_DECOMPRESSION_DIR}" ]; then
        echo "nginx package decompression directory is exist"
        cd ${NGINX_INSTALL_PACKAGE_DECOMPRESSION_DIR}
    else
        echo "nginx安装包未解压!"
        exit 1
    fi
    # Since nginx 1.21.5, Change: now nginx is built with the PCRE2 library by default.
    # use --with-ld-opt='-lpcre'
    ./configure --prefix=/usr/local/nginx_${NGINX_VERSION} \
    --user=nginx \
    --group=nginx \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-ld-opt='-lpcre' \
    --with-http_realip_module \
    --with-http_image_filter_module \
    --with-http_gzip_static_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-openssl=${workdir}/openssl-${OPENSSL_VERSION} \
    --add-module=${workdir}/ngx_http_geoip2_module-${GEOIP2_VERSION} \
    --with-ld-opt="-L/usr/local/libmaxminddb_${LIBMAXMINDDB_VERSION}/lib" \
    --with-cc-opt="-I/usr/local/libmaxminddb_${LIBMAXMINDDB_VERSION}/include"
    
    if [ $? != 0 ]; then
        echo "configure nginx failed!"
        exit 1
    fi

    # 编译
    make;
    if [ $? != 0 ]; then
        echo "make nginx failed!"
        exit 1
    fi

    # 执行安装
    make install
    if [ $? != 0 ]; then
        echo "make install nginx failed!"
        exit 1
    else
        ln -s /usr/local/nginx_${NGINX_VERSION} /usr/local/nginx
    fi
    cd ../
}



function nginx_system_path_config() {
    # 添加nginx环境变量
    . /etc/profile
    echo ${PATH} |grep "/usr/local/nginx/sbin"
    if [ $? == 0 ]; then
        echo "nginx path is exist"
    else
        sed -i 's/^export PATH=.*$/&:\/usr\/local\/nginx\/sbin/g' /etc/profile
    fi
    . /etc/profile
}

function after_nginx_install() {
    # nginx安装后设置
    if [ ! -d "/etc/nginx" ]; then
        cp -a /usr/local/nginx_${NGINX_VERSION}/conf /etc/nginx
        mkdir /etc/nginx/conf.d
    fi

    mv /usr/local/nginx_${NGINX_VERSION}/conf /usr/local/nginx_${NGINX_VERSION}/conf_yl
    ln -s /etc/nginx /usr/local/nginx_${NGINX_VERSION}/conf  

}

function CopyGeoLiteDatabase() {
    # GeoLite 库复制到目录 /etc/GeoLite
    #mkdir -p ${GeoLiteDatabase_DIR}
    
    cd ${workdir}/GeoLite
    tar -zxvf GeoLite2-ASN_${GeoLite2_ASN_VERSION}.tar.gz 
    cp GeoLite2-ASN_${GeoLite2_ASN_VERSION}/GeoLite2-ASN.mmdb ${GeoLiteDatabase_DIR}
    tar -zxvf GeoLite2-Country_${GeoLite2_Country_VERSION}.tar.gz
    cp GeoLite2-Country_${GeoLite2_Country_VERSION}/GeoLite2-Country.mmdb ${GeoLiteDatabase_DIR}
    tar -Jxf GeoLite2-City_${GeoLite2_City_VERSION}.tar.xz
    cp GeoLite2-City_${GeoLite2_City_VERSION}/GeoLite2-City.mmdb ${GeoLiteDatabase_DIR}
    
}

function geoipupdate_install() {
    # 安装geoipupdate
    yum -y install ${workdir}/geoipupdate_7.1.1_linux_amd64.rpm
    #mv /etc/GeoIP.conf /etc/GeoIP.conf.bak
    #cp ${workdir}/GeoLite/GeoIP.conf /etc
}

function nginx_auto_start_script() {
    # 设置nignx自动启动脚本
    ## CentOS 6
    uname -r| grep '^2.6.'
    if [ $? == 0 ]; then
        \cp -f init.d.nginx /etc/init.d/nginx
        chmod +x /etc/init.d/nginx
        chkconfig nginx on #　开启自动启动

        ldconfig
        sleep 1
        service nginx start
    else
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
        systemctl daemon-reload
        systemctl enable nginx
        ldconfig
        sleep 1
        systemctl start nginx.service
    fi

}

function check_nginx_is_ok() {
    # 检查nginx安装正常
    ldconfig
    . /etc/profile
    nginx -t
    if [ $? == 0 ]; then
        echo "nginx install success."
    else
        echo "nginx install failed!"
    fi
}


function main() {
    # 入口函数
    echo "begin install nginx..."
    # 依赖的步骤顺序要正确
    system_path_config
    library_dynamic_config
    install_dependent_components
    check_dependent_components_install_status
    openssl_install
    #pcre_install
    libmaxminddb_install
    before_nginx_install
    nginx_install
    nginx_system_path_config
    after_nginx_install
    nginx_auto_start_script
    geoipupdate_install
    CopyGeoLiteDatabase
    check_nginx_is_ok
}

main
