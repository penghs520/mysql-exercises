# 09 - MySQL日志系统 - 参考答案

## 一、错误日志（Error Log）

### 1. 查看错误日志配置

```sql
-- 查看错误日志位置
SHOW VARIABLES LIKE 'log_error';

-- 典型输出
-- log_error = /var/log/mysql/error.log
-- 或 /var/lib/mysql/mysql-error.log

-- 查看错误日志级别（MySQL 8.0+）
SHOW VARIABLES LIKE 'log_error_verbosity';

-- 级别说明：
-- 1 = 仅错误（Errors）
-- 2 = 错误和警告（Errors and warnings）默认
-- 3 = 错误、警告和通知（Errors, warnings, and notes）
```

**查看错误日志文件**：
```bash
# 方法1：直接查看
cat /var/log/mysql/error.log

# 方法2：查看最近50行
tail -n 50 /var/log/mysql/error.log

# 方法3：实时查看（追踪新日志）
tail -f /var/log/mysql/error.log

# 方法4：查找包含"ERROR"的行
grep -i "ERROR" /var/log/mysql/error.log | tail -20

# 方法5：查看今天的错误
grep "$(date +%Y-%m-%d)" /var/log/mysql/error.log | grep -i "error"
```

### 2. 分析错误日志

**错误1：Assertion failure**
```
[ERROR] [MY-013183] [InnoDB] Assertion failure: row0mysql.cc:1234
```

**原因分析**：
- InnoDB存储引擎内部断言失败
- 通常是软件bug或数据页损坏
- row0mysql.cc:1234 表示源代码位置

**解决方法**：
```bash
# 1. 记录完整错误信息和堆栈
grep -A 20 "Assertion failure" /var/log/mysql/error.log

# 2. 检查InnoDB数据文件完整性
# 强制恢复模式启动（仅用于导出数据）
# my.cnf添加：
# [mysqld]
# innodb_force_recovery = 1  # 级别1-6，从低到高

# 3. 导出数据
mysqldump --all-databases > backup.sql

# 4. 重建实例
# 删除ibdata、ib_logfile等，重新初始化

# 5. 导入数据
mysql < backup.sql

# 6. 升级MySQL版本（可能是已知bug）
```

**错误2：Operating system error number 28**
```
[ERROR] [MY-012592] [InnoDB] Operating system error number 28 in a file operation
```

**原因分析**：
- 错误码28 = ENOSPC（No space left on device）
- 磁盘空间不足

**解决方法**：
```bash
# 1. 检查磁盘空间
df -h

# 2. 查找大文件
du -sh /var/lib/mysql/*
du -sh /var/log/mysql/*

# 3. 清理binlog
mysql -e "PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL 7 DAY);"

# 4. 清理relay log（从库）
mysql -e "RESET SLAVE; START SLAVE;"

# 5. 清理慢查询日志
> /var/log/mysql/slow.log

# 6. 扩容磁盘（根本解决）
```

**错误3：Found 1 prepared transactions**
```
[Warning] [MY-010909] [Server] Found 1 prepared transactions!
```

**原因分析**：
- XA事务（分布式事务）未完成
- 可能是应用异常退出或MySQL崩溃

**解决方法**：
```sql
-- 查看未完成的XA事务
XA RECOVER;

-- 输出示例：
-- formatID, gtrid_length, bqual_length, data
-- 1, 36, 0, 'xid-12345'

-- 提交XA事务
XA COMMIT 'xid-12345';

-- 或回滚
XA ROLLBACK 'xid-12345';
```

## 二、慢查询日志（Slow Query Log）

### 3. 启用慢查询日志

```sql
-- 查看慢查询配置
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'log_queries_not_using_indexes';

-- 典型输出：
-- slow_query_log = OFF
-- slow_query_log_file = /var/lib/mysql/slow.log
-- long_query_time = 10.000000

-- 启用慢查询日志
SET GLOBAL slow_query_log = 'ON';

-- 设置慢查询阈值为2秒
SET GLOBAL long_query_time = 2;

-- 记录未使用索引的查询
SET GLOBAL log_queries_not_using_indexes = 'ON';

-- 限制未使用索引的查询日志频率（每分钟最多10条）
SET GLOBAL log_throttle_queries_not_using_indexes = 10;

-- 持久化配置（my.cnf）
-- [mysqld]
-- slow_query_log = 1
-- slow_query_log_file = /var/log/mysql/slow.log
-- long_query_time = 2
-- log_queries_not_using_indexes = 1

-- 查看慢查询统计
SHOW GLOBAL STATUS LIKE 'Slow_queries';
-- Slow_queries = 245（累计慢查询数）
```

### 4. 分析慢查询日志

**执行测试慢查询**：
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

**查看慢查询日志**：
```bash
# 查看慢查询日志文件
tail -100 /var/log/mysql/slow.log

# 慢查询日志格式示例：
# Time: 2024-01-15T10:30:45.123456Z
# User@Host: study_user[study_user] @ localhost []
# Query_time: 3.456789  Lock_time: 0.000123  Rows_sent: 1500  Rows_examined: 150000
# SET timestamp=1705318245;
# SELECT o.*, u.username ...

# 字段含义：
# Query_time: 查询执行时间（秒）
# Lock_time: 等待锁的时间（秒）
# Rows_sent: 返回的行数
# Rows_examined: 扫描的行数
```

**找出执行时间最长的3条SQL**：
```bash
# 方法1：手工查找
grep "Query_time" /var/log/mysql/slow.log | sort -k3 -rn | head -3

# 方法2：使用mysqldumpslow
mysqldumpslow -s t -t 3 /var/log/mysql/slow.log

# mysqldumpslow参数：
# -s: 排序方式
#   t = 查询时间（默认）
#   l = 锁定时间
#   r = 返回记录数
#   c = 查询次数
# -t: 返回前N条
# -g: 正则匹配

# 输出示例：
# Count: 15  Time=5.23s (78s)  Lock=0.00s (0s)  Rows=1000.0 (15000), study_user[study_user]@localhost
#   SELECT o.*, u.username FROM orders o JOIN users u ON o.user_id = u.id WHERE o.created_at >= 'S'
```

**其他有用的分析**：
```bash
# 按查询次数排序
mysqldumpslow -s c -t 10 /var/log/mysql/slow.log

# 查看包含特定表的慢查询
mysqldumpslow -g "orders" /var/log/mysql/slow.log

# 按平均查询时间排序
mysqldumpslow -s at -t 10 /var/log/mysql/slow.log

# 使用pt-query-digest（更强大）
pt-query-digest /var/log/mysql/slow.log > slow_report.txt
```

