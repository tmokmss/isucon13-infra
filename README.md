アプリは[こちら](https://github.com/tmokmss/isucon13-app/)

## 使い方
* `make init`
  * シンボリックリンクを配置する
* `make apply`
  * 変更を適用する

## snippets
### disable apparmor
We normally don't need this operation unless using symbolic link for my.cnf.

```sh
sudo apparmor_status
ls /etc/apparmor.d/
sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/disable/usr.sbin.mysqld
```

### show systemd definition
```sh
systemctl cat isucholar.go.service

# or check the definition file directly
sudo systemctl status isucholar.go.service

# something like this will appear
● isucholar.go.service - isucholar.go
     Loaded: loaded (/etc/systemd/system/isucholar.go.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2023-11-02 06:51:40 UTC; 1h 46min ago
   Main PID: 26760 (isucholar)
      Tasks: 15 (limit: 2260)
     Memory: 478.9M
     CGroup: /system.slice/isucholar.go.service
             └─26760 /home/isucon/webapp/go/isucholar

cat /etc/systemd/system/isucholar.go.service
```

### setup alp
```sh
cd ~/
wget https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_linux_amd64.zip
unzip alp_linux_amd64.zip
sudo install alp /usr/local/bin/alp
rm alp*

sudo cat /var/log/nginx/access.log | alp ltsv -m "/api/chair/buy/.+","/api/estate/req_doc/.+","/api/chair/\d+","/api/recommended_estate/.+","/api/estate/\d+"
```

### setup pt-query-digest
```sh
sudo apt install -y percona-toolkit
sudo pt-query-digest /var/log/mysql/mysql-slow.log
```

### mysql tuner
Also see: https://github.com/major/MySQLTuner-perl#specific-usage

```sh
wget http://mysqltuner.pl/ -O mysqltuner.pl
sudo cp mysqltuner.pl /usr/local/bin
sudo chmod +x /usr/local/bin/mysqltuner.pl
sudo mysqltuner.pl --host 127.0.0.1
```

### setup netdata
To view detailed metrics and trends about IO, CPU utilization, memory, etc.

```sh
# https://learn.netdata.cloud/docs/installing/one-line-installer-for-all-linux-systems
curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh

# Then ssh portforward from the host
ssh -L localhost:19999:localhost:19999 isu1

# stop the agent
sudo systemctl stop netdata
sudo systemctl disable netdata
```

### logging locations
```sh
sudo chmod -R 777 /var/log/mysql
sudo chmod -R 777 /var/log/nginx

sudo less /var/log/syslog
sudo less /var/log/mysql
sudo less /var/log/nginx

journalctl -q -u isucholar.go -f
journalctl -xe
```

### Disable mitigations

```sh
sudo update-grub
# check grub cfg files e.g. 
# Sourcing file `/etc/default/grub'
# Sourcing file `/etc/default/grub.d/40-force-partuuid.cfg'
# Sourcing file `/etc/default/grub.d/50-cloudimg-settings.cfg'
# Sourcing file `/etc/default/grub.d/99-isucon.cfg'
# Sourcing file `/etc/default/grub.d/init-select.cfg' 

# Find the file containing GRUB_CMDLINE_LINUX option
# Sometimes it's used to set RAM limit

sudo vim /etc/default/grub.d/99-isucon.cfg
# add this line
GRUB_CMDLINE_LINUX="mitigations=off"
# or append the option
GRUB_CMDLINE_LINUX="mem=2G mitigations=off"

sudo update-grub
sudo reboot
```

### ssh portforwarding

```sh
# without bastion
ssh -L localhost:8080:localhost:80 ec2-user@13.0.0.30
ssh -L localhost:3306:localhost:3306 isu2

# with bastion (13.0.0.30 to 172.31.6.60)
ssh -L localhost:8080:172.31.6.60:80 ec2-user@13.0.0.30

# forward multiple ports using alias
ssh -L localhost:8080:172.31.6.60:80 -L localhost:3306:172.31.6.60:3306 ec2
ssh -L localhost:8080:localhost:3000 -L localhost:3306:localhost:3306 isu1

# need root privilege to forward well-known ports
sudo ssh -N -i /Users/xxx/.ssh/id_ed25519 -L443:localhost:443 isucon@isu

# using ssh-tunnel-manager https://github.com/tinned-software/ssh-tunnel-manager/
ssh-tunnel-manager --config ssh-tunnel-manager.conf start
```

### create MySQL user that one can connect from any cidr
add `bind-address = 0.0.0.0` to `mysqld.conf`

apply conf and connect

```sh
sudo service mysql restart
sudo mysql -u root
# or this?
mysql -uisucon -pisucon
```

run SQL query

```sh
# before mysql 8.0 / mariadb
GRANT ALL ON *.* to isucon@'%' IDENTIFIED BY 'isucon';

# after mysql 8.0
CREATE USER 'isucon'@'%' IDENTIFIED BY 'isucon';
GRANT ALL ON *.* to 'isucon'@'%';
```

### Install redis
```sh
sudo apt install -y redis-server

sudo vim /etc/redis/redis.conf
# edit:
# protected-mode no
# supervised systemd
# comment out bind 127.0.0.1 ::1
```

### Setup pprof
Modify app code

```go
import {
	"log"
	// ...
	_ "net/http/pprof"
}

func main() {
	runtime.SetBlockProfileRate(1)
	runtime.SetMutexProfileFraction(1)
	go func() {
		log.Print(http.ListenAndServe("0.0.0.0:6060", nil))
	}()
 // ...
}
```

Deploy and execute the below command:

```sh
sudo apt install -y graphviz
go tool pprof -seconds 60 -http=0.0.0.0:8081 PATH_TO_BIANRY http://localhost:6060/debug/pprof/profile
```

Run ssh port forwarding and open http://localhost:8081

```sh
ssh -L localhost:8081:localhost:8081 isu1
```

### Clean up journal log
```sh
# check journal log size
sudo journalctl --disk-usage

# reteain only recent logs up to 200MB
sudo journalctl --vacuum-size=200M
```

## Additional resources
* https://github.com/catatsuy/memo_isucon
* https://gist.github.com/minhquang4334/26e86a84731164581ed25d3fc7fe5211
* https://gist.github.com/catatsuy/e627aaf118fbe001f2e7c665fda48146
