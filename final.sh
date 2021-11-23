#!/bin/bash

function restrict_logins {
	groupadd usrs	# create new group to help restrict ssh
	declare -i pf=0
	OIFS=$IFS; IFS=:
	while read name ignore; do
		if [ "$name" == "postfix" ]; then
			pf=$pf+1
		elif [ "$pf" -gt 0 ]; then
			usermod -a -G usrs $name
### for testing purposes ###
			passwd -u "$name"	
#			passwd -l "$name"
		fi
	done < /etc/shadow
	IFS=$OIFS
}

function new_admin {
	echo "Enter new admin username: "
	read name
	useradd $name
	passwd $pw
	usermod -aG wheel $name
	passwd -u $name
}

function restrict_ssh {
	echo "DenyGroups	usrs	root" >> /etc/ssh/sshd_config
	echo "AllowGroups	wheel" >> /etc/ssh/sshd_config
	systemctl restart sshd
}

function add_legal_banner {
	echo "Unauthorized access to this server is prohibited.  Immediately disconneect." > /etc/issue
	sed -i 's/#Banner none/Banner \/etc\/issue/g' /etc/ssh/sshd_config
}

function add_lynis {
	yum install epel-release -y
	yum update -y
	yum install lynis -y
	lynis audit system	
# can add to see if user wants to view warnings/suggestions
}

function aide_setup {
	yum install aide -y
	aide --init
	mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
# can add to crontab to check every now and then
}

function process_acc {
	yum install psacct -y
	systemctl start psacct
	systemctl enable psacct
}

function disable_fs_mounting {
	echo "install cramfs /bin/false
install freevxfs /bin/false
install hfs /bin/false
install hfsplus /bin/false
install jffs /bin/false
install udf /bin/false" >> /etc/modprobe.d/dccp-blacklist.conf
}


#restrict_logins
#new_admin
#restrict_ssh
#add_legal_banner
#add_lynis
#aide_setup
#process_acc
#disable_fs_mounting