### 5. 慢查询优化实战

**场景1：订单统计优化**

**原始慢查询**：
```sql
SELECT
    DATE(o.created_at) AS order_date,
    COUNT(*) AS order_count,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_amount
FROM orders o
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
GROUP BY DATE(o.created_at)
ORDER BY order_date DESC;
```

**分析执行计划**：
```sql
EXPLAIN SELECT
    DATE(o.created_at) AS order_date,
    COUNT(*) AS order_count,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_amount
FROM orders o
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
GROUP BY DATE(o.created_at)
ORDER BY order_date DESC;

-- 问题：
-- 1. DATE(o.created_at) 函数导致索引失效
-- 2. 可能全表扫描
-- 3. 文件排序（filesort）
```

**优化方案**：
```sql
-- 创建索引
CREATE INDEX idx_created_at ON orders(created_at);

-- 优化SQL（避免在索引列使用函数）
SELECT
    DATE(o.created_at) AS order_date,
    COUNT(*) AS order_count,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_amount
FROM orders o
WHERE o.created_at >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 1 YEAR), '%Y-%m-%d 00:00:00')
  AND o.created_at < DATE_FORMAT(NOW(), '%Y-%m-%d 23:59:59')
GROUP BY DATE(o.created_at)
ORDER BY order_date DESC;

-- 或使用生成列（MySQL 5.7+）
ALTER TABLE orders ADD COLUMN created_date DATE GENERATED ALWAYS AS (DATE(created_at)) STORED;
CREATE INDEX idx_created_date ON orders(created_date);

-- 使用生成列查询
SELECT
    created_date AS order_date,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_amount
FROM orders
WHERE created_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY created_date
ORDER BY order_date DESC;
```

**场景2：用户购买行为分析优化**

**原始慢查询**：
```sql
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

**分析**：
```sql
EXPLAIN SELECT ...;

-- 问题：
-- 1. 三表连接，数据量大
-- 2. LEFT JOIN后用HAVING过滤，效率低
-- 3. 需要扫描大量数据
```

**优化方案**：
```sql
-- 方案1：改为INNER JOIN（如果只需要有订单的用户）
SELECT
    u.id,
    u.username,
    COUNT(DISTINCT o.id) AS order_count,
    COUNT(DISTINCT oi.product_id) AS product_count,
    SUM(oi.quantity * oi.price) AS total_spent
FROM users u
INNER JOIN orders o ON u.id = o.user_id  -- 改为INNER JOIN
INNER JOIN order_items oi ON o.id = oi.order_id
GROUP BY u.id, u.username
ORDER BY total_spent DESC
LIMIT 100;

-- 方案2：使用子查询预过滤
SELECT
    u.id,
    u.username,
    t.order_count,
    t.product_count,
    t.total_spent
FROM users u
INNER JOIN (
    SELECT
        o.user_id,
        COUNT(DISTINCT o.id) AS order_count,
        COUNT(DISTINCT oi.product_id) AS product_count,
        SUM(oi.quantity * oi.price) AS total_spent
    FROM orders o
    INNER JOIN order_items oi ON o.id = oi.order_id
    GROUP BY o.user_id
) t ON u.id = t.user_id
ORDER BY t.total_spent DESC
LIMIT 100;

