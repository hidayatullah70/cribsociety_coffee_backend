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
('cat_signature',    'SIGNATURE',        1, TRUE),
('cat_coffee',       'COFFEE',           2, TRUE),
('cat_non_coffee',   'NON COFFEE',       3, TRUE),
('cat_food',         'FOOD',             4, TRUE),
('cat_matcha_yakult','MATCHA & YAKULT',  5, TRUE),
('cat_snack',        'SNACK',            6, TRUE),
('cat_addon',        'ADD ON',           7, TRUE);

-- ------------------------------------------------------------------------------
-- Products Seed (37 items)
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `products` (`id`, `category_id`, `name`, `description`, `price`, `image_url`, `available`, `low_stock_threshold`, `is_archived`) VALUES
-- 1. SIGNATURE
('prod_crib_aren_latte',        'cat_signature', 'CRIB AREN LATTE', 'Espresso double shot dipadukan dengan susu segar creamy dan gula aren organik khas Crib Society.', 28000.00, '/menu/signatureCoffee/cribSignaturePalm.png', TRUE, 10, FALSE),
('prod_crib_butterscotch_latte','cat_signature', 'CRIB BUTTERSCOTCH LATTE', 'Espresso racikan khas dengan saus butterscotch manis gurih dan tekstur susu velvety lembut.', 32000.00, '/menu/signatureCoffee/cribSignaturePalm.png', TRUE, 10, FALSE),
('prod_crib_chocolate_creamy',  'cat_signature', 'CRIB CHOCOLATE CREAMY', 'Dark chocolate premium dengan susu kental creamy dan sentuhan cacao dusting di atasnya.', 30000.00, '/menu/signatureCoffee/cribSignaturePalm.png', TRUE, 10, FALSE),
('prod_crib_red_spark',         'cat_signature', 'CRIB RED SPARK', 'Kombinasi sparkling segar dengan sirup red berry dan espresso cold brew beraroma buah.', 30000.00, '/menu/signatureCoffee/cribSignaturePalm.png', TRUE, 8, FALSE),
('prod_crib_matcha_strawberry', 'cat_signature', 'CRIB MATCHA STRAWBERRY', 'Layer bertingkat dari pure strawberry compote, susu segar, dan ceremonial Uji matcha.', 34000.00, '/menu/signatureCoffee/cribSignaturePalm.png', TRUE, 8, FALSE),

-- 2. COFFEE
('prod_cappucino',      'cat_coffee', 'CAPPUCINO', 'Perpaduan seimbang espresso kaya rasa, steamed milk, dan microfoam tebal dengan taburan cokelat.', 28000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 10, FALSE),
('prod_latte',          'cat_coffee', 'LATTE', 'Espresso murni dengan steamed milk lembut dan lapisan foam tipis bertekstur sutra.', 28000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 10, FALSE),
('prod_americano',      'cat_coffee', 'AMERICANO', 'Double espresso dilarutkan dengan air mineral dingin/panas, menghasilkan profil kopi bersih dan segar.', 22000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 15, FALSE),
('prod_strawberry_cano','cat_coffee', 'STRAWBERRY CANO', 'Americano segar berpadu dengan sirup strawberry manis asam yang menyegarkan dahaga.', 26000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 10, FALSE),
('prod_peach_cano',     'cat_coffee', 'PEACH CANO', 'Americano dingin dengan ekstrak buah peach aromatik dan aftertaste buah yang manis elegan.', 26000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 10, FALSE),
('prod_pineapple_cano', 'cat_coffee', 'PINEAPPLE CANO', 'Sensasi segar espresso berpadu dengan rasa tropis nanas segar yang renyah di lidah.', 26000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 10, FALSE),
('prod_vanilla_latte',  'cat_coffee', 'VANILLA LATTE', 'Caffè latte klasik yang diperkaya dengan sirup vanila aromatik manis lembut.', 30000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 10, FALSE),
('prod_caramel_latte',  'cat_coffee', 'CARAMEL LATTE', 'Espresso dan susu segar berpadu saus karamel lezat dengan rasa manis gurih khas.', 30000.00, '/menu/coffee/matchaExpressoDirty.png', TRUE, 10, FALSE),

