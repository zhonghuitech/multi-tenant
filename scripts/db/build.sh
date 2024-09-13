#!/usr/bin/env bash
################################
# 用于本地执行生成 db 的脚本
################################

DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

# 1. 构建数据库的docker镜像 （含有初始化数据）
docker build -t multitenant_db:v1 .

# 2. 创建虚拟网络
network_name="multitenant_net"

# 检查网络是否存在
if ! docker network ls | grep -q "$network_name"; then
    # 如果网络不存在，则创建网络
    echo "Creating network: $network_name"
    docker network create "$network_name"
else
    echo "Network $network_name already exists."
fi

# 3. 创建数据库容器，并启动
docker run -itd --name multitenant_db -p 3306:3306  --net=$network_name multitenant_db:v1
