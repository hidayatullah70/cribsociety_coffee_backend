-- ==============================================================================
-- Crib Society Coffee — Database Schema & Seed Data
-- Specification Reference: sot/DATABASE-SPEC.md (v0.2.0)
-- Target DBMS: MySQL 8.0+ / MariaDB 10.5+
-- Charset: utf8mb4, Collation: utf8mb4_unicode_ci
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------------------------
-- Table: users
-- Roles: owner, staff
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('owner', 'staff') NOT NULL DEFAULT 'staff',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: categories
-- Product menu classifications
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `categories` (
    `id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_categories_sort_order` (`sort_order`),
    KEY `idx_categories_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: products
-- Catalog products with pricing and stock thresholds
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `products` (
    `id` VARCHAR(36) NOT NULL,
    `category_id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `available` BOOLEAN NOT NULL DEFAULT TRUE,
    `low_stock_threshold` INT NULL DEFAULT 5,
    `is_archived` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) 
        REFERENCES `categories` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_products_price` CHECK (`price` >= 0),
    CONSTRAINT `chk_products_low_stock` CHECK (`low_stock_threshold` IS NULL OR `low_stock_threshold` >= 0),
    KEY `idx_products_category_id` (`category_id`),
    KEY `idx_products_available` (`available`),
    KEY `idx_products_is_archived` (`is_archived`),
    KEY `idx_products_category_available` (`category_id`, `available`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: product_variants
-- Product size/type options with price modifiers
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `product_variants` (
    `id` VARCHAR(36) NOT NULL,
    `product_id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `price_delta` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_variants_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY `idx_product_variants_product_id` (`product_id`),
    KEY `idx_product_variants_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: addons
-- Extra toppings/modifiers for products
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `addons` (
    `id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `chk_addons_price` CHECK (`price` >= 0),
    KEY `idx_addons_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: product_addons
-- Many-to-Many junction between products and permitted addons
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `product_addons` (
    `product_id` VARCHAR(36) NOT NULL,
    `addon_id` VARCHAR(36) NOT NULL,
    PRIMARY KEY (`product_id`, `addon_id`),
    CONSTRAINT `fk_prod_addons_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_prod_addons_addon` FOREIGN KEY (`addon_id`) 
        REFERENCES `addons` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY `idx_product_addons_addon_id` (`addon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: orders