-- 3. NON COFFEE
('prod_cookies_cream', 'cat_non_coffee', 'COOKIES & CREAM', 'Minuman creamy vanila dengan remukan biskuit cokelat renyah dan topping melimpah.', 30000.00, '/menu/nonCoffee/nonCoffeepng.png', TRUE, 10, FALSE),
('prod_red_velvet',    'cat_non_coffee', 'RED VELVET', 'Paduan rasa red velvet kaya rasa dengan susu segar creamy dan rasa cokelat lembut.', 28000.00, '/menu/nonCoffee/nonCoffeepng.png', TRUE, 10, FALSE),
('prod_taro',          'cat_non_coffee', 'TARO', 'Rasa taro manis legit beraroma khas berpadu sempurna dengan susu segar.', 28000.00, '/menu/nonCoffee/nonCoffeepng.png', TRUE, 10, FALSE),
('prod_lemon_tea',     'cat_non_coffee', 'LEMON TEA', 'Seduhan teh hitam pilihan dengan perasan lemon segar alami yang asam manis menyegarkan.', 22000.00, '/menu/nonCoffee/nonCoffeepng.png', TRUE, 10, FALSE),
('prod_lychee_tea',    'cat_non_coffee', 'LYCHEE TEA', 'Teh harum wangi dengan sirup leci manis segar dan buah leci utuh di dalamnya.', 25000.00, '/menu/nonCoffee/nonCoffeepng.png', TRUE, 10, FALSE),
('prod_mineral_water', 'cat_non_coffee', 'MINERAL WATER', 'Air mineral kemasan botol segar dan dingin untuk menjaga hidrasi tubuh.', 10000.00, '/menu/nonCoffee/nonCoffeepng.png', TRUE, 20, FALSE),

-- 4. FOOD
('prod_crib_chiken_salted_egg', 'cat_food', 'CRIB CHIKEN SALTED EGG', 'Ayam krispi renyah dibalut saus telur asin gurih harum daun kari di atas nasi hangat.', 38000.00, '/menu/food/cribComfortFriedRice.png', TRUE, 8, FALSE),
('prod_crib_nanban_rice_garlic','cat_food', 'CRIB NANBAN RICE GARLIC', 'Ayam nanban juicy dengan siraman saus tartar gurih di atas nasi aroma bawang putih spesial.', 38000.00, '/menu/food/cribComfortFriedRice.png', TRUE, 8, FALSE),
('prod_crib_fried_rice',        'cat_food', 'CRIB FRIED RICE', 'Nasi goreng racikan bumbu khas Crib Society dengan potongan ayam, telur, dan kerupuk renyah.', 32000.00, '/menu/food/cribComfortFriedRice.png', TRUE, 10, FALSE),
('prod_crib_comfort_fried_rice','cat_food', 'CRIB COMFORT FRIED RICE', 'Nasi goreng rempah istimewa berpadu sosis, telur mata sapi, dan acar segar pelengkap.', 35000.00, '/menu/food/cribComfortFriedRice.png', TRUE, 10, FALSE),

-- 5. MATCHA & YAKULT
('prod_matcha_latte',     'cat_matcha_yakult', 'MATCHA LATTE', 'Bubuk matcha murni berkualitas Jepang diseduh dengan susu hangat/dingin creamy berbusa halus.', 30000.00, '/menu/matchaYakult/matchaSeries.png', TRUE, 10, FALSE),
('prod_matcha_vanilla',   'cat_matcha_yakult', 'MATCHA VANILLA', 'Matcha latte gurih dipadukan dengan aroma vanila manis untuk rasa yang lebih lembut.', 32000.00, '/menu/matchaYakult/matchaSeries.png', TRUE, 10, FALSE),
('prod_peach_yakult',     'cat_matcha_yakult', 'PEACH YAKULT', 'Kombinasi asam manis Yakult segar dengan rasa buah peach manis yang harum dan dingin.', 26000.00, '/menu/matchaYakult/yakultSeries.png', TRUE, 10, FALSE),
('prod_pineapple_yakult', 'cat_matcha_yakult', 'PINEAPPLE YAKULT', 'Paduan probiotik Yakult dengan sari nanas segar, sangat cocok diminum di cuaca terik.', 26000.00, '/menu/matchaYakult/yakultSeries.png', TRUE, 10, FALSE),
('prod_strawberry_yakult','cat_matcha_yakult', 'STRAWBERRY YAKULT', 'Minuman probiotik Yakult berpadu sirup strawberry merah manis asam yang menggugah selera.', 26000.00, '/menu/matchaYakult/yakultSeries.png', TRUE, 10, FALSE),

