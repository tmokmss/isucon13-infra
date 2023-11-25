SHELL=/bin/bash
usage:
	# Use with an argument: e.g. make <command>

init:
	cp ~/.bashrc ./.bashrc | true
	cp ~/.tmux.conf ./.tmux.conf | true
	cp ~/.vimrc ./.vimrc | true
	cp /etc/inputrc ./inputrc | true
	cp ~/env.sh ./env.sh | true
	cp /etc/nginx/nginx.conf ./nginx.conf | true
	# cp /etc/nginx/sites-enabled/isupipe.conf ./isupipe.conf | true
	cp /etc/nginx/sites-enabled/isupipe.conf ./isupipe.conf | true
	# cp /etc/mysql/my.cnf ./my.cnf | true
	cp /etc/mysql/mysql.conf.d/mysqld.cnf mysqld.cnf | true
	cp /etc/powerdns/pdns.conf pdns.conf | true
	cp /etc/dnsdist/dnsdist.conf dnsdist.conf | true
	
apply:
	# cannot apply this from Makefile for some reason
	# source ~/.bashrc
	# bind -f ~/.inputrc
	cp .bashrc ~/.bashrc
	cp .vimrc ~/.vimrc
	cp .tmux.conf ~/.tmux.conf
	cp .inputrc ~/.inputrc
	cp env.sh ~/env.sh
	sudo cp .vimrc /root/.vimrc
	sudo cp ./nginx.conf /etc/nginx/nginx.conf
	# sudo cp ./isupipe.conf /etc/nginx/sites-enabled/isupipe.conf
	sudo cp ./isupipe.conf /etc/nginx/sites-enabled/isupipe.conf
	# sudo cp ./my.cnf /etc/mysql/my.cnf
	sudo cp ./mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
	sudo cp ./pdns.conf /etc/powerdns/pdns.conf
	sudo cp ./dnsdist.conf /etc/dnsdist/dnsdist.conf
	make nginx
	make db
	make pdns

date:
	@TZ=Asia/Tokyo date +"%Y-%m-%dT%H:%M:%S%z"

db:
	sudo systemctl restart mysql.service

nginx:
	sudo systemctl restart nginx.service
pdns:
	sudo systemctl restart pdns

app:
	# TODO: check command to restart the app
	sudo systemctl restart isupipe-go

alp: date
	# Add arguments: e.g. make alp args="--sort p99 -r"
	sudo alp --config alp.yaml ltsv --file /var/log/nginx/access.log $(args)

ptq: date
	sudo pt-query-digest --explain 'h=isu2,u=isucon,p=isucon,D=isupipe' --limit 10 /var/log/mysql/mysql-slow.log

mss: date
	sudo mysqldumpslow -s t -t 20 /var/log/mysql/mysql-slow.log

reset-log:
	sudo rm /var/log/mysql/mysql-slow.log || true
	sudo rm /var/log/nginx/access.log || true
	make --no-print-directory db
	make --no-print-directory nginx

