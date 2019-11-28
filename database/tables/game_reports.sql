/*
Navicat SQLite Data Transfer

Source Server         : GarrysModDS
Source Server Version : 30714
Source Host           : :0

Target Server Type    : SQLite
Target Server Version : 30714
File Encoding         : 65001

Date: 2015-10-23 20:05:39
*/

PRAGMA foreign_keys = OFF;

-- ----------------------------
-- Table structure for game_reports
-- ----------------------------
DROP TABLE IF EXISTS "main"."game_reports";
CREATE TABLE "game_reports" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"nType"  INTEGER NOT NULL,
"szTarget"  TEXT,
"szComment"  TEXT,
"nDate"  INTEGER NOT NULL,
"szReporter"  TEXT NOT NULL,
"szHandled"  TEXT,
"szEvidence"  TEXT
);
