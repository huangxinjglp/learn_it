------------------------------------------------------------------------------------
------------------------            MySQL 5.7.* 安装操作      ------------------------
------------------------------------------------------------------------------------
************************************************************************************
Mysql 安装支持文档：
https://www.mysql.com/support/supportedplatforms/database.html
------------------------------------------------------------------------------------
--------① 如下操作为MySQL安装时通用操作步骤：
------------------------------------------------------------------------------------
1）、系统默认安装相关组件检索
检索：rpm -qa | grep mysql
卸载：rpm -e mysql-libs-5.1.73-8.el6_8.x86_64 --nodeps

2）、创建组、用户、数据目录
# 创建组
groupadd mysql
# 创建用户
useradd -r -g mysql -s /bin/false mysql
# 创建数据目录：
mkdir /mysql/data/3306/data -p
mkdir /mysql/log/3306 -p

3）、安装必要组件
yum install bison-devel ncurses-devel libaio-devel

------------------------------------------------------------------------------------
--------02--MySQL 5.7.* 二进制安装操作
------------------------------------------------------------------------------------
1）、上传安装包至 /soft
cd /soft
rz

2）、安装包解压并配置环境变量
tar -zxf mysql-5.7.43-linux-glibc2.12-x86_64.tar.gz

ln -s /soft/mysql-5.7.43-linux-glibc2.12-x86_64 /mysql/app/mysql

# 配置环境变量并生效
echo "export MYSQL_HOME=/mysql/app/mysql" >> /etc/profile
echo 'export PATH=$MYSQL_HOME/bin:$PATH' >> /etc/profile
source /etc/profile

mysql --version

3）、配置MySQL参数文件 my.cnf 与 初始化操作

# 配置 my.cnf 参数文件
vim /mysql/data/3306/my.cnf

# 授权
chown mysql:mysql /mysql -R

# 初始化操作
mysqld --defaults-file=/mysql/data/3306/my.cnf --initialize --user=mysql --basedir=/mysql/app/mysql --datadir=/mysql/data/3306/data

# 查看日志是否存在错误
more /mysql/log/3306/itpuxdb-error.err

4）、配置启停服务脚本、启动服务
# 配置启停服务脚本
cd /mysql/app/mysql/support-files/
cp -a mysql.server mysql
（按照实际环境情况进行修改脚本 mysql）

# 脚本测试
mv -t /etc/init.d/ mysql
# 删除系统默认参数配置文件 /etc/my.cnf
rm -f /etc/my.cnf


# 启动测试
service mysql start

# 停止测试
service mysql stop

# 状态测试
service mysql status

# 重启测试
service mysql restart

5）、使用默认密码登录MySQL、开启远程策略、设置系统开机自启
# 查看默认密码
more /mysql/log/3306/itpuxdb-error.err | grep 'root@localhost'

# 登录 MySQL
ln -s /mysql/data/3306/mysql.sock /tmp/mysql.sock

mysql -uroot -p'QnEst)9_r2pk'

# 修改密码
# 方式一：
set password=password('rootroot');
flush privileges;

# 方式二：
alter user 'root'@'localhost' identified by 'rootroot';
flush privileges;
exit

# 开启远程策略
mysql -uroot -prootroot

grant all privileges on *.* to 'root'@'%' identified by 'rootroot' with grant option;
flush privileges;
use mysql;
select user, host from user where user='root';
exit

# 设置系统开机MySQL自启
chkconfig --level 2345 mysql on
chkconfig --list | grep mysql


6）、测试数据模拟演示
# 创建用户
create user itpux identified by 'itpuxitpux';
flush privileges;

# 创建数据库
create database itpuxdb default charset utf8 default collate utf8_general_ci;
flush privileges;

# 授权用户 itpux 管理 itpuxdb
# 本地连接
grant all privileges on itpuxdb.* to 'itpux'@'localhost' identified by 'itpuxitpux' with grant option;
# 远程连接
grant all privileges on itpuxdb.* to 'itpux'@'%' identified by 'itpuxitpux' with grant option;
flush privileges;
exit

# 切换itpux用户登录
mysql -uitpux -pitpuxitpux

# 选择数据库
use itpuxdb;

# 创建测试表 employees
create table employees (
id int auto_increment primary key comment '员工编号',
name varchar(100) not null comment '员工姓名',
age int not null comment '员工年龄',
address varchar(200) not null comment '地址'
)engine=innodb comment '员工表';

commit;
show tables;

# 插入测试数据
insert into employees (name, age, address) values ('张三', 30, '北京');
insert into employees (name, age, address) values ('李四', 18, '上海');
insert into employees (name, age, address) values ('王五', 24, '深圳');

commit;

# 查询所有数据
select * from employees;

------------------------------------------------------------------------------------
--------03--MySQL 5.7.* 源码安装操作
------------------------------------------------------------------------------------
1）、安装必要组件
yum install gcc bison ncurses ncurses-devel zlib libxml2 openssl openssl-devel libstdc++-devel gcc-c++ libaio libaio-devel -y

