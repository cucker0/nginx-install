# nginx-install
nginx install package and install script


## How to Install
```
# nginx-1.12.1
yum -y install git; \
 mkdir /usr/local/src/nginx-1.12.1_v0; \
 cd /usr/local/src/nginx-1.12.1_v0; \
 git clone https://github.com/cucker0/nginx-install.git; \
 cd nginx-install/nginx-1.12.1; \
 bash ./nginx_install.sh; \
 . /etc/profile;

nginx-1.12.2
yum -y install git; \
 mkdir /usr/local/src/nginx-1.12.2_v0; \
 cd /usr/local/src/nginx-1.12.2_v0; \
 git clone https://github.com/cucker0/nginx-install.git; \
 cd nginx-install/nginx-1.12.2; \
 bash ./nginx_install.sh; \
 . /etc/profile;

# nginx-1.14.2
yum -y install git; \
 mkdir /usr/local/src/nginx-1.14.2_v0; \
 cd /usr/local/src/nginx-1.14.2_v0; \
 git clone https://github.com/cucker0/nginx-install.git; \
 cd nginx-install/nginx-1.14.2; \
 bash ./nginx_install.sh; \
 . /etc/profile;

# nginx-1.18.0
yum -y install git; \
 mkdir /usr/local/src/nginx-1.18.0_v0; \
 cd /usr/local/src/nginx-1.18.0_v0; \
 git clone https://github.com/cucker0/nginx-install.git; \
 cd nginx-install/nginx-1.18.0; \
 bash ./nginx_install.sh; \
 . /etc/profile;

```

## Others
```bash
# nginx upstream check 项目
https://github.com/zhouchangxun/ngx_healthcheck_module

# 阿里nginx_upstream_check_module
https://github.com/yaoweibin/nginx_upstream_check_module
```