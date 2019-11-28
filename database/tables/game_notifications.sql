/*
Navicat SQLite Data Transfer

Source Server         : GarrysModDS
Source Server Version : 30714
Source Host           : :0

Target Server Type    : SQLite
Target Server Version : 30714
File Encoding         : 65001

Date: 2015-10-23 20:05:26
*/

PRAGMA foreign_keys = OFF;

-- ----------------------------
-- Table structure for game_notifications
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_notifications";
CREATE TABLE "game_notifications" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"szUID"  TEXT NOT NULL,
"szMap"  TEXT NOT NULL,
"szName"  TEXT,
"nStyle"  INTEGER NOT NULL,
"nDifference"  INTEGER NOT NULL,
"nDate"  INTEGER NOT NULL
);