-- 方案3：创建物化视图或汇总表
CREATE TABLE user_purchase_summary (
    user_id BIGINT PRIMARY KEY,
    order_count INT,
    product_count INT,
    total_spent DECIMAL(15,2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_total_spent (total_spent)
) ENGINE=InnoDB;

-- 定期更新汇总表（通过定时任务或触发器）
REPLACE INTO user_purchase_summary
SELECT
    o.user_id,
    COUNT(DISTINCT o.id) AS order_count,
    COUNT(DISTINCT oi.product_id) AS product_count,
    SUM(oi.quantity * oi.price) AS total_spent,
    NOW()
FROM orders o
INNER JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.user_id;

-- 查询汇总表（速度快）
SELECT u.id, u.username, ups.*
FROM user_purchase_summary ups
INNER JOIN users u ON ups.user_id = u.id
ORDER BY ups.total_spent DESC
LIMIT 100;

-- 必要的索引
CREATE INDEX idx_user_id ON orders(user_id);
CREATE INDEX idx_order_id ON order_items(order_id);
CREATE INDEX idx_product_id ON order_items(product_id);
```

**验证优化效果**：
```sql
-- 优化前
SET profiling = 1;
SELECT ...原始SQL;
SHOW PROFILES;

-- 优化后
SELECT ...优化后SQL;
SHOW PROFILES;

-- 对比查询时间
```

## 三、二进制日志（Binary Log）

### 6. 配置binlog

```sql
-- 查看binlog配置
SHOW VARIABLES LIKE 'log_bin%';
SHOW VARIABLES LIKE 'binlog%';

-- 关键配置参数及含义：
```

**my.cnf配置示例**：
```ini
[mysqld]
# 开启binlog
log-bin = /var/lib/mysql/mysql-bin
server-id = 1

# binlog格式
binlog-format = ROW
# STATEMENT: 记录SQL语句，日志小但可能主从不一致
# ROW: 记录每行的变化，日志大但一致性好（推荐）
# MIXED: 混合模式，一般用STATEMENT，特殊情况用ROW

# binlog行镜像（ROW格式下）
binlog-row-image = FULL
# FULL: 记录所有列（默认）
# MINIMAL: 只记录变化的列和where条件涉及的列（节省空间）
# NOBLOB: 不记录BLOB/TEXT列（除非必要）

# 单个binlog文件大小
max-binlog-size = 1G

# binlog过期时间（MySQL 8.0+）
binlog-expire-logs-seconds = 604800  # 7天

# 或（MySQL 5.7）
expire-logs-days = 7

# binlog缓存大小
binlog-cache-size = 4M  # 单个事务binlog缓存
max-binlog-cache-size = 2G  # 最大缓存

# binlog刷盘策略
sync-binlog = 1
# 0: 由操作系统决定何时刷盘（快但不安全）
# 1: 每次事务提交都刷盘（安全但慢，推荐）
# N: 每N个事务刷盘一次（平衡性能和安全）

# binlog组提交（提升sync_binlog=1的性能）
binlog-group-commit-sync-delay = 0  # 延迟微秒数
binlog-group-commit-sync-no-delay-count = 0  # 累积事务数

# 指定binlog的数据库（可选）
# binlog-do-db = study_db

# 忽略binlog的数据库（可选）
# binlog-ignore-db = test
```

**查看当前binlog文件**：
```sql
SHOW MASTER STATUS;

-- 输出示例：
-- +------------------+----------+--------------+------------------+-------------------+
-- | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
-- +------------------+----------+--------------+------------------+-------------------+
-- | mysql-bin.000003 |     1234 |              |                  |                   |
-- +------------------+----------+--------------+------------------+-------------------+

SHOW BINARY LOGS;

-- 输出示例：
-- +------------------+-----------+-----------+
-- | Log_name         | File_size | Encrypted |
-- +------------------+-----------+-----------+
-- | mysql-bin.000001 | 177       | No        |
-- | mysql-bin.000002 | 15234567  | No        |
-- | mysql-bin.000003 | 1234      | No        |
-- +------------------+-----------+-----------+
```

### 7. 查看binlog内容

```sql
-- 查看binlog事件（前10条）
SHOW BINLOG EVENTS IN 'mysql-bin.000003' LIMIT 10;

-- 输出示例：
-- +------------------+-----+----------------+-----------+-------------+---------------------------------------+
-- | Log_name         | Pos | Event_type     | Server_id | End_log_pos | Info                                  |
-- +------------------+-----+----------------+-----------+-------------+---------------------------------------+
-- | mysql-bin.000003 |   4 | Format_desc    |         1 |         125 | Server ver: 8.0.32, Binlog ver: 4     |
-- | mysql-bin.000003 | 125 | Previous_gtids |         1 |         156 |                                       |
-- | mysql-bin.000003 | 156 | Gtid           |         1 |         235 | SET @@SESSION.GTID_NEXT= 'xxx:1'      |
-- | mysql-bin.000003 | 235 | Query          |         1 |         316 | BEGIN                                 |
-- | mysql-bin.000003 | 316 | Table_map      |         1 |         378 | table_id: 85 (study_db.orders)        |
-- | mysql-bin.000003 | 378 | Write_rows     |         1 |         445 | table_id: 85 flags: STMT_END_F        |
-- | mysql-bin.000003 | 445 | Xid            |         1 |         476 | COMMIT /* xid=123 */                  |
-- +------------------+-----+----------------+-----------+-------------+---------------------------------------+

-- 从特定位置查看
SHOW BINLOG EVENTS IN 'mysql-bin.000003' FROM 156 LIMIT 10;
```

**执行测试DML操作**：
```sql
-- 插入数据
INSERT INTO users (username, email, phone)
VALUES ('testuser', 'test@example.com', '13800138000');

-- 更新数据
UPDATE users SET phone = '13900139000' WHERE username = 'testuser';

-- 删除数据
DELETE FROM users WHERE username = 'testuser';

-- 查看刚才操作的binlog
SHOW BINLOG EVENTS IN 'mysql-bin.000003' FROM 1234 LIMIT 20;
```

**使用mysqlbinlog解析**：
```bash
# 基本解析（ROW格式需要-v参数才能看到具体数据）
mysqlbinlog /var/lib/mysql/mysql-bin.000003

# ROW格式解析，显示实际数据
mysqlbinlog --base64-output=decode-rows -v /var/lib/mysql/mysql-bin.000003

# 只看特定数据库
mysqlbinlog --database=study_db mysql-bin.000003

# 按位置范围解析
mysqlbinlog --start-position=156 --stop-position=476 mysql-bin.000003

# 按时间范围解析
mysqlbinlog \
  --start-datetime="2024-01-15 10:00:00" \
  --stop-datetime="2024-01-15 11:00:00" \
  mysql-bin.000003

# 输出示例（ROW格式 + -v）：
### INSERT INTO `study_db`.`users`
### SET
###   @1=1001 /* INT meta=0 nullable=0 is_null=0 */
###   @2='testuser' /* VARSTRING(200) meta=200 nullable=0 is_null=0 */
###   @3='test@example.com' /* VARSTRING(200) meta=200 nullable=0 is_null=0 */
###   @4='13800138000' /* VARSTRING(40) meta=40 nullable=1 is_null=0 */
```

### 8. binlog恢复数据

**完整恢复流程**：

**步骤1：模拟误删除**
```sql
-- 记录当前binlog位置
SHOW MASTER STATUS;
-- 假设：mysql-bin.000003, Position: 5000

-- 执行删除操作
DELETE FROM orders WHERE id BETWEEN 1000 AND 1010;

-- 再次查看binlog位置
SHOW MASTER STATUS;
-- 假设：mysql-bin.000003, Position: 6500
```

**步骤2：找到删除操作的binlog位置**
```bash
# 方法1：通过时间范围查找
mysqlbinlog --start-position=5000 --stop-position=6500 \
  --base64-output=decode-rows -v \
  /var/lib/mysql/mysql-bin.000003 | grep -i "DELETE FROM orders"

# 方法2：通过SQL查找binlog事件
mysql -e "SHOW BINLOG EVENTS IN 'mysql-bin.000003' FROM 5000 LIMIT 100" | grep -i delete
```

```sql
-- 假设找到：
-- DELETE操作开始位置：5234
-- DELETE操作结束位置（COMMIT）：5678
```

**步骤3：提取删除前的数据**

方案A：从删除前的binlog恢复
```bash
# 1. 提取删除操作之前的binlog（5000-5234之间如果有INSERT）
mysqlbinlog --start-position=5000 --stop-position=5234 \
  /var/lib/mysql/mysql-bin.000003 > before_delete.sql

# 2. 查看内容确认
cat before_delete.sql

# 3. 如果这段binlog没有有用的INSERT，需要从备份恢复
```

方案B：从备份+binlog恢复（推荐）
```bash
# 1. 恢复昨天的全量备份
mysql study_db < backup_yesterday.sql

# 2. 应用备份后到删除前的binlog
mysqlbinlog --start-position=备份时的位置 \
  --stop-position=5234 \  # 删除操作之前
  /var/lib/mysql/mysql-bin.000002 \
  /var/lib/mysql/mysql-bin.000003 | mysql study_db

# 3. 跳过删除操作，继续应用之后的binlog
mysqlbinlog --start-position=5678 \  # 删除操作之后
  /var/lib/mysql/mysql-bin.000003 | mysql study_db
```

方案C：从延迟从库恢复
```bash
# 如果有延迟从库，且还未执行删除操作
# 在延迟从库导出数据
mysqldump -h延迟从库IP -uroot -p \
  --single-transaction \
  study_db orders --where="id BETWEEN 1000 AND 1010" > recover.sql

# 恢复到主库
mysql -hMASTER_IP -uroot -p study_db < recover.sql
```

### 9. 基于时间点恢复（PITR）

**场景**：数据库在2024-01-15 14:30:00发生故障，需要恢复到故障前

**前提条件**：
- 有最近的全量备份（如：2024-01-15 00:00:00）
- 有备份后到故障前的完整binlog

**恢复步骤**：

```bash
# 步骤1：恢复全量备份
echo "开始恢复全量备份..."
mysql -uroot -p study_db < backup_2024-01-15_00-00-00.sql

# 步骤2：确定binlog范围
# 从备份文件中找到备份时的binlog位置
grep "CHANGE MASTER" backup_2024-01-15_00-00-00.sql
# 或
head -50 backup_2024-01-15_00-00-00.sql | grep "MASTER_LOG_POS"

# 假设输出：
# -- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000010', MASTER_LOG_POS=154;

# 步骤3：应用binlog（从备份时间到故障前）
echo "应用binlog..."
mysqlbinlog \
  --start-datetime="2024-01-15 00:00:00" \
  --stop-datetime="2024-01-15 14:29:59" \
  /var/lib/mysql/mysql-bin.000010 \
  /var/lib/mysql/mysql-bin.000011 \
  /var/lib/mysql/mysql-bin.000012 | mysql -uroot -p study_db

# 或使用位置恢复（更精确）
mysqlbinlog \
  --start-position=154 \
  --stop-position=故障前的位置 \
  mysql-bin.000010 mysql-bin.000011 | mysql -uroot -p study_db

# 步骤4：验证数据完整性
mysql -uroot -p study_db -e "SELECT COUNT(*) FROM orders;"
mysql -uroot -p study_db -e "SELECT MAX(created_at) FROM orders;"

# 步骤5：跳过故障操作（如果是误操作导致）
# 假设故障是因为误执行了DROP TABLE
# 从binlog中找到DROP TABLE的位置：5678-5890
# 应用之后的正常操作
mysqlbinlog --start-position=5890 mysql-bin.000012 | mysql -uroot -p study_db

echo "恢复完成！"
```

**PITR脚本示例**：
```bash
#!/bin/bash
# pitr_restore.sh - 基于时间点恢复脚本

BACKUP_FILE=$1
STOP_DATETIME=$2
MYSQL_USER="root"
MYSQL_PASS="password"
DATABASE="study_db"
BINLOG_DIR="/var/lib/mysql"

if [ -z "$BACKUP_FILE" ] || [ -z "$STOP_DATETIME" ]; then
    echo "用法: $0 <备份文件> <恢复到的时间点>"
    echo "示例: $0 backup.sql '2024-01-15 14:29:59'"
    exit 1
fi

echo "========== 开始PITR恢复 =========="
echo "备份文件: $BACKUP_FILE"
echo "恢复到: $STOP_DATETIME"

# 1. 恢复全量备份
echo "[1/4] 恢复全量备份..."
mysql -u$MYSQL_USER -p$MYSQL_PASS $DATABASE < $BACKUP_FILE
if [ $? -ne 0 ]; then
    echo "错误：备份恢复失败"
    exit 1
fi

# 2. 提取备份时的binlog位置
echo "[2/4] 提取binlog位置..."
BINLOG_FILE=$(grep "CHANGE MASTER TO MASTER_LOG_FILE" $BACKUP_FILE | sed "s/.*MASTER_LOG_FILE='\([^']*\)'.*/\1/")
BINLOG_POS=$(grep "CHANGE MASTER TO MASTER_LOG_FILE" $BACKUP_FILE | sed "s/.*MASTER_LOG_POS=\([0-9]*\).*/\1/")

echo "起始binlog: $BINLOG_FILE, Position: $BINLOG_POS"

# 3. 列出需要应用的binlog文件
echo "[3/4] 查找binlog文件..."
BINLOG_FILES=$(ls -1 $BINLOG_DIR/mysql-bin.* | \
    awk -F'.' -v start="${BINLOG_FILE##*.}" '$NF >= start' | \
    tr '\n' ' ')

echo "binlog文件: $BINLOG_FILES"

# 4. 应用binlog
echo "[4/4] 应用binlog到 $STOP_DATETIME..."
mysqlbinlog \
    --start-position=$BINLOG_POS \
    --stop-datetime="$STOP_DATETIME" \
    --database=$DATABASE \
    $BINLOG_FILES | mysql -u$MYSQL_USER -p$MYSQL_PASS $DATABASE

if [ $? -eq 0 ]; then
    echo "========== 恢复成功！ =========="
else
    echo "错误：binlog应用失败"
    exit 1
fi
```

## 四、重做日志（Redo Log）

### 10. 理解Redo Log

```sql
-- 查看redo log配置
SHOW VARIABLES LIKE 'innodb_log%';

-- 关键配置及含义：
```

**配置参数详解**：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `innodb_log_file_size` | 48MB | 每个redo log文件大小 |
| `innodb_log_files_in_group` | 2 | redo log文件数量（循环使用） |
| `innodb_log_buffer_size` | 16MB | redo log缓冲区大小 |
| `innodb_flush_log_at_trx_commit` | 1 | 日志刷盘策略（最重要） |
| `innodb_log_group_home_dir` | ./ | redo log文件目录 |

**innodb_flush_log_at_trx_commit详解**：

```sql
-- 查看当前值
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';

-- 三种模式对比：
```

| 值 | 行为 | 性能 | 安全性 | 数据丢失风险 |
|----|------|------|--------|--------------|
| **0** | 每秒写入并刷盘一次 | 最高 | 最低 | 可能丢失1秒数据 |
| **1** | 每次事务提交写入并刷盘 | 最低 | 最高 | 不丢失（推荐） |
| **2** | 每次事务提交写入，每秒刷盘 | 中等 | 中等 | 可能丢失1秒数据 |

**详细说明**：

**模式0**：
```
事务提交 -> redo log buffer（内存）
         -> 每秒一次 -> OS cache -> 刷盘

风险：MySQL崩溃或服务器断电，丢失约1秒的事务
适用：对性能要求极高，可容忍少量数据丢失的场景（如日志、临时数据）
```

**模式1（默认，推荐）**：
```
事务提交 -> redo log buffer -> OS cache -> 立即刷盘

风险：几乎无数据丢失风险（除非磁盘损坏）
适用：生产环境，金融、电商等对数据一致性要求高的场景
```

**模式2**：
```
事务提交 -> redo log buffer -> OS cache
         -> 每秒一次 -> 刷盘

风险：MySQL崩溃不丢数据，但服务器断电可能丢失约1秒事务
适用：可容忍服务器故障时丢失少量数据的场景
```

**配置建议**：
```ini
# my.cnf
[mysqld]
# 生产环境（安全优先）
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1

# 性能优化环境（可容忍少量数据丢失）
innodb_flush_log_at_trx_commit = 2
sync_binlog = 10

# 测试环境（性能优先）
innodb_flush_log_at_trx_commit = 0
sync_binlog = 0
```

### 11. Redo Log与性能

**测试准备**：
```sql
-- 创建测试表
CREATE TABLE test_redo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 创建存储过程
DELIMITER $$
CREATE PROCEDURE batch_insert(IN insert_count INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    START TRANSACTION;
    WHILE i < insert_count DO
        INSERT INTO test_redo(data) VALUES (UUID());
        SET i = i + 1;
    END WHILE;
    COMMIT;
END$$
DELIMITER ;
```

**性能测试**：

**测试1：innodb_flush_log_at_trx_commit = 0**
```sql
SET GLOBAL innodb_flush_log_at_trx_commit = 0;

-- 清空表
TRUNCATE TABLE test_redo;

-- 测试插入10000条
SET @start = NOW(6);
CALL batch_insert(10000);
SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) / 1000 AS elapsed_ms;

-- 预期结果：约1000-2000ms
```

**测试2：innodb_flush_log_at_trx_commit = 1**
```sql
SET GLOBAL innodb_flush_log_at_trx_commit = 1;

TRUNCATE TABLE test_redo;

SET @start = NOW(6);
CALL batch_insert(10000);
SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) / 1000 AS elapsed_ms;

