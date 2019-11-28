/*
Navicat SQLite Data Transfer

Source Server         : GarrysModDS
Source Server Version : 30714
Source Host           : :0

Target Server Type    : SQLite
Target Server Version : 30714
File Encoding         : 65001

Date: 2015-05-16 22:02:46
*/

PRAGMA foreign_keys = OFF;

-- ----------------------------
-- Table structure for game_admins
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_admins";
CREATE TABLE "game_admins" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"szSteam"  TEXT NOT NULL,
"nLevel"  INTEGER NOT NULL DEFAULT 0
);

-- ----------------------------
-- Records of game_admins
-- ----------------------------

-- ----------------------------
-- Table structure for game_bots
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_bots";
CREATE TABLE "game_bots" (
"szMap"  TEXT NOT NULL,
"szPlayer"  TEXT,
"nTime"  INTEGER NOT NULL,
"nStyle"  INTEGER NOT NULL,
"szSteam"  TEXT NOT NULL,
"szDate"  TEXT
);

-- ----------------------------
-- Records of game_bots
-- ----------------------------

-- ----------------------------
-- Table structure for game_logs
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_logs";
CREATE TABLE "game_logs" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"szData"  TEXT,
"szDate"  TEXT DEFAULT NULL,
"szAdminSteam"  TEXT NOT NULL,
"szAdminName"  TEXT DEFAULT NULL
);

-- ----------------------------
-- Records of game_logs
-- ----------------------------

-- ----------------------------
-- Table structure for game_map
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_map";
CREATE TABLE "game_map" (
"szMap"  TEXT NOT NULL,
"nMultiplier"  INTEGER NOT NULL DEFAULT 1,
"nBonusMultiplier"  INTEGER,
"nPlays"  INTEGER NOT NULL DEFAULT 0,
"nOptions"  INTEGER,
"szDate"  TEXT,
PRIMARY KEY ("szMap" ASC)
);

-- ----------------------------
-- Records of game_map
-- ----------------------------
INSERT INTO "main"."game_map" VALUES ('bhop_deluxe', 5, null, 0, null, '2015-05-09 01:25:13');
INSERT INTO "main"."game_map" VALUES ('bhop_1n5an3_hard', 10, null, 0, null, '2015-05-09 01:40:43');
INSERT INTO "main"."game_map" VALUES ('bhop_1n5an3_harder', 20, null, 0, null, '2015-05-09 01:45:48');
INSERT INTO "main"."game_map" VALUES ('bhop_3d', 30, null, 0, null, '2015-05-09 01:46:51');
INSERT INTO "main"."game_map" VALUES ('bhop_absolutebhop_v4', 80, null, 0, null, '2015-05-09 01:50:04');
INSERT INTO "main"."game_map" VALUES ('bhop_adventure_final', 35, null, 0, null, '2015-05-09 01:56:11');
INSERT INTO "main"."game_map" VALUES ('bhop_advi_new', 40, null, 0, null, '2015-05-09 02:00:29');
INSERT INTO "main"."game_map" VALUES ('bhop_algebradude', 20, null, 0, null, '2015-05-09 02:02:48');
INSERT INTO "main"."game_map" VALUES ('bhop_angkor', 100, null, 0, null, '2015-05-09 02:04:03');
INSERT INTO "main"."game_map" VALUES ('bhop_arcane_v1', 250, null, 0, null, '2015-05-09 02:06:48');
INSERT INTO "main"."game_map" VALUES ('bhop_arcane2_a06', 120, null, 0, null, '2015-05-09 02:10:16');
INSERT INTO "main"."game_map" VALUES ('bhop_aquatic_v1', 40, null, 0, null, '2015-05-09 02:14:51');
INSERT INTO "main"."game_map" VALUES ('bhop_areaportal_v1', 85, null, 0, null, '2015-05-09 02:16:16');
INSERT INTO "main"."game_map" VALUES ('bhop_autobadges', 90, null, 0, null, '2015-05-09 02:18:58');
INSERT INTO "main"."game_map" VALUES ('bhop_awful2', 170, null, 0, null, '2015-05-09 02:32:55');
INSERT INTO "main"."game_map" VALUES ('bhop_awful3', 65, null, 0, null, '2015-05-09 02:35:52');
INSERT INTO "main"."game_map" VALUES ('bhop_bkz_goldbhop', 30, null, 0, null, '2015-05-09 02:37:26');
INSERT INTO "main"."game_map" VALUES ('bhop_blackrockshooter', 55, null, 0, null, '2015-05-09 02:38:33');
INSERT INTO "main"."game_map" VALUES ('bhop_blue_aux', 30, null, 0, null, '2015-05-09 02:42:11');
INSERT INTO "main"."game_map" VALUES ('bhop_bob_v1', 40, null, 0, null, '2015-05-09 02:46:24');
INSERT INTO "main"."game_map" VALUES ('bhop_cartoons', 100, null, 0, null, '2015-05-09 02:47:53');
INSERT INTO "main"."game_map" VALUES ('bhop_ch4', 40, null, 0, null, '2015-05-09 02:48:37');
INSERT INTO "main"."game_map" VALUES ('bhop_choice', 30, null, 0, null, '2015-05-09 02:51:24');
INSERT INTO "main"."game_map" VALUES ('bhop_christmas', 50, null, 0, null, '2015-05-09 03:00:17');
INSERT INTO "main"."game_map" VALUES ('bhop_aztec_fixed', 5, null, 0, null, '2015-05-09 03:04:22');
INSERT INTO "main"."game_map" VALUES ('bhop_cobblestone', 15, null, 0, null, '2015-05-09 03:05:29');
INSERT INTO "main"."game_map" VALUES ('bhop_combine', 15, null, 0, null, '2015-05-09 03:07:09');
INSERT INTO "main"."game_map" VALUES ('bhop_danmark', 80, null, 0, null, '2015-05-09 03:07:38');
INSERT INTO "main"."game_map" VALUES ('bhop_desolation', 25, null, 0, null, '2015-05-09 03:10:09');
INSERT INTO "main"."game_map" VALUES ('bhop_duality_v2', 30, null, 0, null, '2015-05-09 03:11:33');
INSERT INTO "main"."game_map" VALUES ('bhop_eazy', 10, null, 0, null, '2015-05-09 03:12:49');
INSERT INTO "main"."game_map" VALUES ('bhop_eazy_v2', 15, null, 0, null, '2015-05-09 03:13:12');
INSERT INTO "main"."game_map" VALUES ('bhop_extan', 150, null, 0, null, '2015-05-09 03:13:45');
INSERT INTO "main"."game_map" VALUES ('bhop_factory_v2', 140, null, 0, null, '2015-05-09 03:15:20');
INSERT INTO "main"."game_map" VALUES ('bhop_freedompuppies_new', 10, null, 0, null, '2015-05-09 03:18:07');
INSERT INTO "main"."game_map" VALUES ('bhop_fresh', 70, null, 0, null, '2015-05-09 11:02:30');
INSERT INTO "main"."game_map" VALUES ('bhop_glassy', 40, null, 0, null, '2015-05-09 12:35:38');
INSERT INTO "main"."game_map" VALUES ('bhop_green_fixx', 15, null, 0, null, '2015-05-09 12:37:07');
INSERT INTO "main"."game_map" VALUES ('bhop_hopi_noproblem_v1', 65, null, 0, null, '2015-05-09 12:43:27');
INSERT INTO "main"."game_map" VALUES ('bhop_icebase', 20, null, 0, null, '2015-05-09 12:46:48');
INSERT INTO "main"."game_map" VALUES ('bhop_impulse', 30, null, 0, null, '2015-05-09 12:52:12');
INSERT INTO "main"."game_map" VALUES ('bhop_it_nine-up', 40, null, 0, null, '2015-05-09 12:53:43');
INSERT INTO "main"."game_map" VALUES ('bhop_japan', 65, null, 0, null, '2015-05-09 12:57:15');
INSERT INTO "main"."game_map" VALUES ('bhop_jegg', 110, null, 0, null, '2015-05-09 13:00:26');
INSERT INTO "main"."game_map" VALUES ('bhop_jierdas', 10, null, 0, null, '2015-05-09 13:03:52');
INSERT INTO "main"."game_map" VALUES ('bhop_k26000_b2', 10, null, 0, null, '2015-05-09 13:07:18');
INSERT INTO "main"."game_map" VALUES ('bhop_kiwi_cwfx', 10, null, 0, null, '2015-05-09 13:08:42');
INSERT INTO "main"."game_map" VALUES ('bhop_kz_ocean', 5, null, 0, null, '2015-05-09 13:10:42');
INSERT INTO "main"."game_map" VALUES ('bhop_kz_ravine', 5, null, 0, null, '2015-05-09 13:11:37');
INSERT INTO "main"."game_map" VALUES ('bhop_kz_volcano', 10, null, 0, null, '2015-05-09 13:28:50');
INSERT INTO "main"."game_map" VALUES ('bhop_larena_nodoors', 35, null, 0, null, '2015-05-09 14:04:55');
INSERT INTO "main"."game_map" VALUES ('bhop_legenda_v2', 10, null, 0, null, '2015-05-09 14:27:43');
INSERT INTO "main"."game_map" VALUES ('bhop_legion', 25, null, 0, null, '2015-05-09 14:31:43');
INSERT INTO "main"."game_map" VALUES ('bhop_lego', 150, null, 0, null, '2015-05-09 14:36:47');
INSERT INTO "main"."game_map" VALUES ('bhop_mapsuck', 15, null, 0, null, '2015-05-09 14:41:10');
INSERT INTO "main"."game_map" VALUES ('bhop_mario_fxd', 160, null, 0, null, '2015-05-09 15:05:43');
INSERT INTO "main"."game_map" VALUES ('bhop_mcginis_fix', 130, null, 0, null, '2015-05-09 15:22:07');
INSERT INTO "main"."game_map" VALUES ('bhop_messs_123', 60, null, 0, null, '2015-05-09 15:26:46');
INSERT INTO "main"."game_map" VALUES ('bhop_militia_v2', 15, null, 0, null, '2015-05-09 15:36:16');
INSERT INTO "main"."game_map" VALUES ('bhop_mist_3', 35, null, 0, null, '2015-05-09 16:32:40');
INSERT INTO "main"."game_map" VALUES ('bhop_monster_beta', 80, null, 0, null, '2015-05-09 16:39:13');
INSERT INTO "main"."game_map" VALUES ('bhop_monster_jam', 60, null, 0, null, '2015-05-09 16:45:54');
INSERT INTO "main"."game_map" VALUES ('bhop_nacho_libre_simo', 5, null, 0, null, '2015-05-09 16:48:05');
INSERT INTO "main"."game_map" VALUES ('bhop_noobhop_exg', 10, null, 0, null, '2015-05-09 16:50:16');
INSERT INTO "main"."game_map" VALUES ('bhop_paisaweeaboo_beta3', 140, null, 0, null, '2015-05-09 16:55:17');
INSERT INTO "main"."game_map" VALUES ('bhop_pinky', 10, null, 0, null, '2015-05-09 17:05:07');
INSERT INTO "main"."game_map" VALUES ('bhop_pro_bhopper_mp', 10, null, 0, null, '2015-05-09 17:06:33');
INSERT INTO "main"."game_map" VALUES ('bhop_reding', 45, null, 0, null, '2015-05-09 17:14:09');
INSERT INTO "main"."game_map" VALUES ('bhop_sahara', 30, null, 0, null, '2015-05-09 17:33:16');
INSERT INTO "main"."game_map" VALUES ('bhop_sourcejump', 10, null, 0, null, '2015-05-09 17:43:52');
INSERT INTO "main"."game_map" VALUES ('bhop_space', 40, null, 0, null, '2015-05-09 18:07:09');
INSERT INTO "main"."game_map" VALUES ('bhop_speedrun_valley', 60, null, 0, null, '2015-05-09 18:38:52');
INSERT INTO "main"."game_map" VALUES ('bhop_jx', 10, null, 0, null, '2015-05-09 19:42:43');
INSERT INTO "main"."game_map" VALUES ('bhop_strafe_summer', 40, null, 0, null, '2015-05-09 19:53:08');
INSERT INTO "main"."game_map" VALUES ('bhop_swik_b1', 30, null, 0, null, '2015-05-09 20:06:56');
INSERT INTO "main"."game_map" VALUES ('bhop_tasku', 25, null, 0, null, '2015-05-09 20:09:06');
INSERT INTO "main"."game_map" VALUES ('bhop_thc_egypt', 75, null, 0, null, '2015-05-09 20:29:51');
INSERT INTO "main"."game_map" VALUES ('bhop_tut_v2', 35, null, 0, null, '2015-05-09 20:35:17');
INSERT INTO "main"."game_map" VALUES ('bhop_twisted', 95, null, 0, null, '2015-05-09 20:38:04');
INSERT INTO "main"."game_map" VALUES ('bhop_veritas', 120, null, 0, null, '2015-05-09 20:44:33');
INSERT INTO "main"."game_map" VALUES ('bhop_wayz', 125, null, 0, null, '2015-05-09 20:49:23');
INSERT INTO "main"."game_map" VALUES ('bhop_white', 60, null, 0, null, '2015-05-09 20:53:37');
INSERT INTO "main"."game_map" VALUES ('bhop_soaatana', 30, null, 0, null, '2015-05-09 20:57:22');
INSERT INTO "main"."game_map" VALUES ('bhop_dretox', 20, null, 0, null, '2015-05-09 21:03:04');
INSERT INTO "main"."game_map" VALUES ('bhop_speedrun_skyline', 30, null, 0, null, '2015-05-09 21:06:27');
INSERT INTO "main"."game_map" VALUES ('bhop_jegypt', 50, null, 0, null, '2015-05-09 21:11:00');
INSERT INTO "main"."game_map" VALUES ('bhop_0', 30, null, 0, null, '2015-05-09 21:17:52');
INSERT INTO "main"."game_map" VALUES ('bhop_soft', 100, null, 0, null, '2015-05-09 21:23:39');
INSERT INTO "main"."game_map" VALUES ('bhop_jib_jib', 20, null, 0, null, '2015-05-09 21:26:42');
INSERT INTO "main"."game_map" VALUES ('bhop_pologos_fix', 40, null, 0, null, '2015-05-09 21:34:41');
INSERT INTO "main"."game_map" VALUES ('bhop_mist_4', 75, null, 0, null, '2015-05-12 16:56:15');
INSERT INTO "main"."game_map" VALUES ('bhop_snowy', 150, null, 0, null, '2015-05-13 03:59:32');
INSERT INTO "main"."game_map" VALUES ('bhop_whoevenbhops_final', 30, null, 0, null, '2015-05-13 04:07:38');
INSERT INTO "main"."game_map" VALUES ('bhop_hexag0n', 40, null, 0, null, '2015-05-13 04:51:12');
INSERT INTO "main"."game_map" VALUES ('bhop_scrollcity', 30, null, 0, null, '2015-05-13 05:00:16');
INSERT INTO "main"."game_map" VALUES ('bhop_proving_a_point', 10, null, 0, null, '2015-05-13 11:36:42');
INSERT INTO "main"."game_map" VALUES ('bhop_seiz', 10, null, 0, null, '2015-05-13 11:42:19');
INSERT INTO "main"."game_map" VALUES ('bhop_bluerace', 40, null, 0, null, '2015-05-13 11:44:39');
INSERT INTO "main"."game_map" VALUES ('bhop_smokee_2_fix', 170, null, 0, null, '2015-05-13 11:52:29');
INSERT INTO "main"."game_map" VALUES ('bhop_giga_citadel_v2', 200, null, 0, null, '2015-05-13 12:00:22');
INSERT INTO "main"."game_map" VALUES ('bhop_omn', 200, null, 0, null, '2015-05-13 12:04:00');
INSERT INTO "main"."game_map" VALUES ('bhop_pims_cwfx', 15, null, 0, null, '2015-05-13 12:06:57');
INSERT INTO "main"."game_map" VALUES ('bhop_screelee', 210, null, 0, null, '2015-05-13 12:17:25');
INSERT INTO "main"."game_map" VALUES ('bhop_shrubhop', 35, null, 0, null, '2015-05-13 12:24:39');
INSERT INTO "main"."game_map" VALUES ('bhop_kz_chillhop', 20, null, 0, null, '2015-05-16 12:55:16');
INSERT INTO "main"."game_map" VALUES ('bhop_kz_cartooncastle', 5, null, 0, null, '2015-05-16 13:04:00');
INSERT INTO "main"."game_map" VALUES ('bhop_kz_femto', 35, null, 0, null, '2015-05-16 13:07:51');
INSERT INTO "main"."game_map" VALUES ('bhop_kz_mix_journeys', 60, null, 0, null, '2015-05-16 13:11:11');
INSERT INTO "main"."game_map" VALUES ('bhop_kerpele', 30, null, 0, null, '2015-05-16 13:20:01');
INSERT INTO "main"."game_map" VALUES ('bhop_paskaaa', 45, null, 0, null, '2015-05-16 13:24:42');
INSERT INTO "main"."game_map" VALUES ('bhop_despondent', 180, null, 0, null, '2015-05-16 13:33:12');
INSERT INTO "main"."game_map" VALUES ('bhop_aster', 45, null, 0, null, '2015-05-16 13:41:13');
INSERT INTO "main"."game_map" VALUES ('bhop_tropics', 40, null, 0, null, '2015-05-16 13:45:31');
INSERT INTO "main"."game_map" VALUES ('bhop_sketchy_v4', 30, null, 0, null, '2015-05-16 13:50:09');
INSERT INTO "main"."game_map" VALUES ('bhop_jungle3k', 30, null, 0, null, '2015-05-16 13:54:51');
INSERT INTO "main"."game_map" VALUES ('bhop_slayer_fixed', 15, null, 0, null, '2015-05-16 13:56:33');
INSERT INTO "main"."game_map" VALUES ('bhop_voyage', 170, null, 0, null, '2015-05-16 17:53:06');
INSERT INTO "main"."game_map" VALUES ('bhop_badges_mini', 185, null, 0, null, '2015-05-16 18:04:57');
INSERT INTO "main"."game_map" VALUES ('bhop_ogel', 55, null, 0, null, '2015-05-16 18:21:22');
INSERT INTO "main"."game_map" VALUES ('bhop_fuckfear_fix', 120, null, 0, null, '2015-05-16 18:23:26');
INSERT INTO "main"."game_map" VALUES ('bhop_strafe_winter', 90, null, 0, null, '2015-05-16 18:29:31');
INSERT INTO "main"."game_map" VALUES ('bhop_speedrun_habitat_v2', 25, null, 0, null, '2015-05-16 18:32:53');

