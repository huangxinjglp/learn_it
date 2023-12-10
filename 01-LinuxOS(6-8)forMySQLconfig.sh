------------------------------------------------------------------------------------
------------------------          Linux OS  优化配置操作      ------------------------
------------------------------------------------------------------------------------
1）、主机名配置
	echo "[IP地址]    [主机名]" >> /etc/hosts

2）、关闭SELinxu
	sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config

3）、配置本地YUM源
mount /dev/cdrom /mnt

vim /etc/yum.repods/local.repo

# 内容如下
[Local]
name= Local ISO Repo
baseurl=file:///mnt
gpgcheck=0

# 挂载信息写入磁盘实现永久挂载
echo "/dev/cdrom  /mnt  iso9660 defaults 0 0" >> /etc/fstab

# 安装常用命令
# vim:常用终端文本编辑器、wget:常用终端下载工具、lrzsz:常用本地上传下载工具、net-tools:网络调试工具、tree:树形目录、bash-completion:tab键提示工具

yum install vim wget lrzsz net-tools tree bash-completion -y

4）、英文语言环境配置
echo "export LANG=en_US.UTF8" >> /etc/profile
source /etc/profile

5）、控制资源分配限制配置
echo "session required pam_limits.so" >> /etc/pam.d/login


------------------------------------------------------------------------------------
------------------------      Linux 6系OS  优化配置操作     ------------------------
------------------------------------------------------------------------------------
01)、关闭防火墙
# 临时关闭
service iptables stop

# 永久关闭
chkconfig --level 2345 iptables off

02)、资源限制参数
echo "* soft nproc 65535" >> /etc/security/limits.conf
echo "* hard nproc 65535" >> /etc/security/limits.conf
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf
echo "* soft stack 65535" >> /etc/security/limits.conf
echo "* hard stack 65535" >> /etc/security/limits.conf

echo "* - nproc 65535" > /etc/security/limits.d/90-nproc.conf

03)、关闭NUMA功能
vim /etc/grub.conf
追加内容：numa=off

04)、IO调度算法配置：
vim /etc/rc.d/rc.local
# 追加如下内容
echo 'deadline' > /sys/block/sdb/queue/scheduler
echo 'deadline' > /sys/block/sdc/queue/scheduler
echo 'deadline' > /sys/block/sdd/queue/scheduler
echo 'deadline' > /sys/block/sde/queue/scheduler

echo '16' > /sys/block/sdb/queue/read_ahead_kb
echo '16' > /sys/block/sdc/queue/read_ahead_kb
echo '16' > /sys/block/sdd/queue/read_ahead_kb
echo '16' > /sys/block/sde/queue/read_ahead_kb

echo '512' > /sys/block/sdb/queue/nr_requests
echo '512' > /sys/block/sdc/queue/nr_requests
echo '512' > /sys/block/sdd/queue/nr_requests
echo '512' > /sys/block/sde/queue/nr_requests

05)、虚拟内存与保留内存配置
# 生产环境设置：vm.min_free_kbytes=512000
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.min_free_kbytes=51200" >> /etc/sysctl.conf

06)、磁盘分区管理
# 安装分区工具
yum install lvm2 -y

# 物理卷创建
pvcreate /dev/sd{b..e}

# 卷组创建
vgcreate mysqlvg /dev/sd{b..c}
vgcreate backupvg /dev/sdd
vgcreate softvg /dev/sde

# 逻辑卷配置
lvcreate -n mysqllv -L 30G mysqlvg
lvcreate -n datalv -L 30G mysqlvg
lvcreate -n loglv -L 30G mysqlvg
lvcreate -n backuplv -L 50G backupvg
lvcreate -n softlv -L 30G softvg

# 格式化操作
mkfs.ext4 /dev/mysqlvg/mysqllv
mkfs.ext4 /dev/mysqlvg/datalv
mkfs.ext4 /dev/mysqlvg/loglv
mkfs.ext4 /dev/backupvg/backuplv
mkfs.ext4 /dev/softvg/softlv

# 创建挂载点并进行挂载
mkdir /mysql/{app,data,log,backup} -p
mkdir /soft

mount /dev/mysqlvg/mysqllv /mysql/app
mount /dev/mysqlvg/datalv /mysql/data
mount /dev/mysqlvg/loglv /mysql/log
mount /dev/backupvg/backuplv /mysql/backup
mount /dev/softvg/softlv /soft

# 写入磁盘
echo "/dev/mysqlvg/mysqllv       /mysql/app            ext4   defaults   0 0" >> /etc/fstab
echo "/dev/mysqlvg/datalv         /mysql/data           ext4   defaults   0 0" >> /etc/fstab
echo "/dev/mysqlvg/loglv           /mysql/log     	   ext4   defaults   0 0" >> /etc/fstab
echo "/dev/backupvg/backuplv    /mysql/backup        ext4   defaults   0 0" >> /etc/fstab
echo "/dev/softvg/softlv            /soft                        ext4   defaults   0 0" >> /etc/fstab



