-- ============================================================================
-- SCHEMA & SEED SCRIPT : sql_video_games (MySQL 8.0+ Compatible)
-- Architecture : 25 tables interconnectées (Identité, Catalogue, In-Game, Économie)
-- Volume total : 80 000 lignes d'entraînement sourcées (WoW, CS2, Supermarket Sim, Dofus)
-- ============================================================================

DROP DATABASE IF EXISTS sql_video_games;
CREATE DATABASE sql_video_games CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sql_video_games;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- DOMAINE 1 : IDENTITÉ, RÔLES & RÉSEAU SOCIAL (5 tables)
-- ============================================================================

-- 1. Rôles utilisateurs
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    label VARCHAR(100) NOT NULL,
    description TEXT
) ENGINE=InnoDB;

-- 2. Utilisateurs (Sans colonne password, authentification SSO externe)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    external_auth_uuid CHAR(36) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    role_id INT NOT NULL,
    country_code CHAR(2) NOT NULL DEFAULT 'FR',
    reputation_score INT NOT NULL DEFAULT 100,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

-- 3. Profils joueurs étendus (1-1 avec users)
CREATE TABLE user_profiles (
    user_id INT PRIMARY KEY,
    bio VARCHAR(500),
    favorite_platform VARCHAR(30) NOT NULL DEFAULT 'PC',
    twitch_handle VARCHAR(60),
    discord_tag VARCHAR(60),
    total_playtime_hours INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Relations d'amitié / parrainage (Graphe social / récursivité)
CREATE TABLE user_friendships (
    id INT AUTO_INCREMENT PRIMARY KEY,
    requester_id INT NOT NULL,
    addressee_id INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACCEPTED',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_friendship (requester_id, addressee_id),
    CONSTRAINT fk_friend_req FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_friend_add FOREIGN KEY (addressee_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Badges communautaires obtenus
CREATE TABLE user_badges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    badge_code VARCHAR(50) NOT NULL,
    badge_title VARCHAR(100) NOT NULL,
    awarded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_badges_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- DOMAINE 2 : CATALOGUE, CATÉGORISATION & LIKES (6 tables)
-- ============================================================================

-- 6. Studios / Éditeurs
CREATE TABLE studios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    country VARCHAR(60) NOT NULL,
    founded_year SMALLINT NOT NULL
) ENGINE=InnoDB;

-- 7. Jeux vidéo (WoW, CS2, Supermarket Simulator, Dofus)
CREATE TABLE games (
    id INT AUTO_INCREMENT PRIMARY KEY,
    studio_id INT NOT NULL,
    slug VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(120) NOT NULL,
    release_year SMALLINT NOT NULL,
    base_currency_name VARCHAR(40) NOT NULL,
    pegi_rating TINYINT NOT NULL,
    CONSTRAINT fk_games_studio FOREIGN KEY (studio_id) REFERENCES studios(id)
) ENGINE=InnoDB;

-- 8. Catégories hiérarchiques (Auto-référencée pour WITH RECURSIVE)
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NULL,
    slug VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 9. Table pivot Jeux <-> Catégories
CREATE TABLE game_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    category_id INT NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE KEY uq_game_cat (game_id, category_id),
    CONSTRAINT fk_gc_game FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
    CONSTRAINT fk_gc_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10. Likes sur les jeux catégorisés (Table jointée demandée)
CREATE TABLE categorized_game_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    game_category_id INT NOT NULL,
    liked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_game_cat_like (user_id, game_category_id),
    CONSTRAINT fk_cgl_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_cgl_game_cat FOREIGN KEY (game_category_id) REFERENCES game_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 11. Patchs & Mises à jour majeures sourcées
CREATE TABLE game_patches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    version_code VARCHAR(30) NOT NULL,
    patch_title VARCHAR(150) NOT NULL,
    released_date DATE NOT NULL,
    CONSTRAINT fk_patches_game FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- DOMAINE 3 : UNIVERS IN-GAME, SERVEURS, PERSONNAGES & ITEMS (8 tables)
-- ============================================================================

-- 12. Serveurs / Royaumes / Régions
CREATE TABLE game_servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    server_name VARCHAR(80) NOT NULL,
    region VARCHAR(20) NOT NULL,
    server_type VARCHAR(40) NOT NULL,
    max_capacity INT NOT NULL DEFAULT 10000,
    CONSTRAINT fk_servers_game FOREIGN KEY (game_id) REFERENCES games(id)
) ENGINE=InnoDB;

-- 13. Classes / Archétypes / Rôles In-Game
CREATE TABLE game_classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    class_name VARCHAR(80) NOT NULL,
    archetype_role VARCHAR(40) NOT NULL,
    CONSTRAINT fk_classes_game FOREIGN KEY (game_id) REFERENCES games(id)
) ENGINE=InnoDB;

-- 14. Guildes / Équipes Esports / Franchises
CREATE TABLE guilds (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    server_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    tag VARCHAR(12) NOT NULL,
    faction_or_side VARCHAR(40) NOT NULL,
    created_at DATE NOT NULL,
    CONSTRAINT fk_guilds_game FOREIGN KEY (game_id) REFERENCES games(id),
    CONSTRAINT fk_guilds_server FOREIGN KEY (server_id) REFERENCES game_servers(id)
) ENGINE=InnoDB;

