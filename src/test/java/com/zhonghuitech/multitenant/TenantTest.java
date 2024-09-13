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
