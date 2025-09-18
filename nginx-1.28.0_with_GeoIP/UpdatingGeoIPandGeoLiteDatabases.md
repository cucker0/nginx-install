# Updating GeoIP and GeoLite Databases

ref [Updating GeoIP and GeoLite Databases](https://dev.maxmind.com/geoip/updating-databases/)

## 1. Install GeoIP Update
安装包：https://github.com/maxmind/geoipupdate/releases

## 2. 获取包含帐号信息的 GeoIP.conf
Log in to your account portal to download a partially [pre-filled configuration file](https://www.maxmind.com/en/accounts/current/license-key/GeoIP.conf) and save it in your configuration directory (e.g., `/usr/local/etc/`) as `GeoIP.conf`. You will need to replace the `YOUR_LICENSE_KEY_HERE`W placeholder with an active license key associated with your MaxMind account. You can see your license key information on [your account License Keys page](https://www.maxmind.com/en/accounts/current/license-key).


```
# GeoIP.conf file - used by geoipupdate program to update databases
# from https://www.maxmind.com
AccountID YOUR_ACCOUNT_ID_HERE
LicenseKey YOUR_LICENSE_KEY_HERE
EditionIDs YOUR_EDITION_IDS_HERE
```

## 3. 运行GeoIP Update
Run `geoipupdate`. To fully automate this process on Linux or Unix, use a crontab file like:
```
# top of crontab
MAILTO=your@email.com

36 6 * * 0,3 /usr/local/bin/geoipupdate
# end of crontab
```