# multi-tenant
[![Java CI with Maven](https://github.com/zhonghuitech/multi-tenant/actions/workflows/maven.yml/badge.svg)](https://github.com/zhonghuitech/multi-tenant/actions/workflows/maven.yml)

Springboot 3 + Druid + MybatisPlus 多租户实现（共享表方案）。

## 准备工作
先建数据库表，docker 建数据库表脚本在 `scripts/db`
```mysql
drop table if exists sys_user;
CREATE TABLE `sys_user`
(
    `user_id`   bigint      NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `user_name` varchar(30) NOT NULL COMMENT '用户名',
    PRIMARY KEY (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=Dynamic COMMENT='用户信息表';

INSERT INTO `sys_user` (user_id, user_name)
values (1, 'admin'),
       (2, 'zhonghui'),
       (3, 'aborn');

drop table if exists user_addr;
CREATE TABLE `user_addr`
(
    `id`        bigint       NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `user_id`   bigint       NOT NULL COMMENT '用户ID',
    `addr`      varchar(500) NOT NULL COMMENT '地址信息',
    `tenant_id` varchar(64) DEFAULT 'default' COMMENT '租户ID',
    PRIMARY KEY (`user_id`) USING BTREE,
    KEY         `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=Dynamic COMMENT='用户信息表';

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
```
## MybatisPlus多租户的配置
MybatisPlus 有一个扩展`TenantLineInnerInterceptor`已经实现了多租户的能力，它在数据查询的时候默认帮忙加上 `tenant_id = 'tn'` 租户的限制，以达到按租户过滤的功能。在数据插入时默认将当前用户的 `tenant_id`插入相应字段。这个过程对代码无侵入性，也不需要过多改造原有 SQL语句。

配置`MybatisPlusConfig`
```
package com.zhonghuitech.multitenant.config;

import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.handler.TenantLineHandler;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.TenantLineInnerInterceptor;
import net.sf.jsqlparser.expression.Expression;
import net.sf.jsqlparser.expression.StringValue;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * @author aborn
 * @since 2018-08-10
 */
@Configuration
@MapperScan("com.zhonghuitech.**.mapper")
public class MybatisPlusConfig {
    public static final String tenantId = "zhc";

    /**
     * 多租户插件配置
     */
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new TenantLineInnerInterceptor(new TenantLineHandler() {
            @Override
            public Expression getTenantId() {
                return new StringValue(tenantId);
            }

            // 这是 default 方法,默认返回 false 表示所有表都需要拼多租户条件
            @Override
            public boolean ignoreTable(String tableName) {
                if ("sys_user".equals(tableName)) {
                    return true;
                }

                return false;
            }
        }));
        // 如果用了分页插件注意先 add TenantLineInnerInterceptor 再 add PaginationInnerInterceptor
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor());
        return interceptor;
    }
}
```
这里的 `getTenantId` 实现是个关键，依据你的项目来，一般是传入的是登录用户的租户 ID字段，我这里为了测试方便直接写死为`zhc`。
`ignoreTable` 对于一些表，可以跳过多租户模型（表里本身无`tenant_id`字段），在这里可以配置。我这里配置了`sys_user`这张表不做多租户的过滤。这里有个坑，如果代码里配置了`SqlSessionFactory`的注入，需要将上面改成，否则多租户插件不生效：
![image.png](https://upload-images.jianshu.io/upload_images/297930-c16bace4a7515187.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 测试多租户
编写测试用例：
```
package com.zhonghuitech.multitenant;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zhonghuitech.multitenant.config.MybatisPlusConfig;
import com.zhonghuitech.multitenant.entity.User;
import com.zhonghuitech.multitenant.mapper.UserMapper;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.util.CollectionUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * @author aborn (jiangguobao)
 * @date 2024/09/13 11:03
 */
@SpringBootTest
public class TenantTest {
    @Autowired
    private UserMapper mapper;

    @Test
    void contextLoads() {
    }

    @Test
    void dSelect() {
        List<User> userList = mapper.selectList(null);
        userList.forEach(u -> Assertions.assertTrue(MybatisPlusConfig.tenantId.equals(u.getTenantId())));
    }

    // 联表Join的测试
    @Test
    void dSelectJoin() {
        List<User> userList = mapper.getAddrAndUser(null);
        if (!CollectionUtils.isEmpty(userList)) {
            userList.forEach(u -> Assertions.assertTrue(MybatisPlusConfig.tenantId.equals(u.getTenantId())));
        }
    }

    // 分页查询的测试
    @Test
    void lambdaPagination() {
        Page<User> page = new Page<>(1, 2);
        Page<User> result = mapper.selectPage(page, Wrappers.<User>lambdaQuery().orderByAsc(User::getUserId));
        assertThat(result.getTotal()).isGreaterThan(2);
        assertThat(result.getRecords().size()).isEqualTo(2);
    }
}
```
测试结果：
![CC894416-3788-4FC1-B93D-3D5795405ECD.png](https://upload-images.jianshu.io/upload_images/297930-558670a5ab3bd3a5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

看打印出的 SQL 语句，自动加上了 `tenant_id='zhc'`的限制条件。

## 源码地址：
https://github.com/zhonghuitech/multi-tenant