2）、上传安装包至 /soft
cd /soft
rz

3）、解压缩安装编译工具cmake
tar zxf cmake-3.5.2.tar.gz

cd cmake-3.5.2/ && ./bootstrap

gmake

gmake install

4）、解压缩安装 MySQL
# 解压缩
tar -zxf mysql-boost-5.7.43.tar.gz

# 编译安装
cd mysql-5.7.43

cmake . -DCMAKE_INSTALL_PREFIX=/mysql/app/mysql \
-DENABLED_LOCAL_INFILE=1 \
-DMYSQL_DATADIR=/mysql/data/3306/data \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DSYSCONFDIR=/mysql/data/3306 \
-DMYSQL_UNIX_ADDR=/mysql/data/3306/mysql.sock \
-DMYSQL_TCP_PORT=3306 \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_EXTRA_CHARSETS=all -DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=/soft/mysql-5.7.43/boost/boost_1_59_0

make -j 2 && make install

5）、配置环境变量、参数文件并初始化MySQL
# 配置环境变量
echo "export MYSQL_HOME=/mysql/app/mysql" >> /etc/profile
echo 'export PATH=$PATH:$MYSQL_HOME/bin' >> /etc/profile
source /etc/profile

# 配置 my.cnf 参数文件
vim /mysql/data/3306/my.cnf

# 授权
chown mysql:mysql /mysql -R

# 初始化操作
mysqld --defaults-file=/mysql/data/3306/my.cnf --initialize --user=mysql --basedir=/mysql/app/mysql --datadir=/mysql/data/3306/data

# 查看日志是否存在错误
more /mysql/log/3306/itpuxdb-error.err

6）、配置启停服务脚本、启动服务
# 配置启停服务脚本
cd /mysql/app/mysql/support-files/
cp -a mysql.server mysql
（按照实际环境情况进行修改脚本 mysql）

# 脚本测试
mv -t /etc/init.d/ mysql
# 删除系统默认参数配置文件 /etc/my.cnf
rm -f /etc/my.cnf


# 启动测试
service mysql start

# 停止测试
service mysql stop

# 状态测试
service mysql status

# 重启测试
service mysql restart

7）、使用默认密码登录MySQL、开启远程策略、设置系统开机自启
# 查看默认密码
more /mysql/log/3306/itpuxdb-error.err | grep 'root@localhost'

# 登录 MySQL
ln -s /mysql/data/3306/mysql.sock /tmp/mysql.sock

mysql -uroot -p'QnEst)9_r2pk'

# 修改密码
# 方式一：
set password=password('rootroot');
flush privileges;

# 方式二：
alter user 'root'@'localhost' identified by 'rootroot';
flush privileges;
exit

# 开启远程策略
mysql -uroot -prootroot

grant all privileges on *.* to 'root'@'%' identified by 'rootroot' with grant option;
flush privileges;
use mysql;
select user, host from user where user='root';

exit

# 设置系统开机MySQL自启
chkconfig --level 2345 mysql on
chkconfig --list | grep mysql

8）、测试数据模拟演示
# 创建用户
create user itpux identified by 'itpuxitpux';
flush privileges;

# 创建数据库
create database itpuxdb default charset utf8 default collate utf8_general_ci;
flush privileges;

# 授权用户 itpux 管理 itpuxdb
# 本地连接
grant all privileges on itpuxdb.* to 'itpux'@'localhost' identified by 'itpuxitpux' with grant option;
# 远程连接
grant all privileges on itpuxdb.* to 'itpux'@'%' identified by 'itpuxitpux' with grant option;
flush privileges;
exit

# 切换itpux用户登录
mysql -uitpux -pitpuxitpux

# 选择数据库
use itpuxdb;

# 创建测试表 employees
create table employees (
id int auto_increment primary key comment '员工编号',
name varchar(100) not null comment '员工姓名',
age int not null comment '员工年龄',
address varchar(200) not null comment '地址'
)engine=innodb comment '员工表';

commit;
show tables;

# 插入测试数据
insert into employees (name, age, address) values ('张三', 30, '北京');
insert into employees (name, age, address) values ('李四', 18, '上海');
insert into employees (name, age, address) values ('王五', 24, '深圳');

commit;

# 查询所有数据
select * from employees;


------------------------------------------------------------------------------------
--------04--MySQL 5.7.* YUM源安装操作
------------------------------------------------------------------------------------
1）、该安装方式不利于生产使用
# 忽略上面数据目录维护步骤

2）、从下载 YUM源库安装RPM包 并安装
# Linux 6.*
cd /soft && wget  https://dev.mysql.com/get/mysql80-community-release-el6-10.noarch.rpm

# Linux 7.*
cd /soft && wget https://dev.mysql.com/get/mysql80-community-release-el7-11.noarch.rpm

# Linux 8.*
cd /soft && wget https://dev.mysql.com/get/mysql80-community-release-el8-9.noarch.rpm

