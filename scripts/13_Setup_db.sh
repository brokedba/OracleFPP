#!/bin/bash
# Abort on any error
set -e


echo 'INSTALLER: Started up'
echo "******************************************************************************"
echo "Set up neofetch vagrant welcome page." `date`
echo "******************************************************************************"
curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
yum install neofetch -y

mkdir /home/vagrant/.config/
mkdir /home/vagrant/.config/neofetch
cp /vagrant/config/neofetch_config.conf /home/vagrant/.config/neofetch/config.conf
chown -R vagrant /home/vagrant/.config/
sudo mv /etc/motd /etc/motd.old

echo "******************************************************************************"
echo "Set up environment for one-off actions." `date`
echo "******************************************************************************"
export ORACLE_BASE=${DB_BASE}
export ORACLE_HOME=${DB_HOME}
export SOFTWARE_DIR=/vagrant/ORCL_software
export ORA_INVENTORY=/u01/app/oraInventory
export SCRIPTS_DIR=/home/oracle/scripts
export DATA_DIR=/u02/oradata


# get up to date
#yum upgrade -y

echo 'INSTALLER: System updated'

# fix locale warning
#yum reinstall -y glibc-common
#echo LANG=en_US.utf-8 >> /etc/environment
#echo LC_ALL=en_US.utf-8 >> /etc/environment

#echo 'INSTALLER: Locale set'

# set system time zone
#sudo timedatectl set-timezone $SYSTEM_TIMEZONE
#echo "INSTALLER: System time zone set to $SYSTEM_TIMEZONE"

# Install Oracle Database prereq and openssl packages
 yum install -y oracle-rdbms-server-12cR1-preinstall openssl

# echo 'INSTALLER: Oracle preinstall and openssl complete'

# 
echo "******************************************************************************"
echo " Create directories ." `date`
echo "******************************************************************************"

mkdir -p /u01/app
mkdir -p ${ORACLE_BASE}
mkdir -p ${DATA_DIR}
chown -R oracle.oinstall /u01 /u02
chown oracle:oinstall -R $ORACLE_BASE

echo 'INSTALLER: Oracle directories created'

echo "******************************************************************************"
echo " set environment variables ." `date`
echo "******************************************************************************"
 
echo "export ORACLE_BASE=${ORACLE_BASE}" >> /home/oracle/.bashrc
echo "export ORACLE_HOME=${ORACLE_HOME}" >> /home/oracle/.bashrc
echo "export ORACLE_SID=${ORACLE_SID}" >> /home/oracle/.bashrc
echo "export PATH=$PATH:$ORACLE_HOME/bin" >> /home/oracle/.bashrc
echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib" >> /home/oracle/.bashrc
echo "export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

echo "******************************************************************************"
echo " Install Oracle ." `date`
echo "******************************************************************************"

case "$ORACLE_EDITION" in
  "EE")
    unzip "${SOFTWARE_DIR}/linuxamd64_12102_database_?of2.zip" -d /tmp
    ;;
  "SE2")
    unzip "${SOFTWARE_DIR}/linuxamd64_12102_database_se2_?of2.zip" -d /tmp
    ;;
  *)
    echo "INSTALLER: Invalid ORACLE_EDITION $ORACLE_EDITION. Must be EE or SE2. Exiting."
    exit 1
    ;;
esac

cp /vagrant/scripts/ora-response/db_install.rsp.tmpl /tmp/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|${ORACLE_BASE}|g" /tmp/db_install.rsp
sed -i -e "s|###ORACLE_HOME###|${ORACLE_HOME}|g" /tmp/db_install.rsp
sed -i -e "s|###ORACLE_EDITION###|${ORACLE_EDITION}|g" /tmp/db_install.rsp
su -l oracle -c "yes | /tmp/database/runInstaller -silent -showProgress -ignorePrereq -waitforcompletion -responseFile /tmp/db_install.rsp"
$ORACLE_BASE/oraInventory/orainstRoot.sh
$ORACLE_HOME/root.sh
# some files in the installer zips are extracted without write permissions
chmod -R u+w /tmp/database
rm -rf /tmp/database
rm /tmp/db_install.rsp

echo 'INSTALLER: Oracle software installed'


echo "******************************************************************************"
echo " Create sqlnet.ora, listener.ora and tnsnames.ora " `date`
echo "******************************************************************************"

su -l oracle -c "mkdir -p $ORACLE_HOME/network/admin"
su -l oracle -c "echo 'NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)' > $ORACLE_HOME/network/admin/sqlnet.ora"

# Listener.ora
su -l oracle -c "echo 'LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
' > $ORACLE_HOME/network/admin/listener.ora"

su -l oracle -c "echo '$ORACLE_SID=localhost:$LISTENER_PORT/$ORACLE_SID' > $ORACLE_HOME/network/admin/tnsnames.ora"
su -l oracle -c "echo '$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)' >> $ORACLE_HOME/network/admin/tnsnames.ora"

# Start LISTENER
su -l oracle -c "lsnrctl start"

echo 'INSTALLER: Listener created'

echo "******************************************************************************"
echo " Create database " `date`
echo "******************************************************************************"

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 8`1"}

cp /vagrant/scripts/ora-response/dbca.rsp.tmpl /tmp/dbca.rsp
sed -i -e "s|###ORACLE_SID###|${ORACLE_SID}|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|${ORACLE_PDB}|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_CHARACTERSET###|${ORACLE_CHARACTERSET}|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|${ORACLE_PASSWORD}|g" /tmp/dbca.rsp
sed -i -e "s|###DATA_DIR###|${DATA_DIR}|g" /tmp/dbca.rsp
# Create DB
su -l oracle -c "dbca -silent -createDatabase -responseFile /tmp/dbca.rsp"

echo "******************************************************************************"
echo " Post DB setup tasks " `date`
echo "******************************************************************************"

# 12.1.0.2 requires DBMS_XDB_CONFIG.SETHTTPSPORT for non-standard port to work
su -l oracle -c "sqlplus / as sysdba <<EOF
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   ALTER SYSTEM SET LOCAL_LISTENER = '(ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))' SCOPE=BOTH;
   ALTER SYSTEM REGISTER;
   EXEC DBMS_XDB_CONFIG.SETHTTPSPORT ($EM_EXPRESS_PORT);
   exit;
EOF"

rm /tmp/dbca.rsp

echo 'INSTALLER: Database created'

sed '$s/N/Y/' /etc/oratab | sudo tee /etc/oratab > /dev/null
echo 'INSTALLER: Oratab configured'

echo "******************************************************************************"
echo " Configure systemd to start oracle instance on startup " `date`
echo "******************************************************************************"
# 
sudo cp /vagrant/scripts/oracle-rdbms.service /etc/systemd/system/
sudo sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service
sudo systemctl daemon-reload
sudo systemctl enable oracle-rdbms
sudo systemctl start oracle-rdbms
echo "INSTALLER: Created and enabled oracle-rdbms systemd's service"

#sudo cp /vagrant/scripts/setPassword.sh /home/oracle/
#sudo chown oracle:oinstall /home/oracle/setPassword.sh
#sudo chmod u+x /home/oracle/setPassword.sh

#echo "INSTALLER: setPassword.sh file setup";


echo 'INSTALLER: Done running user-defined post-setup scripts'

echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PASSWORD";

echo "INSTALLER: Installation complete, database ready to use!";