-- 预期结果：约5000-10000ms（显著变慢）
```

**测试3：innodb_flush_log_at_trx_commit = 2**
```sql
SET GLOBAL innodb_flush_log_at_trx_commit = 2;

TRUNCATE TABLE test_redo;

SET @start = NOW(6);
CALL batch_insert(10000);
SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) / 1000 AS elapsed_ms;

-- 预期结果：约2000-4000ms（介于0和1之间）
```

**性能对比总结**：
```
假设测试结果：
模式0: 1500ms（基准）
模式1: 8000ms（约5.3倍变慢）
模式2: 3000ms（约2倍变慢）

结论：
- 模式1最安全但性能最差
- 模式0性能最好但风险最高
- 模式2是性能和安全的折中
```

**优化建议**：
```sql
-- 1. 使用批量提交减少刷盘次数
START TRANSACTION;
INSERT INTO test_redo(data) VALUES ('a');
INSERT INTO test_redo(data) VALUES ('b');
INSERT INTO test_redo(data) VALUES ('c');
COMMIT;  -- 一次刷盘

-- 而不是：
INSERT INTO test_redo(data) VALUES ('a');  -- 刷盘
INSERT INTO test_redo(data) VALUES ('b');  -- 刷盘
INSERT INTO test_redo(data) VALUES ('c');  -- 刷盘