------------------------------------------------------------------------------------
# 安装执行
rpm -ivh mysql80-community-release-el6-10.noarch.rpm

3）、修改 mysql-community.repo 文件
cd /etc/yum.repos.d/ && vim mysql-community.repo

# 关闭8.0源，开启5.7源
8.0: enabled=0
5.7: enabled=1

4）、使用 yum 方式安装 MySQL 5.7*
yum install mysql-community-server -y

5）、启动MySQL服务并完成初始化
service mysqld start

6）、登录 MySQL 、修改默认密码、开启远程策略
# 查看默认密码
more /var/log/mysqld.log | grep 'root@localhost'

# 登录MySQL
mysql -uroot -pAFy6Qxtrn=bf

# 修改默认密码
# YUM源方式安装MySQL密码策略较为严格，设置密码时复杂度稍高
alter user 'root'@'localhost' identified by 'P@ssW0rd';
flush privileges;

# 开启远程策略
grant all privileges on *.* to 'root'@'%' identified by 'P@ssW0rd' with grant option;
flush privileges;

7）、测试数据模拟演示
# 创建用户
create user itpux identified by 'P@ssW0rd';
flush privileges;

# 创建数据库
create database itpuxdb default charset utf8 default collate utf8_general_ci;
flush privileges;

# 授权用户 itpux 管理 itpuxdb
# 本地连接
grant all privileges on itpuxdb.* to 'itpux'@'localhost' identified by 'P@ssW0rd' with grant option;
# 远程连接
grant all privileges on itpuxdb.* to 'itpux'@'%' identified by 'P@ssW0rd' with grant option;
flush privileges;
exit

# 切换itpux用户登录
mysql -uitpux -pP@ssW0rd

# 选择数据库
use itpuxdb;

# 创建测试表 employees
create table employees (
id int auto_increment primary key comment '员工编号',
name varchar(100) not null comment '员工姓名',
age int not null comment '员工年龄',
address varchar(200) not null comment '地址'
)engine=innodb comment '员工表';

commit;
show tables;

# 插入测试数据
insert into employees (name, age, address) values ('张三', 30, '北京');
insert into employees (name, age, address) values ('李四', 18, '上海');
insert into employees (name, age, address) values ('王五', 24, '深圳');

commit;

# 查询所有数据
select * from employees;

------------------------------------------------------------------------------------
--------05--MySQL 5.7.* RPM包安装操作
------------------------------------------------------------------------------------
# 官方安装手册
https://dev.mysql.com/doc/refman/5.7/en/linux-installation-rpm.html
------------------------------------------------------------------------------------

1）、该安装方式不利于生产使用
# 忽略上面数据目录维护步骤

2）、MySQL RPM包下载
Linux 6.*：
cd /soft && wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.44-1.el6.x86_64.rpm-bundle.tar

Linux 7.*:
cd /soft && wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.44-1.el7.x86_64.rpm-bundle.tar

3）、解压缩并安装 RPM 包
tar xf mysql-5.7.44-1.el6.x86_64.rpm-bundle.tar

yum install mysql-community-{server,client,common,libs}-* mysql-5.*

4）、启动服务并初始化 MySQL
# 启动服务
service mysqld start

# 停止服务
service mysqld stop

# 查看状态
service mysqld status

# 重启服务
service mysqld restart

5）、查看默认密码、登录MySQL服务、修改默认密码、开启远程登录策略
# 查看默认密码
more /var/log/mysqld.log | grep 'root@localhost'

# 登录MySQL服务
mysql -uroot -p'?P9Oj:lRroid'

# 修改默认密码
set password=password('P@ssW0rd');
flush privileges;

# 开启远程登录策略
grant all privileges on *.* to 'root'@'%' identified by 'P@ssW0rd' with grant option;
flush privileges;

6）、测试数据模拟演示
# 创建用户
create user itpux identified by 'P@ssW0rd';
flush privileges;

# 创建数据库
create database itpuxdb default charset utf8 default collate utf8_general_ci;
flush privileges;

# 授权用户 itpux 管理 itpuxdb
# 本地连接
grant all privileges on itpuxdb.* to 'itpux'@'localhost' identified by 'P@ssW0rd' with grant option;
# 远程连接
grant all privileges on itpuxdb.* to 'itpux'@'%' identified by 'P@ssW0rd' with grant option;
flush privileges;
exit

# 切换itpux用户登录
mysql -uitpux -pP@ssW0rd

# 选择数据库
use itpuxdb;

# 创建测试表 employees
create table employees (
id int auto_increment primary key comment '员工编号',
name varchar(100) not null comment '员工姓名',
age int not null comment '员工年龄',
address varchar(200) not null comment '地址'
)engine=innodb comment '员工表';

commit;
show tables;

# 插入测试数据
insert into employees (name, age, address) values ('张三', 30, '北京');
insert into employees (name, age, address) values ('李四', 18, '上海');
insert into employees (name, age, address) values ('王五', 24, '深圳');

commit;

# 查询所有数据
select * from employees;