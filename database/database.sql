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
-- Catalog products with pricing, image, and stock thresholds
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `products` (
    `id` VARCHAR(36) NOT NULL,
    `category_id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `image_url` VARCHAR(500) NULL,
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
-- Table: product_addons (Junction)
-- M:N link between products and valid addons
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `product_addons` (
    `product_id` VARCHAR(36) NOT NULL,
    `addon_id` VARCHAR(36) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`, `addon_id`),
    CONSTRAINT `fk_product_addons_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_product_addons_addon` FOREIGN KEY (`addon_id`) 
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

-- ==============================================================================
-- SEED DATA
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Users Seed (Password: 'password123' bcrypt hash)
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `is_active`) VALUES
('usr_owner_01', 'Admin Owner', 'owner@cribsociety.coffee', '$2b$10$J9DVVjXaH2TL0U8iMbvJLOi7ABoRTfXcWqZri.VvfoqTZZ92Ht68y', 'owner', TRUE),
('usr_staff_01', 'Barista Sarah', 'sarah@cribsociety.coffee', '$2b$10$J9DVVjXaH2TL0U8iMbvJLOi7ABoRTfXcWqZri.VvfoqTZZ92Ht68y', 'staff', TRUE),
('usr_staff_02', 'Cashier Dimas', 'dimas@cribsociety.coffee', '$2b$10$J9DVVjXaH2TL0U8iMbvJLOi7ABoRTfXcWqZri.VvfoqTZZ92Ht68y', 'staff', TRUE);

-- ------------------------------------------------------------------------------
-- Categories Seed (Synchronized with Landing Page Menu)
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `categories` (`id`, `name`, `sort_order`, `is_active`) VALUES
('cat_signature_coffee', 'Signature Coffee', 1, TRUE),
('cat_coffee',           'Coffee',           2, TRUE),
('cat_non_coffee',       'Non Coffee',       3, TRUE),
('cat_food',             'Food',             4, TRUE),
('cat_matcha_yakult',    'Matcha & Yakult',  5, TRUE),
('cat_snack',            'Snack',            6, TRUE),
('cat_addon',            'Add On',           7, TRUE);