-- 2. 增大redo log buffer
SET GLOBAL innodb_log_buffer_size = 32 * 1024 * 1024;  -- 32MB

-- 3. 使用SSD磁盘（大幅提升刷盘性能）

-- 4. 组提交优化（MySQL 5.6+自动开启）
-- 多个事务的redo log一起刷盘
```

## 五、回滚日志（Undo Log）

### 12. 理解Undo Log

```sql
-- 查看undo log配置
SHOW VARIABLES LIKE 'innodb_undo%';

-- 关键配置：
-- innodb_undo_directory: undo log目录
-- innodb_undo_tablespaces: undo表空间数量（MySQL 8.0默认2）
-- innodb_undo_log_truncate: 是否自动truncate undo表空间
-- innodb_max_undo_log_size: undo表空间最大大小

-- 查看当前活跃事务和undo使用情况
SELECT
    trx_id AS 事务ID,
    trx_state AS 事务状态,
    trx_started AS 开始时间,
    TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS 运行秒数,
    trx_rows_locked AS 锁定行数,
    trx_rows_modified AS 修改行数,
    trx_tables_locked AS 锁定表数
FROM information_schema.innodb_trx
ORDER BY trx_started;

-- 查看undo表空间
SELECT
    TABLESPACE_NAME AS 表空间名,
    FILE_NAME AS 文件路径,
    FILE_SIZE / 1024 / 1024 AS size_mb,
    AUTOEXTEND_SIZE / 1024 / 1024 AS 自动扩展MB
FROM information_schema.FILES
WHERE TABLESPACE_NAME LIKE '%undo%'
ORDER BY TABLESPACE_NAME;
```

**输出示例**：
```
表空间名     文件路径                  size_mb  自动扩展MB
innodb_undo_001  /var/lib/mysql/undo_001  100.00   64.00
innodb_undo_002  /var/lib/mysql/undo_002  100.00   64.00
```

### 13. Undo Log与MVCC

**实验：验证undo log在MVCC中的作用**

**会话1：开启事务并更新**
```sql
-- 会话1
USE study_db;

-- 查看当前订单状态
SELECT id, user_id, status, total_amount
FROM orders WHERE id = 100;

-- 假设结果：
-- id=100, user_id=10, status='paid', total_amount=500.00

-- 开启事务并更新
START TRANSACTION;

UPDATE orders
SET status = 'cancelled', total_amount = 0
WHERE id = 100;

-- 查询确认更新
SELECT id, user_id, status, total_amount
FROM orders WHERE id = 100;
-- 结果：id=100, status='cancelled', total_amount=0

-- 保持事务打开30秒（不要COMMIT）
SELECT SLEEP(30);
```

**会话2：查询同一数据（REPEATABLE READ隔离级别）**
```sql
-- 会话2（新开一个终端）
USE study_db;

-- 设置隔离级别
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 开启事务
START TRANSACTION;

-- 查询相同的订单
SELECT id, user_id, status, total_amount
FROM orders WHERE id = 100;

-- 结果：id=100, status='paid', total_amount=500.00
-- 看到的是旧值！因为会话1还未提交

-- 等待会话1提交后再查询
-- （在会话1执行COMMIT后）
SELECT id, user_id, status, total_amount
FROM orders WHERE id = 100;

-- 结果：仍然是 status='paid', total_amount=500.00
-- 因为REPEATABLE READ保证可重复读，读取的是事务开始时的快照

COMMIT;

-- 事务提交后再查询
SELECT id, user_id, status, total_amount
FROM orders WHERE id = 100;

-- 现在看到最新值：status='cancelled', total_amount=0
```

**原理解释**：

```
时间线：
T1: 会话2开启事务，建立read view
T2: 会话1更新数据，写入undo log（保存旧值）
T3: 会话2查询数据
    -> 发现当前版本是会话1的事务ID（未提交）
    -> 通过undo log回溯到T1时的数据版本
    -> 返回旧值：status='paid'

