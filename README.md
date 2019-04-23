# nginx-install
nginx install package and install script


# how to install
```
yum -y install git; mkdir /usr/local/src/nginx-1.12.1_v0; cd /usr/local/src/nginx-1.12.1_v0;
git clone https://github.com/cucker0/nginx-install.git
cd nginx_install
chmod +x nginx_install.sh
./nginx_install.sh

举例：
nginx-1.12.1
yum -y install git; mkdir /usr/local/src/nginx-1.12.1_v0; cd /usr/local/src/nginx-1.12.1_v0; git clone https://github.com/cucker0/nginx-install.git; cd nginx-install/nginx-1.12.1; chmod +x nginx_install.sh; ./nginx_install.sh; . /etc/profile;

nginx-1.12.2
yum -y install git; mkdir /usr/local/src/nginx-1.12.2_v0; cd /usr/local/src/nginx-1.12.2_v0; git clone https://github.com/cucker0/nginx-install.git; cd nginx-install/nginx-1.12.2; chmod +x nginx_install.sh; ./nginx_install.sh; . /etc/profile;

nginx-1.14.2
yum -y install git; mkdir /usr/local/src/nginx-1.14.2_v0; cd /usr/local/src/nginx-1.14.2_v0; git clone https://github.com/cucker0/nginx-install.git; cd nginx-install/nginx-1.14.2; bash ./nginx_install.sh; . /etc/profile;

# nginx upstream check 项目
https://github.com/zhouchangxun/ngx_healthcheck_module
# 阿里nginx_upstream_check_module
https://github.com/yaoweibin/nginx_upstream_check_module


```
