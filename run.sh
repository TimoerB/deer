rm -f deer.tar.gz
mv deer.sh /usr/lib/.
cd /usr/lib
chmod +x deer.sh
cd ../bin
ln -fs ../lib/deer.sh deer
