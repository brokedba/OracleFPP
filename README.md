# Oracle Fleet Patching and Provisioning (FPP) Vagrant build on VirtualBox (brokedba EDIT)

###### Master build: Ruggero Citton (<ruggero.citton@oracle.com>) - Orale RAC Pack, Cloud Innovation and Solution Engineering Team
###### Forked and updated by : @brokedba (<https://twitter.com/BrokeDba>) 

This directory contains Vagrant build files to provision automatically
one Grid Infrastructure and FPP Server host + (optional) an Oracle FPP target with an optional 12c DB home, using Vagrant, Oracle Linux 7.4 and shell scripts.

##### What I changed #####
- I added few shell scripts and modified the VagrantFile to add disks in the target FPP and deploy a 12c database while provisioning the host.
- This will allow to import and image from an existing 12c database  as it's not possible through image zip files as for 18/19c home images. 
[
![image](https://user-images.githubusercontent.com/29458929/100491479-d8f33080-30f1-11eb-9e55-656f570368c5.png)
](https://github.com/brokedba/OracleFPP)

# Important #
This build has been adapted to allow for a 12 db to be shipped with the target (optional) and was tested on VirtualBox but the change do not apply to kvm/Libvirt. 
please only select virtualbox as hypervisor as otherwise the provisoning will fail. 
- I will try to remove any kvm libvirt refences from this README as it's not applicable but it'll depend on my availability. 


![](images/OracleFPP.png)


## Prerequisites

1. Read the [prerequisites in the top level README](../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM
1. You need to download Database binary separately

## Free disk space requirement

- Grid Infrastructure and Database binary zip under "./ORCL_software": ~9.3 Gb
- Grid Infrastructure on u01 vdisk (node1, location set by `u01_disk`): ~7 Gb
- OS guest vdisk (node1/node2) located on default VirtualBox VM location: ~2.5 Gb
  - In case of KVM/libVirt provider, the disk is created under `storage pool = "storage_pool_name"`
  - In case of VirtualBox
    - Use `VBoxManage list systemproperties |grep folder` to find out the current VM default location
    - Use `VBoxManage setproperty machinefolder <your path>` to set VM default location
- Dynamically allocated storage for ASM shared virtual disks (node1, location set by `asm_disk_path`): ~24 Gb


## Memory requirement

- Deploy one Grid Infrastructure and FPP Server (host1) at least 12Gb are required
- Deploy OL7 host2 (optional) as Oracle FPP target at least 6Gb are required (including the 12c database if chosen)

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects.git`
2. Change into OracleFPP folder (`/repo clone path/vagrant-projects/RACPack/OracleFPP`)
3. Download Grid Infrastructure and Database (optional) binary from OTN into `./ORCL_software` folder (*)
4. Run `vagrant up`
5. Connect to Oracle FPP Server (node1).
6. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

(*) Download Grid Infrastructure and Database binary from OTN into `ORCL_software` folder
https://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html

    Accept License Agreement
    go to version (19c) for Linux x86-64 you need -> "See All", example

    * Oracle Database 19c Grid Infrastructure (19.3) for Linux x86-64
        LINUX.X64_193000_grid_home.zip (3,059,705,302 bytes)
        (sha256sum - d668002664d9399cf61eb03c0d1e3687121fc890b1ddd50b35dcbe13c5307d2e)

    * Oracle Database 19c (19.3) for Linux x86-64 (optional)
       LINUX.X64_193000_db_home.zip (4,564,649,047 bytes)
       (sha256sum - ba8329c757133da313ed3b6d7f86c5ac42cd9970a28bf2e6233f3235233aa8d8)

## Customization

You can customize your Oracle environment by amending the parameters in the configuration file: `./config/vagrant.yml`
The following can be customized:

#### host1

- `vm_name`          : VM Guest partial name. The full name will be <prefix_name>-<vm_name>
- `mem_size`         : VM Guest memory size Mb (minimum 12Gb --> 12288)
- `cpus`             : VM Guest virtual cores
- `public_ip`        : VM public ip.
- `vip_ip`           : Oracle RAC VirtualIP (VIP).
- `private_ip`       : VM private ip
- `scan_ip1`         : Oracle RAC SCAN IP1
- `scan_ip2`         : Oracle RAC SCAN IP2
- `scan_ip3`         : Oracle RAC SCAN IP3
- `gns_IP`           : Oracle RAC GNS (FPP requirement)
- `ha_vip`           : Oracle RAC HA_VIP (FPP requirement)
- `storage_pool_name`: KVM/libVirt storage pool name
- `u01_disk`:          VirtualBox Oracle binary virtual disk (u01) file path


#### host2

- `vm_name`          : VM Guest partial name. The full name will be <prefix_name>-<vm_name>
- `mem_size`         : VM Guest memory size Mb (minimum 6Gb --> 6144)
- `cpus`             : VM Guest virtual cores
- `public_ip`        : VM public ip.
- `storage_pool_name`: KVM/libVirt storage pool name
- `u01_disk`:          VirtualBox Oracle binary virtual disk (u01) file path
- `deploy`           : It can be 'true' or 'false'. Using false node2 deploy will be skipped.

- My addition (To ship Host2 with a 12c Database, you always have the choice to not deploy it by setting deploy_db to False). 

![](https://user-images.githubusercontent.com/29458929/89244819-7a032c00-d5d5-11ea-9977-2173f4bdf34e.png)


#### shared network

- `prefix_name`      : VM Guest prefix name (the GI cluster name will be: <prefix_name>-c')
- `network`          : It can be 'hostonly' or 'public'.
  - In case of 'hostonly', the guest VMs are using "host-Only" network defined as 'vboxnet0' (changed to vboxnet0)
  - In case of 'public' a bridge network will be setup ('netmask' and 'gateway' are required). During startup the bridge network is required
- `bridge_nic`       : KVM/libVirt bridge NIC, required in case of 'public' network
- `netmask`          : Required in case of 'public' network
- `gateway`          : Required in case of 'public' network
- `dns_public_ip`    : Required in case of 'public' network
- `domain`           : VM Guest domain name

#### shared storage

- `storage_pool_name`: KVM/libVirt Oradata dbf KVM storage pool name
- `oradata_disk_path`: VirtualBox Oradata dbf path
- `asm_disk_num`     : Oracle RAC Automatic Storage Manager virtual disk number (min 4)
- `asm_disk_size`    : Oracle RAC Automatic Storage Manager virtual disk (max) size in Gb (at least 10)

#### environment

- `provider`         : It's defining the provider to be used: 'libvirt' or 'virtualbox'
- `grid_software`    : Oracle Database 18c Grid Infrastructure (18.3) for Linux x86-64 zip file (or above)
- `root_password`    : VM Guest root password
- `grid_password`    : VM Guest grid password
- `oracle_password`  : VM Guest oracle password
- `sys_password`     : Oracled RDBMS SYS password
- `ora_languages`    : Oracle products languages
- `asm_lib_type`     : ASM library in use (ASMLIB/AFD)

#### Virtualbox provider Example1 (Oracle FPP Server available on host-only Virtualbox network):
```
# -----------------------------------------------
# vagrant.yml for VirtualBox
# -----------------------------------------------
host1:
  vm_name: fpp-Server
  mem_size: 12288
  cpus: 1
  public_ip:     192.168.78.101
  vip_ip:        192.168.78.201
  scan_ip1:      192.168.78.151
  scan_ip2:      192.168.78.152
  scan_ip3:      192.168.78.153
  gns_ip:        192.168.78.108
  ha_vip:        192.168.78.109
  private_ip:    192.168.100.101
  u01_disk: ./fpps_u01.vdi

host2:
  vm_name: fpp-Client
  mem_size: 6144
  cpus: 1
  public_ip: 192.168.78.102
  u01_disk: ./fppc_u01.vdi
  u02_disk: ./fppc_u02.vdi
  deploy: 'true'
  deploy_db: 'true'
  oracle_base: /u01/app/oracle
  db_home: /u01/app/oracle/product/12.1.0.2/dbhome_1
  db_sid: cdb1
  pdb: pdb1
  charset: AL32UTF8
  edition: EE
  listener_port: 1521
  
shared:
  prefix_name:   london-fleet
  # ---------------------------------------------
  network:       hostonly
  netmask:       
  gateway:       
  dns_public_ip: 8.8.8.8
  domain:        evilcorp.com
  # ---------------------------------------------
  non_rotational: 'on'
  # ---------------------------------------------
  asm_disk_path: C:\DATA\VM\boxes\FPP\shared
  asm_disk_num:   6
  asm_disk_size: 10
  # ---------------------------------------------

env:
  provider: virtualbox
  # ---------------------------------------------
  gi_software: LINUX.X64_193000_grid_home.zip
  # ---------------------------------------------
  root_password:   welcome1
  grid_password:   welcome1
  oracle_password: welcome1
  sys_password:    welcome1
  # ---------------------------------------------
  ora_languages:   en,en_US
  # ---------------------------------------------
```



## Note

- `SYSTEM_TIMEZONE`: `automatically set (see below)`
  The system time zone is used by the database for SYSDATE/SYSTIMESTAMP.
  The guest time zone will be set to the host time zone when the host time zone is a full hour offset from GMT.
  When the host time zone isn't a full hour offset from GMT (e.g., in India and parts of Australia), the guest time zone will be set to UTC.
  You can specify a different time zone using a time zone name (e.g., "America/Los_Angeles") or an offset from GMT (e.g., "Etc/GMT-2"). For more information on specifying time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
- Wallet Zip file location `/tmp/wallet_<pdb name>.zip`.
  Copy the file on client machine, unzip and set TNS_ADMIN to Wallet loc. Connect to DB using Oracle Sql Client or using your App

- If you are behind a proxy, set the following env variables
  - (Linux/MacOSX)
    - export http_proxy=http://proxy:port
    - export https_proxy=https://proxy:port

  - (Windows)
    - set http_proxy=http://proxy:port
    - set https_proxy=https://proxy:port

## FPP commands you could test postdeploy based on the configuration file above

Note1 : as you need the Database binaries zip file under "ORCL_software"  
Note2 : having limited resource you may want setup the following JAVA env variables for grid user : `JVM_ARGS="-Xms512m -Xmx512m" and _JAVA_OPTIONS="-XX:ParallelGCThreads=2"` before rhpctl commands executions  
Note3 : you can connect host1/host2 issuing 'vagrant ssh host1/host2'  
Note4 : following some fpp commands you may want to try

- `rhpctl import image -image db_19300 -imagetype ORACLEDBSOFTWARE -zip /vagrant/ORCL_software/LINUX.X64_193000_db_home.zip`
- `rhpctl import image -image gi_19300 -imagetype ORACLEGISOFTWARE -zip /vagrant/ORCL_software/LINUX.X64_193000_grid_home.zip`
- `rhpctl add workingcopy -workingcopy wc_db_19300 -image db_19300 -user oracle -groups OSBACKUP=dba,OSDG=dba,OSKM=dba,OSRAC=dba -oraclebase /u01/app/oracle -path /u01/app/oracle/product/193000/dbhome_1 -targetnode fppc -root`
- `rhpctl add database -workingcopy wc_db_19300 -dbname ORCL -dbtype SINGLE -cdb -pdbName PDB -numberOfPDBs 2 -root`
- Import an image from an existing 12c database home
```
[grid@fpp-Server]$ rhpctl import image -image db_12102 -imagetype ORACLEDBSOFTWARE -path /u01/app/oracle/product/12.1.0.2/dbhome_1 -targetnode fpp-Client
 -root
Enter user "root" password:
fpp-Server.evilcorp.com: Adding storage for image ...
fpp-Server.evilcorp.com: Creating a new ACFS file system for image "db_12102" ...
fpp-Server.evilcorp.com: Starting export file system...
fpp-Server.evilcorp.com: Mounting file system...
fpp-Server.evilcorp.com: Copying files...
fpp-Server.evilcorp.com: Removing export file system ...

QUERY IMAGE
 ============  
  
  [grid@fpp-Server ~]$ rhpctl query image -image db_12102
  fpp-Server.evilcorp.com: Audit ID: 17
  Image name: db_12102
  Owner: grid@london-fleet-c
  Site: london-fleet-c
  Access control: USER:grid@london-fleet-c
  Access control: ROLE:OTHER
  Access control: ROLE:GH_IMG_PUBLISH
  Access control: ROLE:GH_IMG_ADMIN
  Access control: ROLE:GH_IMG_VISIBILITY
  Parent Image:
  Software home path: /rhp_storage/images/idb_12102399207/swhome
  Image state: PUBLISHED
  Image size: 5320 Megabytes
  Image Type: ORACLEDBSOFTWARE
  Image Version: 12.1.0.2.0
  Groups configured in the image: OSDBA=dba,OSBACKUP=dba,OSDG=dba,OSKM=dba
  Image platform: Linux_AMD64
  Interim patches installed:
  Contains a non-rolling patch: FALSE
  Complete: TRUE
```

- upgrade from an existing 12 target db_home to a 19c working copy 

```

[grid@fpp-Server ~]$ rhpctl upgrade database -dbname cdb1 -sourcehome /u01/app/oracle/product/12.1.0.2/dbhome_1  -destwc wc_db_19300 -targetnode fpp-Client -root
         Enter user "root" password:

```
