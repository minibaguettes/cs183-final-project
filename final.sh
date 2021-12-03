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
			passwd -l "$name"
		fi
	done < /etc/shadow
	IFS=$OIFS
}

function new_admin {
	echo "Enter new admin username: "
	read name
	useradd $name
	passwd -uf $name
	passwd $name
	usermod -aG wheel $name
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

}

function disable_fs_mounting {
	echo "install cramfs /bin/false
install freevxfs /bin/false
install hfs /bin/false
install hfsplus /bin/false
install jffs /bin/false
install udf /bin/false" >> /etc/modprobe.d/dccp-blacklist.conf
}

function disable_usb_mounting {
	echo "install usb-storage /bin/true" > /etc/modprobe.d/disable-usb-storage.conf
}

function disable_uncommon_networks {
	echo "install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
install rose /bin/true
install ax25 /bin/true
install netrom /bin/true
install x25 /bin/true
install decnet /bin/true
install econet /bin/true
install rds /bin/true
install af_802154 /bin/true" > /etc/modprobe.d/disable-uncommon-network.conf
}

function restrict_root_access {
	chmod 700 /root	
}

function restrict_compilers {
	chmod og-rx /usr/bin/gcc
	chmod og-rx /usr/bin/g++
}

function remove_old_packages {
	yum remove `package-cleanup --leaves -q`
}

function move_tmp {
	echo "tmpfs /tmp tmpfs rw,nosuid,nodev" >> /etc/fstab
}

function yum_update {
	#yum update
	echo "poggers"
}

function yum_update_daily {
	echo "#!/bin/bash

yum update -y" > /etc/cron.daily/lockdown_update.sh
}

function remount_dirs_with_restrictions {
	mount -o remount,noexec /tmp
	mount -o remount,rw,hidepid=2 /proc
	mount -o remount,noexec /dev
	mount -o remount,nodev /run
}

function undo_all {
	rm -r -f /etc/modprobe.d/disable-uncommon-network.conf
	rm -r -f /etc/modprobe.d/disable-usb-storage.conf

	chmod 550 /root
	
	chmod 755 /usr/bin/gcc
	chmod 755 /usr/bin/g++	
}

function read_exit {
	select answer in "Yes" "No"; do
		case $answer in
			Yes ) echo "Running..."; break;;
			No ) echo "Exiting lockdown script..."; exit ;;
		esac
	done
}

function read_input_exit {
	typeset -f "$1" | tail -n +2
	echo "$2[Enter a number]"
	select answer in "Yes" "No" "Abort"; do
		case $answer in
			Yes ) echo "Running..."; $1; echo "Done."; break;;
			No ) echo "Skipped"; break;;
			Abort ) echo "Exiting lockdown script..."; exit;;
		esac
	done
}

echo "Run lockdown script final.sh? [Enter a number] "
read_exit

read_input_exit yum_update "Update and upgrade all packages? "

read_input_exit restrict_logins "Restrict logins? "

read_input_exit new_admin "Set new admin? "

read_input_exit restrict_ssh "Restrict SSH? "

read_input_exit add_legal_banner "Add legal banner? "

read_input_exit add_lynis "Install Lynis? "

read_input_exit aide_setup "Install and set up Aide? "

read_input_exit process_acc "Enable process accounting? "

read_input_exit disable_usb_mounting "Disable USB mounting? " 

read_input_exit disable_uncommon_networks "Disable uncommon network protocols? "

read_input_exit restrict_root_access "Restrict access to /root directory? "

read_input_exit restrict_compilers "Restrict access to compilers? "

read_input_exit remove_old_packages "Remove old packages? "

read_input_exit move_tmp "Move /tmp to tmpfs? "

read_input_exit remount_dirs_with_restrictions "Remount /tmp, /proc, /dev, and /run to be more restrictive? "

read_input_exit disable_fs_mounting "Disable filesystem mounting? "

read_input_exit yum_update_daily "Add daily update to crontab? "

echo "Lockdown script complete. System hardened. Exiting..."

exit 0
