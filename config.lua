--- 公共数据模块
-- @class module

module("Config", package.seeall)

--- 静态变量的定义表
-- @class table
-- @name CONSTANTS
-- @field LIMITLESS 表示无限响应
-- @field ABILITY_ANSWER_WINDOW 异能响应窗口枚举
-- <ul><li><b>WINDOW_INVALID</b>: 无效窗口，保留</li></ul>
-- <ul><li><b>WINDOW_ROUND_START</b>: 回合开始</li></ul>
-- <ul><li><b>WINDOW_ACTION_START</b>: 行动开始</li></ul>
-- <ul><li><b>WINDOW_TARGET_CHOOSE</b>:  目标指定前</li></ul>
-- <ul><li><b>WINDOW_TARGET_CHOOSE_AFTER</b>: 目标指定后</li></ul>
-- <ul><li><b>WINDOW_ATTACK_BEFORE</b>: 目标指定时</li></ul>
-- <ul><li><b>WINDOW_ATTACK_AFTER</b>: 攻击之后</li></ul>
-- <ul><li><b>WINDOW_DEFEND_BEFORE</b>: 防御之前</li></ul>
-- <ul><li><b>WINDOW_DEFEND_AFTER</b>: 防御之后</li></ul>
-- <ul><li><b>WINDOW_ROUND_END</b>: 回合结束</li></ul>
-- <ul><li><b>WINDOW_MATCH_END</b>: 局结束</li></ul>
-- <ul><li><b>WINDOW_DEATH</b>: 死亡窗口</li></ul>
-- @field ABILITY_INFLUENCE_PROPERTY_TARGET 异能作用（影响，效果）目标
-- <ul><li><b>INVALIDE</b>: 无任何影响</li></ul>
-- <ul><li><b>ATTACK</b>: 影响攻击力</li></ul>
-- <ul><li><b>HP</b>: 影响血量</li></ul>
-- <ul><li><b>SPEED</b>: 影响速度</li></ul>
-- @field ABILITY_TARGET_INFLUENCE_RANGE 目标作用范围，全员、己方全员、敌方全员、全员任意单位（符合条件）、己方任意单位（符合条件）等
-- @field ABILITY_TARGET_CHOOSE_TACTICS 异能选择目标单位类型策略、条件，配合 targetInfluenceRange 属性
-- <ul><li><b>INVALID</b>:无效单位（保留）</li></ul>
-- <ul><li><b>ACTIVE_UNIT</b>:目前行动的单位</li></ul>
-- <ul><li><b>DEFEND_UNIT</b>:目前防御的单位</li></ul>
-- <ul><li><b>RACE_LIMIT</b>:种族限制</li></ul>
-- <ul><li><b>ATTACK_TYPE_LIMIT</b>:攻击属性限制</li></ul>
-- <ul><li><b>ATTACK_LIMIT</b>:攻击力限制</li></ul>
-- <ul><li><b>SPEED_LIMIT</b>:速度限制</li></ul>
-- <ul><li><b>HP_LIMIT</b>:血量限制</li></ul>
-- <ul><li><b>CARD_NO_LIMIT</b>:特定卡牌</li></ul>
-- <ul><li><b>UNIT_NUM_LIMIT</b>:在场盟军数量限制</li></ul>
-- <ul><li><b>HP_SUMMATION</b>:血量合</li></ul>
-- <ul><li><b>ATTACK_SUMMATION</b>:攻击力合</li></ul>
-- @field targetChooseTacticsExt 异能选择额外判断，是否取反等
CONSTANTS = {
	-- 无限
	LIMITLESS = -1,
	
	-- 异能响应窗口
	ABILITY_ANSWER_WINDOW = {
		-- 无效窗口，保留
		WINDOW_INVALID = 0,
		-- 局开始
		WINDOW_MATCH_START = 1,
		-- 回合开始
		WINDOW_ROUND_START = 2,
		-- 行动开始
		WINDOW_ACTION_START = 3,
		-- 目标指定前
		WINDOW_TARGET_CHOOSE = 4,
		-- 目标指定时
		WINDOW_TARGET_CHOOSE_AFTER = 5,
		-- 攻击之前
		WINDOW_ATTACK_BEFORE = 6,
		-- 攻击之后
		WINDOW_ATTACK_AFTER = 7,
		-- 防御之前
		WINDOW_DEFEND_BEFORE = 8,
		-- 防御之后
		WINDOW_DEFEND_AFTER = 9,
		-- 行动结束
		WINDOW_ACTION_END = 10
		-- 回合结束
		WINDOW_ROUND_END = 11,
		-- 局结束
		WINDOW_MATCH_END = 12,
		-- 死亡窗口
		WINDOW_DEATH = 100
	},
	-- 异能作用的属性
	ABILITY_INFLUENCE_PROPERTY_TARGET = {
		-- 无任何影响
		INVALIDE = 0,
		-- 影响攻击力
		ATTACK = 1,
		-- 影响血量
		HP = 2,
		-- 影响速度
		SPEED = 3
	},
	-- 异能影响的单位范围，全员和单体
	ABILITY_TARGET_INFLUENCE_RANGE = {
		-- 全场单位
		ALL = 1,
		-- 任意单体
		ANY = 2,
		-- 己方任意单体效果
		ANY_WE = 3,
		-- 敌方任意单体
		ANY_OPPONENT = 4,
		-- 己方全员
		ALL_WE = 5,
		-- 敌方全员
		ALL_OPPONENT = 6,
		-- 自己
		ME = 7,
		-- 己方全员非自己
		ALL_WE_NOT_ME = 8,
	},
	-- 异能种类
	ABILITY_TYPES = {
		UNKNOW = 0,
		-- 光环类
		HOLO = 1,
		-- 
	},
	
	-- 异能选择目标单位类型策略
	ABILITY_TARGET_CHOOSE_TACTICS = {
		-- 无效单位（保留）
		INVALID = 0,
		-- 目前行动的单位
		ACTIVE_UNIT = 1,
		-- 目前防御的单位
		DEFEND_UNIT = 2,
		-- 种族限制
		RACE_LIMIT = 3,
		-- 攻击属性限制
		ATTACK_TYPE_LIMIT = 4,
		-- 攻击力限制
		ATTACK_LIMIT = 5,
		-- 速度限制
		SPEED_LIMIT = 6,
		-- 血量限制
		HP_LIMIT = 7,
		-- 特定卡牌
		CARD_NO_LIMIT = 8,
		-- 在场盟军数量限制
		UNIT_NUM_LIMIT = 9,
		-- 血量合
		HP_SUMMATION = 10,
		-- 攻击力合
		ATTACK_SUMMATION = 11,
	},
	
	-- 异能选择额外判断，是否取反等
	ABILITY_TARGET_CHOOSE_TACTICS_EXT = {
		-- 默认值
		NORMAL_FLAG = 0,
		-- 取反
		NOT_FLAG = 1,
	}
}