undo log链：
最新版本: (trx_id=101, status='cancelled', total_amount=0)
  ↓ (undo log指针)
旧版本: (trx_id=50, status='paid', total_amount=500.00)
  ↓
更旧版本: (trx_id=20, status='pending', total_amount=500.00)
```

**任务解答**：

**1. 为什么会话2看到的是旧值？**

- 会话2使用REPEATABLE READ隔离级别，基于MVCC（多版本并发控制）
- 会话2开启事务时创建一致性视图（read view）
- 查询时发现最新版本由未提交事务（会话1）创建
- 通过undo log找到对会话2可见的旧版本数据

**2. undo log在这个过程中起什么作用？**

- **存储旧版本数据**：UPDATE前的值存储在undo log中
- **支持MVCC**：提供历史版本数据供其他事务读取
- **事务回滚**：如果会话1执行ROLLBACK，通过undo log恢复数据
- **实现一致性读**：保证REPEATABLE READ的可重复读特性

**3. 如果长时间不提交事务，undo log会有什么问题？**

**问题1：undo log膨胀**
```sql
-- 查看长事务
SELECT
    trx_id,
    trx_started,
    TIMESTAMPDIFF(MINUTE, trx_started, NOW()) AS 运行分钟数,
    trx_rows_modified AS 修改行数
FROM information_schema.innodb_trx
WHERE TIMESTAMPDIFF(MINUTE, trx_started, NOW()) > 10
ORDER BY trx_started;

-- 长事务导致undo log无法被purge（清理）
-- undo表空间持续增长
```

**问题2：影响性能**
```
- undo log链变长，回溯版本变慢
- 查询性能下降
- 磁盘空间占用增加
```

**问题3：阻塞purge线程**
```sql
-- 查看purge进度
SHOW ENGINE INNODB STATUS\G

-- 查找：
-- History list length 1234
-- 如果这个值很大（>10000），说明purge落后

-- 原因：有长事务存在，purge不能清理undo log
```

**解决方案**：
```sql
-- 1. 找出长事务
SELECT * FROM information_schema.innodb_trx
WHERE TIMESTAMPDIFF(SECOND, trx_started, NOW()) > 60;

-- 2. Kill长事务
KILL 线程ID;

-- 3. 应用层优化
-- - 避免长事务
-- - 及时提交或回滚
-- - 拆分大事务为小事务

-- 4. 监控undo表空间大小
SELECT
    TABLESPACE_NAME,
    FILE_SIZE / 1024 / 1024 AS size_mb
FROM information_schema.FILES
WHERE TABLESPACE_NAME LIKE '%undo%';

-- 5. 配置自动truncate
SET GLOBAL innodb_undo_log_truncate = ON;
SET GLOBAL innodb_max_undo_log_size = 1073741824;  -- 1GB
```

## 六、通用查询日志（General Log）

### 14. 启用通用日志

```sql
-- 查看通用日志配置
SHOW VARIABLES LIKE 'general_log%';

-- 输出示例：
-- general_log = OFF
-- general_log_file = /var/lib/mysql/hostname.log

-- 临时启用通用日志（会话结束后失效）
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/tmp/mysql_general.log';

-- 执行一些查询测试
SELECT * FROM users LIMIT 1;
UPDATE users SET last_login = NOW() WHERE id = 1;
DELETE FROM cart_items WHERE user_id = 999;

-- 查看通用日志
```

**查看通用日志文件**：
```bash
tail -50 /tmp/mysql_general.log

# 输出示例：
# 2024-01-15T10:30:45.123456Z    10 Connect   root@localhost on study_db using Socket
# 2024-01-15T10:30:46.234567Z    10 Query     SELECT * FROM users LIMIT 1
# 2024-01-15T10:30:47.345678Z    10 Query     UPDATE users SET last_login = NOW() WHERE id = 1
# 2024-01-15T10:30:48.456789Z    10 Query     DELETE FROM cart_items WHERE user_id = 999
# 2024-01-15T10:30:49.567890Z    10 Quit

# 格式说明：
# 时间戳 | 线程ID | 事件类型 | 详细信息
```

**关闭通用日志**：
```sql
-- 务必关闭，避免性能影响
SET GLOBAL general_log = 'OFF';
```

**任务解答**：

**1. 通用日志和慢查询日志的区别**

| 特性 | 通用日志 | 慢查询日志 |
|------|----------|-----------|
| 记录内容 | 所有SQL语句 | 执行时间超过阈值的SQL |
| 日志量 | 巨大 | 相对较小 |
| 性能影响 | 很大（10-15%） | 较小（<5%） |
| 适用场景 | 调试、审计 | 性能优化 |
| 生产环境 | 不推荐 | 推荐开启 |
| 包含信息 | 连接、查询、退出等 | 查询时间、锁等待、扫描行数 |

**2. 为什么不建议在生产环境开启通用日志**

**原因1：性能影响严重**
```
- 每条SQL都要写日志
- 磁盘I/O显著增加
- QPS下降10-15%
- 高并发场景下影响更明显
```

**原因2：日志量巨大**
```bash
# 一个中等规模网站：
# - QPS: 1000
# - 每条SQL平均100字节
# - 每秒日志量: 100KB
# - 每天日志量: 8.6GB
# - 一周: 60GB+
```

**原因3：磁盘空间风险**
```
- 日志增长快，容易填满磁盘
- 磁盘满会导致MySQL无法写入
- 数据库崩溃风险
```

**原因4：有更好的替代方案**
```
- 慢查询日志：定位性能问题
- binlog：数据恢复、审计
- Performance Schema：详细的性能分析
- 审计插件：如MySQL Enterprise Audit
- 数据库防火墙：ProxySQL、MaxScale
```

**适用场景**：
```
✓ 临时调试特定问题（<5分钟）
✓ 审计某个用户的操作（短时间）
✓ 测试环境
✓ 开发环境

✗ 生产环境长期开启
✗ 高并发场景
```

**更好的审计方案**：
```sql
-- 方案1：使用MySQL Enterprise Audit（商业版）

-- 方案2：使用Performance Schema
SELECT
    EVENT_NAME,
    SQL_TEXT,
    CURRENT_SCHEMA,
    TIMER_WAIT / 1000000000 AS duration_ms
FROM performance_schema.events_statements_history
WHERE CURRENT_SCHEMA = 'study_db'
ORDER BY TIMER_START DESC
LIMIT 100;

-- 方案3：使用ProxySQL审计
-- ProxySQL可以记录所有查询到单独的审计日志

