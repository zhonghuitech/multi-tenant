SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

USE `mtenant`;

drop table if exists `sys_user`;
CREATE TABLE `sys_user`
(
    `user_id`   bigint      NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `user_name` varchar(30) NOT NULL COMMENT '用户名',
    `tenant_id` varchar(64) DEFAULT 'default' COMMENT '租户ID',
    PRIMARY KEY (`user_id`) USING BTREE,
    KEY         `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=Dynamic COMMENT='用户信息表';

INSERT INTO `sys_user` (user_id, user_name, tenant_id)
values (1, 'admin', 'default'),
       (2, 'zhonghui', 'zhc'),
       (3, 'ceshi', 'zhc'),
       (4, 'aborn', 'zhc');

drop table if exists `user_addr`;
CREATE TABLE `user_addr`
(
    `id`        bigint       NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `user_id`   bigint       NOT NULL COMMENT '用户ID',
    `addr`      varchar(500) NOT NULL COMMENT '地址信息',
    PRIMARY KEY (`id`) USING BTREE,
    KEY         `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=Dynamic COMMENT='用户信息表';

INSERT INTO `user_addr` (id, user_id, addr)
values (1, 2, '中慧物联苏州'),
       (2, 2, '中慧物联上海地址'),
       (3, 2, '中慧物联重庆地址'),
       (4, 2, '中慧物联广州地址'),
       (5, 2, '中慧广州地址'),
       (6, 2, '中慧物联广州地址'),
       (7, 2, '中慧物联广州地址'),
       (8, 1, '中慧物联广州地址'),
       (9, 1, '中慧物联广州地址');

SET FOREIGN_KEY_CHECKS = 1;

