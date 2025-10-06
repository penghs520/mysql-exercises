# MySQL 学习项目

基于真实电商数据库的MySQL系统化学习项目

## 📚 项目简介

这是一个完整的MySQL学习环境，包含：
- **Docker化的MySQL 8.0环境**
- **10万+条电商业务数据**
- **10个阶段的系统化学习路径**
- **丰富的练习题和参考答案**

## 🚀 快速开始

### 1. 启动环境

```bash
# 启动MySQL容器（首次启动会自动初始化数据，需要1-2分钟）
docker-compose up -d

# 查看初始化进度
docker logs -f mysql-study
```

### 2. 连接数据库

```bash
# 方式1：使用docker exec
docker exec -it mysql-study mysql -uroot -proot study_db --default-character-set=utf8mb4

# 方式2：从主机连接
mysql -h 127.0.0.1 -P 3307 -uroot -proot study_db --default-character-set=utf8mb4
```

### 3. 验证数据

```sql
-- 查看所有表
SHOW TABLES;

-- 查看数据统计
SELECT
  (SELECT COUNT(*) FROM users) AS users,
  (SELECT COUNT(*) FROM products) AS products,
  (SELECT COUNT(*) FROM orders) AS orders,
  (SELECT COUNT(*) FROM order_items) AS order_items;
```

## 📖 学习路径

详细学习计划请查看 [LEARNING-PLAN.md](LEARNING-PLAN.md)

### 10个学习阶段

| 阶段 | 主题 | 预计时间 | 练习文件 |
|------|------|---------|---------|
| 1 | 基础查询 | 1天 | [exercises/01-基础查询.md](exercises/01-基础查询.md) |
| 2 | 多表连接 | 1-2天 | [exercises/02-多表连接.md](exercises/02-多表连接.md) |
| 3 | 聚合分组 | 1-2天 | [exercises/03-聚合分组.md](exercises/03-聚合分组.md) |
| 4 | 高级查询 | 2-3天 | [exercises/04-高级查询.md](exercises/04-高级查询.md) |
| 5 | 索引优化 | 2-3天 | [exercises/05-索引优化.md](exercises/05-索引优化.md) |
| 6 | 事务处理 | 2-3天 | [exercises/06-事务处理.md](exercises/06-事务处理.md) |
| 7 | 存储过程 | 2-3天 | [exercises/07-存储过程.md](exercises/07-存储过程.md) |
| 8 | 视图权限 | 1-2天 | [exercises/08-视图权限.md](exercises/08-视图权限.md) |
| 9 | 性能优化 | 1-2天 | [exercises/09-性能优化.md](exercises/09-性能优化.md) |
| 10 | 综合实战 | 5-7天 | [exercises/10-综合实战.md](exercises/10-综合实战.md) |

（每天2-3小时）

## 💾 数据库结构

### 核心业务表（10张表，116,585条数据）

```
用户相关:
├── users (1,000)              # 用户信息
└── user_addresses (3,000)     # 收货地址

商品相关:
├── categories (50)            # 商品分类
├── products (500)             # 商品信息
└── product_skus (1,000)       # 商品SKU

交易相关:
├── orders (20,000)            # 订单
├── order_items (50,000)       # 订单明细
└── payments (16,035)          # 支付记录

互动相关:
├── cart_items (5,000)         # 购物车
└── product_reviews (20,000)   # 商品评价
```

## 📁 项目结构

```
mysql-study/
├── README.md                   # 项目说明
├── CLAUDE.md                   # Claude Code配置
├── LEARNING-PLAN.md            # 详细学习计划
├── docker-compose.yml          # Docker配置
├── Dockerfile                  # MySQL镜像配置
├── init-scripts/               # 数据库初始化脚本
│   └── 01-ecommerce-schema.sql
├── exercises/                  # 练习题目
│   ├── 01-基础查询.md
│   ├── 02-多表连接.md
│   ├── 03-聚合分组.md
│   ├── 04-高级查询.md
│   ├── 05-索引优化.md
│   ├── 06-事务处理.md
│   ├── 07-存储过程.md
│   ├── 08-视图权限.md
│   ├── 09-性能优化.md
│   └── 10-综合实战.md
└── solutions/                  # 参考答案
    ├── README.md
    ├── 01-基础查询.md
    └── 02-多表连接.md
```

## 🎯 学习建议

1. **循序渐进**: 按照01-10的顺序学习，非重点章节可以暂时不学或简单了解即可，例如存储过程和函数、视图与权限两篇
2. **动手实践**: 每个练习都要自己编写SQL并执行
3. **先做后看**: 先独立完成练习，再查看参考答案
4. **理解原理**: 不要死记硬背，理解SQL的执行逻辑
5. **性能意识**: 养成用EXPLAIN分析的习惯
6. **记录总结**: 记录学习笔记和常见问题

## 🛠️ 常用命令

```bash
# 启动容器
docker-compose up -d

# 停止容器
docker-compose down

# 重启容器（保留数据）
docker-compose restart

# 重建容器（清空数据）
docker-compose down -v && docker-compose up -d

# 查看日志
docker logs mysql-study

# 备份数据库
docker exec mysql-study mysqldump -uroot -proot study_db > backup.sql

# 恢复数据库
docker exec -i mysql-study mysql -uroot -proot study_db < backup.sql
```

## 🔧 环境配置

- **MySQL版本**: 8.0
- **端口映射**: 主机3307 -> 容器3306
- **Root密码**: root
- **数据库名**: study_db
- **学习用户**: study_user / study123
- **字符集**: utf8mb4

## 📝 示例查询

```sql
-- 查看热销商品TOP10
SELECT
  p.name,
  SUM(oi.quantity) as total_sold,
  SUM(oi.total_amount) as revenue
FROM products p
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id
WHERE o.status = 3
GROUP BY p.id, p.name
ORDER BY total_sold DESC
LIMIT 10;

-- 用户消费排行
SELECT
  u.username,
  COUNT(o.id) as order_count,
  SUM(o.pay_amount) as total_spending
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 3
GROUP BY u.id, u.username
ORDER BY total_spending DESC
LIMIT 20;
```

## 🤝 贡献

欢迎提交Issue和Pull Request来完善这个学习项目！

## 📄 许可

本项目仅用于学习目的。

---

**开始你的MySQL学习之旅吧！** 🎉