-- 方案4：应用层审计
-- 在应用代码中记录关键SQL操作
```

## 七、日志管理和优化

### 15. binlog清理策略

```sql
-- 查看所有binlog文件
SHOW BINARY LOGS;

-- 输出示例：
-- +------------------+-----------+-----------+
-- | Log_name         | File_size | Encrypted |
-- +------------------+-----------+-----------+
-- | mysql-bin.000001 | 177       | No        |
-- | mysql-bin.000002 | 15234567  | No        |
-- | mysql-bin.000003 | 89765432  | No        |
-- | mysql-bin.000004 | 45678901  | No        |
-- | mysql-bin.000005 | 12345678  | No        |
-- +------------------+-----------+-----------+

-- 手动清理指定binlog之前的文件
PURGE BINARY LOGS TO 'mysql-bin.000003';
-- 删除mysql-bin.000001和mysql-bin.000002

-- 按时间清理（清理7天前的binlog）
PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL 7 DAY);

-- 按具体日期清理
PURGE BINARY LOGS BEFORE '2024-01-01 00:00:00';

-- 清理所有binlog（危险！）
RESET MASTER;

-- 自动清理配置（MySQL 8.0+）
SET GLOBAL binlog_expire_logs_seconds = 604800;  -- 7天 = 7*24*3600

-- MySQL 5.7
SET GLOBAL expire_logs_days = 7;

-- 持久化配置（my.cnf）
-- [mysqld]
-- binlog_expire_logs_seconds = 604800
```

**binlog清理策略设计**：

**考虑因素**：
1. **备份周期**：保留时间应大于备份周期
2. **从库同步**：确保从库已同步完成
3. **磁盘空间**：预留足够空间
4. **恢复需求**：PITR需要完整的binlog链

**推荐策略**：

```
场景1：每日全量备份
- binlog保留时间：7天
- 理由：可恢复最近7天任意时间点的数据

场景2：每周全量 + 每日增量备份
- binlog保留时间：14天
- 理由：最坏情况下，用上周全量+14天binlog恢复

场景3：主从复制环境
- binlog保留时间：根据从库最大延迟 + 缓冲
- 例如：从库最大延迟1小时，保留3天（72小时）

场景4：多个从库、级联复制
- binlog保留时间：更长（如14-30天）
- 防止从库长时间宕机后无法恢复
```

**清理前检查**：
```sql
-- 1. 检查主从同步状态
-- 在所有从库执行
SHOW SLAVE STATUS\G

-- 确认：
-- - Slave_IO_Running: Yes
-- - Slave_SQL_Running: Yes
-- - Seconds_Behind_Master: 0或很小
-- - Master_Log_File: 当前正在读取的主库binlog

-- 2. 检查备份覆盖范围
-- 确保要删除的binlog已被备份覆盖

-- 3. 执行清理
PURGE BINARY LOGS TO '安全的binlog文件';

-- 4. 验证
SHOW BINARY LOGS;
```

**自动化清理脚本**：
```bash
#!/bin/bash
# binlog_cleanup.sh - binlog清理脚本

MYSQL_USER="root"
MYSQL_PASS="password"
RETENTION_DAYS=7

# 1. 检查从库同步状态
echo "检查从库同步状态..."
SLAVE_STATUS=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master" | awk '{print $2}')

if [ "$SLAVE_STATUS" != "0" ] && [ "$SLAVE_STATUS" != "NULL" ]; then
    echo "警告：从库延迟 ${SLAVE_STATUS}秒，跳过清理"
    exit 1
fi

# 2. 清理binlog
echo "清理${RETENTION_DAYS}天前的binlog..."
mysql -u$MYSQL_USER -p$MYSQL_PASS -e "PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL $RETENTION_DAYS DAY);"

# 3. 检查结果
echo "剩余binlog："
mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW BINARY LOGS;"

echo "binlog清理完成"
```

### 16. 日志轮转和归档

**手动轮转binlog**：
```sql
-- 轮转binlog（关闭当前binlog，开启新的）
FLUSH BINARY LOGS;

-- 轮转所有日志
FLUSH LOGS;
-- 包括：binlog、error log、slow log、general log
```

**任务：编写自动归档脚本**

```bash
#!/bin/bash
# mysql_binlog_archive.sh - binlog归档脚本

# 配置
MYSQL_USER="root"
MYSQL_PASS="password"
BINLOG_DIR="/var/lib/mysql"
ARCHIVE_DIR="/backup/mysql/binlog_archive"
COMPRESS_CMD="gzip"  # 或使用 xz、zstd
RETENTION_DAYS=7
ARCHIVE_RETENTION_DAYS=30

LOG_FILE="/var/log/mysql_binlog_archive.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "========== 开始binlog归档 =========="

# 1. 创建归档目录
mkdir -p $ARCHIVE_DIR/$(date +%Y%m%d)

# 2. 轮转binlog
log "轮转binlog..."
mysql -u$MYSQL_USER -p$MYSQL_PASS -e "FLUSH BINARY LOGS;" 2>>$LOG_FILE
if [ $? -ne 0 ]; then
    log "错误：binlog轮转失败"
    exit 1
fi

# 3. 获取当前binlog文件
CURRENT_BINLOG=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW MASTER STATUS\G" | grep "File:" | awk '{print $2}')
log "当前binlog: $CURRENT_BINLOG"

# 4. 归档旧binlog（除当前文件外）
log "归档binlog文件..."
for binlog in $(ls -1 $BINLOG_DIR/mysql-bin.[0-9]* 2>/dev/null); do
    binlog_name=$(basename $binlog)

    # 跳过当前binlog
    if [ "$binlog_name" == "$CURRENT_BINLOG" ]; then
        log "跳过当前binlog: $binlog_name"
        continue
    fi

    # 检查文件修改时间
    file_age_days=$(( ($(date +%s) - $(stat -f%m "$binlog" 2>/dev/null || stat -c%Y "$binlog")) / 86400 ))

    if [ $file_age_days -ge $RETENTION_DAYS ]; then
        log "归档: $binlog_name (${file_age_days}天前)"

        # 压缩并归档
        $COMPRESS_CMD -c "$binlog" > "$ARCHIVE_DIR/$(date +%Y%m%d)/${binlog_name}.gz"

        if [ $? -eq 0 ]; then
            log "压缩成功: ${binlog_name}.gz"
            # 可选：删除原文件（谨慎）
            # rm -f "$binlog"
        else
            log "错误：压缩失败: $binlog_name"
        fi
    fi
done

# 5. 清理MySQL中的binlog引用
log "清理MySQL binlog..."
mysql -u$MYSQL_USER -p$MYSQL_PASS -e "PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL $RETENTION_DAYS DAY);" 2>>$LOG_FILE

