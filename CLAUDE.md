# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a MySQL 8 study repository with a Docker-based learning environment.

## Commands

### 启动MySQL环境
```bash
# 使用docker-compose启动（推荐）
docker-compose up -d

# 首次启动需要等待数据初始化（约1-2分钟）
# 查看初始化日志
docker logs -f mysql-study

# 或使用Dockerfile直接构建和运行
docker build -t mysql-study .
docker run -d -p 3307:3306 --name mysql-study mysql-study
```

### 连接到MySQL
```bash
# 使用docker exec进入容器
docker exec -it mysql-study mysql -uroot -proot --default-character-set=utf8mb4

# 或使用study_user登录
docker exec -it mysql-study mysql -ustudy_user -pstudy123 study_db --default-character-set=utf8mb4
```

### 停止和清理
```bash
# 停止服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

## Architecture

- `Dockerfile`: MySQL 8.0环境配置
- `docker-compose.yml`: Docker Compose配置，包含数据持久化
- `init-scripts/`: 存放初始化SQL脚本的目录（容器启动时自动执行）
  - `01-ecommerce-schema.sql`: 电子商城示例数据库（约10万条数据）

### 默认配置
- Root密码: `root`
- 学习数据库: `study_db`
- 学习用户: `study_user` / `study123`
- 字符集: utf8mb4
- 端口: 3307 (主机) -> 3306 (容器)

### 电子商城数据库结构
包含10张核心业务表，约10万条示例数据：
- `users` (1000条) - 用户信息
- `categories` (50条) - 商品分类
- `products` (500条) - 商品信息
- `product_skus` (1000条) - 商品SKU规格
- `cart_items` (5000条) - 购物车
- `user_addresses` (3000条) - 收货地址
- `orders` (20000条) - 订单
- `order_items` (50000条) - 订单明细
- `product_reviews` (20000条) - 商品评价
- `payments` (20000条) - 支付记录

## 学习计划

### 学习资源
- **练习题目**: `exercises/` 目录包含10个阶段的练习
- **参考答案**: `solutions/` 目录包含部分练习的答案
- **学习顺序**: 按01-10的顺序依次学习

### 学习阶段概览
1. 基础查询 - SELECT、WHERE、ORDER BY、LIMIT
2. 多表连接 - JOIN、子查询
3. 聚合分组 - GROUP BY、HAVING、聚合函数
4. 高级查询 - 窗口函数、CTE、UNION
5. 索引优化 - EXPLAIN、索引设计
6. 事务处理 - ACID、隔离级别、锁
7. 性能优化 - 慢查询、分页优化、查询优化
8. 主从与集群 - 主从复制、读写分离、高可用
9. MySQL日志 - binlog、redo log、慢查询日志
10. 分库分表 - 垂直拆分、水平拆分、中间件

### 学习建议
```bash
# 1. 启动环境
docker-compose up -d

# 2. 连接数据库
docker exec -it mysql-study mysql -uroot -proot study_db --default-character-set=utf8mb4

# 3. 开始第一阶段练习
# 打开 exercises/01-基础查询.md

# 4. 完成后对照答案
# 查看 solutions/01-基础查询.md
```