-- 6. SNACKS
('prod_crib_bites_platter',      'cat_snack', 'CRIB BITES PLATTER', 'Platter kombinasi kentang goreng, sosis krispi, dan cireng renyah dengan saus cocolan nikmat.', 35000.00, '/menu/snack/frenchFries.png', TRUE, 10, FALSE),
('prod_french_fries',            'cat_snack', 'FRENCH FRIES', 'Kentang goreng renyah keemasan bertabur garam gurih dan rempah pilihan.', 22000.00, '/menu/snack/frenchFries.png', TRUE, 15, FALSE),
('prod_choco_cheese_toasty',     'cat_snack', 'CHOCO CHEESE TOASTY', 'Roti panggang mentega dengan isian cokelat lumer tebal dan parutan keju gurih melimpah.', 25000.00, '/menu/snack/crispyBananaChoChees.png', TRUE, 10, FALSE),
('prod_crispy_banana_cho_chees', 'cat_snack', 'CRISPY BANANA CHO & CHEES', 'Pisang goreng renyah krispi dengan limpahan cokelat leleh dan keju cheddar parut.', 25000.00, '/menu/snack/crispyBananaChoChees.png', TRUE, 10, FALSE),
('prod_cireng_rujak',            'cat_snack', 'CIRENG RUJAK', 'Cireng kenyal gurih digoreng garing disajikan dengan cocolan bumbu rujak pedas manis.', 20000.00, '/menu/snack/frenchFries.png', TRUE, 10, FALSE),
('prod_dimsum',                  'cat_snack', 'DIMSUM', 'Dimsum ayam kukus lembut juicy disajikan dengan saus chili oil pedas gurih.', 24000.00, '/menu/snack/frenchFries.png', TRUE, 10, FALSE),

-- 7. ADD ON
('prod_extra_shoot', 'cat_addon', 'EXTRA SHOOT', 'Tambahan satu shot espresso murni ekstra mantap untuk minuman kopi Anda.', 6000.00, '/menu/addOn/friedEgg.png', TRUE, 20, FALSE),
('prod_fried_egg',   'cat_addon', 'FRIED EGG', 'Telur mata sapi goreng setengah matang atau matang sempurna pelengkap hidangan makanan.', 6000.00, '/menu/addOn/friedEgg.png', TRUE, 15, FALSE),
('prod_extra_syrup', 'cat_addon', 'EXTRA SYRUP', 'Tambahan pilihan sirup Vanilla, Caramel, Palm, atau Hazelnut.', 5000.00, '/menu/addOn/friedEgg.png', TRUE, 15, FALSE);

-- ------------------------------------------------------------------------------
-- Product Variants Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `product_variants` (`id`, `product_id`, `name`, `price_delta`, `is_active`) VALUES
('var_aren_iced',       'prod_crib_aren_latte',         'Iced', 0.00, TRUE),
('var_aren_hot',        'prod_crib_aren_latte',         'Hot',  0.00, TRUE),
('var_butter_iced',     'prod_crib_butterscotch_latte', 'Iced', 0.00, TRUE),
('var_butter_hot',      'prod_crib_butterscotch_latte', 'Hot',  0.00, TRUE),
('var_choco_iced',      'prod_crib_chocolate_creamy',   'Iced', 0.00, TRUE),
('var_choco_hot',       'prod_crib_chocolate_creamy',   'Hot',  0.00, TRUE),
('var_red_iced',        'prod_crib_red_spark',          'Iced', 0.00, TRUE),
('var_mstr_iced',       'prod_crib_matcha_strawberry',  'Iced', 0.00, TRUE),

