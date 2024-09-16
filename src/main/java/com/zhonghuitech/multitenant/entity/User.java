package com.zhonghuitech.multitenant.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.experimental.Accessors;

/**
 * <p>
 * 用户实体对应表 user
 * </p>
 *
 * @author aborn
 * @since 2018-08-11
 */
@Data
@Accessors(chain = true)
@TableName("sys_user")
public class User {
    @TableId
    private Long userId;

    private String userName;

    /**
     * 租户 ID
     */
    private String tenantId;

    /**
     * 在 user_addr 里的字段
     */
    @TableField(exist = false)
    private String addr;
}
