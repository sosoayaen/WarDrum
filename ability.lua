--- 异能模块，从属于卡牌模块的一个属性
-- @class module
-- @author Jason Tou sosoayaen@gmail.com
-- @copyright Jason Tou
module("Ablity", package.seeall)

local const_mt = {
	-- 不允许中途修改值
	__newindex = function(t, k, v) end
}

--- 静态变量的定义表
-- @class table
-- @name CONSTANTS
-- @field LIMITLESS 表示无限响应
-- @field answerWindow 异能响应窗口枚举
-- @field influencePropertyTarget 异能作用（影响，效果）目标
-- @field targetInfluenceRange 目标作用范围，全员、己方全员、敌方全员、全员任意单位（符合条件）、己方任意单位（符合条件）等
-- @field targetChooseTactics 异能选择目标单位类型策略、条件，配合 targetInfluenceRange 属性
-- @field targetChooseTacticsExt 异能选择额外判断，是否取反等
CONSTANTS = {
	-- 无限
	LIMITLESS = -1,
	
	-- 异能响应窗口
	answerWindow = {
		-- 无效窗口，保留
		WINDOW_INVALID = 0,
		-- 回合开始
		WINDOW_ROUND_START = 1,
		-- 行动开始
		WINDOW_ACTION_START = 2,
		-- 目标指定前
		WINDOW_TARGET_CHOOSE = 3,
		-- 目标指定时
		WINDOW_TARGET_CHOOSE_AFTER = 4,
		-- 攻击之前
		WINDOW_ATTACK_BEFORE = 5,
		-- 攻击之后
		WINDOW_ATTACK_AFTER = 6,
		-- 防御之前
		WINDOW_DEFEND_BEFORE = 7,
		-- 防御之后
		WINDOW_DEFEND_AFTER = 8,
		-- 回合结束
		WINDOW_ROUND_END = 9,
		-- 局结束
		WINDOW_MATCH_END = 10,
		-- 死亡窗口
		WINDOW_DEATH = 100
	},
	-- 异能作用的属性
	influencePropertyTarget = {
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
	targetInfluenceRange = {
		-- 全场有效（活着）单位效果
		ALL = 0,
		-- 任意单体
		ANY = 1,
		-- 己方任意单体效果
		ANY_WE = 2,
		-- 敌方任意单体
		ANY_OPPONENT = 3,
		-- 己方全员
		ALL_WE = 4,
		-- 敌方全员
		ALL_OPPONENT = 5
	},
	-- 异能选择目标单位类型策略
	targetChooseTactics = {
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
	targetChooseTacticsExt = {
		-- 默认值
		NORMAL_FLAG = 0,
		-- 取反
		NOT_FLAG = 1,
	}
}

-- 设置元表
setmetatable(CONSTANTS, const_mt)

--- 异能属性基类
-- @class table
-- @name ExceptionalAbilityClass
-- @field keyWord 异能关键字（暂时保留）
-- @field description <code>string</code> 当前异能的描述
-- @field action <code>table</table> 响应属性 @see ExceptionalAbilityClass.action
-- @field property <code>table</code> 异能属性 @see ExceptionalAbilityClass.property
-- @field targetList 异能影响的目标列表
-- @see CONSTANTS
local ExceptionalAbilityClass = {
	-- 技能关键字
	keyWord = "null",
	
	-- 技能描述
	description = "",
	
	-- 响应属性，在什么时候响应
	-- @class table
	-- @field counts 响应次数
	-- @field answerWindow 响应时机 @see CONSTANTS.answerWindow
	action = {
		-- ////////////
		-- 响应次数
		-- 大于0表示次数，-1表示无限响应, 0 表示不响应
		counts = 0,
		
		-- ///////////
		-- 响应时机
		-- @see CONSTANTS.answerWindow
		answerWindow = CONSTANTS.answerWindow.WINDOW_INVALID,
	},
	-- //////////////
	-- 异能属性
	-- @class table
	-- @field targetInfluenceRange 异能目标范围
	property = {
		-- 异能目标范围
		-- 表明此异能的目标是全体还是单体，还有己方和敌方
		-- @see CONSTANTS.targetInfluenceRange
		targetInfluenceRange = CONSTANTS.targetInfluenceRange.ANY, -- 默认单体
		
		-- 异能作用属性
		-- 表明此异能会改变的属性，目前无非 『攻击力』、『速度』、『血量』
		-- @see CONSTANTS.influencePropertyTarget
		influenceType = CONSTANTS.influencePropertyTarget.ATTACK,
		
		-- 异能影响的数值
		-- 表明此异能发动后，根据influenceType属性来结算效果值，值有正负之分，直接累加结算
		-- @example 1. influenceType == CONSTANTS.influencePropertyTarget.ATTACK
		--               2. influenceValue == 1
		--               3. action.answerWindow == CONSTANTS.answerWindow.WINDOW_ATTACK_BEFORE
		--               4. targetInfluenceRange == CONSTANTS.targetInfluenceRange.ALL_WE
		--               5. influenceResponseCount = 1
		--               7. liquidateRemoveAbility = true
		--               8. persistentHostUnit = -1 表示无需施法单位
		--               这表示在行动攻击前的窗口结算，在攻击前给己方所有单位增加1点攻击力BUFF，结算后取消
		influenceValue = 1,
		
		-- 异能响应次数，-1表示无限响应
		influenceResponseCount = 1,
		
		-- 异能是否需要持续施法单位 -1 表示无需施法单位
		persistentHostUnit = -1,
		
		-- 是否发动后直接取消（在清算、结算阶段移除此技能）
		liquidateRemoveAbility = true,
	},
	
	-- 异能起效对象列表，标记受该技能影响的单位（待定）
	-- @runtime
	targetList = {},
}

--- 对象创建
-- @class function
-- @param o 可传可不传
-- @return 返回一个ExceptionalAbilityClass的实例
function ExceptionalAbilityClass:new(o)
	o = o or {}
	
	-- 设置元表
	setmetatable(o, self)
	
	-- 设置对应搜索路径为ExceptionalAbilityClass本身
	-- 使实例拥有对应的成员函数和成员变量
	self.__index = self
	
	-- 重写其输出格式
	self.__tostring = function(t)
		
	end
	
	-- 返回实例
	return o
end

-- 返回工厂类
return ExceptionalAbilityClass