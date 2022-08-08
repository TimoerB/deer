ruser=$(whoami)
if [[ "$#" -eq "1" ]]; then
	user="$1"
else
	read -p "User to install into [$ruser]:" user
fi
rm -f deer.tar.gz
rm -f run.sh
chmod +x deerDaemon.sh
chmod +x deer.sh
sed "s/whoami/$user/g" deerd.service.template > deerd.service
rm -f deerd.service.template
mv deer.sh /usr/lib/.
mv deerd.service /etc/systemd/system/
mkdir -p /srv/deerd
mv deerDaemon.sh /srv/deerd
cd /usr/bin
ln -fs ../lib/deer.sh deer
service deerd start
systemctl enable deerd

echo '. /etc/bash_completion.d/deer-completion.sh' >> /home/$user/.bashrc