-- ----------------------------
-- Table structure for game_reports
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_reports";
CREATE TABLE "game_reports" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"nType"  INTEGER NOT NULL,
"szComment"  TEXT,
"szDate" TEXT,
"szReporter"  TEXT NOT NULL,
"szHandled"  TEXT
);

-- ----------------------------
-- Records of game_reports
-- ----------------------------

-- ----------------------------
-- Table structure for game_times
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_times";
CREATE TABLE "game_times" (
"szUID"  TEXT NOT NULL,
"szPlayer"  TEXT,
"szMap"  TEXT NOT NULL,
"nStyle"  INTEGER NOT NULL,
"nTime"  INTEGER NOT NULL,
"nPoints"  INTEGER NOT NULL,
"nDate"  INTEGER,
"vData"  TEXT
);

-- ----------------------------
-- Records of game_times
-- ----------------------------

-- ----------------------------
-- Table structure for game_zones
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_zones";
CREATE TABLE "game_zones" (
"szMap"  TEXT NOT NULL,
"nType"  INTEGER NOT NULL,
"vPos1"  TEXT,
"vPos2"  TEXT
);

-- ----------------------------
-- Records of game_zones
-- ----------------------------
INSERT INTO "main"."game_zones" VALUES ('bhop_3d', 0, '-495.97 16.03 0.03', '-80.03 431.88 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_3d', 1, '6672.03 -4719.97 -319.97', '7087.97 -4303.90 80.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_autobadges', 0, '-5230.07 4336.64 2112.03', '-5104.01 4463.97 2240.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_autobadges', 1, '-4752.28 7952.03 3008.03', '-4578.80 8111.97 3136.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_autobadges', 2, '-4398.82 7952.03 3008.03', '-4208.03 8112.00 3136.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_autobadges', 3, '-6607.97 3216.03 2080.03', '-6569.38 3254.02 2208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_1n5an3_hard', 0, '-496.00 -496.33 64.03', '-16.03 -16.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_1n5an3_hard', 1, '1744.03 -496.61 64.03', '2223.97 -16.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_1n5an3_harder', 0, '-495.97 -412.05 64.03', '-16.03 -16.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_1n5an3_harder', 1, '1744.03 -497.14 64.03', '2223.97 -16.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_2flocci2furious', 0, '-15019.39 -1725.19 4300.93', '-14777.89 -1401.86 4428.93');
INSERT INTO "main"."game_zones" VALUES ('bhop_2flocci2furious', 1, '-10956.97 12048.03 -10311.97', '-4845.00 13039.97 -8270.27');
INSERT INTO "main"."game_zones" VALUES ('bhop_aux_a9', 0, '-14848.20 -14080.63 14528.03', '-14668.50 -13567.98 14656.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aux_a9', 1, '8208.86 10768.01 -12287.97', '8687.97 11759.97 -11775.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_angkor', 0, '-1888.00 -157.03 2048.03', '-1715.49 -0.03 2176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_angkor', 1, '785.96 -1467.44 -682.43', '1580.55 -561.71 -517.91');
INSERT INTO "main"."game_zones" VALUES ('bhop_arcane_v1', 0, '1415.52 -495.97 14400.03', '1520.19 496.00 14528.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_arcane_v1', 1, '-10223.97 -13935.99 -14719.97', '-9232.00 -13329.39 -14591.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_areaportal_v1', 0, '10688.03 -9541.00 -424.97', '11235.99 -9369.20 -296.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_areaportal_v1', 1, '-8852.00 -7751.24 -424.97', '-8298.59 -7582.03 -296.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_adventure_final', 1, '2648.01 10448.06 -223.97', '2799.97 11183.97 -95.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_adventure_final', 0, '1232.03 -2513.02 0.03', '1712.00 -2328.03 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_advi_new', 0, '1266.01 2523.00 -4944.71', '2194.97 2873.14 -4816.71');
INSERT INTO "main"."game_zones" VALUES ('bhop_advi_new', 1, '602.02 -229.97 -762.34', '978.18 230.00 -634.34');
INSERT INTO "main"."game_zones" VALUES ('bhop_ananas', 1, '10374.00 -3307.00 2765.03', '11841.96 281.00 3277.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_ananas', 2, '6018.51 -2303.76 427.03', '6062.97 -2088.96 555.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_ananas', 3, '5956.41 -3964.01 585.28', '6100.95 -3868.93 727.04');
INSERT INTO "main"."game_zones" VALUES ('bhop_ananas', 0, '8296.03 -5382.22 64.03', '8589.97 -5086.00 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_airflow_v2_fix', 1, '-1263.97 242.01 96.03', '-944.01 463.99 196.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_airflow_v2_fix', 0, '16.01 -623.99 96.03', '367.98 -401.67 196.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_algebradude', 0, '3215.77 -271.97 -47.97', '3407.97 463.99 80.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_algebradude', 1, '-271.97 1392.03 -47.97', '-106.32 1743.97 80.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aquatic_v1', 0, '32.03 -160.75 16.03', '241.58 -32.03 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aquatic_v1', 1, '-916.00 706.02 16.03', '-723.26 980.97 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_at_night', 0, '-687.97 -431.97 96.03', '-481.10 -272.03 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_austere', 0, '76.54 -303.97 80.03', '182.97 239.97 208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_austere', 1, '-2102.97 -2669.35 2155.03', '-60.03 -2377.03 2283.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_badges', 1, '9744.03 10768.02 -6655.97', '11695.97 12624.45 -6527.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_badges', 2, '-12528.75 676.70 -9121.41', '-12450.44 774.09 -8918.19');
INSERT INTO "main"."game_zones" VALUES ('bhop_badges', 3, '-1649.82 -7486.77 -13269.25', '-1558.58 -7418.75 -13140.13');
INSERT INTO "main"."game_zones" VALUES ('bhop_badges', 0, '-6927.32 6831.48 736.03', '-6512.22 7055.97 864.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bitches_fix', 0, '-301.98 19.56 128.03', '172.13 239.90 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bitches_fix', 2, '3511.07 407.46 392.72', '3575.29 462.49 520.72');
INSERT INTO "main"."game_zones" VALUES ('bhop_bitches_fix', 3, '7000.57 -2595.97 448.03', '7066.24 -2563.55 576.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bitches_fix', 1, '1180.03 -676.15 76.03', '1508.00 328.07 204.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_addict_v2_3xl', 2, '-15106.97 -9799.97 -51.97', '-14962.36 -9649.39 80.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_addict_v2_3xl', 3, '-6961.76 -4975.26 -47.97', '-6820.03 -4840.03 80.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_addict_v2_3xl', 0, '-5210.65 2271.42 244.03', '-4955.50 2593.49 372.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bkz_goldbhop', 2, '5040.03 2791.70 -359.97', '5071.52 2831.97 -231.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_bkz_goldbhop', 3, '3156.33 2252.36 488.03', '3165.47 2312.77 616.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bkz_goldbhop', 1, '3072.03 1936.03 288.03', '3503.97 2527.97 416.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bkz_goldbhop', 0, '-247.97 -120.00 16.03', '-40.00 259.79 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_blackrockshooter', 0, '-3307.97 -130.97 63.03', '-2610.21 336.60 191.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_blackrockshooter', 1, '6193.03 -11582.97 -254.82', '6966.95 -10835.00 -126.82');
INSERT INTO "main"."game_zones" VALUES ('bhop_blackrockshooter', 2, '2738.67 952.15 -100.48', '2775.93 991.58 27.52');
INSERT INTO "main"."game_zones" VALUES ('bhop_blackrockshooter', 3, '-3369.06 -710.89 -100.48', '-3317.20 -655.17 27.52');
INSERT INTO "main"."game_zones" VALUES ('bhop_brax', 0, '-623.93 0.00 -255.97', '559.99 79.97 -127.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_brax', 2, '2960.00 6658.19 -6399.97', '3086.89 6682.50 -6271.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_brax', 3, '5512.26 -2169.56 -7175.13', '7718.52 -1785.39 -7008.08');
INSERT INTO "main"."game_zones" VALUES ('bhop_brax', 1, '-5360.00 3856.03 -7839.97', '-3344.01 7248.00 -6815.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_bluerace', 0, '14384.03 15504.03 14912.03', '14703.32 15823.97 14992.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bluerace', 1, '4016.03 11759.97 13092.03', '4144.06 11952.36 13220.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bluerace', 2, '4473.91 12222.91 12480.03', '4593.20 12236.18 12608.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_bluerace', 3, '4020.93 12200.57 13121.85', '4046.73 12230.61 13255.51');
INSERT INTO "main"."game_zones" VALUES ('bhop_arcane_v1', 3, '-3055.97 -8175.97 15616.03', '-2585.54 -7184.03 15744.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 0, '3044.33 11834.03 54.03', '3347.68 12002.85 182.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 1, '3026.06 -8519.64 -3693.26', '3385.50 -8425.81 -3532.04');
INSERT INTO "main"."game_zones" VALUES ('bhop_catalyst', 0, '-5099.68 8855.26 -377.97', '-4932.17 9020.38 -249.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_catalyst', 1, '6717.28 229.25 -7585.97', '7408.62 907.00 -7457.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_ch4', 0, '338.13 -468.00 64.03', '391.00 -138.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_ch4', 1, '4040.03 874.03 15.03', '4558.97 1423.97 143.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_ch4', 2, '-1848.21 -256.97 64.03', '-1644.00 271.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_ch4', 3, '-892.84 764.01 64.03', '-298.03 1151.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_clarity', 0, '752.00 898.46 64.03', '1008.00 1007.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_clarity', 1, '-4063.97 -5359.97 -1823.97', '-3515.15 -3361.62 -1295.71');
INSERT INTO "main"."game_zones" VALUES ('bhop_clarity', 2, '-5372.71 -3421.77 -1471.97', '-5297.40 -3363.28 -1343.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_clarity', 3, '-4237.58 -3358.16 -1155.97', '-4177.08 -3344.03 -1027.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cobblestone', 0, '-177.47 208.03 128.03', '23.07 655.97 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cobblestone', 1, '163.60 2702.00 128.03', '233.94 2884.24 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cobblestone', 2, '472.03 2779.64 288.05', '505.33 2812.02 388.05');
INSERT INTO "main"."game_zones" VALUES ('bhop_cobblestone', 3, '714.98 2829.89 417.03', '752.00 2872.81 545.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_combine', 0, '472.41 912.03 32.03', '643.57 1280.00 160.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_combine', 1, '10644.03 6860.98 -429.21', '11011.97 7047.83 -301.21');
INSERT INTO "main"."game_zones" VALUES ('bhop_combine', 2, '124.03 3640.03 -745.74', '776.32 4300.00 -617.74');
INSERT INTO "main"."game_zones" VALUES ('bhop_combine', 3, '7063.16 3640.02 -745.74', '7711.99 4299.97 -617.74');
INSERT INTO "main"."game_zones" VALUES ('bhop_cutekittenz', 0, '-10128.78 9334.66 128.03', '-9728.99 9537.94 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cutekittenz', 1, '-11035.97 9392.03 566.03', '-10359.03 9815.97 694.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cutekittenz', 2, '-1788.70 -4835.41 6278.06', '-1742.18 -4788.68 6412.58');
INSERT INTO "main"."game_zones" VALUES ('bhop_cutekittenz', 3, '-1557.99 -3833.58 6443.03', '-1531.47 -3787.85 6571.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw', 0, '-4844.97 1730.05 5012.03', '-4778.19 2038.59 5140.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw', 1, '-11237.92 4256.17 649.03', '-10759.73 4732.48 777.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw', 2, '-2479.97 3808.03 5134.03', '-2192.03 4029.05 5262.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw', 3, '-2479.97 5273.73 6030.03', '-2192.13 5407.97 6158.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_collab', 0, '-4410.63 -5975.21 8299.03', '-3556.88 -5626.49 8427.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_collab', 1, '8413.63 -7048.49 5633.03', '8892.43 -6569.83 5761.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_collab', 3, '5917.48 -41.60 845.24', '6002.87 -2.52 973.24');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_collab', 2, '7001.70 923.64 2750.03', '7058.62 973.78 2878.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_journey', 0, '2423.64 2138.30 1102.03', '2598.60 2319.95 1230.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_journey', 1, '-14916.80 -8181.51 -2227.97', '-14000.53 -7267.24 -2099.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_journey', 2, '-9120.23 5791.19 -6255.97', '-8914.45 5980.04 -6127.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cw_journey', 3, '-7655.56 14216.03 -15063.97', '-7048.03 14631.97 -14935.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_dan', 0, '-494.47 112.03 0.03', '495.97 495.14 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_dan', 1, '-205.14 4271.86 384.03', '52.57 4526.48 512.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_dan', 3, '-2918.93 10364.19 96.03', '-2451.88 10428.69 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_dan', 2, '-2757.51 8771.83 -23.97', '-2631.51 8794.77 104.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_danmark', 0, '96.03 144.03 96.03', '543.97 558.83 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_danmark', 1, '7824.03 3856.03 96.03', '9039.97 4591.97 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_danmark', 2, '9027.29 3824.00 512.03', '9071.97 3859.75 640.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_danmark', 3, '8542.19 4225.75 288.03', '8543.34 4229.80 416.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_fix', 0, '-4130.97 3222.75 382.03', '-3843.03 3510.00 510.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_fix', 1, '753.76 12394.04 -4720.97', '890.98 12570.72 -4592.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_depot', 0, '-15484.04 -12089.65 420.03', '-15315.88 -11936.47 548.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_depot', 1, '-7983.99 1408.03 16.03', '-7312.03 1931.50 196.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_depot', 3, '-15507.46 -12236.44 228.79', '-15328.61 -12149.52 268.79');
INSERT INTO "main"."game_zones" VALUES ('bhop_depot', 2, '-15495.96 -11373.73 16.03', '-15428.90 -11312.03 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aux_a9', 4, '11248.51 11737.80 -11449.54', '12833.18 11782.08 -11185.78');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_for_retards', 0, '-15.97 2817.26 -543.97', '303.97 2851.71 -415.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_for_retards', 1, '1440.03 2688.03 -927.97', '1759.97 2974.02 -799.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_deppy', 0, '7998.03 -9376.00 453.03', '8606.00 -9153.11 581.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_deppy', 1, '-7522.97 4825.03 742.20', '-6915.03 5048.98 870.20');
INSERT INTO "main"."game_zones" VALUES ('bhop_deppy', 3, '-894.01 -457.86 876.03', '-827.22 -395.13 1004.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_deppy', 2, '-675.07 229.75 400.03', '-633.03 273.25 528.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_desolation', 2, '2530.92 9107.60 -1975.97', '3035.59 9320.74 -1847.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_desolation', 3, '2754.67 -11078.98 -6263.71', '2803.36 -11027.10 -6134.41');
INSERT INTO "main"."game_zones" VALUES ('bhop_desolation', 0, '-5946.06 -14728.00 11712.03', '-5393.55 -14487.77 11840.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_desolation', 1, '-5918.84 14043.88 11712.03', '-5267.12 14248.04 11852.23');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_benchmark', 0, '10413.74 12256.03 11504.03', '10511.97 12505.96 11632.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_benchmark', 1, '-11926.19 -5723.71 6144.03', '-10561.51 -4456.50 6272.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_benchmark', 2, '-1107.51 -4111.73 4208.03', '-1061.79 -4075.45 4336.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_benchmark', 3, '-1328.62 -4527.79 6096.03', '-1279.74 -4487.69 6224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_absolutebhop_v4', 0, '-2441.07 2624.00 -421.97', '-2080.03 3027.96 -289.26');
INSERT INTO "main"."game_zones" VALUES ('bhop_absolutebhop_v4', 1, '-3071.09 -6149.76 -691.97', '-2867.35 -5895.20 -563.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_absolutebhop_v4', 4, '-5184.97 -658.53 -50.97', '-4860.03 -254.03 49.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_absolutebhop_v4', 3, '-3930.62 818.58 77.03', '-3850.77 866.11 205.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_absolutebhop_v4', 2, '-5986.97 -1679.49 55.03', '-5852.83 -1603.47 183.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_deluxe', 0, '16.08 -111.97 64.03', '227.97 175.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_deluxe', 1, '-3497.97 1080.26 -85.97', '-3170.03 1217.86 42.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_deluxe', 3, '621.06 -111.97 192.03', '857.97 175.97 320.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_deluxe', 2, '1820.03 -2207.00 2668.03', '1883.88 -2167.20 2796.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_drop', 0, '-11480.88 13363.98 -255.97', '-11168.30 13460.66 -155.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_drop', 1, '2657.09 1002.90 -7527.96', '2882.18 1984.95 -6601.94');
INSERT INTO "main"."game_zones" VALUES ('bhop_drop', 2, '-1571.41 8079.24 -4703.97', '-1491.74 8159.97 -4575.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_drop', 3, '3546.59 7412.18 -4367.97', '4036.71 7557.52 -4237.45');
INSERT INTO "main"."game_zones" VALUES ('bhop_frankerz_999xl_extreme', 0, '-15855.97 -15856.00 14848.03', '-13840.03 -15390.18 14976.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_frankerz_999xl_extreme', 1, '-15855.97 -15855.97 -10751.97', '14578.65 15985.79 -9358.70');
INSERT INTO "main"."game_zones" VALUES ('bhop_easyhop', 0, '-527.17 -225.18 24.03', '-289.80 -16.02 152.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_easyhop', 1, '-814.55 -231.97 24.03', '-592.03 5.33 152.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy', 0, '-463.97 -463.97 64.03', '-237.35 -243.89 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy', 1, '-1090.40 -447.82 64.03', '-784.03 -126.37 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy_v2', 0, '14.84 -175.99 48.03', '242.06 176.00 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy_v2', 1, '4528.03 1744.03 48.03', '5028.28 2240.00 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_edge_v2', 0, '-419.99 1271.53 100.03', '-305.48 1393.13 228.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_edge_v2', 1, '-4207.97 5996.00 197.53', '-4069.35 6155.97 325.53');
INSERT INTO "main"."game_zones" VALUES ('bhop_eject', 0, '13852.13 2439.63 -159.97', '13944.38 2761.13 -158.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_eject', 2, '14242.01 1349.71 -143.68', '14347.10 1504.53 -4.17');
INSERT INTO "main"."game_zones" VALUES ('bhop_eject', 1, '9117.71 -2583.43 -47.97', '9474.68 -2279.54 80.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eman_on', 0, '-3634.86 -13436.18 502.50', '-3538.70 -13387.34 659.93');
INSERT INTO "main"."game_zones" VALUES ('bhop_eman_on', 1, '-3308.89 -13167.99 -1919.97', '-3244.93 -13136.00 -1855.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_empty_eyes', 0, '-15117.22 14848.55 176.03', '-14997.88 15102.66 304.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_empty_eyes', 1, '-5871.97 -2222.44 8416.03', '-5543.70 -1927.28 8544.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_enmity_beta3', 0, '-608.00 -207.97 72.03', '-248.03 -54.23 200.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_enmity_beta3', 1, '-15495.97 3384.03 -1087.97', '-15400.03 3479.95 -959.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_evo_fix', 0, '-6078.37 3112.17 -463.97', '-5944.43 3523.00 -335.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_evo_fix', 1, '-7188.64 2803.03 -825.97', '-6196.03 3779.30 -485.22');
INSERT INTO "main"."game_zones" VALUES ('bhop_exceptional', 0, '1031.37 1289.12 -511.97', '1177.25 1560.27 -383.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_exceptional', 1, '-3631 583 -511', '-3216 719 -347');
INSERT INTO "main"."game_zones" VALUES ('bhop_exquisite', 0, '-64.80 65.06 80.03', '128.84 180.96 208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_exquisite', 1, '3158.43 -2417.70 -1535.97', '3296.00 -2179.78 -1407.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_extan', 0, '9.66 -161.49 -71.97', '190.33 311.64 56.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_extan', 1, '-584.58 4224.03 -569.26', '132.97 4952.18 -441.26');
INSERT INTO "main"."game_zones" VALUES ('bhop_factory_v2', 0, '-1531.28 -129.58 -95.97', '-1356.06 201.91 32.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_factory_v2', 1, '465.44 -7567.97 -479.97', '1280.07 -6384.00 -351.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_flocci', 0, '-3742.97 -886.10 -1119.97', '-3284.01 -647.01 -991.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_flocci', 1, '-11686.82 -6590.85 476.03', '-11034.25 -6104.44 604.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_fracture', 0, '2596.24 -948.90 -599.99', '2798.22 -606.01 -471.99');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_fracture', 3, '4912.03 -2779.52 -5023.97', '5212.46 -2336.02 -4895.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_fracture', 2, '3319.24 -2277.87 -4943.97', '3623.99 -2040.34 -4815.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_fracture', 1, '410.03 2767.98 384.03', '820.53 3166.54 512.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_lovers', 0, '-6191.97 9168.03 8896.03', '-6000.03 9647.97 9024.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_lovers', 2, '-5626.67 -1106.97 -1260.28', '-5351.68 -696.07 -899.23');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_lovers', 3, '5775.88 -1021.74 -3279.97', '5800.88 -888.01 -3151.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_fly_lovers', 1, '5631.95 -1117.54 -3423.97', '5948.16 -801.74 -3153.38');
INSERT INTO "main"."game_zones" VALUES ('bhop_forchi_strafe', 0, '-1452.32 31.03 -73.97', '-1300.01 313.46 54.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_forchi_strafe', 2, '-2957.27 175.72 -1642.97', '-2895.62 244.94 -1514.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_forchi_strafe', 3, '-2584.43 426.03 -1192.97', '-2530.03 458.16 -1064.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_forchi_strafe', 1, '-6236.61 -704.58 -1983.97', '-6176.59 -654.02 -1855.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_forresttemple_beta', 0, '330.02 30.31 187.03', '462.78 156.95 315.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_forresttemple_beta', 3, '-2012.00 5196.27 1352.03', '-1984.82 5231.97 1481.42');
INSERT INTO "main"."game_zones" VALUES ('bhop_forresttemple_beta', 2, '-132.60 3383.65 326.03', '-115.61 3447.71 465.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_forresttemple_beta', 1, '2146.02 1634.50 287.03', '2644.16 1847.99 415.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fps_max_sr', 0, '-14464.49 12034.85 14848.03', '-14193.77 12270.99 14976.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fps_max_sr', 2, '7030.96 -8350.99 -9318.17', '7106.90 -8285.93 -9190.05');
INSERT INTO "main"."game_zones" VALUES ('bhop_fps_max_sr', 3, '6370.52 -6982.98 -9120.07', '6429.11 -6945.23 -8985.69');
INSERT INTO "main"."game_zones" VALUES ('bhop_fps_max_sr', 1, '6474.98 -7035.23 -9251.35', '6577.85 -6915.13 -8970.08');
INSERT INTO "main"."game_zones" VALUES ('bhop_freakin', 0, '4048.00 4496.52 144.03', '4338.25 4912.00 272.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_freakin', 2, '10381.24 1130.20 -479.97', '10441.01 1183.91 -351.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_freakin', 3, '11413.23 944.01 416.03', '11447.97 975.99 544.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_freakin', 1, '7040.94 1168.03 -1279.97', '7343.97 1409.33 -1151.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_fresh', 2, '-288.29 -8371.80 3958.03', '194.33 -7841.31 4086.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fresh', 3, '-4662.86 -8370.85 3960.03', '-4192.04 -7847.76 4088.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fresh', 0, '-709.53 7367.14 -4564.97', '-595.71 7867.78 -4436.57');
INSERT INTO "main"."game_zones" VALUES ('bhop_frosties_gm', 0, '-15146.55 -7739.02 -13703.97', '-14781.84 -7279.46 -13575.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_frosties_gm', 1, '-5325.27 -2299.97 -557.97', '-4918.69 -2166.64 -429.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_frosties_gm', 2, '1659.03 -12479.97 -3311.97', '1774.09 -12003.51 -3159.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_frosties_gm', 3, '5756.99 -11876.38 -2983.97', '5904.18 -11596.73 -2855.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_frost_bite_v1a', 0, '1056.87 164.77 128.03', '1265.79 626.68 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_frost_bite_v1a', 1, '-1275.90 1289.90 477.04', '-784.55 1770.22 605.04');
INSERT INTO "main"."game_zones" VALUES ('bhop_frost_bite_v1a', 2, '-10392.63 1358.03 -127.97', '-10300.48 1399.16 1.21');
INSERT INTO "main"."game_zones" VALUES ('bhop_frost_bite_v1a', 3, '-9454.51 1289.55 1712.03', '-9293.68 1485.76 1840.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fruits2', 0, '-12538.09 8884.35 11394.03', '-12152.48 9497.20 11522.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fruits2', 1, '11518.54 -940.44 10008.53', '11714.52 -559.30 10136.53');
INSERT INTO "main"."game_zones" VALUES ('bhop_fruits2', 2, '-4178.95 13168.03 12304.03', '-3942.34 13455.97 12432.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fruits2', 3, '11538.09 -1707.69 11137.53', '11782.87 -1441.93 11265.53');
INSERT INTO "main"."game_zones" VALUES ('bhop_fuckfear_fix', 0, '-304.55 -46.75 64.03', '-212.02 171.02 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fuckfear_fix', 1, '1743.07 9.35 624.03', '1964.41 232.79 752.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury', 0, '-8175.97 4480.48 64.03', '-7952.00 4600.74 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury', 1, '-7911.97 -1255.97 584.03', '-7448.03 -792.01 712.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury', 2, '3088.03 11560.60 -1023.97', '3125.34 11599.97 -895.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury', 3, '2581.37 13078.02 -1069.69', '2626.21 13117.76 -938.50');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury_2', 0, '-11519.96 12448.00 -1887.97', '-11360.03 12533.11 -1759.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury_2', 1, '-8175.97 12600.03 1524.03', '-7824.03 13007.97 1652.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury_2', 2, '-7771.82 12756.29 1240.03', '-7730.94 12854.51 1368.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_fury_2', 3, '-11461.88 12604.93 -1887.97', '-11360.03 12680.00 -1759.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_giga_citadel_v2', 0, '-2937.16 1208.03 -239.97', '-2804.30 1655.42 -111.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_giga_citadel_v2', 1, '-6130.13 4255.66 -207.97', '-5761.44 4526.70 -79.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_giga_citadel_v2', 3, '-7670.47 2879.66 -703.97', '-7577.82 2960.00 -575.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_giga_citadel_v2', 2, '-8289.90 3004.22 -703.97', '-8223.15 3068.77 -575.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_gismo_fix', 0, '5680.03 195.44 64.03', '6087.97 500.63 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_gismo_fix', 1, '-8655.97 48.03 64.03', '-8240.03 279.82 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_gismo_fix', 2, '-10190.05 48.03 64.03', '-9264.03 415.44 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_gismo_fix', 3, '-11215.97 48.03 64.03', '-10793.82 290.43 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_glassy', 0, '-15280.00 -15919.06 15952.03', '-15120.48 -15377.26 16080.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_glassy', 1, '-11805.51 -15207.97 13120.03', '-10685.43 -13264.03 13248.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_glassy', 4, '-11777.81 -15664.34 13312.03', '-6358.14 -15223.16 13462.25');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenhouse', 0, '399.21 -3724.73 64.03', '557.60 -3384.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenhouse', 1, '15454.96 -3743.97 64.03', '15530.91 -3384.04 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenhouse', 2, '99.03 -3220.70 -2560.87', '367.06 -2834.43 -2432.87');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenhouse', 3, '2497.65 -3219.36 -2555.97', '2820.97 -2834.43 -2427.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenroom_final', 0, '2075.03 -173.21 -1033.97', '2162.97 -32.86 -905.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenroom_final', 1, '3306.03 -1519.98 -2421.97', '4233.97 -432.03 -2293.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenroom_final', 2, '-274.38 -4277.97 -1427.97', '-235.12 -4238.82 -1299.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_greenroom_final', 3, '-4901.30 -7404.97 -3837.97', '-4778.07 -6837.03 -3709.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_green_fixx', 0, '64.68 -446.54 96.03', '256.10 -255.73 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_green_fixx', 1, '524.91 -463.97 96.03', '760.02 -240.03 226.69');
INSERT INTO "main"."game_zones" VALUES ('bhop_guly', 0, '-4245.38 -2331.85 -103.97', '-4150.03 -1888.00 24.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_guly', 1, '-2762.14 2345.18 -4.25', '-2353.43 2716.04 123.75');
INSERT INTO "main"."game_zones" VALUES ('bhop_haddock', 0, '560.01 -1391.97 1008.03', '686.01 -1072.01 1136.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_haddock', 1, '-1593.97 -2007.97 -471.97', '-954.03 -1336.03 -343.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_haddock', 2, '4920.03 -1029.44 -2983.97', '5399.99 -872.00 -2855.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_haddock', 3, '-1591.97 -1031.97 -351.97', '-952.03 -360.03 -223.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_handsuplol', 0, '6654.09 1512.00 1120.03', '6848.00 1991.97 1248.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_handsuplol', 1, '-4103.97 3600.03 -5343.97', '-3824.99 4087.97 -5215.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_hell', 0, '-7599.17 320.03 -352.00', '-6400.77 743.60 -223.99');
INSERT INTO "main"."game_zones" VALUES ('bhop_hell', 2, '-10560.20 538.95 1612.61', '-10513.78 589.77 1816.89');
INSERT INTO "main"."game_zones" VALUES ('bhop_hell', 3, '-6198.58 4637.93 370.42', '-5995.10 4890.63 499.42');
INSERT INTO "main"."game_zones" VALUES ('bhop_hell', 1, '4682.03 -2567.97 752.03', '6265.97 -1177.03 1752.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_highfly', 0, '-240.00 -671.97 9412.03', '3.19 -144.01 9413.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_highfly', 1, '-5364.97 -6623.97 2688.03', '-4655.03 -6258.30 2816.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hikari_beta', 0, '-4284.50 886.34 -399.97', '-4146.07 1019.77 -271.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_hikari_beta', 1, '4770.53 1372.38 4448.03', '6566.59 1846.69 4576.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hikari_beta', 2, '4752.03 9040.03 9280.03', '5051.28 9903.97 9419.32');
INSERT INTO "main"."game_zones" VALUES ('bhop_hikari_beta', 3, '7065.74 8959.99 8384.03', '7286.18 9981.56 8634.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hive', 0, '-13799.97 13821.92 -1263.97', '-13592.03 13972.65 -1135.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_hive', 1, '-338.89 -550.16 -9967.97', '-131.16 -432.85 -9839.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_hive', 3, '-6295.97 13317.35 -5952.97', '-6272.03 13403.63 -5824.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_hive', 2, '-8127.44 13074.20 -2834.64', '-8072.40 13163.53 -2702.71');
INSERT INTO "main"."game_zones" VALUES ('bhop_hoover', 0, '-192.89 22.79 64.03', '24.00 345.74 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hoover', 1, '5940.88 -54.08 -2893.11', '6936.02 541.49 -2765.11');
INSERT INTO "main"."game_zones" VALUES ('bhop_hoover', 2, '-106.06 408.63 257.03', '-6.61 520.29 385.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hoover', 3, '3198.71 814.46 -4077.49', '3247.45 860.97 -3949.49');
INSERT INTO "main"."game_zones" VALUES ('bhop_house', 0, '-303.09 545.86 32.03', '280.76 697.20 160.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_house', 1, '-497.97 -416.97 -605.97', '503.62 1823.97 -477.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_house', 3, '428.48 -1791.97 -605.97', '496.00 -1721.95 -477.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_house', 2, '119.93 6317.26 1020.56', '220.84 6408.37 1199.00');
INSERT INTO "main"."game_zones" VALUES ('bhop_h_box_v1', 0, '-367.97 265.61 -127.97', '367.97 431.28 3.21');
INSERT INTO "main"."game_zones" VALUES ('bhop_h_box_v1', 1, '-632.68 -1649.79 -2111.97', '-395.02 -1414.06 -1983.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_h_box_v1', 2, '784.03 582.72 576.03', '1001.58 752.00 704.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_h_box_v1', 3, '3237.99 2672.38 545.71', '3432.29 2772.94 686.15');
INSERT INTO "main"."game_zones" VALUES ('bhop_idiosyncrasy', 0, '-7257.63 2634.50 775.03', '-7121.01 2809.68 903.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_idiosyncrasy', 1, '-10032.00 -1741.92 404.03', '-9860.96 -1602.04 532.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_idiosyncrasy', 3, '860.03 -9277.32 -8328.97', '920.08 -9223.03 -8200.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_idiosyncrasy', 2, '1894.42 -11441.10 -9589.78', '1946.20 -11379.64 -9461.02');
INSERT INTO "main"."game_zones" VALUES ('bhop_impecible', 0, '512.03 -15.97 -735.97', '991.97 463.97 -607.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_impecible', 1, '-5486.97 7644.03 255.03', '-5150.03 8319.97 383.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_impecible', 2, '-2396.18 1868.67 -1289.57', '-2322.25 1944.35 -1131.44');
INSERT INTO "main"."game_zones" VALUES ('bhop_impecible', 3, '-3445.16 1446.88 -506.92', '-3418.43 1515.85 -366.54');
INSERT INTO "main"."game_zones" VALUES ('bhop_aux_a9', 2, '-13419.94 -13935.97 -15359.97', '-13303.89 -13712.01 -15231.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_aux_a9', 3, '-7663.97 1026.91 -12799.97', '-6928.00 1519.96 -12671.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 3, '4932.01 903.03 -2571.97', '4969.88 950.45 -2443.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 2, '8909.06 6522.80 -2120.97', '8935.60 6547.34 -2060.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kiwi_cwfx', 0, '-6427.94 -224.00 384.03', '-6290.47 271.97 512.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kiwi_cwfx', 1, '3078.34 -2095.97 -143.97', '3343.97 -1760.03 -15.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_areaportal_v1', 2, '-2020.97 -8920.97 -60.97', '-1683.55 -8453.02 67.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_areaportal_v1', 3, '4661.66 -10532.97 -60.97', '4859.96 -10057.89 121.27');
INSERT INTO "main"."game_zones" VALUES ('bhop_impulse', 0, '3168.55 607.84 0.03', '3361.00 718.34 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_impulse', 1, '1424.01 -880.00 -255.97', '1526.38 -656.03 -127.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_infog', 0, '992.31 24.00 307.03', '1575.97 475.97 435.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_infog', 1, '68.03 -1789.96 -668.97', '1515.97 -532.03 -540.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_infog', 2, '3256.03 6697.22 98.03', '3341.16 6805.97 226.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_infog', 3, '3645.05 235.72 -3739.97', '3853.84 255.63 -3611.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_insanelyserz', 0, '-13834.97 13636.64 -2091.97', '-13419.03 14064.97 -1963.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_insanelyserz', 1, '-287.30 400.33 32.03', '188.50 779.90 160.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_it_gbr', 0, '-700.13 -12829.01 128.03', '-578.21 -12768.08 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_it_gbr', 1, '-5601.66 4374.79 768.03', '-5537.62 4848.97 896.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_it_nine-up', 0, '-3064.10 3715.53 -2015.97', '-3008.67 3835.44 -1887.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_it_nine-up', 1, '352.42 -5070.77 -1769.97', '501.25 -5016.89 -1641.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_it_nine-up', 2, '-5395.29 5586.20 -2015.97', '-5357.23 5915.10 -1887.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_it_nine-up', 3, '-3016.30 5745.34 -1769.97', '-2908.84 5787.54 -1641.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_ivy_final', 0, '-3437.97 6445.41 114.53', '-3148.01 6570.97 242.53');
INSERT INTO "main"."game_zones" VALUES ('bhop_ivy_final', 1, '-6784.34 -1829.73 -2439.97', '-5083.03 -125.01 -1743.62');
INSERT INTO "main"."game_zones" VALUES ('bhop_ivy_final', 2, '3012.98 6957.14 -2491.97', '3063.74 7033.24 -2363.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_jegg', 0, '-1007.97 528.00 -991.97', '-853.88 1008.00 -863.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_jegg', 1, '224.03 4768.03 -5303.97', '707.29 5247.98 -5000.16');
INSERT INTO "main"."game_zones" VALUES ('bhop_jegg', 3, '-1568.00 3936.13 -4983.97', '-1458.96 4223.97 -4855.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_jegg', 2, '98.87 5165.37 -5559.97', '136.04 5204.35 -5431.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_jierdas', 1, '2507.03 364.03 -1799.97', '2675.35 534.38 -1671.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_jierdas', 0, '-272.32 225.44 592.03', '511.96 304.00 720.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_k26000_b2', 0, '-368.47 28.11 64.03', '-151.02 361.69 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_k26000_b2', 1, '12432.00 108.50 70.03', '12737.99 442.66 198.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kiseki', 0, '-1788.53 -1021.52 896.03', '-1722.66 -720.37 1024.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kiseki', 1, '12048.03 336.03 -8703.97', '13359.97 1775.97 -8103.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_femto', 0, '-5984.99 3272.03 544.03', '-5810.20 3879.97 672.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_femto', 1, '-4111.97 6040.48 -1759.97', '-3610.78 6375.99 -1459.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_mix_journeys', 0, '-7671.27 2389.41 11920.03', '-7566.23 2540.35 12048.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_mix_journeys', 1, '-8655.97 -4281.98 -8831.97', '-8388.00 -4130.07 -8703.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_mix_journeys', 2, '-6489.62 7322.47 5063.38', '-6450.96 7371.26 5230.48');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_mix_journeys', 3, '-1298.76 5190.16 5189.80', '-1148.79 5264.32 5334.98');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_ocean', 0, '-1482.65 1028.87 32.03', '-1348.26 1138.00 160.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_ocean', 1, '2361.32 -524.52 158.99', '2511.21 -346.44 288.27');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_ravine', 0, '-249.88 -1330.10 -128.50', '220.83 -1026.45 -0.24');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_ravine', 1, '5513.22 -4910.68 -1459.69', '6222.05 -4266.17 -1109.69');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_tryhardkittenz_fix', 0, '-2935.50 -2789.16 253.03', '-2709.14 -2480.00 381.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_tryhardkittenz_fix', 1, '-10844.59 -569.46 -2017.97', '-9373.99 1416.46 -1889.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_watertemple', 0, '-2691.24 -2607.97 -383.97', '-2462.17 -1872.03 -255.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_watertemple', 1, '3980.03 3193.40 -1215.97', '4459.97 3292.43 -1087.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_larena_nodoors', 0, '928.95 -250.28 0.03', '1069.20 63.14 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_larena_nodoors', 1, '-495.97 14681.33 2112.03', '943.97 15207.99 2241.02');
INSERT INTO "main"."game_zones" VALUES ('bhop_legenda_v2', 0, '-582.88 -333.58 -98.97', '-443.93 -52.03 29.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_legenda_v2', 1, '-4157.67 -4146.46 -841.97', '-4012.59 -4005.44 -713.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_legion', 0, '-777.00 1352.03 0.03', '-617.62 1959.97 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_legion', 1, '4880.03 -3551.97 -439.97', '5295.99 -3377.27 -39.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego', 0, '-240.00 -14.86 128.03', '-96.69 128.32 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego', 1, '1521.30 -8905.32 1008.03', '1967.76 -8480.90 1537.47');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego2', 0, '3812.98 -10171.22 64.03', '3953.57 -9776.00 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego2', 1, '3376.03 -9075.01 -191.97', '3937.47 -8544.03 101.01');
INSERT INTO "main"."game_zones" VALUES ('bhop_legolis', 0, '227.43 124.84 160.03', '799.46 254.61 288.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_legolis', 1, '-9606.67 2304.03 -655.97', '-9133.18 3359.97 -527.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_letour', 0, '230.29 68.48 96.03', '382.09 443.78 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_letour', 1, '48.01 16.03 528.03', '562.56 495.97 656.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lolamap_v2', 0, '-1059.97 834.77 128.03', '-602.03 982.13 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lolamap_v2', 1, '3045.02 1559.25 -802.97', '3684.34 2157.24 -674.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_lost_world', 0, '-207.12 -1109.57 80.03', '144.12 -648.03 112.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lost_world', 1, '12064.13 -166.18 8160.03', '13050.97 767.06 8288.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mcginis_fix', 0, '-14559.90 -223.55 768.03', '-14367.95 96.02 896.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mcginis_fix', 1, '-8930.24 620.77 288.03', '-8528.83 939.05 484.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_messs_123', 0, '1504.75 -230.39 -63.97', '1696.88 -160.29 64.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_messs_123', 1, '-331.83 -463.08 320.03', '423.76 371.19 448.66');
INSERT INTO "main"."game_zones" VALUES ('bhop_metal_v2', 0, '-1399.99 4.57 68.03', '-902.01 149.05 196.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_metal_v2', 1, '3222.74 -2847.97 68.03', '3725.09 -2630.54 196.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_miku_v2', 1, '-2503.40 1278.51 -443.97', '-2309.74 1789.44 -315.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_miku_v2', 0, '-2876.91 112.12 -443.97', '-2755.79 916.64 -315.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_militia_v2', 1, '1267.16 -4898.36 77.03', '1666.97 -4554.44 205.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_militia_v2', 0, '11.43 -156.42 72.03', '391.94 -45.95 172.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mine', 0, '-11545.56 12656.26 334.61', '-11408.35 13053.00 462.61');
INSERT INTO "main"."game_zones" VALUES ('bhop_mine', 1, '9451.55 -451.32 -3021.97', '9738.35 -35.67 -2873.64');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist', 0, '-925.41 -1028.42 1297.03', '-640.03 -925.18 1425.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist', 1, '-1173.97 -1429.00 1307.03', '-1030.13 -1199.53 1435.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_3', 0, '-1775.97 -2015.64 -511.97', '-1425.03 -1867.39 -383.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_3', 1, '10144.03 -9399.98 10168.03', '10496.00 -9302.78 10618.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_beta', 0, '-3715.97 -3819.94 64.03', '-3530.88 -3698.88 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_beta', 1, '2312.31 6079.69 304.03', '2598.56 6703.07 432.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_jam', 4, '9126.76 -860.71 5985.73', '11236.80 3814.26 6170.93');
INSERT INTO "main"."game_zones" VALUES ('bhop_montana_fix', 0, '-9555.05 3783.03 -1448.97', '-9477.07 4087.65 -1320.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_montana_fix', 1, '-6879.89 -5299.77 3842.03', '-6030.77 -4560.10 3970.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_muchfast', 0, '7522.50 -15200.00 -5343.97', '8092.14 -14991.91 -5215.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_muchfast', 1, '13984.03 2272.03 -10879.97', '14655.97 2540.86 -10379.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_muchfast', 2, '-111.97 -5103.98 -9919.97', '559.97 -4915.13 -9791.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_muchfast', 3, '-111.97 10833.86 -9919.97', '559.98 11087.99 -9791.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_nacho_libre_simo', 0, '-1312.80 32.07 65.82', '-1113.24 479.62 193.82');
INSERT INTO "main"."game_zones" VALUES ('bhop_nacho_libre_simo', 1, '-2527.97 -3871.89 -1398.27', '-2272.01 -3616.01 -1270.27');
INSERT INTO "main"."game_zones" VALUES ('bhop_nipple_fix', 0, '80.00 -4845.10 48.03', '196.16 -4641.98 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_noobhop_exg', 0, '-671.84 -1455.97 64.03', '-208.01 -992.70 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_noobhop_exg', 1, '5464.50 2160.00 64.03', '6114.99 2533.12 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_omn', 0, '756.03 13552.54 68.03', '1184.97 13745.97 196.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_omn', 1, '3173.85 8354.03 -1330.97', '3444.97 8992.97 -1202.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_osti', 0, '-6918.03 -2489.10 728.08', '-6845.30 -2379.70 856.08');
INSERT INTO "main"."game_zones" VALUES ('bhop_osti', 1, '8680.49 -2168.49 1407.53', '8869.97 -1949.02 1535.53');
INSERT INTO "main"."game_zones" VALUES ('bhop_paisaweeaboo_beta3', 0, '-2017.15 92.17 128.03', '-1824.83 539.82 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_paisaweeaboo_beta3', 1, '-1439.97 4880.03 -991.97', '-1216.03 5535.94 -863.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_pinky', 0, '-224.03 269.68 16.03', '-31.62 446.09 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_pinky', 4, '-1200.00 -353.49 160.03', '1327.97 2223.97 288.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_pinky', 1, '1040.03 1484.69 16.03', '1306.20 1673.87 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_portal', 1, '-7535.97 4112.03 2816.03', '-6928.03 4719.97 2944.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_portal', 0, '-889.61 957.02 532.03', '-787.88 1092.99 660.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_pro_bhopper_mp', 0, '1903.49 0.01 -137.97', '2066.52 303.97 -37.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_pro_bhopper_mp', 1, '-2400.00 984.76 -287.97', '-2096.03 1233.83 -159.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_quist_final', 0, '-6344.38 9260.51 -114.97', '-6249.81 9763.90 13.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_quist_final', 1, '-3346.90 -8393.04 -104.47', '-3251.32 -7797.89 26.64');
INSERT INTO "main"."game_zones" VALUES ('bhop_raw', 0, '2088.29 -10732.97 66.03', '2540.97 -10648.43 194.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_raw', 1, '-6254.97 -10603.00 -845.97', '-6035.03 -10383.04 -717.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_red', 0, '-640.00 -416.00 -31.97', '-260.37 415.99 96.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_red', 1, '11024.03 -351.97 -31.97', '11711.97 351.97 96.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_redwood', 0, '1699.53 -1711.85 72.03', '1863.93 -1456.03 200.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_redwood', 1, '1704.03 1376.00 40.03', '1967.97 2124.34 168.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_rooster', 0, '4468.03 -2569.99 24.03', '4947.99 -2396.00 152.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_rooster', 1, '-603.19 11164.03 -247.97', '-300.03 11611.97 -119.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_sahara', 0, '-811.97 -320.03 66.03', '-634.00 -291.28 194.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_sahara', 1, '640.03 237.74 66.03', '817.97 563.12 194.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_sahara', 4, '-2099.51 446.52 607.67', '-282.30 1105.09 784.11');
INSERT INTO "main"."game_zones" VALUES ('bhop_sahara', 3, '-1060.97 783.27 202.36', '-956.38 940.12 378.45');
INSERT INTO "main"."game_zones" VALUES ('bhop_sahara', 2, '-299.88 619.15 2.03', '-260.87 654.82 130.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_screelee', 0, '968.00 -536.01 -405.97', '1342.96 543.93 -277.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_screelee', 1, '6325.03 3517.42 -2155.97', '7699.98 4837.97 -1454.65');
INSERT INTO "main"."game_zones" VALUES ('bhop_serzv2_opti', 0, '13262.92 1472.60 -2393.97', '13476.97 1606.23 -2265.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_serzv2_opti', 1, '-2101.97 -13162.97 -11663.97', '-890.25 -11531.03 -11535.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_shades', 0, '194.18 -122.63 0.03', '315.19 111.97 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_shades', 1, '14351.78 -1151.97 -2367.97', '14703.97 -16.00 -2239.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_shrubhop', 0, '709.87 92.30 48.03', '762.18 147.78 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_shrubhop', 1, '-4339.97 -8463.97 -2687.97', '-4176.01 -7630.19 -2559.50');
INSERT INTO "main"."game_zones" VALUES ('bhop_speedrun_valley', 0, '-1755.21 -195.99 -199.97', '-1337.99 23.97 -71.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_speedrun_valley', 1, '7694.43 -4375.84 -199.97', '8120.59 -4080.60 -71.01');
INSERT INTO "main"."game_zones" VALUES ('bhop_sqee', 1, '-2935.96 3635.61 -13951.97', '-2616.03 4373.09 -13351.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_sqee', 0, '-1769.65 -8911.99 2368.03', '-1123.32 -8594.11 2496.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafearena', 0, '-2431.86 4047.50 163.03', '-2231.03 4233.97 291.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafearena', 1, '-1373.97 4469.03 -19.97', '-446.03 4867.97 108.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_winter', 0, '0.62 13280.19 64.03', '254.24 13376.80 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_winter', 1, '62.54 -7726.77 208.03', '319.68 -7409.75 336.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_stronghold', 0, '176.03 16.03 -31.97', '335.99 120.05 96.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_stronghold', 1, '7847.62 1543.26 5984.03', '8176.00 1775.97 6112.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_subsidence', 0, '-207.97 1968.03 1696.03', '28.68 2480.00 1824.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_subsidence', 1, '1424.12 11408.03 128.03', '2159.97 12131.97 428.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_superdooperhard', 0, '-3567.98 -1519.97 512.03', '-2576.03 -1025.64 640.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_superdooperhard', 1, '8208.03 9635.04 512.03', '10223.97 10735.97 640.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_swik_b1', 0, '-3055.80 -2031.97 -1023.97', '-2832.00 -1938.00 -895.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_swik_b1', 1, '-1007.97 92.41 -1023.97', '-5.57 1017.49 -775.77');
INSERT INTO "main"."game_zones" VALUES ('bhop_tasku', 0, '-175.97 -553.95 128.03', '239.97 -335.91 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tasku', 1, '6356.03 -2828.00 -798.97', '6721.29 -2576.03 -658.12');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego2', 2, '2864.03 -9103.97 -2415.97', '3215.97 -8867.08 -2287.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego2', 3, '81.29 -4735.97 -1807.97', '139.09 -4560.03 -1679.97');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_yonkoma', 0, '1615.22 4048.03 320.03', '1657.86 4239.99 448.82');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_yonkoma', 1, '-6703.98 8848.03 -8943.97', '-6096.03 9212.42 -8815.97');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_yonkoma', 4, '-1756.95 11841.48 -4031.97', '-1637.49 12079.99 -3881.46');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_yonkoma', 2, '-10735.84 7440.03 -9151.97', '-10672.03 7607.97 -9023.97');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_yonkoma', 3, '-7439.99 6928.03 -9119.97', '-7404.35 6959.97 -8991.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc', 0, '2217.38 -1310.97 8.03', '2329.64 -991.03 136.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc', 1, '-9343.43 8466.03 8.03', '-9214.74 8786.00 137.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_gold', 0, '-5629.81 -730.25 99.03', '-5570.43 -203.44 227.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_gold', 1, '-13295.97 9218.41 104.03', '-12304.03 9264.07 232.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_island', 0, '-2821.21 -8448.16 96.03', '-2433.95 -8319.49 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_island', 1, '3124.03 -1817.28 1006.03', '4115.97 -1632.54 1135.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_island', 2, '6247.58 -3960.89 520.16', '6286.27 -3920.34 656.70');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_island', 3, '3367.03 -6615.66 531.84', '3432.01 -6572.03 671.30');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_egypt', 0, '4880.03 6672.03 -991.97', '4911.64 6879.19 -863.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_egypt', 1, '3511.05 1982.03 -991.97', '3650.97 2515.97 -863.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_egypt', 2, '11185.07 1650.18 -882.97', '11245.46 1741.15 -754.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_egypt', 3, '7292.65 2219.19 -882.97', '7354.20 2278.97 -754.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_platinum', 0, '-13187.06 237.75 128.03', '-12891.53 391.30 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_platinum', 1, '-997.14 11443.88 -11568.97', '-253.16 11792.18 -11440.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_platinum', 2, '-4415.47 13155.97 10747.29', '-4381.31 13189.99 10879.63');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_platinum', 3, '-6037.87 11443.60 10406.71', '-5978.10 11497.72 10575.55');
INSERT INTO "main"."game_zones" VALUES ('bhop_toc', 0, '511.19 -239.99 -191.97', '633.06 255.74 -63.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_toc', 1, '9712.03 4354.14 -2303.97', '9999.99 4405.61 -2053.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_together', 0, '1188.33 -4440.19 14796.03', '1485.88 -4308.19 14924.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_together', 1, '496.14 3356.17 -10679.97', '726.97 3551.97 -10529.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_enmity_beta3', 2, '-7250.21 6053.97 -815.97', '-7226.49 6113.73 -687.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_enmity_beta3', 3, '-8267.84 8173.23 -1663.97', '-8234.70 8205.89 -1535.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_austere', 2, '-15336.92 5681.03 4670.03', '-15271.70 6549.97 4798.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_austere', 3, '2411.45 7198.03 4670.03', '2762.98 8066.97 4798.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_austere', 4, '515.30 -714.99 480.03', '827.45 -388.27 608.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_austere', 4, '307.22 -328.60 80.03', '459.39 -239.97 384.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_empty_eyes', 2, '-4988.25 -2044.12 8416.03', '-4487.12 -1944.78 8544.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_empty_eyes', 3, '-2672.00 -4369.67 8416.03', '-2587.11 -4079.24 8544.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_messs_123', 2, '1296.68 1679.31 255.97', '1346.05 1739.52 384.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_messs_123', 3, '3972.14 -1125.33 256.03', '4009.01 -1072.23 384.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_handsuplol', 2, '5778.90 1734.47 1396.01', '5821.13 1771.33 1578.48');
INSERT INTO "main"."game_zones" VALUES ('bhop_handsuplol', 3, '4158.67 1857.53 1467.54', '4214.62 1909.38 1625.59');
INSERT INTO "main"."game_zones" VALUES ('bhop_sqee', 2, '1041.64 3944.59 -9359.97', '1095.46 4031.83 -9231.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_sqee', 3, '-2656.78 3636.79 -13951.97', '-2616.03 3676.00 -13823.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_egyptiantemple_gm', 0, '-95.97 31.74 48.03', '415.97 280.00 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_egyptiantemple_gm', 1, '-4037.24 -893.98 968.03', '-3715.34 -584.51 1096.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_yonkoma', 4, '-1795.02 11860.46 -4129.39', '-1707.33 12070.32 -3726.43');
INSERT INTO "main"."game_zones" VALUES ('bhop_ivy_final', 3, '-5796.77 -9252.19 -2240.62', '-5534.12 -9004.59 -2036.80');
INSERT INTO "main"."game_zones" VALUES ('bhop_noobhop_exg', 2, '6353.03 -1454.97 64.03', '6831.00 -1103.00 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_noobhop_exg', 3, '7441.01 974.95 64.03', '7918.97 1326.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tasku', 4, '3643.21 652.20 -90.11', '4156.78 723.15 400.31');
INSERT INTO "main"."game_zones" VALUES ('bhop_arcane_v1', 4, '-1007.97 -1003.12 14400.03', '-842.52 1007.97 14528.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_shrubhop', 4, '1168.52 -344.84 -248.69', '2046.53 340.19 52.80');
INSERT INTO "main"."game_zones" VALUES ('bhop_shrubhop', 4, '-1207.50 -4473.07 -463.68', '-423.72 -4280.23 -151.68');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_mix_journeys', 4, '-8047.99 2399.00 11920.03', '-7952.03 2631.73 12048.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_easyhop', 3, '-575.84 -225.03 168.03', '-559.95 -209.86 232.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_easyhop', 2, '-575.77 3055.02 168.03', '-559.83 3070.72 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_badges_mini', 0, '1553.76 -2287.97 15008.03', '1904.44 -2128.80 15136.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_badges_mini', 1, '1168.03 -4079.97 14912.03', '2287.97 -3037.76 15040.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_awful3', 0, '-923.27 -1007.97 0.03', '-781.41 -336.02 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_awful3', 1, '-6782.89 -1744.00 -6143.97', '-6352.03 -240.03 -6015.97');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_lucid', 0, '-1200.00 -688.00 0.03', '-1027.73 -454.27 128.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_lucid', 1, '-1455.99 2177.58 1552.03', '-1424.02 2259.51 1602.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_lucid', 3, '-559.97 1488.03 -31.97', '-336.03 1647.97 96.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_lucid', 2, '1503.49 -3260.34 16.03', '1577.45 -3208.88 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 4, '-1549.97 7157.52 -1510.97', '-939.03 9475.39 -1382.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 4, '1549.65 5875.03 -1510.97', '2044.71 6567.97 -1382.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 4, '4160.36 5875.03 -1510.97', '4964.60 6567.97 -1382.95');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 4, '6402.66 903.02 -2571.97', '7372.89 2933.12 -2443.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_cartoons', 4, '1845.33 10325.02 2.03', '2875.85 11353.16 240.45');
INSERT INTO "main"."game_zones" VALUES ('bhop_unreality', 0, '-10561.96 5104.03 1280.03', '-10082.22 5584.00 1408.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_unreality', 1, '5537.07 5022.01 -15359.97', '5880.00 5725.72 -15199.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_unreality', 2, '-1487.65 4931.70 -9619.53', '-1401.48 4987.19 -9491.53');
INSERT INTO "main"."game_zones" VALUES ('bhop_unreality', 3, '2118.75 4650.84 -11078.30', '2171.68 4717.24 -10942.07');
INSERT INTO "main"."game_zones" VALUES ('bhop_arcane_v1', 2, '5641.59 -12271.97 13312.03', '6127.97 -11280.03 13440.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_airflow_v2_fix', 2, '-992.29 420.34 96.03', '-965.27 447.76 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_airflow_v2_fix', 3, '-332.45 -239.53 392.03', '-207.10 -191.36 520.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_jam', 0, '6542.55 800.01 3778.03', '6643.05 880.92 3906.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_jam', 1, '80.01 76.27 4252.23', '1967.97 1971.73 4752.23');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_jam', 2, '11118.57 -879.97 5696.03', '11247.97 -720.03 5824.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_jam', 3, '11090.71 3664.03 5696.03', '11247.97 3823.97 5824.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_monster_jam', 4, '9168.03 1648.23 5696.03', '9519.99 2095.97 5868.65');
INSERT INTO "main"."game_zones" VALUES ('bhop_pinky', 4, '-1199.97 -1199.97 160.03', '517.86 -898.38 288.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_pinky', 4, '-1199.99 -1200.00 160.03', '-258.45 2224.00 288.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_militia_v2', 2, '-1444.65 -231.71 72.03', '-1430.13 -223.93 200.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_militia_v2', 3, '-1047.87 -1019.97 72.03', '-1024.85 -996.49 200.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_catalyst', 2, '6717.87 230.11 -7585.97', '7407.35 907.01 -7457.96');
INSERT INTO "main"."game_zones" VALUES ('bhop_catalyst', 3, '6503.30 0.25 -6733.97', '6646.66 143.07 -6605.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_lolamap_v2', 4, '4475.62 -4418.55 3714.38', '4683.86 -4204.34 4497.77');
INSERT INTO "main"."game_zones" VALUES ('bhop_lolamap_v2', 3, '9826.63 7003.01 4008.84', '10313.97 7114.97 4520.05');
INSERT INTO "main"."game_zones" VALUES ('bhop_lolamap_v2', 2, '9986.50 6998.08 3654.03', '10154.46 7085.78 3782.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_the_distance', 0, '-14992.00 -6415.97 32.03', '-14000.03 -6305.17 160.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_the_distance', 1, '5890.55 3462.07 1042.03', '6127.99 3707.40 1170.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_the_distance', 2, '-4155.51 -4623.97 1920.03', '-3984.03 -4144.03 2048.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_the_distance', 3, '-12271.97 592.03 -8127.97', '-11536.00 1077.46 -7999.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_fix', 3, '873.00 -4001.90 1918.03', '915.08 -3962.01 2046.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_fix', 2, '-2895.30 -3165.45 4925.03', '-2841.03 -3107.03 5053.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_null_v2', 0, '-239.84 352.03 80.03', '241.08 510.94 208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_null_v2', 1, '-8991.94 1263.76 1200.03', '-8542.57 1711.38 1400.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_essence', 0, '592.01 -258.54 96.03', '1193.92 -173.37 224.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_essence', 1, '-607.97 992.41 224.03', '-464.03 1118.19 352.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_essence', 4, '-207.97 160.00 96.03', '-161.58 719.98 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_nyrox', 0, '1696.03 -999.97 -3245.97', '2255.97 -848.03 -3117.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_nyrox', 1, '16.03 6031.97 -4623.97', '1007.97 6255.97 -4495.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_nyrox', 2, '-1263.15 29.49 -1375.97', '-1007.81 288.00 -1247.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_nyrox', 3, '-1778.86 680.00 -415.97', '-1618.24 839.97 -287.97');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_essence', 2, '3823.49 644.27 -1679.97', '3903.97 719.97 -1551.97');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_essence', 3, '3510.76 -5808.00 -2719.97', '3585.61 -5768.06 -2591.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_boatylicious', 0, '-180.99 -178.36 8224.03', '180.50 182.51 8352.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_boatylicious', 1, '-295.89 -298.26 1032.03', '300.97 292.95 1160.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_boatylicious', 2, '-62.72 -61.45 8848.03', '66.14 65.61 8976.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_boatylicious', 3, '258.86 -337.17 1941.39', '306.04 -308.95 2096.40');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_rainbows_fix', 1, '1009.19 -2144.71 1560.03', '1088.77 -2055.59 1688.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_letour', 2, '3304.03 11636.40 1480.03', '3399.97 11721.97 1608.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_letour', 3, '48.03 16.03 528.03', '559.77 496.00 656.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_highfly', 2, '-5364.97 25.03 5096.03', '-5289.88 95.59 5116.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_highfly', 3, '-5355.28 -1328.38 3391.36', '-5310.05 -1271.17 3471.36');
INSERT INTO "main"."game_zones" VALUES ('bhop_fuckfear_fix', 2, '1023.93 -302.98 776.04', '1031.93 -296.74 777.04');
INSERT INTO "main"."game_zones" VALUES ('bhop_fuckfear_fix', 3, '-567.98 -471.97 328.03', '-545.44 -451.91 456.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_thc_island', 4, '11.72 -2343.47 244.37', '520.04 -2206.72 800.58');
INSERT INTO "main"."game_zones" VALUES ('bhop_tasku', 2, '6585.42 -4416.34 96.03', '6792.90 -3439.65 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tasku', 3, '-1619.86 -4119.53 390.65', '-1157.48 -4066.77 519.86');
INSERT INTO "main"."game_zones" VALUES ('bhop_fresh', 1, '-1805.93 -10562.56 5154.03', '-911.25 -9986.77 5282.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_evo_v2', 0, '-6108.00 2955.03 -463.97', '-5937.99 3522.97 -335.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_evo_v2', 1, '-7627.97 2216.89 -536.97', '-7127.82 2422.97 -408.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_pinky', 3, '976.29 -722.04 355.45', '1022.23 -677.80 525.60');
INSERT INTO "main"."game_zones" VALUES ('bhop_pinky', 2, '1294.41 2207.41 160.03', '1327.99 2224.00 220.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_together', 2, '2016.06 -3227.66 1560.56', '2093.02 -3177.41 1630.56');
INSERT INTO "main"."game_zones" VALUES ('bhop_together', 3, '1560.82 -3207.16 2515.48', '1717.54 -3072.09 2656.36');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego', 2, '2416.94 -223.97 416.03', '2479.01 -20.90 544.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lego', 3, '3470.86 -1895.95 -2399.97', '3816.94 -1760.03 -2271.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist', 6, '-925.97 -1417.97 1297.03', '-925.97 -1339.78 1425.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist', 4, '-925.97 -1417.97 1297.03', '-925.97 -1342.39 1425.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_stronghold', 2, '7114.01 -6767.97 768.03', '7343.98 -6416.03 896.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_stronghold', 3, '6383.88 -8152.34 1344.03', '6417.53 -8088.10 1496.29');
INSERT INTO "main"."game_zones" VALUES ('bhop_inmomentum_gfl_final', 0, '2143.68 4152.03 -271.97', '2373.97 4631.97 -143.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_inmomentum_gfl_final', 1, '5278.21 4208.03 -383.97', '5680.47 4431.97 -255.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_shrubhop', 3, '-2365.41 -4387.50 -471.71', '-2329.87 -4296.75 -286.11');
INSERT INTO "main"."game_zones" VALUES ('bhop_shrubhop', 2, '298.63 -3133.00 -335.97', '383.97 -3056.03 -207.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_house', 6, '-1374.98 -1752.84 -606.47', '-534.45 8486.32 428.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_3', 4, '-1851.65 -1767.97 -575.97', '-1795.87 -1152.03 -179.41');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_3', 4, '-1403.65 -1998.75 -575.97', '-1392.03 -1152.03 -62.11');
INSERT INTO "main"."game_zones" VALUES ('bhop_snowy', 0, '-122.38 -146.71 112.03', '74.15 173.38 240.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_snowy', 1, '-15599.97 3216.00 -623.97', '-14985.47 4111.99 -495.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_2flocci2furious', 2, '-3057.53 -2757.17 -9439.07', '-2968.88 -2411.34 -9311.07');
INSERT INTO "main"."game_zones" VALUES ('bhop_2flocci2furious', 3, '-1139.81 -2613.99 -8378.57', '-1079.24 -2484.31 -8250.57');
INSERT INTO "main"."game_zones" VALUES ('bhop_flocci', 2, '-4333.11 15095.42 1271.04', '-4042.15 15300.59 1417.29');
INSERT INTO "main"."game_zones" VALUES ('bhop_flocci', 3, '666.76 13908.16 1539.03', '700.55 14050.92 1852.00');
INSERT INTO "main"."game_zones" VALUES ('bhop_3d', 2, '3618.42 2104.37 -607.97', '3727.64 2119.11 -591.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_3d', 3, '4432.00 -1470.60 -55.97', '4442.02 -1281.52 72.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_k26000_b2', 2, '-385.57 208.36 -1436.63', '-334.72 239.04 -1308.63');
INSERT INTO "main"."game_zones" VALUES ('bhop_k26000_b2', 3, '12353.04 237.17 -1436.63', '12394.42 258.98 -1308.63');
INSERT INTO "main"."game_zones" VALUES ('bhop_exodus', 0, '3312.65 817.69 1856.03', '3470.44 974.56 1984.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_exodus', 1, '6160.28 11152.03 3576.03', '6261.69 11370.06 3704.47');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy', 2, '-2191.97 -1839.97 64.03', '-2022.48 -1616.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy', 3, '-2191.97 -975.97 64.03', '-2029.06 -752.03 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_null_v2', 2, '14944.04 1838.56 752.03', '14993.87 1887.97 880.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_null_v2', 3, '15731.07 1056.00 944.03', '15775.97 1102.60 1072.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_communityjump', 0, '-495.97 336.03 -511.97', '239.97 687.16 -383.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_communityjump', 1, '-11064.01 10887.06 -5295.97', '-10950.22 11003.11 -5167.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_communityjump', 2, '8592.03 5800.03 1448.03', '8623.98 5902.35 1576.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_communityjump', 3, '9029.64 5890.16 3296.02', '9135.97 5999.97 3424.02');
INSERT INTO "main"."game_zones" VALUES ('bhop_lj_minecraft_beta', 0, '-496.00 -1135.97 128.03', '-266.99 -528.03 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lj_minecraft_beta', 1, '-493.97 1236.03 128.03', '241.97 1971.97 256.95');
INSERT INTO "main"."game_zones" VALUES ('bhop_lj_minecraft_beta', 2, '257.47 528.02 320.03', '312.57 573.84 448.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_lj_minecraft_beta', 3, '2307.00 -3837.33 256.03', '2357.93 -3783.12 384.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_rainbows_fix', 0, '-89.05 159.62 112.03', '-26.01 320.23 240.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_m41n5tr34m', 0, '-3444.97 -1909.42 36.03', '-3086.93 -1677.23 164.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_m41n5tr34m', 1, '5816.22 7482.03 40.03', '6115.97 7819.97 168.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_redwood', 2, '-218.11 2925.53 640.03', '-177.48 2972.39 768.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_redwood', 3, '1541.31 1103.76 738.62', '1565.24 1134.18 901.36');
INSERT INTO "main"."game_zones" VALUES ('bhop_exodus', 2, '837.89 -700.84 -511.97', '890.71 -644.13 -383.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_exodus', 3, '-987.35 464.73 96.03', '-931.47 512.24 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eman_on', 2, '-4608.02 -9248.97 729.03', '-4573.08 -9212.96 857.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eman_on', 3, '-1189.77 -13083.29 -3391.01', '-1146.05 -13041.96 -3263.01');
INSERT INTO "main"."game_zones" VALUES ('bhop_time_pro', 0, '-7791.97 592.03 64.03', '-7381.88 1199.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_time_pro', 1, '-3096.00 669.11 256.03', '-3073.63 1135.97 384.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_m41n5tr34m', 2, '992.04 -4504.97 63.03', '1074.97 -4420.22 191.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_m41n5tr34m', 3, '-2814.97 -3627.40 63.03', '-2724.40 -3543.00 191.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_sakura', 0, '-903.97 1954.01 -664.97', '-688.00 2047.97 -536.97');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_sakura', 1, '2517.62 2145.64 1768.03', '2769.05 2301.55 1896.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_sakura', 2, '-4125.26 -1247.97 704.03', '-3962.88 -768.09 832.03');
INSERT INTO "main"."game_zones" VALUES ('kz_bhop_sakura', 3, '-3167.37 -1247.98 -383.97', '-2997.19 -768.03 -255.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_trampislow', 0, '3566.84 245.68 -2976.97', '4405.16 700.55 -2848.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_trampislow', 1, '-5036.97 -2468.39 -6147.97', '-4059.02 -1539.03 -6019.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_3', 2, '5600.30 -3704.49 7296.03', '5951.99 -3473.56 7424.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_3', 3, '5600.01 -12008.34 7291.57', '5951.97 -11916.34 7419.57');
INSERT INTO "main"."game_zones" VALUES ('bhop_omn', 2, '-6254.97 2413.03 -1118.97', '-5894.44 3050.97 -990.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_omn', 3, '-7081.97 2489.01 -4705.16', '-6542.03 2947.97 -4577.16');
INSERT INTO "main"."game_zones" VALUES ('bhop_trampislow', 2, '-6976.22 3463.06 -7600.63', '-6869.68 3580.78 -7466.69');
INSERT INTO "main"."game_zones" VALUES ('bhop_trampislow', 3, '-3879.26 3833.35 -7672.72', '-3753.14 3919.17 -7535.32');
INSERT INTO "main"."game_zones" VALUES ('bhop_toc', 2, '-9199.16 -13072.00 -2239.97', '-8735.62 -12850.70 -2111.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_toc', 3, '-9199.97 432.02 -2239.97', '-8656.07 719.99 -2111.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kiwi_cwfx', 3, '3665.45 228.07 -43.49', '3720.70 280.41 88.66');
INSERT INTO "main"."game_zones" VALUES ('bhop_kiwi_cwfx', 2, '-6671.97 193.98 384.03', '-6590.55 271.97 512.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_pro_bhopper_mp', 2, '-2799.98 1561.97 -287.97', '-2712.25 1647.97 -159.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_pro_bhopper_mp', 3, '2417.10 400.07 8.03', '2495.97 479.99 136.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_cobblestone', 7, '631.41 2756.60 288.02', '743.97 2893.08 416.05');
INSERT INTO "main"."game_zones" VALUES ('bhop_miku_v2', 4, '-2590.35 1041.14 -83.75', '-2435.55 1088.29 69.19');
INSERT INTO "main"."game_zones" VALUES ('bhop_miku_v2', 2, '2250.64 2510.25 -72.81', '2310.10 2568.31 70.72');
INSERT INTO "main"."game_zones" VALUES ('bhop_miku_v2', 3, '-2779.02 1547.69 -87.16', '-2683.33 1629.67 65.77');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_femto', 2, '-4111.99 6296.20 -1759.97', '-4033.16 6376.00 -1631.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_femto', 3, '976.03 -2287.97 -2367.97', '1135.97 -1616.03 -2239.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_ocean', 2, '-3454.40 417.09 173.75', '-3385.57 487.64 301.75');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_ocean', 3, '493.48 2500.98 301.16', '663.10 2649.90 432.34');
INSERT INTO "main"."game_zones" VALUES ('bhop_nacho_libre_simo', 2, '-1511.03 433.57 448.03', '-1453.44 488.47 576.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_nacho_libre_simo', 3, '-60.81 -2545.93 -1023.97', '-11.43 -2498.47 -895.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_legion', 2, '-1527.97 2000.03 0.03', '-1290.06 2607.97 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_legion', 3, '-1767.97 2648.00 0.03', '-1644.95 3255.97 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tesquo_v2', 0, '-658.23 -567.97 176.03', '-499.21 -424.03 304.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tesquo_v2', 1, '-4285.10 4228.41 2032.03', '-4151.23 4366.50 2160.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy_v2', 2, '4528.00 2512.03 48.03', '4709.06 2863.97 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy_v2', 3, '4528.03 3760.01 48.03', '4722.27 4112.00 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_badges', 7, '-1496.91 -7662.29 -13276.94', '-1467.06 -7162.01 -13136.30');
INSERT INTO "main"."game_zones" VALUES ('bhop_eazy_v2', 4, '4464.00 -207.99 208.03', '6479.99 1455.99 336.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_arcane2_a06', 0, '1433.33 -130.01 -767.24', '1642.09 192.11 -636.71');
INSERT INTO "main"."game_zones" VALUES ('bhop_arcane2_a06', 1, '-6936.33 -9944.70 -6073.02', '-6680.75 -9871.65 -5930.53');
INSERT INTO "main"."game_zones" VALUES ('bhop_awful2', 0, '-2607.91 1040.03 -1951.97', '-2256.14 1519.97 -1823.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_awful2', 1, '5072.87 -10285.25 1024.03', '9266.95 -6096.27 1152.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_blue_aux', 0, '16.01 25.84 48.03', '367.97 230.29 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_blue_aux', 1, '-1472.00 448.07 -271.97', '-1168.01 735.97 -143.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_bob_v1', 0, '-111.97 -14832.20 -479.97', '111.97 -14728.90 -351.66');
INSERT INTO "main"."game_zones" VALUES ('bhop_bob_v1', 1, '-223.99 -15584.00 -831.97', '223.97 -15200.74 -703.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_choice', 0, '16.03 -1.83 96.03', '495.97 177.30 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_choice', 1, '16.03 -1797.70 448.03', '495.97 -1491.09 576.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_choice', 2, '16.03 -5672.00 -959.97', '496.00 -5467.16 -831.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_choice', 6, '16.03 -5672.00 -959.97', '495.97 -5467.16 -831.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_choice', 3, '-469.96 -4711.97 -959.97', '-144.03 -4232.03 -831.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_christmas', 0, '-3822.11 1658.85 64.03', '-3506.54 1802.74 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_christmas', 1, '-6318.85 7168.03 400.03', '-6209.29 7399.97 528.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aztec_fixed', 0, '0.03 -285.04 72.03', '399.97 -46.43 152.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aztec_fixed', 1, '-1935.00 -715.14 -163.97', '-1583.03 -486.03 -35.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_aztec_fixed', 6, '-1955.17 -871.49 -19.97', '-1558.27 -462.65 108.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_duality_v2', 0, '38.36 -130.65 56.15', '194.07 139.16 184.15');
INSERT INTO "main"."game_zones" VALUES ('bhop_duality_v2', 1, '-143.97 -359.99 -639.39', '547.53 735.97 -511.39');
INSERT INTO "main"."game_zones" VALUES ('bhop_freedompuppies_new', 0, '2193.68 528.03 72.03', '2398.66 1007.97 200.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_freedompuppies_new', 1, '596.05 -1505.41 1400.03', '760.59 -1341.10 1528.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hopi_noproblem_v1', 0, '-238.22 15.90 -127.97', '239.99 208.56 0.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hopi_noproblem_v1', 1, '-2351.02 -1008.00 -4799.97', '-2128.03 -528.01 -4671.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_icebase', 0, '-8111.47 -6493.96 -63.97', '-7828.43 -6317.19 64.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_icebase', 1, '8535.66 4808.57 -223.97', '8806.53 5079.81 -95.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_japan', 0, '2194.17 -7465.59 480.03', '2408.68 -7191.57 608.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_japan', 1, '5728.03 -7944.38 480.03', '6719.97 -7583.03 608.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_volcano', 0, '2588.93 -3558.12 -319.99', '2883.67 -3088.85 -191.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_volcano', 6, '-314.22 -268.31 -319.97', '239.99 230.00 -169.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_volcano', 1, '623.28 -125.95 128.03', '1166.08 329.57 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_legenda_v2', 6, '-1867.13 15.00 -177.09', '-1528.33 82.97 29.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_mapsuck', 0, '-1647.98 -175.97 -447.97', '-1371.42 495.98 -319.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_mapsuck', 1, '4625.99 -2287.98 -2303.97', '5231.97 -528.00 -2175.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_mario_fxd', 0, '5100.03 -2427.97 -3794.97', '5707.99 -2270.07 -3666.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_mario_fxd', 1, '-7226.91 -3205.87 13096.43', '-6720.30 -2624.44 13224.43');
INSERT INTO "main"."game_zones" VALUES ('bhop_mcginis_fix', 6, '-7207.05 -2940.26 -1575.45', '-7079.34 -2689.22 -1202.47');
INSERT INTO "main"."game_zones" VALUES ('bhop_reding', 0, '528.05 -207.99 192.03', '591.99 81.37 320.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_reding', 1, '625.31 -207.97 448.03', '878.97 207.97 576.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_sourcejump', 0, '-1808.00 -5519.97 64.03', '-1456.00 -5423.10 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_sourcejump', 1, '-12191.97 -1039.99 80.03', '-11952.03 -895.77 208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_space', 0, '2862.89 11856.32 160.03', '3217.14 11951.50 288.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_space', 1, '8636.64 -1279.20 865.03', '8828.91 -1088.06 993.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jx', 0, '-305.96 -112.67 64.03', '-199.63 191.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jx', 1, '9017.03 -7936.07 -1918.97', '9409.13 -7424.56 -1790.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_summer', 0, '-7015.95 -3933.59 -2127.97', '-6900.40 -3832.07 -1999.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_strafe_summer', 1, '-4581.84 -5149.12 488.03', '-4299.06 -4834.77 616.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tut_v2', 0, '-12783.85 -13295.97 48.03', '-12432.03 -13136.45 176.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tut_v2', 1, '-13230.07 -11824.00 -1983.97', '-13072.03 -11536.33 -1855.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_twisted', 1, '8342.72 326.13 96.03', '8790.05 903.61 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_twisted', 0, '55.50 48.03 96.00', '552.49 234.34 224.01');
INSERT INTO "main"."game_zones" VALUES ('bhop_veritas', 0, '112.03 2000.03 200.03', '333.19 2479.97 328.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_veritas', 1, '2576.03 -623.97 -751.97', '3053.00 -400.03 -623.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_wayz', 0, '-239.97 -175.97 -63.97', '239.49 509.97 64.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_wayz', 1, '3231.03 -2356.00 -671.97', '4679.97 -888.00 -243.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_white', 0, '473.33 -374.97 144.03', '629.97 241.97 272.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_white', 1, '256.36 1964.01 144.03', '423.97 2580.97 272.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_soaatana', 1, '4463.03 -6000.04 -447.97', '4783.97 -5392.02 -319.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_soaatana', 0, '31.84 96.98 128.23', '288.35 353.23 256.23');
INSERT INTO "main"."game_zones" VALUES ('bhop_dretox', 0, '-9645.42 -9896.19 -1243.97', '-9164.59 -9674.95 -1115.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_dretox', 1, '2736.03 -3983.07 -2047.97', '3183.97 -3600.03 -1919.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_speedrun_skyline', 0, '319.95 -287.23 2080.03', '479.93 -96.85 2208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_speedrun_skyline', 1, '4464.99 9951.90 2080.03', '4655.89 10206.95 2208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jegypt', 0, '-848.69 -81.08 288.03', '-590.29 336.40 416.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jegypt', 1, '-4480.00 -10944.84 -143.97', '-4192.39 -10497.01 -15.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_0', 0, '-392.90 193.51 -63.97', '64.67 456.33 64.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_0', 1, '5803.61 906.84 -1375.97', '6136.30 1145.70 -1247.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_soft', 0, '-463.97 1136.03 -31.97', '463.97 1503.67 96.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_soft', 1, '-3344.15 6224.37 352.03', '-2836.42 6635.43 664.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jib_jib', 0, '-112.00 -1455.97 0.03', '111.90 -1247.33 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jib_jib', 1, '720.03 -1219.97 -55.97', '1263.97 -740.03 72.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_pologos_fix', 0, '-1849.00 -2536.87 928.13', '-1217.73 -2001.14 1056.13');
INSERT INTO "main"."game_zones" VALUES ('bhop_pologos_fix', 6, '-9311.73 -3947.58 2328.79', '-8827.17 -2903.76 2821.30');
INSERT INTO "main"."game_zones" VALUES ('bhop_pologos_fix', 1, '-10103.33 -3108.62 2615.64', '-9774.21 -1864.98 2743.83');
INSERT INTO "main"."game_zones" VALUES ('bhop_0', 3, '1421.17 1291.43 -735.97', '1533.06 1401.03 -607.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_0', 2, '5392.14 4111.05 -671.97', '5747.41 4338.98 -543.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_pologos_fix', 6, '-3309.97 -3535.40 1037.06', '-2314.10 -3047.68 1497.32');
INSERT INTO "main"."game_zones" VALUES ('bhop_mcginis_fix', 6, '-7202.82 -3130.58 -1612.02', '-6633.66 -2944.02 -1192.43');
INSERT INTO "main"."game_zones" VALUES ('bhop_mcginis_fix', 6, '-6810.10 -2941.32 -1651.82', '-6634.42 -2700.91 -1181.43');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_4', 0, '-547.07 -148.97 -435.97', '-477.00 -13.03 -307.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_mist_4', 1, '13604.93 2944.40 3977.03', '13798.97 3136.52 4105.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_whoevenbhops_final', 1, '-7240.85 7327.76 -750.81', '-6591.58 7941.67 -620.84');
INSERT INTO "main"."game_zones" VALUES ('bhop_whoevenbhops_final', 6, '-3552.66 -4721.82 -1554.37', '2350.50 7340.73 -1426.37');
INSERT INTO "main"."game_zones" VALUES ('bhop_whoevenbhops_final', 0, '-304.70 2213.84 1002.80', '-133.12 2656.59 1135.67');
INSERT INTO "main"."game_zones" VALUES ('bhop_hexag0n', 0, '608.33 -1185.70 192.03', '895.86 -1120.20 320.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_hexag0n', 1, '-5151.31 -2846.65 192.03', '-4803.13 -2749.76 320.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_scrollcity', 0, '1041.30 367.83 128.03', '1516.32 558.35 256.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_scrollcity', 1, '84.12 83.63 -767.97', '467.58 435.94 -487.46');
INSERT INTO "main"."game_zones" VALUES ('bhop_scrollcity', 6, '-1792.25 -1856.42 640.03', '-1280.80 -1279.46 768.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_proving_a_point', 0, '-495.99 -352.03 96.03', '-16.03 -16.28 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_proving_a_point', 2, '-496.00 -1136.55 96.03', '-16.03 -928.01 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_proving_a_point', 1, '528.03 -495.97 96.03', '1007.92 -16.00 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_proving_a_point', 3, '-1520.16 -1135.97 96.03', '-1040.02 -656.03 224.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_seiz', 0, '528.03 1040.00 1152.03', '1007.97 1389.10 1280.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_seiz', 1, '5779.27 5264.03 1152.03', '6127.99 5743.97 1280.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_smokee_2_fix', 0, '16.00 -47.97 64.03', '112.99 207.97 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_smokee_2_fix', 1, '4704.02 552.03 -3191.97', '5120.00 967.99 -3063.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_pims_cwfx', 0, '735.40 -3681.97 -87.97', '975.97 -3400.03 40.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_pims_cwfx', 1, '-720.85 2444.36 -87.97', '-404.30 2651.08 40.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_chillhop', 0, '-4783.99 2898.16 0.03', '-4498.99 2987.50 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_chillhop', 1, '272.54 -2799.97 512.03', '432.42 -2576.03 640.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_cartooncastle', 1, '-2623.02 800.03 16.03', '-2401.91 1183.97 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kz_cartooncastle', 0, '224.03 -1485.72 16.03', '607.97 -1383.07 144.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kerpele', 1, '1941.89 -6423.66 336.03', '2357.10 -6006.51 464.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_kerpele', 0, '-880.92 -367.34 80.03', '-656.68 -142.87 208.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_paskaaa', 0, '-511.97 -639.97 208.03', '-277.29 -404.48 336.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_paskaaa', 1, '-6639.41 6816.03 704.03', '-5712.01 7519.97 832.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_despondent', 1, '-2623.90 -929.98 192.03', '-2400.00 -676.03 450.01');
INSERT INTO "main"."game_zones" VALUES ('bhop_despondent', 0, '-318.85 -95.95 64.03', '-62.89 320.00 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aster', 0, '-110.81 16.03 0.03', '-16.01 495.97 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_aster', 1, '2133.76 2064.03 -1663.97', '2288.31 2283.90 -1535.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_tropics', 0, '-760.45 -14.97 42.03', '-702.51 534.77 170.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_tropics', 1, '7792.87 -3291.97 40.03', '8048.97 -2778.03 304.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_sketchy_v4', 1, '-5167.99 -2672.05 240.03', '-4272.03 -1456.03 368.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_sketchy_v4', 0, '-239.97 561.01 192.03', '239.97 671.38 320.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jungle3k', 0, '-888.00 -379.64 -29.97', '-657.87 -148.69 98.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_jungle3k', 1, '8440.03 408.03 384.03', '9207.97 1175.97 512.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_slayer_fixed', 0, '-285.98 33.26 64.03', '-16.03 222.30 192.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_slayer_fixed', 1, '2126.03 1059.31 -1353.97', '3107.97 1259.97 -1225.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_paskaaa', 6, '-30.45 114.82 805.45', '353.30 380.07 940.77');
INSERT INTO "main"."game_zones" VALUES ('bhop_paskaaa', 6, '252.66 -517.95 776.81', '593.39 219.14 977.45');
INSERT INTO "main"."game_zones" VALUES ('bhop_voyage', 0, '-10879.97 -14028.06 -663.97', '-10656.03 -14001.70 -535.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_voyage', 1, '-351.52 8800.02 -13815.97', '351.86 9196.94 -13687.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_ogel', 1, '6352.45 1008.03 832.03', '6448.00 1327.97 960.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_ogel', 2, '2656.54 -1089.33 -1655.97', '2720.15 -1025.71 -1631.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_ogel', 3, '3217.16 -496.25 -1343.97', '3279.97 -368.01 -1215.97');
INSERT INTO "main"."game_zones" VALUES ('bhop_ogel', 0, '-239.97 -239.97 0.03', '-16.03 48.34 128.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_speedrun_habitat_v2', 1, '1440.22 484.13 602.03', '1880.31 803.14 730.03');
INSERT INTO "main"."game_zones" VALUES ('bhop_speedrun_habitat_v2', 0, '2760.51 -1649.97 68.03', '2848.00 -982.03 196.03');