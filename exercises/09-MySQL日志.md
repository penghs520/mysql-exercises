# 09 - MySQL日志系统

## 学习目标
- 理解MySQL各种日志的作用和原理
- 掌握binlog、redo log、undo log的应用场景
- 学会通过日志排查问题和数据恢复
- 了解日志配置优化和日志管理

## 基础知识

### MySQL主要日志类型

1. **错误日志（Error Log）**：记录MySQL启动、运行、关闭过程中的错误信息
2. **慢查询日志（Slow Query Log）**：记录执行时间超过阈值的SQL
3. **通用查询日志（General Log）**：记录所有SQL语句（性能影响大）
4. **二进制日志（Binary Log）**：记录所有DDL和DML操作，用于复制和恢复
5. **中继日志（Relay Log）**：从库接收主库binlog的中转日志
6. **重做日志（Redo Log）**：InnoDB事务日志，保证持久性
7. **回滚日志（Undo Log）**：实现事务回滚和MVCC

## 练习题

### 一、错误日志（Error Log）

#### 1. 查看错误日志配置
```sql
-- 查看错误日志位置
SHOW VARIABLES LIKE 'log_error';

-- 查看错误日志级别（MySQL 8.0+）
SHOW VARIABLES LIKE 'log_error_verbosity';
```

**任务**：
1. 找到你的MySQL错误日志文件位置
2. 使用bash命令查看最近的错误信息

#### 2. 分析错误日志
假设错误日志中出现以下内容，请分析原因：

```
[ERROR] [MY-013183] [InnoDB] Assertion failure: row0mysql.cc:1234
[ERROR] [MY-012592] [InnoDB] Operating system error number 28 in a file operation
[Warning] [MY-010909] [Server] Found 1 prepared transactions!
```

**任务**：每个错误分别代表什么问题？如何解决？

### 二、慢查询日志（Slow Query Log）

#### 3. 启用慢查询日志
```sql
-- 查看慢查询配置
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 启用慢查询日志
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;  -- 2秒
SET GLOBAL log_queries_not_using_indexes = 'ON';  -- 记录未使用索引的查询

-- 查看慢查询统计
SHOW GLOBAL STATUS LIKE 'Slow_queries';
```

#### 4. 分析慢查询日志
查看慢查询日志文件，分析以下内容：

```sql
-- 执行一个慢查询
SELECT o.*, u.username, p.product_name
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.created_at >= '2024-01-01'
ORDER BY o.created_at DESC;
```

**任务**：
1. 使用bash命令查看慢查询日志
2. 找出执行时间最长的3条SQL
3. 使用mysqldumpslow工具分析慢查询日志

```bash
# mysqldumpslow分析示例
mysqldumpslow -s t -t 10 /path/to/slow.log  # 按时间排序，显示前10条
```

#### 5. 慢查询优化实战
针对study_db数据库，编写并优化以下慢查询：

```sql
-- 场景1：订单统计（可能很慢）
SELECT
    DATE(o.created_at) AS order_date,
    COUNT(*) AS order_count,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_amount
FROM orders o
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
GROUP BY DATE(o.created_at)
ORDER BY order_date DESC;

-- 场景2：用户购买行为分析（可能很慢）
SELECT
    u.id,
    u.username,
    COUNT(DISTINCT o.id) AS order_count,
    COUNT(DISTINCT oi.product_id) AS product_count,
    SUM(oi.quantity * oi.price) AS total_spent
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY u.id, u.username
HAVING order_count > 0
ORDER BY total_spent DESC
LIMIT 100;
```

**任务**：
1. 使用EXPLAIN分析这些SQL
2. 添加合适的索引优化查询
3. 验证优化后的执行时间

### 三、二进制日志（Binary Log）

#### 6. 配置binlog
```sql
-- 查看binlog配置
SHOW VARIABLES LIKE 'log_bin%';
SHOW VARIABLES LIKE 'binlog%';

-- 查看当前binlog文件
SHOW MASTER STATUS;

-- 查看所有binlog文件
SHOW BINARY LOGS;
```

**任务**：了解以下配置参数的作用
- binlog_format (STATEMENT/ROW/MIXED)
- binlog_row_image (FULL/MINIMAL/NOBLOB)
- max_binlog_size
- expire_logs_days / binlog_expire_logs_seconds
- sync_binlog

#### 7. 查看binlog内容
```sql
-- 查看binlog事件
SHOW BINLOG EVENTS IN 'binlog文件名' LIMIT 10;

-- 从特定位置查看
SHOW BINLOG EVENTS IN 'binlog文件名' FROM 位置 LIMIT 10;
```

**任务**：
1. 在study_db中执行一些DML操作
2. 查看binlog记录了哪些事件
3. 使用mysqlbinlog工具解析binlog

```bash
# 使用mysqlbinlog解析
mysqlbinlog --base64-output=decode-rows -v binlog文件名
```