-- 15. Personnages / Profils In-Game des joueurs
CREATE TABLE characters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    game_id INT NOT NULL,
    server_id INT NOT NULL,
    class_id INT NOT NULL,
    guild_id INT NULL,
    character_name VARCHAR(80) NOT NULL,
    level_or_rank INT NOT NULL DEFAULT 1,
    currency_balance DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_char_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_char_game FOREIGN KEY (game_id) REFERENCES games(id),
    CONSTRAINT fk_char_server FOREIGN KEY (server_id) REFERENCES game_servers(id),
    CONSTRAINT fk_char_class FOREIGN KEY (class_id) REFERENCES game_classes(id),
    CONSTRAINT fk_char_guild FOREIGN KEY (guild_id) REFERENCES guilds(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 16. Référentiel des Objets / Skins / Dofus / Produits Rayon
CREATE TABLE items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    item_code VARCHAR(50) NOT NULL UNIQUE,
    item_name VARCHAR(120) NOT NULL,
    item_type VARCHAR(50) NOT NULL,
    rarity VARCHAR(30) NOT NULL,
    base_value DECIMAL(12, 2) NOT NULL,
    is_tradeable BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_items_game FOREIGN KEY (game_id) REFERENCES games(id)
) ENGINE=InnoDB;

-- 17. Inventaires des personnages
CREATE TABLE character_inventories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    acquired_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inv_char FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    CONSTRAINT fk_inv_item FOREIGN KEY (item_id) REFERENCES items(id)
) ENGINE=InnoDB;

-- 18. Cartes / Donjons / Zones / Rayons
CREATE TABLE game_maps_dungeons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    code_name VARCHAR(60) NOT NULL,
    display_name VARCHAR(120) NOT NULL,
    zone_type VARCHAR(40) NOT NULL,
    recommended_level INT NOT NULL DEFAULT 1,
    CONSTRAINT fk_maps_game FOREIGN KEY (game_id) REFERENCES games(id)
) ENGINE=InnoDB;

-- 19. Hauts-Faits / Succès / Trophées
CREATE TABLE achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    code VARCHAR(60) NOT NULL UNIQUE,
    title VARCHAR(120) NOT NULL,
    points INT NOT NULL DEFAULT 10,
    CONSTRAINT fk_ach_game FOREIGN KEY (game_id) REFERENCES games(id)
) ENGINE=InnoDB;

-- ============================================================================
-- DOMAINE 4 : ACTIVITÉ, SESSIONS, MATCHS, ÉCONOMIE & MODÉRATION (6 tables)
-- ============================================================================

-- 20. Succès débloqués par personnage
CREATE TABLE character_achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT NOT NULL,
    achievement_id INT NOT NULL,
    unlocked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_char_ach (character_id, achievement_id),
    CONSTRAINT fk_ca_char FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    CONSTRAINT fk_ca_ach FOREIGN KEY (achievement_id) REFERENCES achievements(id)
) ENGINE=InnoDB;

-- 21. Sessions de jeu / Matchs / Journées de magasin
CREATE TABLE game_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT NOT NULL,
    map_id INT NOT NULL,
    patch_id INT NOT NULL,
    started_at DATETIME NOT NULL,
    duration_minutes INT NOT NULL,
    outcome VARCHAR(20) NOT NULL,
    score_or_profit DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_sess_char FOREIGN KEY (character_id) REFERENCES characters(id),
    CONSTRAINT fk_sess_map FOREIGN KEY (map_id) REFERENCES game_maps_dungeons(id),
    CONSTRAINT fk_sess_patch FOREIGN KEY (patch_id) REFERENCES game_patches(id)
) ENGINE=InnoDB;

-- 22. Hôtel des Ventes / Marché Steam / Caisse Enregistreuse (Transactions)
CREATE TABLE market_listings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    seller_character_id INT NOT NULL,
    buyer_character_id INT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12, 2) NOT NULL,
    currency_code VARCHAR(15) NOT NULL,
    status VARCHAR(20) NOT NULL,
    listed_at DATETIME NOT NULL,
    sold_at DATETIME NULL,
    CONSTRAINT fk_mkt_game FOREIGN KEY (game_id) REFERENCES games(id),
    CONSTRAINT fk_mkt_seller FOREIGN KEY (seller_character_id) REFERENCES characters(id),
    CONSTRAINT fk_mkt_buyer FOREIGN KEY (buyer_character_id) REFERENCES characters(id),
    CONSTRAINT fk_mkt_item FOREIGN KEY (item_id) REFERENCES items(id)
) ENGINE=InnoDB;

-- 23. Avis et Notes des joueurs sur les jeux
CREATE TABLE game_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    game_id INT NOT NULL,
    rating TINYINT NOT NULL,
    review_title VARCHAR(150) NOT NULL,
    review_body TEXT,
    helpful_votes INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_game_review (user_id, game_id),
    CONSTRAINT fk_rev_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_rev_game FOREIGN KEY (game_id) REFERENCES games(id)
) ENGINE=InnoDB;