('var_cap_hot',         'prod_cappucino',       'Hot',  0.00, TRUE),
('var_cap_iced',        'prod_cappucino',       'Iced', 0.00, TRUE),
('var_latte_hot',       'prod_latte',           'Hot',  0.00, TRUE),
('var_latte_iced',      'prod_latte',           'Iced', 0.00, TRUE),
('var_ame_iced',        'prod_americano',       'Iced', 0.00, TRUE),
('var_ame_hot',         'prod_americano',       'Hot',  0.00, TRUE),
('var_str_cano',        'prod_strawberry_cano', 'Iced', 0.00, TRUE),
('var_pch_cano',        'prod_peach_cano',      'Iced', 0.00, TRUE),
('var_pin_cano',        'prod_pineapple_cano',  'Iced', 0.00, TRUE),
('var_van_iced',        'prod_vanilla_latte',   'Iced', 0.00, TRUE),
('var_van_hot',         'prod_vanilla_latte',   'Hot',  0.00, TRUE),
('var_car_iced',        'prod_caramel_latte',   'Iced', 0.00, TRUE),
('var_car_hot',         'prod_caramel_latte',   'Hot',  0.00, TRUE),

('var_ck_iced',         'prod_cookies_cream',   'Iced', 0.00, TRUE),
('var_ck_hot',          'prod_cookies_cream',   'Hot',  0.00, TRUE),
('var_rv_iced',         'prod_red_velvet',      'Iced', 0.00, TRUE),
('var_rv_hot',          'prod_red_velvet',      'Hot',  0.00, TRUE),
('var_taro_iced',       'prod_taro',            'Iced', 0.00, TRUE),
('var_taro_hot',        'prod_taro',            'Hot',  0.00, TRUE),
('var_lt_iced',         'prod_lemon_tea',       'Iced', 0.00, TRUE),
('var_lt_hot',          'prod_lemon_tea',       'Hot',  0.00, TRUE),
('var_ly_iced',         'prod_lychee_tea',      'Iced', 0.00, TRUE),
('var_mw_cold',         'prod_mineral_water',   'Cold', 0.00, TRUE),
('var_mw_norm',         'prod_mineral_water',   'Normal',0.00, TRUE),

('var_food_c1',         'prod_crib_chiken_salted_egg',  'Regular Portion', 0.00, TRUE),
('var_food_c2',         'prod_crib_nanban_rice_garlic', 'Regular Portion', 0.00, TRUE),
('var_food_c3',         'prod_crib_fried_rice',         'Regular Portion', 0.00, TRUE),
('var_food_c4',         'prod_crib_comfort_fried_rice', 'Regular Portion', 0.00, TRUE),

('var_ml_iced',         'prod_matcha_latte',      'Iced', 0.00, TRUE),
('var_ml_hot',          'prod_matcha_latte',      'Hot',  0.00, TRUE),
('var_mv_iced',         'prod_matcha_vanilla',    'Iced', 0.00, TRUE),
('var_mv_hot',          'prod_matcha_vanilla',    'Hot',  0.00, TRUE),
('var_py_iced',         'prod_peach_yakult',      'Iced', 0.00, TRUE),
('var_piny_iced',       'prod_pineapple_yakult',  'Iced', 0.00, TRUE),
('var_sy_iced',         'prod_strawberry_yakult', 'Iced', 0.00, TRUE),

('var_snk_plt',         'prod_crib_bites_platter',      'Sharing Size', 0.00, TRUE),
('var_snk_ff',          'prod_french_fries',            'Standard',     0.00, TRUE),
('var_snk_tst',         'prod_choco_cheese_toasty',     'Standard',     0.00, TRUE),
('var_snk_bna',         'prod_crispy_banana_cho_chees', 'Standard',     0.00, TRUE),
('var_snk_crg',         'prod_cireng_rujak',            'Standard',     0.00, TRUE),
('var_snk_dms',         'prod_dimsum',                  '4 Pcs',        0.00, TRUE),

('var_add_shot',        'prod_extra_shoot', '1 Shot',          0.00, TRUE),
('var_add_egg1',        'prod_fried_egg',   'Sunny Side Up',   0.00, TRUE),
('var_add_egg2',        'prod_fried_egg',   'Well Done',       0.00, TRUE),
('var_add_syr1',        'prod_extra_syrup', 'Vanilla Syrup',   0.00, TRUE),
('var_add_syr2',        'prod_extra_syrup', 'Caramel Syrup',   0.00, TRUE),
('var_add_syr3',        'prod_extra_syrup', 'Palm Sugar',      0.00, TRUE);