#### 8. binlog恢复数据
**场景**：误删除了订单数据，需要通过binlog恢复

```sql
-- 1. 模拟误删除
DELETE FROM orders WHERE id BETWEEN 1000 AND 1010;

-- 2. 找到删除操作的binlog位置
SHOW BINLOG EVENTS IN 'binlog文件名' WHERE Info LIKE '%DELETE FROM orders%';

-- 3. 使用mysqlbinlog恢复数据（bash命令）
-- mysqlbinlog --start-position=起始位置 --stop-position=结束位置 binlog文件 | mysql -u用户 -p密码 数据库
```

**任务**：
1. 记录删除操作前的binlog位置
2. 执行删除操作
3. 通过binlog恢复删除的数据

#### 9. 基于时间点恢复（PITR）
**场景**：数据库在2024-01-15 14:30:00发生故障，需要恢复到故障前

```bash
# 1. 恢复全量备份（假设备份时间为2024-01-15 00:00:00）
mysql -u用户 -p密码 数据库 < backup_2024-01-15.sql

# 2. 恢复binlog（从备份时间到故障时间）
mysqlbinlog \
  --start-datetime="2024-01-15 00:00:00" \
  --stop-datetime="2024-01-15 14:29:59" \
  binlog.000001 binlog.000002 | mysql -u用户 -p密码
```

**任务**：设计一个基于时间点的恢复方案

### 四、重做日志（Redo Log）

#### 10. 理解Redo Log
```sql
-- 查看redo log配置
SHOW VARIABLES LIKE 'innodb_log%';

-- 重点关注的参数
-- innodb_log_file_size: 每个redo log文件大小
-- innodb_log_files_in_group: redo log文件数量
-- innodb_flush_log_at_trx_commit: 日志刷盘策略
```

**任务**：解释innodb_flush_log_at_trx_commit的三个值：
- 0：每秒写入并刷盘
- 1：每次事务提交时写入并刷盘（默认）
- 2：每次事务提交时写入，每秒刷盘

分析各自的性能和安全性差异。

#### 11. Redo Log与性能
测试不同innodb_flush_log_at_trx_commit值对性能的影响：

```sql
-- 准备测试表
CREATE TABLE test_redo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 测试插入性能
-- 分别在innodb_flush_log_at_trx_commit = 0, 1, 2下测试
DELIMITER $$
CREATE PROCEDURE batch_insert()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 10000 DO
        INSERT INTO test_redo(data) VALUES (UUID());
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- 测试执行时间
SET @start = NOW(6);
CALL batch_insert();
SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) / 1000 AS elapsed_ms;
```

### 五、回滚日志（Undo Log）

#### 12. 理解Undo Log
```sql
-- 查看undo log配置
SHOW VARIABLES LIKE 'innodb_undo%';

-- 查看当前活跃事务和undo使用情况
SELECT
    trx_id,
    trx_state,
    trx_started,
    trx_rows_locked,
    trx_rows_modified
FROM information_schema.innodb_trx;

-- 查看undo表空间
SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    FILE_SIZE / 1024 / 1024 AS size_mb
FROM information_schema.FILES
WHERE TABLESPACE_NAME LIKE '%undo%';
```

#### 13. Undo Log与MVCC
通过实验理解undo log在MVCC中的作用：

```sql
-- 会话1：开启事务并更新数据
START TRANSACTION;
UPDATE orders SET status = 'cancelled' WHERE id = 100;
SELECT sleep(30);  -- 保持事务打开

-- 会话2：查询同一数据
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT * FROM orders WHERE id = 100;  -- 应该看到旧值
```

**任务**：
1. 解释为什么会话2看到的是旧值
2. undo log在这个过程中起什么作用
3. 如果长时间不提交事务，undo log会有什么问题

### 六、通用查询日志（General Log）

#### 14. 启用通用日志（谨慎使用）
```sql
-- 查看通用日志配置
SHOW VARIABLES LIKE 'general_log%';

-- 临时启用（仅用于调试）
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/tmp/mysql_general.log';

-- 执行一些查询
SELECT * FROM users LIMIT 1;
UPDATE users SET last_login = NOW() WHERE id = 1;

-- 关闭通用日志
SET GLOBAL general_log = 'OFF';
```

**任务**：
1. 查看通用日志文件内容
2. 对比通用日志和慢查询日志的区别
3. 为什么不建议在生产环境开启通用日志

### 七、日志管理和优化

#### 15. binlog清理策略
```sql
-- 查看binlog文件
SHOW BINARY LOGS;

-- 手动清理指定binlog之前的文件
PURGE BINARY LOGS TO 'binlog.000010';

-- 按时间清理
PURGE BINARY LOGS BEFORE '2024-01-01 00:00:00';

-- 自动清理配置（MySQL 8.0+）
SET GLOBAL binlog_expire_logs_seconds = 604800;  -- 7天
```