-- ------------------------------------------------------------------------------
-- Products Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `products` (`id`, `category_id`, `name`, `description`, `price`, `image_url`, `available`, `low_stock_threshold`, `is_archived`) VALUES
-- 1. Signature Coffee
('prod_crib_signature',        'cat_signature_coffee', 'Crib Signature Palm Latte', 'Double shot slow-extracted espresso, creamy oat blend, infused with organic palm nectar & sea salt froth.', 35000.00, 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),
('prod_matcha_espresso_dirty', 'cat_signature_coffee', 'Matcha Espresso Dirty', 'Ceremonial grade Uji matcha bottom layer topped with chilled fresh milk and a floating hot espresso shot.', 38000.00, 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?auto=format&fit=crop&q=80&w=600', TRUE, 8, FALSE),
('prod_tokyo_dark_americano',  'cat_signature_coffee', 'Tokyo Dark Iced Americano', 'Crisp, citrusy washed Ethiopian beans pulled over crystal rock ice with subtle orange twist aroma.', 28000.00, 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&q=80&w=600', TRUE, 15, FALSE),
('prod_spanish_cinnamon_latte','cat_signature_coffee', 'Spanish Cinnamon Latte', 'Sweet condensed milk foundation layered with bold dark roast and freshly ground Ceylon cinnamon.', 34000.00, 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),

-- 2. Coffee
('prod_velvet_flat_white',     'cat_coffee',           'Velvet Flat White', 'Double ristretto with micro-foamed whole milk creating a glossy velvet texture and balanced body.', 32000.00, 'https://images.unsplash.com/photo-1577968897966-3d4325b36b61?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),
('prod_classic_cappuccino',    'cat_coffee',           'Classic Italian Cappuccino', 'Equal parts rich espresso, steamed milk, and thick velvety microfoam dusted with raw cacao powder.', 30000.00, 'https://images.unsplash.com/photo-1534778101976-62847782c213?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),
('prod_v60_filter',            'cat_coffee',           'V60 Single Origin Filter', 'Hand-poured floral Ethiopian Yirgacheffe with notes of bergamot, peach sweetness, and jasmine.', 38000.00, 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&q=80&w=600', TRUE, 5, FALSE),
('prod_vanilla_cold_brew',     'cat_coffee',           'Vanilla Sweet Cold Brew', '18-hour cold-steeped Arabica coffee topped with a splash of sweet vanilla-infused cream.', 33000.00, 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),

-- 3. Non Coffee
('prod_artisan_dark_chocolate','cat_non_coffee',       'Artisan Dark Chocolate', '70% Single-origin Indonesian cocoa blended with steamed fresh milk and organic brown sugar.', 32000.00, 'https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?auto=format&fit=crop&q=80&w=600', TRUE, 8, FALSE),
('prod_earl_grey_milk_tea',    'cat_non_coffee',       'Royal Earl Grey Milk Tea', 'Fragrant citrusy bergamot black tea steeped rich, shaken with creamy fresh milk and wildflower honey.', 28000.00, 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),
('prod_sparkling_berry_hibiscus','cat_non_coffee',     'Sparkling Berry Hibiscus', 'Refreshing cold-brewed crimson hibiscus tea paired with muddled berries, mint, and sparkling soda.', 30000.00, 'https://images.unsplash.com/photo-1556881286-fc6915169721?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),

-- 4. Food
('prod_truffle_beef_bowl',     'cat_food',             'Truffle Beef Gyudon Bowl', 'Tender sliced Australian beef sautéed in aromatic truffle soy sauce over Japanese rice with onsen egg.', 48000.00, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600', TRUE, 5, FALSE),
('prod_creamy_carbonara',      'cat_food',             'Smoked Beef Carbonara', 'Al dente spaghetti tossed in rich parmesan egg yolk sauce, crispy smoked beef bacon, and black pepper.', 45000.00, 'https://images.unsplash.com/photo-1612874742237-6526221588e3?auto=format&fit=crop&q=80&w=600', TRUE, 5, FALSE),
('prod_crispy_chicken_matah',  'cat_food',             'Crispy Chicken Sambal Matah', 'Crispy golden chicken karaage bites served on warm steamed rice with spicy fragrant Balinese sambal matah.', 42000.00, 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&q=80&w=600', TRUE, 6, FALSE),

-- 5. Matcha & Yakult
('prod_uji_matcha_latte',      'cat_matcha_yakult',    'Kyoto Uji Matcha Cloud', 'Ceremonial grade Kyoto Uji matcha whisked fresh with velvety milk and delicate foam layer.', 36000.00, 'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),
('prod_strawberry_matcha_latte','cat_matcha_yakult',   'Strawberry Matcha Fusion', 'Sweet chunky strawberry compote layered with cold whole milk and topped with rich emerald Uji matcha.', 38000.00, 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?auto=format&fit=crop&q=80&w=600', TRUE, 8, FALSE),
('prod_lychee_yakult_breeze',  'cat_matcha_yakult',    'Lychee Yakult Breeze', 'Whole juicy lychee fruit muddled with probiotic Yakult and chilled sparkling soda over ice.', 29000.00, 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),
('prod_mango_yakult_cooler',   'cat_matcha_yakult',    'Mango Yakult Cooler', 'Ripe tropical mango nectar blended with creamy probiotic Yakult and crushed mint ice.', 29000.00, 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),

-- 6. Snack
('prod_truffle_fries',         'cat_snack',            'Truffle Parmesan Fries', 'Crispy shoestring golden fries tossed in white truffle oil, Himalayan pink salt, and grated parmesan.', 26000.00, 'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&q=80&w=600', TRUE, 10, FALSE),
('prod_french_croissant',      'cat_snack',            'French Butter Croissant', '36-layer fermented French AOP butter pastry, baked golden flaky crisp every morning.', 24000.00, 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&q=80&w=600', TRUE, 5, FALSE),
('prod_crispy_chicken_tenders','cat_snack',            'Crispy Chicken Tenders', 'Juicy buttermilk marinated chicken tenders fried golden crisp, served with house dipping sauce.', 32000.00, 'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&q=80&w=600', TRUE, 6, FALSE),
('prod_pain_au_chocolat',      'cat_snack',            'Valrhona Pain au Chocolat', 'Golden laminated dough with two batons of 64% Valrhona French dark chocolate.', 28000.00, 'https://images.unsplash.com/photo-1530610476181-d83430b64dcd?auto=format&fit=crop&q=80&w=600', TRUE, 6, FALSE),

-- 7. Add On
('prod_addon_espresso_shot',   'cat_addon',            'Extra Espresso Shot', 'Additional fresh double shot extracted from our signature house blend coffee beans.', 6000.00, 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&q=80&w=600', TRUE, 20, FALSE),
('prod_addon_oat_milk',        'cat_addon',            'Oat Milk Barista Upgrade', 'Swap regular dairy milk with silky, creamy Oatly Barista Edition oat milk.', 7000.00, 'https://images.unsplash.com/photo-1588710929895-6ef7d87a93a6?auto=format&fit=crop&q=80&w=600', TRUE, 15, FALSE),
('prod_addon_sea_salt_foam',   'cat_addon',            'Sea Salt Cold Foam', 'Thick velvety whipped cold foam sprinkled with fine Himalayan pink sea salt.', 8000.00, 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&q=80&w=600', TRUE, 15, FALSE),
('prod_addon_flavor_syrup',    'cat_addon',            'Artisan Flavored Syrup', 'Extra pumps of Madagascar Vanilla, Salted Caramel, or Hazelnut artisanal syrup.', 5000.00, 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&q=80&w=600', TRUE, 20, FALSE);

-- ------------------------------------------------------------------------------
-- Product Variants Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `product_variants` (`id`, `product_id`, `name`, `price_delta`, `is_active`) VALUES
('var_crib_iced',       'prod_crib_signature',         'Iced (16oz)', 0.00, TRUE),
('var_crib_hot',        'prod_crib_signature',         'Hot (12oz)', 0.00, TRUE),
('var_crib_large',      'prod_crib_signature',         'Iced Large (22oz)', 6000.00, TRUE),
('var_dirty_std',       'prod_matcha_espresso_dirty',  'Iced Dirty (Standard)', 0.00, TRUE),
('var_tokyo_iced',      'prod_tokyo_dark_americano',   'Iced (16oz)', 0.00, TRUE),
('var_tokyo_hot',       'prod_tokyo_dark_americano',   'Hot (10oz)', 0.00, TRUE),
('var_spanish_iced',    'prod_spanish_cinnamon_latte', 'Iced (16oz)', 0.00, TRUE),
('var_spanish_hot',     'prod_spanish_cinnamon_latte', 'Hot (12oz)', 0.00, TRUE),
('var_flat_white_std',  'prod_velvet_flat_white',      'Hot (8oz Standard)', 0.00, TRUE),
('var_capp_hot',        'prod_classic_cappuccino',     'Hot (8oz)', 0.00, TRUE),
('var_capp_iced',       'prod_classic_cappuccino',     'Iced (16oz)', 0.00, TRUE),
('var_v60_hot',         'prod_v60_filter',             'Hot Pour Over', 0.00, TRUE),
('var_v60_iced',        'prod_v60_filter',             'Japanese Flash Iced', 3000.00, TRUE),
('var_coldbrew_iced',   'prod_vanilla_cold_brew',      'Iced (16oz)', 0.00, TRUE),
('var_choco_iced',      'prod_artisan_dark_chocolate', 'Iced (16oz)', 0.00, TRUE),
('var_choco_hot',       'prod_artisan_dark_chocolate', 'Hot (12oz)', 0.00, TRUE),
('var_earl_iced',       'prod_earl_grey_milk_tea',     'Iced (16oz)', 0.00, TRUE),
('var_earl_hot',        'prod_earl_grey_milk_tea',     'Hot (12oz)', 0.00, TRUE),
('var_hibiscus_iced',   'prod_sparkling_berry_hibiscus','Iced (16oz)', 0.00, TRUE),
('var_gyudon_reg',      'prod_truffle_beef_bowl',      'Regular Portion', 0.00, TRUE),
('var_gyudon_large',    'prod_truffle_beef_bowl',      'Large Beef (+50g)', 12000.00, TRUE),
('var_carbonara_std',   'prod_creamy_carbonara',       'Standard Portion', 0.00, TRUE),
('var_chicken_med',     'prod_crispy_chicken_matah',   'Medium Spicy', 0.00, TRUE),
('var_chicken_extra',   'prod_crispy_chicken_matah',   'Extra Spicy', 0.00, TRUE),
('var_matcha_iced',     'prod_uji_matcha_latte',       'Iced (16oz)', 0.00, TRUE),
('var_matcha_hot',      'prod_uji_matcha_latte',       'Hot (12oz)', 0.00, TRUE),
('var_straw_matcha',    'prod_strawberry_matcha_latte','Iced (16oz)', 0.00, TRUE),
('var_lychee_breeze',   'prod_lychee_yakult_breeze',   'Iced (16oz)', 0.00, TRUE),
('var_mango_cooler',    'prod_mango_yakult_cooler',    'Iced (16oz)', 0.00, TRUE),
('var_fries_std',       'prod_truffle_fries',          'Standard Basket', 0.00, TRUE),
('var_croissant_warm',  'prod_french_croissant',       'Warmed Up', 0.00, TRUE),
('var_croissant_room',  'prod_french_croissant',       'Room Temperature', 0.00, TRUE),
('var_tenders_basket',  'prod_crispy_chicken_tenders', '6 pcs Basket', 0.00, TRUE),
('var_pain_warm',       'prod_pain_au_chocolat',       'Warmed Up', 0.00, TRUE),
('var_pain_room',       'prod_pain_au_chocolat',       'Room Temperature', 0.00, TRUE);

-- ------------------------------------------------------------------------------
-- Addons Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `addons` (`id`, `name`, `price`, `is_active`) VALUES
('add_extra_shot',      'Extra Espresso Shot',    6000.00, TRUE),
('add_oat_milk',        'Sub Oat Milk',           7000.00, TRUE),
('add_sea_salt_foam',   'Sea Salt Cold Foam',     8000.00, TRUE),
('add_extra_matcha',    'Extra Uji Matcha Layer', 8000.00, TRUE),
('add_tonic_splash',    'Tonic Water Splash',     5000.00, TRUE),
('add_whipped_cream',   'Whipped Cream',          5000.00, TRUE),
('add_strawberry_jam',  'House Strawberry Jam',   4000.00, TRUE),
('add_butter_pad',      'Extra Salted Butter',    4000.00, TRUE),
('add_extra_egg',       'Extra Onsen Egg',        6000.00, TRUE),
('add_extra_cheese',    'Extra Parmesan Cheese',  5000.00, TRUE),
('add_extra_matah',     'Extra Sambal Matah',     4000.00, TRUE);

-- ------------------------------------------------------------------------------
-- Product Addons Seed (Junction)
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `product_addons` (`product_id`, `addon_id`) VALUES
('prod_crib_signature',        'add_extra_shot'),
('prod_crib_signature',        'add_oat_milk'),
('prod_crib_signature',        'add_sea_salt_foam'),
('prod_matcha_espresso_dirty', 'add_extra_shot'),
('prod_matcha_espresso_dirty', 'add_extra_matcha'),
('prod_tokyo_dark_americano',  'add_extra_shot'),
('prod_tokyo_dark_americano',  'add_tonic_splash'),
('prod_spanish_cinnamon_latte','add_extra_shot'),
('prod_spanish_cinnamon_latte','add_whipped_cream'),
('prod_velvet_flat_white',     'add_oat_milk'),
('prod_velvet_flat_white',     'add_extra_shot'),
('prod_classic_cappuccino',    'add_extra_shot'),
('prod_artisan_dark_chocolate','add_oat_milk'),
('prod_artisan_dark_chocolate','add_sea_salt_foam'),
('prod_truffle_beef_bowl',     'add_extra_egg'),
('prod_creamy_carbonara',      'add_extra_cheese'),
('prod_crispy_chicken_matah',  'add_extra_matah'),
('prod_uji_matcha_latte',      'add_oat_milk'),
('prod_uji_matcha_latte',      'add_sea_salt_foam'),
('prod_strawberry_matcha_latte','add_oat_milk'),
('prod_french_croissant',      'add_strawberry_jam'),
('prod_french_croissant',      'add_butter_pad');

-- ------------------------------------------------------------------------------
-- Inventory Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `inventory` (`product_id`, `quantity`) VALUES
('prod_crib_signature',        45),
('prod_matcha_espresso_dirty', 25),
('prod_tokyo_dark_americano',  80),
('prod_spanish_cinnamon_latte',28),
('prod_velvet_flat_white',     50),
('prod_classic_cappuccino',    40),
('prod_v60_filter',            22),
('prod_vanilla_cold_brew',     35),
('prod_artisan_dark_chocolate',30),
('prod_earl_grey_milk_tea',    35),
('prod_sparkling_berry_hibiscus',40),
('prod_truffle_beef_bowl',     20),
('prod_creamy_carbonara',      18),
('prod_crispy_chicken_matah',  25),
('prod_uji_matcha_latte',      34),
('prod_strawberry_matcha_latte',25),
('prod_lychee_yakult_breeze',  40),
('prod_mango_yakult_cooler',   35),
('prod_truffle_fries',         40),
('prod_french_croissant',      14),
('prod_crispy_chicken_tenders',22),
('prod_pain_au_chocolat',      4),
('prod_addon_espresso_shot',   100),
('prod_addon_oat_milk',        80),
('prod_addon_sea_salt_foam',   60),
('prod_addon_flavor_syrup',    90);

-- ------------------------------------------------------------------------------
-- Inventory Adjustments Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `inventory_adjustments` (`id`, `product_id`, `actor_user_id`, `previous_quantity`, `adjustment_quantity`, `resulting_quantity`, `reason`) VALUES
('adj_init_01', 'prod_crib_signature', 'usr_owner_01', 0, 45, 45, 'Initial stock inbound for opening'),
('adj_init_02', 'prod_french_croissant', 'usr_owner_01', 0, 14, 14, 'Morning fresh bakery delivery'),
('adj_init_03', 'prod_uji_matcha_latte', 'usr_owner_01', 0, 34, 34, 'Uji ceremonial stock inbound'),
('adj_init_04', 'prod_truffle_beef_bowl', 'usr_owner_01', 0, 20, 20, 'Kitchen inventory preparation');

-- ------------------------------------------------------------------------------
-- Sample Orders Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `orders` (`id`, `order_number`,`status`, `payment_status`, `subtotal`, `discount_total`, `total`, `created_by`, `created_at`) VALUES
('ord_sample_01', 'CSC-1001', 'completed', 'paid', 67000.00, 10000.00, 57000.00, 'usr_staff_01', NOW() - INTERVAL 2 HOUR),
('ord_sample_02', 'CSC-1002', 'preparing', 'paid', 43000.00, 0.00, 43000.00, 'usr_staff_02', NOW() - INTERVAL 20 MINUTE),
('ord_sample_03', 'CSC-1003', 'ready', 'paid', 34000.00, 0.00, 34000.00, 'usr_staff_01', NOW() - INTERVAL 10 MINUTE),
('ord_sample_04', 'CSC-1004', 'pending', 'pending', 38000.00, 0.00, 38000.00, 'usr_staff_01', NOW() - INTERVAL 4 MINUTE);

INSERT IGNORE INTO `order_items` (`id`, `order_id`, `product_id`, `product_name_snapshot`, `unit_price`, `quantity`, `line_total`, `variant_name_snapshot`, `addon_snapshot`, `created_at`) VALUES
('item_01_1', 'ord_sample_01', 'prod_crib_signature', 'Crib Signature Palm Latte', 35000.00, 1, 43000.00, 'Iced (16oz)', JSON_ARRAY('Sea Salt Cold Foam'), NOW() - INTERVAL 2 HOUR),
('item_01_2', 'ord_sample_01', 'prod_french_croissant', 'French Butter Croissant', 24000.00, 1, 24000.00, 'Warmed Up', NULL, NOW() - INTERVAL 2 HOUR),
('item_02_1', 'ord_sample_02', 'prod_uji_matcha_latte', 'Kyoto Uji Matcha Cloud', 36000.00, 1, 43000.00, 'Iced (16oz)', JSON_ARRAY('Sub Oat Milk'), NOW() - INTERVAL 20 MINUTE),
('item_03_1', 'ord_sample_03', 'prod_tokyo_dark_americano', 'Tokyo Dark Iced Americano', 28000.00, 1, 34000.00, 'Iced (16oz)', JSON_ARRAY('Extra Espresso Shot'), NOW() - INTERVAL 10 MINUTE),
('item_04_1', 'ord_sample_04', 'prod_v60_filter', 'V60 Single Origin Filter', 38000.00, 1, 38000.00, 'Hot Pour Over', NULL, NOW() - INTERVAL 4 MINUTE);

INSERT IGNORE INTO `discounts` (`id`, `order_id`, `type`, `value`, `amount_applied`, `label`, `created_at`) VALUES
('disc_01', 'ord_sample_01', 'fixed', 10000.00, 10000.00, 'Grand Opening Discount', NOW() - INTERVAL 2 HOUR);

INSERT IGNORE INTO `payments` (`id`, `order_id`, `method`, `amount`, `status`, `external_reference`, `paid_at`, `created_at`) VALUES
('pay_01', 'ord_sample_01', 'qris', 57000.00, 'paid', 'QRIS-GOPAY-992817231', NOW() - INTERVAL 2 HOUR, NOW() - INTERVAL 2 HOUR),
('pay_02', 'ord_sample_02', 'cash', 43000.00, 'paid', 'CASH-REC-1002', NOW() - INTERVAL 20 MINUTE, NOW() - INTERVAL 20 MINUTE),
('pay_03', 'ord_sample_03', 'card', 34000.00, 'paid', 'EDC-BCA-771829', NOW() - INTERVAL 10 MINUTE, NOW() - INTERVAL 10 MINUTE);

INSERT IGNORE INTO `audit_logs` (`id`, `actor_user_id`, `action`, `entity_type`, `entity_id`, `metadata`) VALUES
('aud_01', 'usr_owner_01', 'SYSTEM_INIT', 'system', 'database', JSON_OBJECT('version', '0.2.0', 'status', 'initialized')),
('aud_02', 'usr_owner_01', 'INVENTORY_RESTOCK', 'inventory', 'prod_crib_signature', JSON_OBJECT('qty_added', 45, 'reason', 'Initial stock inbound')),
('aud_03', 'usr_staff_01', 'ORDER_COMPLETED', 'orders', 'ord_sample_01', JSON_OBJECT('order_number', 'CSC-1001', 'total', 57000.00, 'payment_method', 'qris'));

SET FOREIGN_KEY_CHECKS = 1;
