FROM mysql:8.0.32
ENV MYSQL_ROOT_PASSWORD=MultiTenantP123654@23
# 设置时区环境变量，确保与宿主机时区一致
ENV TZ=Asia/Shanghai
COPY init-data /docker-entrypoint-initdb.d
