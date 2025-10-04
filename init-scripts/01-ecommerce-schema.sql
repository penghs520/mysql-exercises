-- ============================================
-- 电子商城学习数据库
-- 包含约10万条示例数据
-- ============================================

USE study_db;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 1. 用户表
-- ============================================
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` VARCHAR(50) NOT NULL COMMENT '用户名',
  `email` VARCHAR(100) NOT NULL COMMENT '邮箱',
  `password_hash` VARCHAR(255) NOT NULL COMMENT '密码hash',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-正常',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_email` (`email`),
  KEY `idx_phone` (`phone`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================
-- 2. 商品分类表
-- ============================================
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  `parent_id` BIGINT UNSIGNED DEFAULT 0 COMMENT '父分类ID, 0表示顶级分类',
  `name` VARCHAR(50) NOT NULL COMMENT '分类名称',
  `level` TINYINT NOT NULL DEFAULT 1 COMMENT '分类层级',
  `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
  `is_show` TINYINT NOT NULL DEFAULT 1 COMMENT '是否显示: 0-隐藏, 1-显示',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_parent_id` (`parent_id`),
  KEY `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品分类表';

-- ============================================
-- 3. 商品表
-- ============================================
DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '商品ID',
  `category_id` BIGINT UNSIGNED NOT NULL COMMENT '分类ID',
  `name` VARCHAR(200) NOT NULL COMMENT '商品名称',
  `sub_title` VARCHAR(255) DEFAULT NULL COMMENT '副标题',
  `main_image` VARCHAR(255) DEFAULT NULL COMMENT '主图URL',
  `price` DECIMAL(10,2) NOT NULL COMMENT '售价',
  `original_price` DECIMAL(10,2) DEFAULT NULL COMMENT '原价',
  `stock` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '库存',
  `sales` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '销量',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-下架, 1-上架',
  `description` TEXT COMMENT '商品描述',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_status` (`status`),
  KEY `idx_price` (`price`),
  KEY `idx_sales` (`sales`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品表';

-- ============================================
-- 4. 商品SKU表
-- ============================================
DROP TABLE IF EXISTS `product_skus`;
CREATE TABLE `product_skus` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'SKU ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `sku_code` VARCHAR(50) NOT NULL COMMENT 'SKU编码',
  `attributes` JSON DEFAULT NULL COMMENT '规格属性 {"颜色":"红色","尺寸":"XL"}',
  `price` DECIMAL(10,2) NOT NULL COMMENT '售价',
  `stock` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '库存',
  `image` VARCHAR(255) DEFAULT NULL COMMENT 'SKU图片',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sku_code` (`sku_code`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品SKU表';

-- ============================================
-- 5. 购物车表
-- ============================================
DROP TABLE IF EXISTS `cart_items`;
CREATE TABLE `cart_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '购物车ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `sku_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'SKU ID',
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '数量',
  `checked` TINYINT NOT NULL DEFAULT 1 COMMENT '是否选中: 0-未选中, 1-选中',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='购物车表';

-- ============================================
-- 6. 收货地址表
-- ============================================
DROP TABLE IF EXISTS `user_addresses`;
CREATE TABLE `user_addresses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '地址ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `receiver_name` VARCHAR(50) NOT NULL COMMENT '收货人姓名',
  `phone` VARCHAR(20) NOT NULL COMMENT '手机号',
  `province` VARCHAR(50) NOT NULL COMMENT '省',
  `city` VARCHAR(50) NOT NULL COMMENT '市',
  `district` VARCHAR(50) NOT NULL COMMENT '区',
  `detail_address` VARCHAR(255) NOT NULL COMMENT '详细地址',
  `is_default` TINYINT NOT NULL DEFAULT 0 COMMENT '是否默认: 0-否, 1-是',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收货地址表';

-- ============================================
-- 7. 订单表
-- ============================================
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `order_no` VARCHAR(50) NOT NULL COMMENT '订单号',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `total_amount` DECIMAL(10,2) NOT NULL COMMENT '订单总金额',
  `pay_amount` DECIMAL(10,2) NOT NULL COMMENT '实付金额',
  `freight` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '运费',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '订单状态: 0-待支付, 1-已支付, 2-已发货, 3-已完成, 4-已取消',
  `receiver_name` VARCHAR(50) NOT NULL COMMENT '收货人',
  `receiver_phone` VARCHAR(20) NOT NULL COMMENT '收货电话',
  `receiver_address` VARCHAR(500) NOT NULL COMMENT '收货地址',
  `payment_method` VARCHAR(20) DEFAULT NULL COMMENT '支付方式',
  `payment_time` TIMESTAMP NULL DEFAULT NULL COMMENT '支付时间',
  `delivery_time` TIMESTAMP NULL DEFAULT NULL COMMENT '发货时间',
  `finish_time` TIMESTAMP NULL DEFAULT NULL COMMENT '完成时间',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '订单备注',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单表';

-- ============================================
-- 8. 订单明细表
-- ============================================
DROP TABLE IF EXISTS `order_items`;
CREATE TABLE `order_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单明细ID',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `sku_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'SKU ID',
  `product_name` VARCHAR(200) NOT NULL COMMENT '商品名称',
  `product_image` VARCHAR(255) DEFAULT NULL COMMENT '商品图片',
  `sku_attrs` VARCHAR(500) DEFAULT NULL COMMENT 'SKU属性',
  `price` DECIMAL(10,2) NOT NULL COMMENT '商品单价',
  `quantity` INT UNSIGNED NOT NULL COMMENT '购买数量',
  `total_amount` DECIMAL(10,2) NOT NULL COMMENT '小计金额',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单明细表';

-- ============================================
-- 9. 商品评价表
-- ============================================
DROP TABLE IF EXISTS `product_reviews`;
CREATE TABLE `product_reviews` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '评价ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `rating` TINYINT NOT NULL COMMENT '评分 1-5星',
  `content` TEXT COMMENT '评价内容',
  `images` JSON DEFAULT NULL COMMENT '评价图片',
  `reply` TEXT DEFAULT NULL COMMENT '商家回复',
  `reply_time` TIMESTAMP NULL DEFAULT NULL COMMENT '回复时间',
  `is_anonymous` TINYINT NOT NULL DEFAULT 0 COMMENT '是否匿名: 0-否, 1-是',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品评价表';

-- ============================================
-- 10. 支付记录表
-- ============================================
DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '支付ID',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `payment_no` VARCHAR(50) NOT NULL COMMENT '支付流水号',
  `payment_method` VARCHAR(20) NOT NULL COMMENT '支付方式: alipay, wechat, unionpay',
  `amount` DECIMAL(10,2) NOT NULL COMMENT '支付金额',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '支付状态: 0-待支付, 1-支付成功, 2-支付失败',
  `trade_no` VARCHAR(100) DEFAULT NULL COMMENT '第三方交易号',
  `paid_at` TIMESTAMP NULL DEFAULT NULL COMMENT '支付时间',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_payment_no` (`payment_no`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付记录表';

-- ============================================
-- 生成示例数据
-- ============================================

-- 1. 生成1000个用户
DROP PROCEDURE IF EXISTS generate_users;
DELIMITER $$
CREATE PROCEDURE generate_users()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 1000 DO
    INSERT INTO users (username, email, password_hash, phone, status, created_at) VALUES (
      CONCAT('user', i),
      CONCAT('user', i, '@example.com'),
      MD5(CONCAT('password', i)),
      CONCAT('13', LPAD(FLOOR(RAND() * 1000000000), 9, '0')),
      IF(RAND() > 0.1, 1, 0),
      DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_users();
DROP PROCEDURE generate_users;

-- 2. 生成商品分类（50个）
INSERT INTO categories (parent_id, name, level, sort_order) VALUES
(0, '电子产品', 1, 1),
(0, '服装鞋包', 1, 2),
(0, '食品饮料', 1, 3),
(0, '家居家装', 1, 4),
(0, '运动户外', 1, 5);

INSERT INTO categories (parent_id, name, level, sort_order)
SELECT id, CONCAT(name, '类目', n), 2, n
FROM categories, (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) nums
WHERE level = 1 LIMIT 45;

-- 3. 生成500个商品
DROP PROCEDURE IF EXISTS generate_products;
DELIMITER $$
CREATE PROCEDURE generate_products()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE cat_id INT;
  DECLARE base_price DECIMAL(10,2);
  WHILE i <= 500 DO
    SET cat_id = 6 + FLOOR(RAND() * 45);
    SET base_price = 10 + FLOOR(RAND() * 990);
    INSERT INTO products (category_id, name, sub_title, price, original_price, stock, sales, status, created_at) VALUES (
      cat_id,
      CONCAT('商品', i, ' - ', ELT(FLOOR(1 + RAND() * 5), '经典款', '新品', '热销款', '限量版', '特惠款')),
      CONCAT('高品质 ', ELT(FLOOR(1 + RAND() * 3), '超值优惠', '限时特价', '品质保证')),
      base_price,
      base_price * (1 + RAND() * 0.5),
      FLOOR(RAND() * 1000),
      FLOOR(RAND() * 10000),
      IF(RAND() > 0.05, 1, 0),
      DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 180) DAY)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_products();
DROP PROCEDURE generate_products;

-- 4. 生成1000个商品SKU
DROP PROCEDURE IF EXISTS generate_skus;
DELIMITER $$
CREATE PROCEDURE generate_skus()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE prod_id INT;
  DECLARE sku_price DECIMAL(10,2);
  WHILE i <= 1000 DO
    SET prod_id = 1 + FLOOR(RAND() * 500);
    SELECT price INTO sku_price FROM products WHERE id = prod_id;
    INSERT INTO product_skus (product_id, sku_code, attributes, price, stock) VALUES (
      prod_id,
      CONCAT('SKU', LPAD(i, 8, '0')),
      JSON_OBJECT(
        '颜色', ELT(FLOOR(1 + RAND() * 5), '黑色', '白色', '红色', '蓝色', '灰色'),
        '尺寸', ELT(FLOOR(1 + RAND() * 4), 'S', 'M', 'L', 'XL')
      ),
      sku_price + FLOOR(RAND() * 50) - 25,
      FLOOR(RAND() * 200)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_skus();
DROP PROCEDURE generate_skus;

-- 5. 生成3000个收货地址
DROP PROCEDURE IF EXISTS generate_addresses;
DELIMITER $$
CREATE PROCEDURE generate_addresses()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE usr_id INT;
  WHILE i <= 3000 DO
    SET usr_id = 1 + FLOOR(RAND() * 1000);
    INSERT INTO user_addresses (user_id, receiver_name, phone, province, city, district, detail_address, is_default) VALUES (
      usr_id,
      CONCAT('收货人', FLOOR(RAND() * 100)),
      CONCAT('13', LPAD(FLOOR(RAND() * 1000000000), 9, '0')),
      ELT(FLOOR(1 + RAND() * 5), '北京市', '上海市', '广东省', '浙江省', '江苏省'),
      ELT(FLOOR(1 + RAND() * 5), '朝阳区', '浦东新区', '天河区', '西湖区', '鼓楼区'),
      CONCAT(ELT(FLOOR(1 + RAND() * 3), '中心街道', '开发区', '高新区')),
      CONCAT('XX路', FLOOR(RAND() * 999), '号'),
      IF(RAND() > 0.7, 1, 0)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_addresses();
DROP PROCEDURE generate_addresses;

-- 6. 生成5000个购物车项
DROP PROCEDURE IF EXISTS generate_cart;
DELIMITER $$
CREATE PROCEDURE generate_cart()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 5000 DO
    INSERT INTO cart_items (user_id, product_id, sku_id, quantity, checked) VALUES (
      1 + FLOOR(RAND() * 1000),
      1 + FLOOR(RAND() * 500),
      IF(RAND() > 0.5, 1 + FLOOR(RAND() * 1000), NULL),
      1 + FLOOR(RAND() * 5),
      IF(RAND() > 0.3, 1, 0)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_cart();
DROP PROCEDURE generate_cart;

-- 7. 生成20000个订单
DROP PROCEDURE IF EXISTS generate_orders;
DELIMITER $$
CREATE PROCEDURE generate_orders()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE usr_id INT;
  DECLARE ord_status TINYINT;
  DECLARE created TIMESTAMP;
  DECLARE pay_amt DECIMAL(10,2);
  WHILE i <= 20000 DO
    SET usr_id = 1 + FLOOR(RAND() * 1000);
    SET ord_status = FLOOR(RAND() * 5);
    SET created = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY);
    SET pay_amt = 10 + FLOOR(RAND() * 1990);

    INSERT INTO orders (
      order_no, user_id, total_amount, pay_amount, freight, status,
      receiver_name, receiver_phone, receiver_address,
      payment_method, payment_time, delivery_time, finish_time, created_at
    ) VALUES (
      CONCAT('ORD', DATE_FORMAT(created, '%Y%m%d'), LPAD(i, 8, '0')),
      usr_id,
      pay_amt,
      pay_amt,
      IF(pay_amt > 99, 0, 10),
      ord_status,
      CONCAT('收货人', usr_id),
      CONCAT('13', LPAD(FLOOR(RAND() * 1000000000), 9, '0')),
      CONCAT(
        ELT(FLOOR(1 + RAND() * 5), '北京市', '上海市', '广东省', '浙江省', '江苏省'),
        ELT(FLOOR(1 + RAND() * 5), '朝阳区', '浦东新区', '天河区', '西湖区', '鼓楼区'),
        'XX路', FLOOR(RAND() * 999), '号'
      ),
      IF(ord_status > 0, ELT(FLOOR(1 + RAND() * 3), 'alipay', 'wechat', 'unionpay'), NULL),
      IF(ord_status > 0, DATE_ADD(created, INTERVAL FLOOR(RAND() * 60) MINUTE), NULL),
      IF(ord_status > 1, DATE_ADD(created, INTERVAL FLOOR(1 + RAND() * 3) DAY), NULL),
      IF(ord_status = 3, DATE_ADD(created, INTERVAL FLOOR(7 + RAND() * 7) DAY), NULL),
      created
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_orders();
DROP PROCEDURE generate_orders;

-- 8. 生成50000个订单明细（平均每个订单2-3个商品）
DROP PROCEDURE IF EXISTS generate_order_items;
DELIMITER $$
CREATE PROCEDURE generate_order_items()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE ord_id INT;
  DECLARE prod_id INT;
  DECLARE item_price DECIMAL(10,2);
  DECLARE item_qty INT;
  WHILE i <= 50000 DO
    SET ord_id = 1 + FLOOR(RAND() * 20000);
    SET prod_id = 1 + FLOOR(RAND() * 500);
    SELECT price INTO item_price FROM products WHERE id = prod_id;
    SET item_qty = 1 + FLOOR(RAND() * 3);

    INSERT INTO order_items (
      order_id, product_id, sku_id, product_name, price, quantity, total_amount
    ) VALUES (
      ord_id,
      prod_id,
      IF(RAND() > 0.5, 1 + FLOOR(RAND() * 1000), NULL),
      CONCAT('商品', prod_id),
      item_price,
      item_qty,
      item_price * item_qty
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_order_items();
DROP PROCEDURE generate_order_items;

-- 9. 生成20000条评价
DROP PROCEDURE IF EXISTS generate_reviews;
DELIMITER $$
CREATE PROCEDURE generate_reviews()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE ord_id INT;
  DECLARE prod_id INT;
  DECLARE usr_id INT;
  WHILE i <= 20000 DO
    SET ord_id = 1 + FLOOR(RAND() * 20000);
    SELECT user_id, product_id INTO usr_id, prod_id
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    WHERE o.id = ord_id LIMIT 1;

    IF prod_id IS NOT NULL THEN
      INSERT INTO product_reviews (product_id, order_id, user_id, rating, content, is_anonymous, created_at) VALUES (
        prod_id,
        ord_id,
        usr_id,
        3 + FLOOR(RAND() * 3),
        ELT(FLOOR(1 + RAND() * 10),
          '商品质量很好，值得购买', '物流很快，包装完整', '性价比高，推荐',
          '还不错，符合预期', '很满意，下次还会买', '质量一般般',
          '物有所值', '送货速度快', '包装精美', '超出预期，好评'
        ),
        IF(RAND() > 0.8, 1, 0),
        DATE_ADD((SELECT created_at FROM orders WHERE id = ord_id), INTERVAL FLOOR(7 + RAND() * 14) DAY)
      );
    END IF;
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_reviews();
DROP PROCEDURE generate_reviews;

-- 10. 生成20000条支付记录
DROP PROCEDURE IF EXISTS generate_payments;
DELIMITER $$
CREATE PROCEDURE generate_payments()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE ord_id INT;
  DECLARE ord_amt DECIMAL(10,2);
  DECLARE pay_time TIMESTAMP;
  WHILE i <= 20000 DO
    SET ord_id = i;
    SELECT pay_amount, payment_time INTO ord_amt, pay_time FROM orders WHERE id = ord_id;

    IF pay_time IS NOT NULL THEN
      INSERT INTO payments (order_id, payment_no, payment_method, amount, status, trade_no, paid_at, created_at) VALUES (
        ord_id,
        CONCAT('PAY', DATE_FORMAT(pay_time, '%Y%m%d%H%i%s'), LPAD(i, 6, '0')),
        ELT(FLOOR(1 + RAND() * 3), 'alipay', 'wechat', 'unionpay'),
        ord_amt,
        1,
        CONCAT('TXN', MD5(CONCAT(ord_id, RAND()))),
        pay_time,
        DATE_SUB(pay_time, INTERVAL FLOOR(RAND() * 60) SECOND)
      );
    END IF;
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL generate_payments();
DROP PROCEDURE generate_payments;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- 数据统计
-- ============================================
SELECT '数据生成完成！' AS '状态';
SELECT
  (SELECT COUNT(*) FROM users) AS '用户数',
  (SELECT COUNT(*) FROM categories) AS '分类数',
  (SELECT COUNT(*) FROM products) AS '商品数',
  (SELECT COUNT(*) FROM product_skus) AS 'SKU数',
  (SELECT COUNT(*) FROM cart_items) AS '购物车项',
  (SELECT COUNT(*) FROM user_addresses) AS '地址数',
  (SELECT COUNT(*) FROM orders) AS '订单数',
  (SELECT COUNT(*) FROM order_items) AS '订单明细',
  (SELECT COUNT(*) FROM product_reviews) AS '评价数',
  (SELECT COUNT(*) FROM payments) AS '支付记录',
  (
    (SELECT COUNT(*) FROM users) +
    (SELECT COUNT(*) FROM categories) +
    (SELECT COUNT(*) FROM products) +
    (SELECT COUNT(*) FROM product_skus) +
    (SELECT COUNT(*) FROM cart_items) +
    (SELECT COUNT(*) FROM user_addresses) +
    (SELECT COUNT(*) FROM orders) +
    (SELECT COUNT(*) FROM order_items) +
    (SELECT COUNT(*) FROM product_reviews) +
    (SELECT COUNT(*) FROM payments)
  ) AS '总记录数';