------------------------------------------------------------------------------------
----------------------      Linux 7系+OS  优化配置操作     ------------------------
------------------------------------------------------------------------------------
01)、关闭防火墙
# 临时关闭
systemctl stop firewalld.service

# 永久关闭
systemctl disable firewalld.service

02)、资源限制参数
echo "* soft memlock 600000" >> /etc/security/limits.conf
echo "* hard memlock 600000" >> /etc/security/limits.conf
echo "* soft nproc 16384" >> /etc/security/limits.conf
echo "* hard nproc 16384" >> /etc/security/limits.conf
echo "* soft nofile 16384" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft stack  16384" >> /etc/security/limits.conf
echo "* hard stack   32768" >> /etc/security/limits.conf

echo "* - nproc 16384" > /etc/security/limits.d/20-nproc.conf

03)、关闭NUMA功能
vim /etc/default/grub
追加内容：numa=off
生成文件：grub2-mkconfig -o /etc/grub2.cfg

04)、IO调度算法配置：
echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then">> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled">> /etc/rc.d/rc.local
echo "fi">> /etc/rc.d/rc.local
echo "if test -f /sys/kernel/mm/transparent_hugepage/defrag; then">> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag">> /etc/rc.d/rc.local
echo "fi">> /etc/rc.d/rc.local

文件位置：/etc/rc.d/rc.local
# 追加如下内容

echo 'deadline' > /sys/block/sdb/queue/scheduler
echo 'deadline' > /sys/block/sdc/queue/scheduler
echo 'deadline' > /sys/block/sdd/queue/scheduler
echo 'deadline' > /sys/block/sde/queue/scheduler

echo '16' > /sys/block/sdb/queue/read_ahead_kb
echo '16' > /sys/block/sdc/queue/read_ahead_kb
echo '16' > /sys/block/sdd/queue/read_ahead_kb
echo '16' > /sys/block/sde/queue/read_ahead_kb

echo '512' > /sys/block/sdb/queue/nr_requests
echo '512' > /sys/block/sdc/queue/nr_requests
echo '512' > /sys/block/sdd/queue/nr_requests
echo '512' > /sys/block/sde/queue/nr_requests

05)、虚拟内存、保留内存、网络调优配置：
# 生产环境设置：vm.min_free_kbytes=512000
echo "vm.nr_hugepages=300" >> /etc/sysctl.conf
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.min_free_kbytes=51200" >> /etc/sysctl.conf


grep "net.ipv4.tcp_keepalive_time = 30" /etc/sysctl.conf
if [ $? != 0 ]
  then
cat <<EOF>> /etc/sysctl.conf
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.ip_local_port_range = 1024 65000
#net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.core.somaxconn = 262144
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_timestamps = 0
EOF
sed -i 's/net.bridge.bridge-nf-call-ip6tables = 0/#net.bridge.bridge-nf-call-ip6tables = 0/g' /etc/sysctl.conf
sed -i 's/net.bridge.bridge-nf-call-iptables = 0/#net.bridge.bridge-nf-call-iptables = 0/g' /etc/sysctl.conf
sed -i 's/net.bridge.bridge-nf-call-arptables = 0/#net.bridge.bridge-nf-call-arptables = 0/g' /etc/sysctl.conf
fi

06)、磁盘分区管理
# 安装分区工具
yum install lvm2 -y

# 物理卷创建
pvcreate /dev/sd{b..e}

# 卷组创建
vgcreate mysqlvg /dev/sd{b..c}
vgcreate backupvg /dev/sdd
vgcreate softvg /dev/sde

# 逻辑卷配置
lvcreate -n mysqllv -L 30G mysqlvg
lvcreate -n datalv -L 30G mysqlvg
lvcreate -n loglv -L 30G mysqlvg
lvcreate -n backuplv -L 50G backupvg
lvcreate -n softlv -L 30G softvg

# 格式化操作
mkfs.xfs /dev/mysqlvg/mysqllv
mkfs.xfs /dev/mysqlvg/datalv
mkfs.xfs /dev/mysqlvg/loglv
mkfs.xfs /dev/backupvg/backuplv
mkfs.xfs /dev/softvg/softlv

# 创建挂载点并进行挂载
mkdir /mysql/{app,data,log,backup} -p
mkdir /soft

mount /dev/mysqlvg/mysqllv /mysql/app
mount /dev/mysqlvg/datalv /mysql/data
mount /dev/mysqlvg/loglv /mysql/log
mount /dev/backupvg/backuplv /mysql/backup
mount /dev/softvg/softlv /soft

# 写入磁盘
echo "/dev/mysqlvg/mysqllv       /mysql/app            ext4   defaults   0 0" >> /etc/fstab
echo "/dev/mysqlvg/datalv         /mysql/data           ext4   defaults   0 0" >> /etc/fstab
echo "/dev/mysqlvg/loglv           /mysql/log     	   ext4   defaults   0 0" >> /etc/fstab
echo "/dev/backupvg/backuplv    /mysql/backup        ext4   defaults   0 0" >> /etc/fstab
echo "/dev/softvg/softlv            /soft                        ext4   defaults   0 0" >> /etc/fstab