-- ------------------------------------------------------------------------------
-- Addons Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `addons` (`id`, `name`, `price`, `is_active`) VALUES
('add_extra_shoot', 'Extra Shoot', 6000.00, TRUE),
('add_fried_egg',   'Fried Egg',   6000.00, TRUE),
('add_extra_syrup', 'Extra Syrup', 5000.00, TRUE);

-- ------------------------------------------------------------------------------
-- Product Addons Seed (Junction)
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `product_addons` (`product_id`, `addon_id`) VALUES
('prod_crib_aren_latte', 'add_extra_shoot'),
('prod_crib_aren_latte', 'add_extra_syrup'),
('prod_crib_butterscotch_latte', 'add_extra_shoot'),
('prod_crib_butterscotch_latte', 'add_extra_syrup'),
('prod_crib_chocolate_creamy', 'add_extra_shoot'),
('prod_crib_chocolate_creamy', 'add_extra_syrup'),
('prod_crib_red_spark', 'add_extra_shoot'),
('prod_crib_red_spark', 'add_extra_syrup'),
('prod_crib_matcha_strawberry', 'add_extra_shoot'),
('prod_crib_matcha_strawberry', 'add_extra_syrup'),

('prod_cappucino', 'add_extra_shoot'),
('prod_cappucino', 'add_extra_syrup'),
('prod_latte', 'add_extra_shoot'),
('prod_latte', 'add_extra_syrup'),
('prod_americano', 'add_extra_shoot'),
('prod_americano', 'add_extra_syrup'),
('prod_strawberry_cano', 'add_extra_shoot'),
('prod_strawberry_cano', 'add_extra_syrup'),
('prod_peach_cano', 'add_extra_shoot'),
('prod_peach_cano', 'add_extra_syrup'),
('prod_pineapple_cano', 'add_extra_shoot'),
('prod_pineapple_cano', 'add_extra_syrup'),
('prod_vanilla_latte', 'add_extra_shoot'),
('prod_vanilla_latte', 'add_extra_syrup'),
('prod_caramel_latte', 'add_extra_shoot'),
('prod_caramel_latte', 'add_extra_syrup'),

('prod_cookies_cream', 'add_extra_syrup'),
('prod_red_velvet', 'add_extra_syrup'),
('prod_taro', 'add_extra_syrup'),
('prod_lemon_tea', 'add_extra_syrup'),
('prod_lychee_tea', 'add_extra_syrup'),

('prod_crib_chiken_salted_egg', 'add_fried_egg'),
('prod_crib_nanban_rice_garlic', 'add_fried_egg'),
('prod_crib_fried_rice', 'add_fried_egg'),
('prod_crib_comfort_fried_rice', 'add_fried_egg'),

('prod_matcha_latte', 'add_extra_shoot'),
('prod_matcha_latte', 'add_extra_syrup'),
('prod_matcha_vanilla', 'add_extra_shoot'),
('prod_matcha_vanilla', 'add_extra_syrup'),
('prod_peach_yakult', 'add_extra_syrup'),
('prod_pineapple_yakult', 'add_extra_syrup'),
('prod_strawberry_yakult', 'add_extra_syrup');

-- ------------------------------------------------------------------------------
-- Inventory Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `inventory` (`product_id`, `quantity`) VALUES
('prod_crib_aren_latte', 45),
('prod_crib_butterscotch_latte', 40),
('prod_crib_chocolate_creamy', 35),
('prod_crib_red_spark', 30),
('prod_crib_matcha_strawberry', 25),
('prod_cappucino', 50),
('prod_latte', 50),
('prod_americano', 60),
('prod_strawberry_cano', 40),
('prod_peach_cano', 40),
('prod_pineapple_cano', 40),
('prod_vanilla_latte', 45),
('prod_caramel_latte', 45),
('prod_cookies_cream', 35),
('prod_red_velvet', 35),
('prod_taro', 35),
('prod_lemon_tea', 50),
('prod_lychee_tea', 45),
('prod_mineral_water', 100),
('prod_crib_chiken_salted_egg', 25),
('prod_crib_nanban_rice_garlic', 25),
('prod_crib_fried_rice', 30),
('prod_crib_comfort_fried_rice', 30),
('prod_matcha_latte', 35),
('prod_matcha_vanilla', 35),
('prod_peach_yakult', 40),
('prod_pineapple_yakult', 40),
('prod_strawberry_yakult', 40),
('prod_crib_bites_platter', 30),
('prod_french_fries', 50),
('prod_choco_cheese_toasty', 35),
('prod_crispy_banana_cho_chees', 35),
('prod_cireng_rujak', 40),
('prod_dimsum', 35),
('prod_extra_shoot', 100),
('prod_fried_egg', 50),
('prod_extra_syrup', 80);