-- 24. Guides & Builds communautaires
CREATE TABLE community_guides (
    id INT AUTO_INCREMENT PRIMARY KEY,
    author_user_id INT NOT NULL,
    game_id INT NOT NULL,
    patch_id INT NOT NULL,
    title VARCHAR(180) NOT NULL,
    views_count INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_guide_author FOREIGN KEY (author_user_id) REFERENCES users(id),
    CONSTRAINT fk_guide_game FOREIGN KEY (game_id) REFERENCES games(id),
    CONSTRAINT fk_guide_patch FOREIGN KEY (patch_id) REFERENCES game_patches(id)
) ENGINE=InnoDB;

-- 25. Tickets de Modération / Anti-Cheat / Litiges HDV
CREATE TABLE moderation_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reporter_user_id INT NOT NULL,
    reported_user_id INT NOT NULL,
    game_id INT NOT NULL,
    assigned_mod_id INT NULL,
    reason_category VARCHAR(50) NOT NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'OPEN',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tkt_reporter FOREIGN KEY (reporter_user_id) REFERENCES users(id),
    CONSTRAINT fk_tkt_reported FOREIGN KEY (reported_user_id) REFERENCES users(id),
    CONSTRAINT fk_tkt_game FOREIGN KEY (game_id) REFERENCES games(id),
    CONSTRAINT fk_tkt_mod FOREIGN KEY (assigned_mod_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ============================================================================
-- PEUPLEMENT DES RÉFÉRENTIELS SOURCÉS (94 lignes fixes)
-- ============================================================================

-- 1. Rôles (5 lignes)
INSERT INTO roles (id, code, label, description) VALUES
(1, 'ADMIN', 'Administrateur Plateforme', 'Accès complet à la gestion de la base et des tournois'),
(2, 'MODERATOR', 'Modérateur Communautaire', 'Gestion des tickets anti-cheat, litiges HDV et avis'),
(3, 'CREATOR', 'Créateur de Contenu / Guide', 'Rédacteur de builds, guides de donjons et stratégies'),
(4, 'PRO_PLAYER', 'Joueur Compétitif / Vétéran', 'Joueur classé Mythique, Global Elite ou Ladder Astrub'),
(5, 'PLAYER', 'Joueur Standard', 'Membre inscrit de la communauté fangame');

-- 6. Studios (4 lignes)
INSERT INTO studios (id, name, country, founded_year) VALUES
(1, 'Blizzard Entertainment', 'USA', 1991),
(2, 'Valve Corporation', 'USA', 1996),
(3, 'Nokta Games', 'Turquie', 2020),
(4, 'Ankama Games', 'France', 2001);

-- 7. Jeux (4 lignes)
INSERT INTO games (id, studio_id, slug, title, release_year, base_currency_name, pegi_rating) VALUES
(1, 1, 'wow', 'World of Warcraft', 2004, 'GOLD', 12),
(2, 2, 'cs2', 'Counter-Strike 2', 2023, 'USD_STEAM', 18),
(3, 3, 'supermarket-sim', 'Supermarket Simulator', 2024, 'USD_CASH', 3),
(4, 4, 'dofus', 'Dofus', 2004, 'KAMAS', 12);

-- 8. Catégories hiérarchiques (8 lignes - Arbre à 3 niveaux)
INSERT INTO categories (id, parent_id, slug, name) VALUES
(1, NULL, 'root-all-games', 'Catalogue Global'),
(2, 1, 'rpg-universe', 'Jeux de Rôle & Progression'),
(3, 1, 'action-tactical', 'Action & Tactique'),
(4, 1, 'sim-management', 'Simulation & Gestion'),
(5, 2, 'mmorpg', 'MMORPG'),
(6, 2, 'tactical-rpg', 'RPG Tactique Tour par Tour'),
(7, 3, 'tactical-fps', 'FPS Tactique 5v5'),
(8, 4, 'retail-sim', 'Gestion de Commerce & Logistique');

-- 9. Jeux <-> Catégories (8 lignes)
INSERT INTO game_categories (id, game_id, category_id, is_primary) VALUES
(1, 1, 5, TRUE),   -- WoW -> MMORPG
(2, 1, 2, FALSE),  -- WoW -> RPG & Progression
(3, 2, 7, TRUE),   -- CS2 -> FPS Tactique
(4, 2, 3, FALSE),  -- CS2 -> Action & Tactique
(5, 3, 8, TRUE),   -- Supermarket Sim -> Gestion Commerce
(6, 3, 4, FALSE),  -- Supermarket Sim -> Simulation
(7, 4, 5, TRUE),   -- Dofus -> MMORPG
(8, 4, 6, FALSE);  -- Dofus -> RPG Tactique

-- 11. Patchs sourcés (8 lignes - 2 par jeu)
INSERT INTO game_patches (id, game_id, version_code, patch_title, released_date) VALUES
(1, 1, '11.0.2', 'The War Within - Saison 1 Palais des Nérub''ar', '2024-09-10'),
(2, 1, '11.1.0', 'Undermine(d) - Terremine', '2025-02-25'),
(3, 2, '1.40.3.1', 'Armory Update & Kilowatt Case', '2024-10-02'),
(4, 2, '1.40.8.0', 'Premier Season 2 & Train Rework', '2025-01-29'),
(5, 3, '0.2.1', 'Mise à jour Stockage, Étiquettes & Caissiers', '2024-05-18'),
(6, 3, '0.3.0', 'Épicerie Fine, Nettoyage & Commandes en Ligne', '2024-11-12'),
(7, 4, '2.73', 'Bataille de l''Aurore Pourpre', '2024-09-17'),
(8, 4, '3.0.0', 'Dofus Unity 3.0 - Refonte Graphique & Pionniers', '2024-12-03');

-- 12. Serveurs / Régions (8 lignes - 2 par jeu)
INSERT INTO game_servers (id, game_id, server_name, region, server_type, max_capacity) VALUES
(1, 1, 'Hyjal', 'EU-FR', 'PvE Normal', 25000),
(2, 1, 'Archimonde', 'EU-FR', 'PvP / Mythique', 22000),
(3, 2, 'EU-West (Frankfurt/Paris)', 'EU', 'Competitive 128-Subtick', 50000),
(4, 2, 'EU-North (Stockholm)', 'EU', 'Premier Matchmaking', 45000),
(5, 3, 'Local-FR-Store-01', 'EU-FR', 'Solo / Cloud Save', 10000),
(6, 3, 'Local-EU-Franchise-02', 'EU', 'Leaderboard Cloud', 10000),
(7, 4, 'Draconiros', 'INT-FR', 'Monocompte', 18000),
(8, 4, 'Dakal 1 (Unity)', 'INT-FR', 'Pionnier Monocompte', 20000);

-- 13. Classes / Rôles In-Game (12 lignes - 3 par jeu)
INSERT INTO game_classes (id, game_id, class_name, archetype_role) VALUES
(1, 1, 'Paladin Vindicte', 'DPS Mêlée'),
(2, 1, 'Prêtre Discipline', 'Soigneur'),
(3, 1, 'Guerrier Protection', 'Tank'),
(4, 2, 'Entry Fragger', 'Rifler / Ouverture'),
(5, 2, 'AWPer', 'Sniper Principal'),
(6, 2, 'In-Game Leader (IGL)', 'Stratège / Support'),
(7, 3, 'Gérant de Supérette', 'Logistique & Prix'),
(8, 3, 'Caissier Rapide', 'Encaissement'),
(9, 3, 'Magasinier Réassort', 'Gestion des Stocks'),
(10, 4, 'Iop Terre/Feu', 'DPS Mêlée'),
(11, 4, 'Eniripsa Soin', 'Soigneur / Soutien'),
(12, 4, 'Cra Multi-DoCrit', 'DPS Distance');

-- 16. Objets / Skins / Dofus / Produits Rayon (16 lignes - 4 par jeu)
INSERT INTO items (id, game_id, item_code, item_name, item_type, rarity, base_value, is_tradeable) VALUES
(1, 1, 'WOW-THUNDERFURY', 'Lame-tonnerre, épée bénie du Cherchevent', 'Arme Légendaire', 'Légendaire', 250000.00, FALSE),
(2, 1, 'WOW-FLASK-TEMPER', 'Flacon de maîtrise tempérée', 'Consommable Raid', 'Rare', 850.00, TRUE),
(3, 1, 'WOW-MOUNT-INVINCIBLE', 'Rênes d''Invincible', 'Monture', 'Épique', 500000.00, FALSE),
(4, 1, 'WOW-ORE-BISMUTH', 'Minerai de bismuth rang 3', 'Composant Métier', 'Commun', 145.00, TRUE),
(5, 2, 'CS2-AWP-DLORE', 'AWP | Dragon Lore (Factory New)', 'Skin Fusil Sniper', 'Covert', 12500.00, TRUE),
(6, 2, 'CS2-AK47-REDLINE', 'AK-47 | Redline (Field-Tested)', 'Skin Fusil Assaut', 'Classified', 28.50, TRUE),
(7, 2, 'CS2-KARAMBIT-FADE', 'Karambit | Fade (Factory New)', 'Couteau', 'Covert', 2650.00, TRUE),
(8, 2, 'CS2-CASE-KILOWATT', 'Kilowatt Case', 'Caisse', 'Base Grade', 1.15, TRUE),
(9, 3, 'SMS-CHOCOPIC', 'Céréales Chocopic (Carton x12)', 'Produit Rayon', 'Commun', 4.80, TRUE),
(10, 3, 'SMS-SUSHI-LARGE', 'Plateau Sushi Royal (Carton x8)', 'Produit Surgelé', 'Rare', 18.50, TRUE),
(11, 3, 'SMS-OLIVE-OIL', 'Huile d''Olive Extra Vierge', 'Épicerie', 'Peu Commun', 7.20, TRUE),
(12, 3, 'SMS-COFFEE-BIO', 'Café Moulu Arabica Bio', 'Boisson', 'Peu Commun', 6.40, TRUE),
(13, 4, 'DOF-OCRE', 'Dofus Ocre', 'Dofus Primordial', 'Légendaire', 45000000.00, TRUE),
(14, 4, 'DOF-VULBIS', 'Dofus Vulbis', 'Dofus', 'Légendaire', 38000000.00, TRUE),
(15, 4, 'DOF-PAIN-BLE', 'Pain au Blé Complet', 'Consommable Vie', 'Commun', 120.00, TRUE),
(16, 4, 'DOF-GALET-BRASILLANT', 'Galet Brasillant', 'Ressource Kolizéton', 'Rare', 185000.00, TRUE);

-- 18. Cartes / Donjons / Zones (8 lignes - 2 par jeu)
INSERT INTO game_maps_dungeons (id, game_id, code_name, display_name, zone_type, recommended_level) VALUES
(1, 1, 'NERUBAR-PALACE', 'Palais des Nérub''ar (Mythique)', 'Raid 20 Joueurs', 80),
(2, 1, 'ARA-KARA', 'Ara-Kara, la cité des Échos (+12)', 'Donjon Mythique+', 80),
(3, 2, 'de_mirage', 'Mirage', 'Carte Compétitive', 10),
(4, 2, 'de_inferno', 'Inferno', 'Carte Compétitive', 10),
(5, 3, 'STORE-DOWNTOWN', 'Supérette Centre-Ville (120m²)', 'Magasin Principal', 15),
(6, 3, 'STORAGE-ANNEX', 'Entrepôt Logistique & Frigos', 'Zone Stockage', 25),
(7, 4, 'COMTE-HAREBOURG', 'Donjon du Comte Harebourg', 'Donjon Frigost III', 200),
(8, 4, 'KOLOSSIUM-3V3', 'Arène du Kolizéum 3v3', 'PvP Classé', 200);

-- 19. Hauts-Faits / Succès (8 lignes - 2 par jeu)
INSERT INTO achievements (id, game_id, code, title, points) VALUES
(1, 1, 'WOW-CE-ANSUREK', 'Du sang neuf : Reine Ansurek Mythique', 50),
(2, 1, 'WOW-KSM-S1', 'Maître mythique de The War Within : Saison 1', 30),
(3, 2, 'CS2-ACE-MIRAGE', 'Ace sur Mirage en Premier', 40),
(4, 2, 'CS2-GLOBAL-25K', 'Élite Mondiale 25 000 CS Rating', 50),
(5, 3, 'SMS-ZERO-QUEUE', 'Zéro attente en caisse pendant 7 jours', 20),
(6, 3, 'SMS-EMPIRE-100K', 'Chiffre d''affaires cumulé de 100 000 $', 35),
(7, 4, 'DOF-6-DOFUS', 'Maître des Six Dofus Primordiaux', 50),
(8, 4, 'DOF-SOLO-HAREBOURG', 'Comte Harebourg (Duo / Mains Propres)', 45);

-- 14. Guildes / Équipes (5 lignes)
INSERT INTO guilds (id, game_id, server_id, name, tag, faction_or_side, created_at) VALUES
(1, 1, 1, 'Les Fils d''Orgrimmar', 'ORGRI', 'Horde', '2018-08-14'),
(2, 1, 2, 'L''Aube d''Hurlevent', 'AUBE', 'Alliance', '2019-03-22'),
(3, 2, 3, 'Vitality Academy Fan', 'VIT', 'CT/T Esports', '2023-10-01'),
(4, 3, 5, 'Fédération des Caissiers Rapides', 'BIPBIP', 'Indépendants', '2024-03-10'),
(5, 4, 7, 'Les Bouftous Galactiques', 'BOUF', 'Bontarien', '2020-11-05');

-- ============================================================================
-- MOTEUR DE GÉNÉRATION PROCÉDURALE MYSQL 8.0+ (79 906 lignes générées)
-- Total global = 94 (référentiels) + 79 906 = 80 000 lignes exactes !
-- ============================================================================

-- Augmentation temporaire de la limite de récursivité CTE pour générer jusqu'à 25 000 lignes
SET SESSION cte_max_recursion_depth = 30000;

-- Table utilitaire temporaire de nombres de 1 à 25 000
CREATE TEMPORARY TABLE seq_numbers (n INT PRIMARY KEY) ENGINE=Memory;

INSERT INTO seq_numbers (n)
WITH RECURSIVE cte_seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM cte_seq WHERE n < 25000
)
SELECT n FROM cte_seq;

