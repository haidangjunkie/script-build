#!/usr/bin/env bash
HOME_MCUS=/var/www/html/$2
WORK_SPACE_JENKIN=/var/lib/jenkins/workspace/$2/$3
HOME_CONFIG=/var/www/html/source_config/production

#--------------------------------------------------------------------------------------
#get params from jenkins
DOMAIN=$1
PATH_DEFAULT_DOMAIN_CONFIG="/etc/nginx/sites-available/"
PATH_DOMAIN_CONFIG=${PATH_DEFAULT_DOMAIN_CONFIG}${DOMAIN}".conf"
SITEROOT=${HOME_MCUS}
#time modify of file config
MTIME_DOMAIN_SET=`date -r "/home/deploy_scripts/config-auto-build-new-site/default.conf" "+%s"`
#MTIME_DOMAIN_GET=`date -r "${PATH_DOMAIN_CONFIG}" "+%s"`
MTIME_ADMIN_SET=`date -r "/home/deploy_scripts/config-auto-build-new-site/admin.conf" "+%s"`
#MTIME_ADMIN_GET=`date -r "/etc/nginx/sites-available/admin.conf" "+%s"`
MTIME_AFFTRUST_SET=`date -r "/home/deploy_scripts/config-auto-build-new-site/afftrust.conf" "+%s"`
#MTIME_AFFTRUST_GET=`date -r "/etc/nginx/sites-available/afftrust.conf" "+%s"`
#copy default config
if [ ! -f ${PATH_DOMAIN_CONFIG} -o MTIME_DOMAIN_SET>`date -r "${PATH_DOMAIN_CONFIG}" "+%s"` ]; then
	rm ${PATH_DOMAIN_CONFIG};
	rm "/etc/nginx/sites-enabled/"${DOMAIN}".conf";
	#copy and link config
	cp "/home/deploy_scripts/config-auto-build-new-site/default.conf" ${PATH_DOMAIN_CONFIG};
	ln -s ${PATH_DOMAIN_CONFIG} "/etc/nginx/sites-enabled/"${DOMAIN}".conf";
	sed -i -e "s|DOMAIN|$DOMAIN|g" ${PATH_DOMAIN_CONFIG};
	sed -i -e "s|SITEROOT|${SITEROOT}|g" ${PATH_DOMAIN_CONFIG};
fi	


#copy config admin
if [ ! -f /etc/nginx/sites-available/admin.conf -o MTIME_ADMIN_SET>`date -r "/etc/nginx/sites-available/admin.conf" "+%s"` ]; then
	rm "/etc/nginx/sites-available/admin.conf";
	rm "/etc/nginx/sites-enabled/admin.conf";
	cp "/home/deploy_scripts/config-auto-build-new-site/admin.conf" "/etc/nginx/sites-available/admin.conf";
	sed -i -e "s|DOMAIN|$DOMAIN|g" "/etc/nginx/sites-available/admin.conf";
	ln -s "/etc/nginx/sites-available/admin.conf" "/etc/nginx/sites-enabled/admin.conf"
fi

#copy config afftrust
if [ ! -f /etc/nginx/sites-available/afftrust.conf -o MTIME_AFFTRUST_SET>`date -r "/etc/nginx/sites-available/afftrust.conf" "+%s"` ]; then
	rm "/etc/nginx/sites-available/afftrust.conf";
	rm "/etc/nginx/sites-enabled/afftrust.conf";
	cp "/home/deploy_scripts/config-auto-build-new-site/afftrust.conf" "/etc/nginx/sites-available/afftrust.conf";
	sed -i -e "s|DOMAIN|$DOMAIN|g" "/etc/nginx/sites-available/afftrust.conf";
	ln -s "/etc/nginx/sites-available/afftrust.conf" "/etc/nginx/sites-enabled/afftrust.conf"	
fi	

#restart nginx
service nginx restart

#restart API
#sudo sh /home/deploy_scripts/Live/live_api.sh
#sudo sh /home/deploy_scripts/Live/live_admin.sh
#sudo sh /home/deploy_scripts/Live/afftrust.sh

echo 'Rename domain in Admin config';
cd /var/www/html/Admin_Live/public;
DOMAIN='http://'$DOMAIN'/'
echo $DOMAIN;
sed -i -e "s|DOMAIN|$DOMAIN|g" /var/www/html/Admin_Live/public/app.config.js
#--------------------------------------------------------------------------------------

echo "****** Copy master souce code from jenkin workspace to Live ******";
rsync -az --delete --exclude='.git/' --exclude='/storage/framework/sessions/' ${WORK_SPACE_JENKIN}/ ${HOME_MCUS}/;

#create session folder
#[ -f ${HOME_MCUS}/storage/framework/sessions ] && chmod -R 777 ${HOME_MCUS}/storage/framework/sessions || mkdir ${HOME_MCUS}/storage/framework/sessions && chmod -R 777 ${HOME_MCUS}/storage/framework/sessions
if [ -f ${HOME_MCUS}/storage/framework/sessions ]; then 
	chmod -R 777 ${HOME_MCUS}/storage/framework/sessions;
else
	mkdir ${HOME_MCUS}/storage/framework/sessions;
	chmod -R 777 ${HOME_MCUS}/storage/framework/sessions;
fi

echo "****** Working with config file and content... ******";

cd ${HOME_MCUS}/config
mv config.php.production config.php
mv app.php.production app.php

sudo cp -r ${HOME_CONFIG}/database.php ${HOME_MCUS}/config/
sed -i "s@RANDOM_VERSION@$RANDOM@g" config.php

cd ${HOME_MCUS}/app/Exceptions
mv Handler.php.production Handler.php

echo "****** Working with permission... ******";

chown -R apache:apache ${HOME_MCUS}/storage
chown -R apache:apache ${HOME_MCUS}/storage/logs
chown -R apache:apache ${HOME_MCUS}/storage/framework
chown -R apache:apache ${HOME_MCUS}/vendor/

chmod -R 777 ${HOME_MCUS}/storage/logs
chmod -R 777 ${HOME_MCUS}/vendor/
chmod -R 777 ${HOME_MCUS}/storage
chmod -R 777 ${HOME_MCUS}/storage/framework

# End

echo "Copy robot.txt if exist"
#[ -f /var/www/html/robots.txt ] && sudo cp /var/www/html/robots.txt ${HOME_MCUS} || echo "File robots.txt not exist! Skip copy"
if [ -f /var/www/html/robots.txt ]; then 
	sudo cp /var/www/html/robots.txt ${HOME_MCUS};
fi	