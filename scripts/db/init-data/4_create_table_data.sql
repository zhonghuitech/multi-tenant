SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

USE `mtenant`;

drop table if exists `sys_user`;
CREATE TABLE `sys_user`
(
    `user_id`   bigint      NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `user_name` varchar(30) NOT NULL COMMENT '用户名',
    PRIMARY KEY (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=Dynamic COMMENT='用户信息表';

INSERT INTO `sys_user` (user_id, user_name)
values (1, 'admin'),
       (2, 'zhonghui'),
       (3, 'aborn');

drop table if exists `user_addr`;
CREATE TABLE `user_addr`
(
    `id`        bigint       NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `user_id`   bigint       NOT NULL COMMENT '用户ID',
    `addr`      varchar(500) NOT NULL COMMENT '地址信息',
    `tenant_id` varchar(64) DEFAULT 'default' COMMENT '租户ID',
    PRIMARY KEY (`id`) USING BTREE,
    KEY         `idx_user_id` (`user_id`),
    KEY         `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=Dynamic COMMENT='用户信息表';

INSERT INTO `user_addr` (id, user_id, addr, tenant_id)
values (1, 2, '中慧物联苏州', 'zhc'),
       (2, 2, '中慧物联上海地址', 'zhc'),
       (3, 2, '中慧物联重庆地址', 'zhc'),
       (4, 2, '中慧物联广州地址', 'zhc'),
       (5, 2, '中慧广州地址', 'zhc'),
       (6, 2, '中慧物联广州地址', 'zhc'),
       (7, 2, '中慧物联广州地址', 'ali'),
       (8, 1, '中慧物联广州地址', 'ali'),
       (9, 1, '中慧物联广州地址', 'unk');

SET FOREIGN_KEY_CHECKS = 1;