-- ----------------------------------------------------------------------------
-- 2. USERS : 5 000 lignes
-- ----------------------------------------------------------------------------
INSERT INTO users (id, external_auth_uuid, username, email, role_id, country_code, reputation_score, is_verified, created_at)
SELECT
    n AS id,
    UUID() AS external_auth_uuid,
    CONCAT(
        ELT(1 + (n % 10), 'Kaelthas', 'ZywOoFan', 'CaissierPro', 'Goultard', 'Thrall', 'kennyS_JR', 'RayonMaster', 'Joris', 'Sylvanas', 'Dofusien'),
        '_', n
    ) AS username,
    CONCAT('player_', n, '@fangame-arena.fr') AS email,
    CASE
        WHEN n <= 10 THEN 1
        WHEN n <= 60 THEN 2
        WHEN n <= 360 THEN 3
        WHEN n <= 1100 THEN 4
        ELSE 5
    END AS role_id,
    ELT(1 + (n % 6), 'FR', 'FR', 'FR', 'BE', 'CH', 'CA') AS country_code,
    50 + (n % 451) AS reputation_score,
    (n % 3 = 0) AS is_verified,
    DATE_ADD('2023-01-01 08:00:00', INTERVAL (n * 190) MINUTE) AS created_at
FROM seq_numbers
WHERE n <= 5000;

