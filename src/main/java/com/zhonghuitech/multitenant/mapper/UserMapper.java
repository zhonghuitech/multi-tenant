package com.zhonghuitech.multitenant.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhonghuitech.multitenant.entity.User;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 *
 * @author aborn
 * @since 2024-09-14
 */
public interface UserMapper extends BaseMapper<User> {

    /**
     * 自定义SQL：默认也会增加多租户条件
     * 参考打印的SQL
     * @return
     */
    Integer myCount();

    List<User> getAddrAndUser(@Param("userName") String username);
}
