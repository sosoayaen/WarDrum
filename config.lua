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
	ANSWER_WINDOW = {
		-- 循环窗口，只用作流程判断，游戏中并无次窗口定义
		WINDOW_CIRCLE = -1,
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
		WINDOW_ACTION_END = 10,
		-- 回合结束
		WINDOW_ROUND_END = 11,
		-- 局结束
		WINDOW_MATCH_END = 12,
		-- 死亡窗口
		WINDOW_DEATH = 100
	},
	ANSWER_WINDOW_DESC =
	{
		"局开始",
		"回合开始",
		"行动开始",
		"目标指定前",
		"目标指定后",
		"攻击之前",
		"攻击之后",
		"防御之前",
		"防御之后",
		"行动结束",
		"回合结束",
		"局结束",
	},
	-- 异能响应类型，只在自己行动的时候响应
	ANSWER_TYPE_ME = 1,
	-- 在己方行动时
	ANSWER_TYPE_WE = 2,
	-- 在地方行动的时候响应
	ANSWER_TYPE_OPPONENT = 3,
	-- 在所有单位行动的时候皆可响应
	ANSWER_TYPE_ALL = 4,
	
	-- 异能作用的属性
	ABILITY_INFLUENCE_PROPERTY_TARGET = {
		-- 无任何影响
		INVALIDE = 0,
		-- 影响攻击力
		ATTACK = 1,
		-- 影响血量
		HITPOINT = 2,
		-- 影响速度
		SPEED = 3
	},
	
	-- 异能条件判断所用的属性
	ABILITY_CONDITION_INFLUENCE_PROPERTY = {
	
		INVALIDE = 0,
		
		ATTACK = 1,
		
		HITPOINT = 2,
		
		SPEED = 3,
		
		-- 是否受伤
		GETHURT = 4,
	}
	-- 异能影响的单位范围，全员和单体
	-- ABILITY_TARGET_INFLUENCE_RANGE = {
		-- 全场单位
		TARGET_ALL = 1,
		-- 任意单体
		TARGET_ANY = 2,
		-- 己方任意单体效果
		TARGET_ANY_WE = 3,
		-- 敌方任意单体
		TARGET_ANY_OPPONENT = 4,
		-- 己方全员
		TARGET_ALL_WE = 5,
		-- 敌方全员
		TARGET_ALL_OPPONENT = 6,
		-- 自己
		TARGET_ME = 7,
		-- 己方全员非自己
		TARGET_ALL_WE_NOT_ME = 8,
		-- 敌方全员非目标单位
		TARGET_ALL_OPPONENT_NOT_TARGET = 9,
		-- 目前行动的单位
		TARGET_ACTION_UNIT = 10,
		-- 目前防御的单位
		TARGET_DEFEND_UNIT = 11,
		-- 己方行动单位
		TARGET_WE_ACTION_UNIT = 12,
		-- 己方防御单位
		TARGET_WE_DEFEND_UNIT = 13,
		-- 敌方行动单位
		TARGET_OPPONENT_ACTION_UNIT = 14,
		-- 敌方防御单位
		TARGET_OPPONENT_DEFEND_UNIT = 15,
--	},
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
	-- 异能用于判断条件的类型，如血量、或者目标是否受到伤害
	-- 异能选择额外判断，是否取反等
	ABILITY_TARGET_CHOOSE_TACTICS_EXT = {
		-- 默认值
		NORMAL_FLAG = 0,
		-- 取反
		NOT_FLAG = 1,
	},

	-- 条件判断标准
	JUDGE_STANDARD =
	{
		-- 无条件
		NONE = 0,
		-- 等于
		EQUALL = 1,
		-- 大于
		GREAT_THAN = 2,
		-- 大于等于
		GREAT_THAN_OR_EQUALL = 3,
		-- 小于
		LESS_THAN = 4,
		-- 小于等于
		LESS_THAN_OR_EQUALL = 5,
	},
	
	-- 异能作用相关宏定义
	-- 攻击力
	EFFECT_ATTACK = 1,
	-- 血量
	EFFECT_HITPOINT = 2,
	-- 速度
	EFFECT_SPEED = 3,
	
	-- 异能作用的状态类型
	-- 异能作用于属性效果，如攻击力等
	EFFECT_TYPE_PROPERTY = 1,
	-- 异能作用于异能状态，相当于异能起效后给对应的目标增加异能
	EFFECT_TYPE_ABILITY = 2,
	
	-- 用于条件判断的属性，如血量、攻击力等
	
}