-- ----------------------------------------------------------------------------
-- 3. USER_PROFILES : 5 000 lignes (1 par user)
-- ----------------------------------------------------------------------------
INSERT INTO user_profiles (user_id, bio, favorite_platform, twitch_handle, discord_tag, total_playtime_hours)
SELECT
    n AS user_id,
    CONCAT('Joueur passionné #', n, ' - Farm de donjons, rush B et réassort de Chocopic !') AS bio,
    ELT(1 + (n % 4), 'PC', 'PC', 'Steam Deck', 'MacOS') AS favorite_platform,
    IF(n % 4 = 0, CONCAT('twitch_tv_gamer_', n), NULL) AS twitch_handle,
    CONCAT('Gamer#', LPAD(n % 9999, 4, '0')) AS discord_tag,
    25 + ((n * 17) % 4500) AS total_playtime_hours
FROM seq_numbers
WHERE n <= 5000;

-- ----------------------------------------------------------------------------
-- 4. USER_FRIENDSHIPS : 6 000 lignes (Graphe social orienté sans cycle trivial)
-- ----------------------------------------------------------------------------
INSERT INTO user_friendships (id, requester_id, addressee_id, status, created_at)
SELECT
    n AS id,
    1 + ((n - 1) % 4900) AS requester_id,
    1 + ((n - 1) % 4900) + 1 + (n % 90) AS addressee_id,
    ELT(1 + (n % 5), 'ACCEPTED', 'ACCEPTED', 'ACCEPTED', 'ACCEPTED', 'PENDING') AS status,
    DATE_ADD('2023-06-01 10:00:00', INTERVAL (n * 45) MINUTE) AS created_at