-- ------------------------------------------------------------------------------
-- Inventory Adjustments Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `inventory_adjustments` (`id`, `product_id`, `actor_user_id`, `previous_quantity`, `adjustment_quantity`, `resulting_quantity`, `reason`) VALUES
('adj_init_001', 'prod_crib_aren_latte', 'usr_owner_01', 0, 45, 45, 'Initial batch upload'),
('adj_init_002', 'prod_crib_comfort_fried_rice', 'usr_owner_01', 0, 30, 30, 'Initial kitchen stock');

-- ------------------------------------------------------------------------------
-- Sample Orders Seed
-- ------------------------------------------------------------------------------
INSERT IGNORE INTO `orders` (`id`, `order_number`, `status`, `payment_status`, `subtotal`, `discount_total`, `total`, `created_by`, `created_at`) VALUES
('ord_init_01', 'CSC-1001', 'COMPLETED', 'PAID', 68000.00, 0.00, 68000.00, 'usr_staff_01', NOW() - INTERVAL 1 HOUR),
('ord_init_02', 'CSC-1002', 'IN_PREPARATION', 'PAID', 41000.00, 0.00, 41000.00, 'usr_staff_02', NOW() - INTERVAL 15 MINUTE),
('ord_init_03', 'CSC-1003', 'PENDING', 'UNPAID', 28000.00, 0.00, 28000.00, 'usr_staff_01', NOW() - INTERVAL 5 MINUTE);

INSERT IGNORE INTO `order_items` (`id`, `order_id`, `product_id`, `product_name_snapshot`, `unit_price`, `quantity`, `line_total`, `variant_name_snapshot`, `addon_snapshot`, `created_at`) VALUES
('item_init_01', 'ord_init_01', 'prod_crib_aren_latte', 'CRIB AREN LATTE', 28000.00, 2, 68000.00, 'Iced', '[{"name":"Extra Shoot","price":6000}]', NOW() - INTERVAL 1 HOUR),
('item_init_02', 'ord_init_02', 'prod_crib_comfort_fried_rice', 'CRIB COMFORT FRIED RICE', 35000.00, 1, 41000.00, 'Regular Portion', '[{"name":"Fried Egg","price":6000}]', NOW() - INTERVAL 15 MINUTE),
('item_init_03', 'ord_init_03', 'prod_cappucino', 'CAPPUCINO', 28000.00, 1, 28000.00, 'Iced', NULL, NOW() - INTERVAL 5 MINUTE);

INSERT IGNORE INTO `discounts` (`id`, `order_id`, `type`, `value`, `amount_applied`, `label`, `created_at`) VALUES
('dsc_init_01', 'ord_init_01', 'percentage', 0.00, 0.00, 'None', NOW());

INSERT IGNORE INTO `payments` (`id`, `order_id`, `method`, `amount`, `status`, `external_reference`, `paid_at`, `created_at`) VALUES
('pay_init_01', 'ord_init_01', 'QRIS', 68000.00, 'PAID', 'QRIS-MID-001', NOW() - INTERVAL 55 MINUTE, NOW() - INTERVAL 1 HOUR),
('pay_init_02', 'ord_init_02', 'CASH', 41000.00, 'PAID', NULL, NOW() - INTERVAL 14 MINUTE, NOW() - INTERVAL 15 MINUTE);

INSERT IGNORE INTO `audit_logs` (`id`, `actor_user_id`, `action`, `entity_type`, `entity_id`, `metadata`) VALUES
('log_init_01', 'usr_owner_01', 'SYSTEM_INIT', 'database', 'main_db', '{"action":"Database seeded with Crib Society official menu catalog v2"}');

SET FOREIGN_KEY_CHECKS = 1;