-- Customer sales orders with lifecycle tracking
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `orders` (
    `id` VARCHAR(36) NOT NULL,
    `order_number` VARCHAR(50) NOT NULL,
    `status` ENUM('pending', 'paid', 'preparing', 'ready', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    `payment_status` ENUM('unpaid', 'pending', 'paid', 'failed', 'cancelled') NOT NULL DEFAULT 'unpaid',
    `subtotal` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `discount_total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `created_by` VARCHAR(36) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_orders_order_number` (`order_number`),
    CONSTRAINT `fk_orders_created_by` FOREIGN KEY (`created_by`) 
        REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_orders_subtotal` CHECK (`subtotal` >= 0),
    CONSTRAINT `chk_orders_discount_total` CHECK (`discount_total` >= 0),
    CONSTRAINT `chk_orders_total` CHECK (`total` >= 0),
    KEY `idx_orders_status` (`status`),
    KEY `idx_orders_payment_status` (`payment_status`),
    KEY `idx_orders_created_at` (`created_at`),
    KEY `idx_orders_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: order_items
-- Line items with immutable snapshot of names, prices, and addons
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `order_items` (
    `id` VARCHAR(36) NOT NULL,
    `order_id` VARCHAR(36) NOT NULL,
    `product_id` VARCHAR(36) NULL,
    `product_name_snapshot` VARCHAR(150) NOT NULL,
    `unit_price` DECIMAL(12, 2) NOT NULL,
    `quantity` INT NOT NULL,
    `line_total` DECIMAL(12, 2) NOT NULL,
    `variant_name_snapshot` VARCHAR(100) NULL,
    `addon_snapshot` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_order_items_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `chk_order_items_unit_price` CHECK (`unit_price` >= 0),
    CONSTRAINT `chk_order_items_quantity` CHECK (`quantity` > 0),
    CONSTRAINT `chk_order_items_line_total` CHECK (`line_total` >= 0),
    KEY `idx_order_items_order_id` (`order_id`),
    KEY `idx_order_items_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: payments
-- Payment attempts and records
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `payments` (
    `id` VARCHAR(36) NOT NULL,
    `order_id` VARCHAR(36) NOT NULL,
    `method` ENUM('cash', 'qris', 'card', 'other') NOT NULL,
    `amount` DECIMAL(12, 2) NOT NULL,
    `status` ENUM('pending', 'paid', 'failed', 'cancelled') NOT NULL DEFAULT 'pending',
    `external_reference` VARCHAR(100) NULL,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_payments_amount` CHECK (`amount` >= 0),
    KEY `idx_payments_order_id` (`order_id`),
    KEY `idx_payments_status` (`status`),
    KEY `idx_payments_external_reference` (`external_reference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: discounts
-- Applied discount history per order
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `discounts` (
    `id` VARCHAR(36) NOT NULL,
    `order_id` VARCHAR(36) NOT NULL,
    `type` ENUM('fixed', 'percentage') NOT NULL,
    `value` DECIMAL(12, 2) NOT NULL,
    `amount_applied` DECIMAL(12, 2) NOT NULL,
    `label` VARCHAR(100) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_discounts_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `chk_discounts_value` CHECK (`value` >= 0),
    CONSTRAINT `chk_discounts_amount_applied` CHECK (`amount_applied` >= 0),
    KEY `idx_discounts_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: inventory
-- Current product-level stock
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `inventory` (
    `product_id` VARCHAR(36) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`),
    CONSTRAINT `fk_inventory_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `chk_inventory_quantity` CHECK (`quantity` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: inventory_adjustments
-- Append-only historical log for all stock mutations
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `inventory_adjustments` (
    `id` VARCHAR(36) NOT NULL,
    `product_id` VARCHAR(36) NOT NULL,
    `actor_user_id` VARCHAR(36) NOT NULL,
    `previous_quantity` INT NOT NULL,
    `adjustment_quantity` INT NOT NULL,
    `resulting_quantity` INT NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_inv_adj_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_inv_adj_actor` FOREIGN KEY (`actor_user_id`) 
        REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_inv_adj_resulting_qty` CHECK (`resulting_quantity` >= 0),
    KEY `idx_inv_adj_product_id` (`product_id`),
    KEY `idx_inv_adj_actor` (`actor_user_id`),
    KEY `idx_inv_adj_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: audit_logs
-- Business-critical actions audit trail
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `audit_logs` (
    `id` VARCHAR(36) NOT NULL,
    `actor_user_id` VARCHAR(36) NULL,
    `action` VARCHAR(100) NOT NULL,
    `entity_type` VARCHAR(100) NOT NULL,
    `entity_id` VARCHAR(100) NOT NULL,
    `metadata` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_audit_logs_actor` FOREIGN KEY (`actor_user_id`) 
        REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    KEY `idx_audit_logs_actor` (`actor_user_id`),
    KEY `idx_audit_logs_entity` (`entity_type`, `entity_id`),
    KEY `idx_audit_logs_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Users Seed (Password: 'password123' bcrypt hash)
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `is_active`) VALUES
('usr_owner_01', 'Admin Owner', 'owner@cribsociety.coffee', '$2b$10$J9DVVjXaH2TL0U8iMbvJLOi7ABoRTfXcWqZri.VvfoqTZZ92Ht68y', 'owner', TRUE),
('usr_staff_01', 'Barista Sarah', 'sarah@cribsociety.coffee', '$2b$10$J9DVVjXaH2TL0U8iMbvJLOi7ABoRTfXcWqZri.VvfoqTZZ92Ht68y', 'staff', TRUE),
('usr_staff_02', 'Cashier Dimas', 'dimas@cribsociety.coffee', '$2b$10$J9DVVjXaH2TL0U8iMbvJLOi7ABoRTfXcWqZri.VvfoqTZZ92Ht68y', 'staff', TRUE);

-- ------------------------------------------------------------------------------
-- Categories Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `categories` (`id`, `name`, `sort_order`, `is_active`) VALUES
('cat_signature', 'Signature Coffee', 1, TRUE),
('cat_espresso',  'Espresso & Classic', 2, TRUE),
('cat_non_coffee','Non-Coffee & Refreshers', 3, TRUE),
('cat_pastry',    'Pastry & Bites', 4, TRUE);

-- ------------------------------------------------------------------------------
-- Products Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `products` (`id`, `category_id`, `name`, `description`, `price`, `available`, `low_stock_threshold`, `is_archived`) VALUES
('prod_crib_aren',      'cat_signature',  'Crib Aren Latte', 'Signature espresso, fresh milk, and organic aren palm sugar.', 28000.00, TRUE, 10, FALSE),
('prod_butterscotch',   'cat_signature',  'Butterscotch Sea Salt Latte', 'Double espresso, rich butterscotch caramel, and sea salt foam.', 34000.00, TRUE, 10, FALSE),
('prod_coco_cappuccino', 'cat_signature', 'Toasted Coconut Cappuccino', 'Velvety microfoam cappuccino infused with toasted coconut syrup.', 32000.00, TRUE, 8, FALSE),
('prod_espresso',       'cat_espresso',   'Double Espresso', 'Rich and intense double shot extracted from 100% Arabica beans.', 20000.00, TRUE, 15, FALSE),
('prod_americano',      'cat_espresso',   'Iced Americano', 'Smooth double espresso diluted with purified cold water and ice.', 24000.00, TRUE, 15, FALSE),
('prod_latte',          'cat_espresso',   'Caffe Latte', 'Espresso balanced with steamed milk and a thin layer of foam.', 28000.00, TRUE, 15, FALSE),
('prod_matcha_latte',   'cat_non_coffee', 'Matcha Oat Latte', 'Ceremonial Uji matcha whisked with creamy oat milk.', 32000.00, TRUE, 10, FALSE),
('prod_berry_fizz',     'cat_non_coffee', 'Wild Berry Soda Fizz', 'Refreshing sparkling soda infused with natural berry reduction and mint.', 26000.00, TRUE, 8, FALSE),
('prod_artisanal_tea',  'cat_non_coffee', 'Earl Grey Lavender Tea', 'Premium whole-leaf black tea scented with French lavender blossoms.', 22000.00, TRUE, 10, FALSE),
('prod_croissant',      'cat_pastry',     'Artisan Butter Croissant', 'Flaky, buttery multi-layered traditional French croissant baked fresh daily.', 25000.00, TRUE, 5, FALSE),
('prod_fudge_brownie',  'cat_pastry',     'Sea Salt Fudge Brownie', 'Decadent dark chocolate brownie with a sprinkle of Maldon sea salt.', 22000.00, TRUE, 5, FALSE),
('prod_cinnamon_roll',  'cat_pastry',     'Cream Cheese Cinnamon Roll', 'Warm fluffy brioche rolled with cinnamon brown sugar, topped with cream cheese glaze.', 28000.00, TRUE, 5, FALSE);

-- ------------------------------------------------------------------------------
-- Product Variants Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `product_variants` (`id`, `product_id`, `name`, `price_delta`, `is_active`) VALUES
('var_aren_reg',   'prod_crib_aren',    'Regular (12oz)', 0.00, TRUE),
('var_aren_large', 'prod_crib_aren',    'Large (16oz)', 6000.00, TRUE),
('var_butter_reg',   'prod_butterscotch', 'Regular (12oz)', 0.00, TRUE),
('var_butter_large', 'prod_butterscotch', 'Large (16oz)', 6000.00, TRUE),
('var_latte_hot',  'prod_latte',        'Hot (8oz)', 0.00, TRUE),
('var_latte_iced', 'prod_latte',        'Iced (12oz)', 2000.00, TRUE),
('var_matcha_hot',  'prod_matcha_latte', 'Hot (8oz)', 0.00, TRUE),
('var_matcha_iced', 'prod_matcha_latte', 'Iced (12oz)', 2000.00, TRUE);

-- ------------------------------------------------------------------------------
-- Addons Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `addons` (`id`, `name`, `price`, `is_active`) VALUES
('add_extra_espresso', 'Extra Espresso Shot', 6000.00, TRUE),
('add_oat_milk',       'Swap to Oat Milk', 7000.00, TRUE),
('add_almond_milk',    'Swap to Almond Milk', 8000.00, TRUE),
('add_vanilla_syrup',  'Vanilla Syrup Pump', 4000.00, TRUE),
('add_caramel_drizzle','Salted Caramel Drizzle', 5000.00, TRUE),
('add_ice_cream_scoop','Vanilla Ice Cream Scoop', 8000.00, TRUE);

-- ------------------------------------------------------------------------------
-- Product Addons Seed (Junction)
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `product_addons` (`product_id`, `addon_id`) VALUES
('prod_crib_aren', 'add_extra_espresso'),
('prod_crib_aren', 'add_oat_milk'),
('prod_crib_aren', 'add_almond_milk'),
('prod_crib_aren', 'add_caramel_drizzle'),
('prod_butterscotch', 'add_extra_espresso'),
('prod_butterscotch', 'add_oat_milk'),
('prod_butterscotch', 'add_caramel_drizzle'),
('prod_latte', 'add_extra_espresso'),
('prod_latte', 'add_oat_milk'),
('prod_latte', 'add_almond_milk'),
('prod_latte', 'add_vanilla_syrup'),
('prod_matcha_latte', 'add_extra_espresso'),
('prod_matcha_latte', 'add_vanilla_syrup'),
('prod_matcha_latte', 'add_ice_cream_scoop'),
('prod_fudge_brownie', 'add_ice_cream_scoop'),
('prod_croissant',     'add_caramel_drizzle');

-- ------------------------------------------------------------------------------
-- Inventory Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `inventory` (`product_id`, `quantity`) VALUES
('prod_crib_aren',       45),
('prod_butterscotch',    30),
('prod_coco_cappuccino', 25),
('prod_espresso',        100),
('prod_americano',       80),
('prod_latte',           50),
('prod_matcha_latte',    35),
('prod_berry_fizz',      20),
('prod_artisanal_tea',   40),
('prod_croissant',       12),
('prod_fudge_brownie',   8),
('prod_cinnamon_roll',   15);

-- ------------------------------------------------------------------------------
-- Inventory Adjustments Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `inventory_adjustments` (`id`, `product_id`, `actor_user_id`, `previous_quantity`, `adjustment_quantity`, `resulting_quantity`, `reason`) VALUES
('adj_init_01', 'prod_crib_aren',     'usr_owner_01', 0, 45,  45,  'Initial stock inbound for opening'),
('adj_init_02', 'prod_butterscotch',  'usr_owner_01', 0, 30,  30,  'Initial stock inbound for opening'),
('adj_init_03', 'prod_croissant',     'usr_owner_01', 0, 12,  12,  'Morning fresh bakery delivery'),
('adj_init_04', 'prod_fudge_brownie', 'usr_owner_01', 0, 8,   8,   'Morning fresh bakery delivery');

-- ------------------------------------------------------------------------------
-- Sample Orders Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `orders` (`id`, `order_number`, `status`, `payment_status`, `subtotal`, `discount_total`, `total`, `created_by`, `created_at`) VALUES
('ord_sample_01', '#CSC-1001', 'completed', 'paid', 62000.00, 5000.00, 57000.00, 'usr_staff_01', NOW() - INTERVAL 2 HOUR),
('ord_sample_02', '#CSC-1002', 'preparing', 'paid', 34000.00, 0.00, 34000.00, 'usr_staff_02', NOW() - INTERVAL 20 MINUTE),
('ord_sample_03', '#CSC-1003', 'ready', 'paid', 54000.00, 0.00, 54000.00, 'usr_staff_01', NOW() - INTERVAL 10 MINUTE);

INSERT IGNORE INTO `order_items` (`id`, `order_id`, `product_id`, `product_name_snapshot`, `unit_price`, `quantity`, `line_total`, `variant_name_snapshot`, `addon_snapshot`, `created_at`) VALUES
('item_01_1', 'ord_sample_01', 'prod_crib_aren', 'Crib Aren Latte', 34000.00, 1, 34000.00, 'Large (16oz)', JSON_ARRAY('Extra Espresso Shot'), NOW() - INTERVAL 2 HOUR),
('item_01_2', 'ord_sample_01', 'prod_croissant', 'Artisan Butter Croissant', 25000.00, 1, 28000.00, NULL, JSON_ARRAY('Salted Caramel Drizzle'), NOW() - INTERVAL 2 HOUR),
('item_02_1', 'ord_sample_02', 'prod_butterscotch', 'Butterscotch Sea Salt Latte', 34000.00, 1, 34000.00, 'Regular (12oz)', NULL, NOW() - INTERVAL 20 MINUTE),
('item_03_1', 'ord_sample_03', 'prod_matcha_latte', 'Matcha Oat Latte', 32000.00, 1, 32000.00, 'Hot (8oz)', NULL, NOW() - INTERVAL 10 MINUTE),
('item_03_2', 'ord_sample_03', 'prod_fudge_brownie', 'Sea Salt Fudge Brownie', 22000.00, 1, 22000.00, NULL, NULL, NOW() - INTERVAL 10 MINUTE);

INSERT IGNORE INTO `discounts` (`id`, `order_id`, `type`, `value`, `amount_applied`, `label`, `created_at`) VALUES
('disc_01', 'ord_sample_01', 'fixed', 5000.00, 5000.00, 'Opening Promo Voucher', NOW() - INTERVAL 2 HOUR);

INSERT IGNORE INTO `payments` (`id`, `order_id`, `method`, `amount`, `status`, `external_reference`, `paid_at`, `created_at`) VALUES
('pay_01', 'ord_sample_01', 'qris', 57000.00, 'paid', 'QRIS-GOPAY-992817231', NOW() - INTERVAL 2 HOUR, NOW() - INTERVAL 2 HOUR),
('pay_02', 'ord_sample_02', 'cash', 34000.00, 'paid', 'CASH-REC-1002', NOW() - INTERVAL 20 MINUTE, NOW() - INTERVAL 20 MINUTE),
('pay_03', 'ord_sample_03', 'card', 54000.00, 'paid', 'EDC-BCA-771829', NOW() - INTERVAL 10 MINUTE, NOW() - INTERVAL 10 MINUTE);

INSERT IGNORE INTO `audit_logs` (`id`, `actor_user_id`, `action`, `entity_type`, `entity_id`, `metadata`) VALUES
('aud_01', 'usr_owner_01', 'SYSTEM_INIT', 'system', 'database', JSON_OBJECT('version', '0.2.0', 'status', 'initialized')),
('aud_02', 'usr_owner_01', 'INVENTORY_RESTOCK', 'inventory', 'prod_crib_aren', JSON_OBJECT('qty_added', 45, 'reason', 'Initial stock inbound')),
('aud_03', 'usr_staff_01', 'ORDER_COMPLETED', 'orders', 'ord_sample_01', JSON_OBJECT('order_number', '#CSC-1001', 'total', 57000.00, 'payment_method', 'qris'));

SET FOREIGN_KEY_CHECKS = 1;