FROM seq_numbers
WHERE n <= 6000;

-- ----------------------------------------------------------------------------
-- 5. USER_BADGES : 4 000 lignes
-- ----------------------------------------------------------------------------
INSERT INTO user_badges (id, user_id, badge_code, badge_title, awarded_at)
SELECT
    n AS id,
    1 + ((n * 7) % 5000) AS user_id,
    ELT(1 + (n % 5), 'FOUNDER_2023', 'BUG_HUNTER', 'TOP_TRADER', 'RAID_LEADER', 'CASHIER_GOD') AS badge_code,
    ELT(1 + (n % 5), 'Pionnier du Fangame', 'Chasseur de Bugs SQL', 'Magnat de l''HDV', 'Chef de Raid Mythique', 'Bip-Bip d''Or') AS badge_title,
    DATE_ADD('2023-09-01 12:00:00', INTERVAL (n * 60) MINUTE) AS awarded_at
FROM seq_numbers
WHERE n <= 4000;

-- ----------------------------------------------------------------------------
-- 10. CATEGORIZED_GAME_LIKES : 9 000 lignes (Likes sur jeux catégorisés)
-- ----------------------------------------------------------------------------
INSERT INTO categorized_game_likes (id, user_id, game_category_id, liked_at)
SELECT
    n AS id,
    1 + ((n - 1) % 5000) AS user_id,
    1 + ((n + FLOOR((n - 1) / 5000) * 3) % 8) AS game_category_id,
    DATE_ADD('2023-05-01 09:00:00', INTERVAL (n * 35) MINUTE) AS liked_at
FROM seq_numbers
WHERE n <= 9000;

-- ----------------------------------------------------------------------------
-- 15. CHARACTERS : 8 000 lignes (2 000 par jeu avec serveur/classe/guilde cohérents)
-- ----------------------------------------------------------------------------
INSERT INTO characters (id, user_id, game_id, server_id, class_id, guild_id, character_name, level_or_rank, currency_balance, created_at)
SELECT
    n AS id,
    1 + ((n * 3) % 5000) AS user_id,
    1 + ((n - 1) % 4) AS game_id,
    CASE (1 + ((n - 1) % 4))
        WHEN 1 THEN 1 + (n % 2)
        WHEN 2 THEN 3 + (n % 2)
        WHEN 3 THEN 5 + (n % 2)
        WHEN 4 THEN 7 + (n % 2)
    END AS server_id,
    CASE (1 + ((n - 1) % 4))
        WHEN 1 THEN 1 + (n % 3)
        WHEN 2 THEN 4 + (n % 3)
        WHEN 3 THEN 7 + (n % 3)
        WHEN 4 THEN 10 + (n % 3)
    END AS class_id,
    CASE (1 + ((n - 1) % 4))
        WHEN 1 THEN IF(n % 3 = 0, NULL, 1 + (n % 2))
        WHEN 2 THEN IF(n % 4 = 0, NULL, 3)
        WHEN 3 THEN IF(n % 5 = 0, NULL, 4)
        WHEN 4 THEN IF(n % 3 = 0, NULL, 5)
    END AS guild_id,
    CONCAT(
        ELT(1 + ((n - 1) % 4), 'Arthas', 'Headshot', 'SuperCaissier', 'Goultard'),
        '_Hero_', n
    ) AS character_name,
    CASE (1 + ((n - 1) % 4))
        WHEN 1 THEN 10 + (n % 71)       -- WoW niveau 10 à 80
        WHEN 2 THEN 1000 + (n % 24000)  -- CS2 Rating 1000 à 25000
        WHEN 3 THEN 1 + (n % 60)        -- Supermarket niveau magasin 1 à 60
        WHEN 4 THEN 20 + (n % 181)      -- Dofus niveau 20 à 200
    END AS level_or_rank,
    CASE (1 + ((n - 1) % 4))
        WHEN 1 THEN ROUND(500 + (n * 13.5) % 150000, 2)       -- Gold WoW
        WHEN 2 THEN ROUND(5 + (n * 2.3) % 3500, 2)            -- USD Steam
        WHEN 3 THEN ROUND(250 + (n * 19.7) % 45000, 2)        -- USD Cash
        WHEN 4 THEN ROUND(10000 + (n * 4500) % 25000000, 2)   -- Kamas Dofus
    END AS currency_balance,
    DATE_ADD('2023-02-01 10:00:00', INTERVAL (n * 50) MINUTE) AS created_at