**任务**：设计一个binlog清理策略，考虑：
1. 保留多久的binlog
2. 如何与备份策略配合
3. 从库同步是否完成

#### 16. 日志轮转和归档
```sql
-- 手动轮转binlog
FLUSH BINARY LOGS;

-- 轮转所有日志
FLUSH LOGS;
```

**任务**：编写一个bash脚本实现：
1. 每天凌晨轮转binlog
2. 将旧binlog压缩归档
3. 保留最近7天的binlog
4. 更早的binlog转移到备份存储

#### 17. 日志监控指标
设计日志相关的监控指标：

```sql
-- binlog生成速度
SHOW GLOBAL STATUS LIKE 'Binlog_cache%';

-- 慢查询数量
SHOW GLOBAL STATUS LIKE 'Slow_queries';

-- redo log写入
SHOW GLOBAL STATUS LIKE 'Innodb_log%';
```

**任务**：创建一个监控查询，获取以下指标
1. 过去1小时binlog增长量
2. 过去1小时慢查询数量
3. redo log刷盘次数

### 八、日志与故障排查

#### 18. 通过日志排查问题
**场景1：主从延迟**
```sql
-- 主库
SHOW MASTER STATUS;

-- 从库
SHOW SLAVE STATUS\G

-- 分析binlog大小和传输速度
-- 检查是否有大事务
```

**场景2：死锁分析**
```sql
-- 查看最近的死锁信息
SHOW ENGINE INNODB STATUS\G

-- 关注LATEST DETECTED DEADLOCK部分
```

**任务**：
1. 从死锁日志中分析死锁原因
2. 如何通过日志避免死锁

#### 19. 日志审计
使用binlog实现SQL审计：

```sql
-- 查询某个时间段内的所有DDL操作
-- 使用mysqlbinlog
```

```bash
mysqlbinlog \
  --start-datetime="2024-01-01 00:00:00" \
  --stop-datetime="2024-01-31 23:59:59" \
  --database=study_db \
  binlog.* | grep -E "CREATE|ALTER|DROP|TRUNCATE"
```

**任务**：
1. 找出最近7天对users表的所有DELETE操作
2. 统计某个用户执行的所有SQL（需要启用general log）

### 九、日志性能优化

#### 20. 优化binlog性能
```sql
-- 调整binlog相关参数
SET GLOBAL binlog_cache_size = 4194304;  -- 4MB
SET GLOBAL max_binlog_cache_size = 18446744073709547520;
SET GLOBAL sync_binlog = 1;  -- 1:最安全但慢, 0或N:快但可能丢数据

-- 选择合适的binlog格式
SET GLOBAL binlog_format = 'ROW';  -- 或 STATEMENT/MIXED
SET GLOBAL binlog_row_image = 'MINIMAL';  -- 减少binlog大小
```

**任务**：
1. 对比不同binlog_format对写入性能的影响
2. 分析binlog_row_image的三种模式（FULL/MINIMAL/NOBLOB）
3. sync_binlog的不同值对性能和安全性的影响

## 综合实战

### 21. 完整的备份恢复演练

**任务**：模拟一次完整的备份和恢复流程

1. 全量备份
```bash
mysqldump -u用户 -p密码 \
  --single-transaction \
  --master-data=2 \
  --flush-logs \
  study_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

2. 记录binlog位置
3. 继续业务操作（插入、更新数据）
4. 模拟故障（删除部分数据）
5. 通过全量备份+binlog恢复到故障前

### 22. 日志告警系统设计

设计一个日志监控和告警系统：

| 日志类型 | 监控项 | 告警阈值 | 处理方案 |
|---------|--------|----------|----------|
| Error Log | 错误数量 | >10/小时 | 人工介入检查 |
| Slow Log | 慢查询数量 | >100/小时 | SQL优化 |
| Binlog | 磁盘使用率 | >80% | 清理旧日志 |
| Redo Log | 等待刷盘次数 | 持续增长 | 调整innodb参数 |

## 拓展思考

1. **日志与数据一致性**：两阶段提交（2PC）中binlog和redo log如何协作？

2. **日志压缩**：MySQL 8.0的binlog事务压缩功能，如何使用？

3. **日志加密**：如何对binlog进行加密，保护敏感数据？

4. **分布式追踪**：如何结合binlog实现分布式系统的数据变更追踪？

5. **日志解析工具**：除了mysqlbinlog，还有哪些工具可以解析MySQL日志？

## 练习提示

- 日志操作对性能有影响，建议在测试环境练习
- binlog是数据恢复的关键，务必理解其原理和使用方法
- 慢查询日志是SQL优化的重要依据，要定期分析
- 不同场景选择不同的日志刷盘策略，平衡性能和安全性

## 参考资料

- MySQL官方文档：MySQL Server Logs
- 《MySQL技术内幕：InnoDB存储引擎》第7章：事务
- Percona博客：binlog最佳实践
- mysqlbinlog工具文档
