
-- 创建用户
create user 'mtenantuser'@'%' identified by 'Mtenant@2049zhc!';
-- 授权
-- ALTER USER 'maisy'@'%' IDENTIFIED WITH mysql_native_password BY '';
grant all privileges on *.* to 'mtenantuser'@'%';
-- 更新
flush privileges;