FROM seq_numbers
WHERE n <= 8000;

-- ----------------------------------------------------------------------------
-- 17. CHARACTER_INVENTORIES : 12 000 lignes (Objets strictement liés au jeu du perso)
-- ----------------------------------------------------------------------------
INSERT INTO character_inventories (id, character_id, item_id, quantity, acquired_at)
SELECT
    n AS id,
    1 + ((n - 1) % 8000) AS character_id,
    (((1 + ((n - 1) % 8000)) - 1) % 4) * 4 + 1 + (n % 4) AS item_id,
    1 + (n % 25) AS quantity,
    DATE_ADD('2023-04-01 14:00:00', INTERVAL (n * 20) MINUTE) AS acquired_at
FROM seq_numbers
WHERE n <= 12000;

-- ----------------------------------------------------------------------------
-- 20. CHARACTER_ACHIEVEMENTS : 6 000 lignes (Succès strictement liés au jeu du perso)
-- ----------------------------------------------------------------------------
INSERT INTO character_achievements (id, character_id, achievement_id, unlocked_at)
SELECT
    n AS id,
    1 + ((n - 1) % 8000) AS character_id,
    (((1 + ((n - 1) % 8000)) - 1) % 4) * 2 + 1 + (n % 2) AS achievement_id,
    DATE_ADD('2023-07-01 16:00:00', INTERVAL (n * 40) MINUTE) AS unlocked_at
FROM seq_numbers
WHERE n <= 6000;

-- ----------------------------------------------------------------------------
-- 21. GAME_SESSIONS : 14 000 lignes (Maps & Patchs strictement liés au jeu du perso)
-- ----------------------------------------------------------------------------
INSERT INTO game_sessions (id, character_id, map_id, patch_id, started_at, duration_minutes, outcome, score_or_profit)
SELECT
    n AS id,
    1 + ((n - 1) % 8000) AS character_id,
    (((1 + ((n - 1) % 8000)) - 1) % 4) * 2 + 1 + (n % 2) AS map_id,
    (((1 + ((n - 1) % 8000)) - 1) % 4) * 2 + 1 + (n % 2) AS patch_id,
    DATE_ADD('2024-01-01 08:00:00', INTERVAL (n * 18) MINUTE) AS started_at,
    15 + (n % 165) AS duration_minutes,
    ELT(1 + (n % 4), 'VICTORY', 'VICTORY', 'DEFEAT', 'COMPLETED') AS outcome,
    ROUND(50 + ((n * 29.5) % 4500), 2) AS score_or_profit
FROM seq_numbers
WHERE n <= 14000;

-- ----------------------------------------------------------------------------
-- 22. MARKET_LISTINGS : 8 000 lignes (Vendeur, Acheteur, Item & Devise cohérents)
-- ----------------------------------------------------------------------------
INSERT INTO market_listings (id, game_id, seller_character_id, buyer_character_id, item_id, quantity, unit_price, currency_code, status, listed_at, sold_at)
SELECT
    n AS id,
    1 + ((n - 1) % 4) AS game_id,
    -- Vendeur appartenant exactement au jeu (1 + (n-1)%4)
    1 + ((n - 1) % 4) + 4 * ((n * 3) % 1999) AS seller_character_id,
    -- Acheteur du même jeu si SOLD
    IF(n % 3 = 0, NULL, 1 + ((n - 1) % 4) + 4 * (((n * 3) + 1) % 1999)) AS buyer_character_id,
    -- Item du même jeu
    ((n - 1) % 4) * 4 + 1 + (n % 4) AS item_id,
    1 + (n % 10) AS quantity,
    CASE (1 + ((n - 1) % 4))
        WHEN 1 THEN ROUND(120 + (n * 17.5) % 50000, 2)
        WHEN 2 THEN ROUND(1.50 + (n * 4.25) % 3000, 2)
        WHEN 3 THEN ROUND(2.50 + (n * 0.85) % 45, 2)
        WHEN 4 THEN ROUND(500 + (n * 1250) % 15000000, 2)
    END AS unit_price,
    ELT(1 + ((n - 1) % 4), 'GOLD', 'USD_STEAM', 'USD_CASH', 'KAMAS') AS currency_code,
    ELT(1 + (n % 3), 'SOLD', 'SOLD', 'ACTIVE') AS status,
    DATE_ADD('2024-02-01 10:00:00', INTERVAL (n * 25) MINUTE) AS listed_at,
    IF(n % 3 = 0, NULL, DATE_ADD('2024-02-01 12:30:00', INTERVAL (n * 25) MINUTE)) AS sold_at