# 6. 清理过期归档
log "清理${ARCHIVE_RETENTION_DAYS}天前的归档..."
find $ARCHIVE_DIR -type f -name "*.gz" -mtime +$ARCHIVE_RETENTION_DAYS -delete
find $ARCHIVE_DIR -type d -empty -delete

# 7. 统计信息
BINLOG_COUNT=$(ls -1 $BINLOG_DIR/mysql-bin.[0-9]* 2>/dev/null | wc -l)
ARCHIVE_COUNT=$(find $ARCHIVE_DIR -name "*.gz" | wc -l)
ARCHIVE_SIZE=$(du -sh $ARCHIVE_DIR 2>/dev/null | awk '{print $1}')

log "统计信息："
log "  - 当前binlog文件数: $BINLOG_COUNT"
log "  - 归档文件数: $ARCHIVE_COUNT"
log "  - 归档总大小: $ARCHIVE_SIZE"

log "========== binlog归档完成 =========="
```

**Crontab配置**：
```bash
# 编辑crontab
crontab -e

# 每天凌晨2点执行归档
0 2 * * * /usr/local/bin/mysql_binlog_archive.sh

# 或者每周一凌晨3点执行
0 3 * * 1 /usr/local/bin/mysql_binlog_archive.sh
```

### 17. 日志监控指标

```sql
-- 1. binlog生成速度
-- 查看binlog缓存使用情况
SHOW GLOBAL STATUS LIKE 'Binlog_cache%';

-- 输出示例：
-- Binlog_cache_disk_use: 123    # 使用磁盘临时文件的事务数
-- Binlog_cache_use: 456789      # 使用binlog缓存的事务数

-- 如果Binlog_cache_disk_use较高，考虑增大binlog_cache_size

-- 2. 慢查询数量
SHOW GLOBAL STATUS LIKE 'Slow_queries';
-- Slow_queries: 245

-- 计算慢查询比例
SELECT
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Slow_queries') AS slow_queries,
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Questions') AS total_queries,
    ROUND((SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Slow_queries') * 100.0 /
          (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Questions'), 2) AS slow_query_pct;

-- 3. redo log写入
SHOW GLOBAL STATUS LIKE 'Innodb_log%';

-- 关键指标：
-- Innodb_log_writes: redo log写入次数
-- Innodb_log_write_requests: redo log写入请求数
-- Innodb_os_log_fsyncs: fsync()调用次数（实际刷盘）
-- Innodb_os_log_written: 写入的字节数
```

**监控查询示例**：

```sql
-- 创建监控查询（每小时执行一次，记录增量）
CREATE TABLE mysql_log_metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metric_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    binlog_generated_mb DECIMAL(10,2),  -- binlog增长（MB）
    slow_queries_count INT,              -- 慢查询数
    redo_log_writes_count BIGINT,       -- redo log写入次数
    redo_log_fsyncs_count BIGINT        -- fsync次数
) ENGINE=InnoDB;

-- 插入监控数据的存储过程
DELIMITER $$
CREATE PROCEDURE collect_log_metrics()
BEGIN
    DECLARE binlog_size BIGINT;
    DECLARE last_binlog_size BIGINT DEFAULT 0;
    DECLARE slow_queries BIGINT;
    DECLARE last_slow_queries BIGINT DEFAULT 0;
    DECLARE redo_writes BIGINT;
    DECLARE last_redo_writes BIGINT DEFAULT 0;
    DECLARE redo_fsyncs BIGINT;
    DECLARE last_redo_fsyncs BIGINT DEFAULT 0;

    -- 获取当前binlog总大小
    SELECT SUM(File_size) INTO binlog_size
    FROM information_schema.FILES
    WHERE TABLESPACE_NAME LIKE '%binlog%';

    -- 获取慢查询数
    SELECT VARIABLE_VALUE INTO slow_queries
    FROM performance_schema.global_status
    WHERE VARIABLE_NAME = 'Slow_queries';

    -- 获取redo log指标
    SELECT VARIABLE_VALUE INTO redo_writes
    FROM performance_schema.global_status
    WHERE VARIABLE_NAME = 'Innodb_log_writes';

    SELECT VARIABLE_VALUE INTO redo_fsyncs
    FROM performance_schema.global_status
    WHERE VARIABLE_NAME = 'Innodb_os_log_fsyncs';

    -- 获取上次的值
    SELECT binlog_generated_mb, slow_queries_count, redo_log_writes_count, redo_log_fsyncs_count
    INTO last_binlog_size, last_slow_queries, last_redo_writes, last_redo_fsyncs
    FROM mysql_log_metrics
    ORDER BY id DESC LIMIT 1;

    -- 插入增量数据
    INSERT INTO mysql_log_metrics(binlog_generated_mb, slow_queries_count, redo_log_writes_count, redo_log_fsyncs_count)
    VALUES (
        (binlog_size - IFNULL(last_binlog_size, 0)) / 1024 / 1024,
        slow_queries - IFNULL(last_slow_queries, 0),
        redo_writes - IFNULL(last_redo_writes, 0),
        redo_fsyncs - IFNULL(last_redo_fsyncs, 0)
    );
END$$
DELIMITER ;

-- 创建事件定时执行（每小时）
CREATE EVENT collect_metrics_hourly
ON SCHEDULE EVERY 1 HOUR
DO CALL collect_log_metrics();

-- 启用事件调度器
SET GLOBAL event_scheduler = ON;

-- 查询监控数据
SELECT
    metric_time AS 时间,
    binlog_generated_mb AS binlog增长MB,
    slow_queries_count AS 慢查询数,
    redo_log_writes_count AS redo写入次数,
    redo_log_fsyncs_count AS fsync次数
FROM mysql_log_metrics
ORDER BY id DESC
LIMIT 24;  -- 最近24小时
```

## 总结

MySQL日志系统是数据库运维的核心，掌握日志的使用对故障排查、性能优化、数据恢复至关重要：

1. **错误日志**：首要排查工具，定位启动、运行时错误
2. **慢查询日志**：SQL优化的依据，生产环境必开
3. **binlog**：数据恢复的生命线，务必妥善保管
4. **redo log**：理解刷盘策略，平衡性能和安全
5. **undo log**：MVCC的基础，注意长事务的影响
6. **日志管理**：合理清理、归档、监控，避免磁盘爆满

**最佳实践**：
- 生产环境开启binlog和慢查询日志
- 定期分析慢查询日志并优化SQL
- 设置合理的binlog保留策略，配合备份
- 监控日志大小和生成速率
- 制定日志归档和恢复演练计划
