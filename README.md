# multi-tenant
[![Java CI with Maven](https://github.com/zhonghuitech/multi-tenant/actions/workflows/maven.yml/badge.svg)](https://github.com/zhonghuitech/multi-tenant/actions/workflows/maven.yml)

Springboot 3 + Druid + MybatisPlus 多租户实现（共享表方案）。

##  1 背景
最近在做一款名为`星舰`的产品，需要用到多租户的能力。多租户的实现无非两种方式，一种方式是采用的是分库分表的模式，每个租户单独一套数据库表；另一种方式是共享数据库表的方式。这两种方式各有各的优缺点。本文以共享数据库表为例，实现多租户。每个表都添加一个`tenant_id`字段，在做表CRUD时，希望能做到和无多租户的 SQL一样。这里，我采用了 `MybatisPlus`的多租户插件。

## 2 准备工作

### 2.1 增加依赖
在项目中添加`mybatis-plus`和`druid`的依赖，如下（注意和 springboot 2.x是有区别的）：
```xml
 <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
            <version>3.5.7</version>
        </dependency>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>druid-spring-boot-3-starter</artifactId>
            <version>1.2.23</version>
</dependency>
```

### 2.2 添加数据库表
先建两张表，一张为用户表 `sys_user`，另一张为用户地址表 `user_addr`，这两张表通过`user_id`字段进行关联。插入对应数据，如下：
![sys_user 表](https://upload-images.jianshu.io/upload_images/297930-f03d3e33dea415a1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![user_addr 表](https://upload-images.jianshu.io/upload_images/297930-e043c99fbe6aa631.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们的租户的字段为 `tenant_id` 这个字段，这里我们只对`sys_user`增加租户 ID字段。建表和插入数据，对应的 SQL语句如下：
```sql
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
```

## 3. MybatisPlus多租户的配置
MybatisPlus 有一个扩展`TenantLineInnerInterceptor`已经实现了多租户的能力，它在数据查询的时候默认帮忙加上 `tenant_id = 'tn'` 租户的限制，以达到按租户过滤的功能。在数据插入时默认将当前用户的 `tenant_id`插入相应字段。这个过程对代码无侵入性，也不需要过多改造原有 SQL语句。

### 3.1 配置 MybatisPlusConfig
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

            @Override
            public boolean ignoreTable(String tableName) {
               return "user_addr".equals(tableName);
            }
        }));
        // 如果用了分页插件注意先 add TenantLineInnerInterceptor 再 add PaginationInnerInterceptor
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor());
        return interceptor;
    }
}
```
注意点：
1. 这里的 `getTenantId` 实现是个关键，依据你实际项目来，一般是传入的是登录用户的租户 ID字段，我这里为了测试方便直接写死为`zhc`。
2. `ignoreTable` 对于一些表，可以跳过多租户模型（表里本身无`tenant_id`字段），在这里可以配置。我这里配置了`user_addr`这张表不做多租户的过滤。
3. 这里有个坑，如果代码里配置了`SqlSessionFactory`的注入，需要将上面改成如下配置，否则多租户插件不生效：
   ![image.png](https://upload-images.jianshu.io/upload_images/297930-c16bace4a7515187.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 3.2 特殊SQL语句忽略拦截
在一些场景下，无需多租户拦截，或者对于一些超级管理员使用的接口，希望跨租户查询、免数据鉴权时，可以通过下面几种方式实现忽略拦截：
1. 使用MybatisPlus框架自带的@InterceptorIgnore注解，以用在Mapper类上，也可以用在`Mapper类`的方法上
2. 添加超级用户账号白名单，可以在`ignoreTable`里针对特定账户，直接返回 true，跳过拦截
3. 添加数据表白名单，可以在`ignoreTable`里针对特定数据库表，直接返回 true，跳过拦截

##  4 测试多租户
### 4.1 编写测试用例
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

### 4.2 运行测试用例
1. 第一个测试用例 `dSelect`，普通查询语句
   运行日志如下：
```
2024-09-16T18:50:05.515+08:00 DEBUG 47298 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.selectList       : ==>  Preparing: SELECT user_id, tenant_id, user_name, nick_name FROM sys_user WHERE tenant_id = 'zhc'
2024-09-16T18:50:05.600+08:00 DEBUG 47298 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.selectList       : ==> Parameters: 
2024-09-16T18:50:05.614+08:00 DEBUG 47298 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.selectList       : <==      Total: 5
```
测试结果：

![image.png](https://upload-images.jianshu.io/upload_images/297930-3db7e9e1f2a11cca.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

真实运行的`sql`如下：
```sql
SELECT user_id, user_name, tenant_id FROM sys_user WHERE tenant_id = 'zhc'
```

看打印出的 SQL 语句，自动加上了 `tenant_id='zhc'`的限制条件。

2. 第二个测试用例 `dSelectJoin`，联表查询语句
   `getAddrAndUser` SQL语句如下：
   ![image.png](https://upload-images.jianshu.io/upload_images/297930-a5c3546141738760.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

运行日志如下：
```
2024-09-16T19:10:19.547+08:00 DEBUG 85079 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.getAddrAndUser   : ==>  Preparing: SELECT u.user_id, u.user_name, u.tenant_id, a.addr FROM sys_user u LEFT JOIN user_addr a ON u.user_id = a.user_id WHERE u.tenant_id = 'zhc'
2024-09-16T19:10:19.616+08:00 DEBUG 85079 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.getAddrAndUser   : ==> Parameters: 
2024-09-16T19:10:19.631+08:00 DEBUG 85079 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.getAddrAndUser   : <==      Total: 8
```
真实运行的`sql`如下：
```sql
SELECT u.user_id, u.user_name, u.tenant_id, a.addr FROM sys_user u LEFT JOIN user_addr a ON u.user_id = a.user_id WHERE u.tenant_id = 'zhc'
```

3. 第三个测试用例`lambdaPagination `，分页查询
   运行日志如下：
```
2024-09-16T19:17:18.460+08:00 DEBUG 82705 --- [multi-tenant] [           main] c.z.m.m.UserMapper.selectList_mpCount    : ==>  Preparing: SELECT COUNT(*) AS total FROM sys_user WHERE tenant_id = 'zhc'
2024-09-16T19:17:18.535+08:00 DEBUG 82705 --- [multi-tenant] [           main] c.z.m.m.UserMapper.selectList_mpCount    : ==> Parameters: 
2024-09-16T19:17:18.545+08:00 DEBUG 82705 --- [multi-tenant] [           main] c.z.m.m.UserMapper.selectList_mpCount    : <==      Total: 1
2024-09-16T19:17:18.548+08:00 DEBUG 82705 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.selectList       : ==>  Preparing: SELECT user_id, user_name, tenant_id FROM sys_user WHERE tenant_id = 'zhc' ORDER BY user_id ASC LIMIT ?
2024-09-16T19:17:18.550+08:00 DEBUG 82705 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.selectList       : ==> Parameters: 2(Long)
2024-09-16T19:17:18.552+08:00 DEBUG 82705 --- [multi-tenant] [           main] c.z.m.mapper.UserMapper.selectList       : <==      Total: 2
```
![分页查询结果](https://upload-images.jianshu.io/upload_images/297930-44a3049ebbe9f226.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


##  5. 源码地址
https://github.com/zhonghuitech/multi-tenant