FROM seq_numbers
WHERE n <= 8000;

-- ----------------------------------------------------------------------------
-- 23. GAME_REVIEWS : 1 500 lignes
-- ----------------------------------------------------------------------------
INSERT INTO game_reviews (id, user_id, game_id, rating, review_title, review_body, helpful_votes, created_at)
SELECT
    n AS id,
    1 + ((n - 1) % 1500) AS user_id,
    1 + ((n - 1) % 4) AS game_id,
    1 + (n % 5) AS rating,
    CONCAT('Mon avis détaillé sur ', ELT(1 + ((n - 1) % 4), 'World of Warcraft', 'Counter-Strike 2', 'Supermarket Simulator', 'Dofus'), ' #', n) AS review_title,
    'Super expérience communautaire, économie dynamique et méta passionnante.' AS review_body,
    (n % 120) AS helpful_votes,
    DATE_ADD('2024-01-15 11:00:00', INTERVAL (n * 90) MINUTE) AS created_at
FROM seq_numbers
WHERE n <= 1500;

-- ----------------------------------------------------------------------------
-- 24. COMMUNITY_GUIDES : 800 lignes
-- ----------------------------------------------------------------------------
INSERT INTO community_guides (id, author_user_id, game_id, patch_id, title, views_count, created_at)
SELECT
    n AS id,
    1 + ((n * 5) % 5000) AS author_user_id,
    1 + ((n - 1) % 4) AS game_id,
    ((n - 1) % 4) * 2 + 1 + (n % 2) AS patch_id,
    CONCAT(
        ELT(1 + ((n - 1) % 4),
            '[WoW] Route Mythique+ optimale',
            '[CS2] Smokes Insta Window Mirage',
            '[Supermarket] Agencement frigos rentabilité max',
            '[Dofus] Quête Dofus Ocre étape par étape'
        ),
        ' - Édition #', n
    ) AS title,
    100 + ((n * 37) % 25000) AS views_count,
    DATE_ADD('2024-03-01 15:00:00', INTERVAL (n * 180) MINUTE) AS created_at
FROM seq_numbers
WHERE n <= 800;

-- ----------------------------------------------------------------------------
-- 25. MODERATION_TICKETS : 606 lignes (Ajustement exact pour atteindre 80 000 lignes)
-- ----------------------------------------------------------------------------
INSERT INTO moderation_tickets (id, reporter_user_id, reported_user_id, game_id, assigned_mod_id, reason_category, status, created_at)
SELECT
    n AS id,
    1 + ((n * 11) % 4900) AS reporter_user_id,
    1 + ((n * 11) % 4900) + 5 AS reported_user_id,
    1 + ((n - 1) % 4) AS game_id,
    IF(n % 4 = 0, NULL, 11 + (n % 50)) AS assigned_mod_id,
    ELT(1 + (n % 4), 'WALLHACK_SUSPICION', 'KAMAS_RMT_BOT', 'NINJA_LOOT_RAID', 'PRIX_ABUSIF_CHOCOPIC') AS reason_category,
    ELT(1 + (n % 3), 'OPEN', 'IN_REVIEW', 'RESOLVED') AS status,
    DATE_ADD('2024-04-01 09:00:00', INTERVAL (n * 210) MINUTE) AS created_at
FROM seq_numbers
WHERE n <= 606;

DROP TEMPORARY TABLE seq_numbers;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- REQUÊTE DE CONTRÔLE DU VOLUME TOTAL (Doit afficher exactement 80 000 lignes)
-- ============================================================================
SELECT
    (SELECT COUNT(*) FROM roles) +
    (SELECT COUNT(*) FROM users) +
    (SELECT COUNT(*) FROM user_profiles) +
    (SELECT COUNT(*) FROM user_friendships) +
    (SELECT COUNT(*) FROM user_badges) +
    (SELECT COUNT(*) FROM studios) +
    (SELECT COUNT(*) FROM games) +
    (SELECT COUNT(*) FROM categories) +
    (SELECT COUNT(*) FROM game_categories) +
    (SELECT COUNT(*) FROM categorized_game_likes) +
    (SELECT COUNT(*) FROM game_patches) +
    (SELECT COUNT(*) FROM game_servers) +
    (SELECT COUNT(*) FROM game_classes) +
    (SELECT COUNT(*) FROM guilds) +
    (SELECT COUNT(*) FROM characters) +
    (SELECT COUNT(*) FROM items) +
    (SELECT COUNT(*) FROM character_inventories) +
    (SELECT COUNT(*) FROM game_maps_dungeons) +
    (SELECT COUNT(*) FROM achievements) +
    (SELECT COUNT(*) FROM character_achievements) +
    (SELECT COUNT(*) FROM game_sessions) +
    (SELECT COUNT(*) FROM market_listings) +
    (SELECT COUNT(*) FROM game_reviews) +
    (SELECT COUNT(*) FROM community_guides) +
    (SELECT COUNT(*) FROM moderation_tickets) AS total_rows_inserted;
