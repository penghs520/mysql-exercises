FROM mysql:8.0

# 设置环境变量
ENV MYSQL_ROOT_PASSWORD=root
ENV MYSQL_DATABASE=study_db
ENV MYSQL_USER=study_user
ENV MYSQL_PASSWORD=study123

# 复制自定义配置文件（如果需要）
# COPY my.cnf /etc/mysql/conf.d/

# 复制初始化SQL脚本（如果有）
# COPY ./init-scripts/ /docker-entrypoint-initdb.d/

# 暴露MySQL端口
EXPOSE 3307

# 设置数据卷
VOLUME ["/var/lib/mysql"]
