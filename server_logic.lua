--[[
	服务器业务处理流程
	小写字母开头的函数表示本地函数，大写的函数表示全局函数
]]
package.path = ".\\?.lua;" .. package.path
require "config"
require "comm"
require "card"
require "util"

-- 一些全局的状态和统计数值变量区域
local BattleSummaryDataTbl = {
	-- 当前行动造成的伤害值，行动开始时清空
	currentActionInjuryValue = 0,
	-- 存活列表
	aliveTable = {},
}

local showOriginalProperty = function(unit, property)
	if unit then
		print(property, unit:getOriginalValue(property))
	end
end

-- 攻击单位数据输出
local showAttackUnit = function(unit)
	if unit then
		print('攻击单位', unit.name, 'round', unit.round, 'groupID', unit.groupID, 'hitPoint', unit.hitPoint, 'attack', unit.attack)
	end
end

-- 防御单位数据输出
local showDefendUnit = function(unit)
	if unit then
		print('防御单位', unit.name, 'round', unit.round, 'groupID', unit.groupID, 'hitPoint', unit.hitPoint)
	end
end

-- 显示单位数据
local showUnit = function(unit)
	if unit then
		print(unit.name, 'groupID', unit.groupID, 'attack', unit.attack, 'speed', unit.speed, 'hitPoint', unit.hitPoint)
	end
end

local CONSTANTS = Config.CONSTANTS

-- 异能响应总表
local answerWindowAssistTable =
{
	-- 局开始
	[CONSTANTS.ANSWER_WINDOW.WINDOW_MATCH_START] = {},
	-- 回合开始
	[CONSTANTS.ANSWER_WINDOW.WINDOW_ROUND_START] = {},
	-- 行动开始
	[CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_START] = {},
	-- 目标指定前
	[CONSTANTS.ANSWER_WINDOW.WINDOW_TARGET_CHOOSE] = {},
	-- 目标指定时
	[CONSTANTS.ANSWER_WINDOW.WINDOW_TARGET_CHOOSE_AFTER] = {},
	-- 攻击之前
	[CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK_BEFORE] = {},
	-- 攻击之后
	[CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK_AFTER] = {},
	-- 防御之前
	[CONSTANTS.ANSWER_WINDOW.WINDOW_DEFEND_BEFORE] = {},
	-- 防御之后
	[CONSTANTS.ANSWER_WINDOW.WINDOW_DEFEND_AFTER] = {},
	-- 行动结束
	[CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_END] = {},
	-- 回合结束
	[CONSTANTS.ANSWER_WINDOW.WINDOW_ROUND_END] = {},
	-- 局结束
	[CONSTANTS.ANSWER_WINDOW.WINDOW_MATCH_END] = {},
	-- 攻击时
	[CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK] = {},
}

-- 得到目标对象的辅助表
local targetAssistTable =
{
	[CONSTANTS.TARGET_ALL] = function(totalUnitArray, actionUnit, defendUnit) end,
	[CONSTANTS.TARGET_ANY] = function(totalUnitArray, actionUnit, defendUnit) end,
	[CONSTANTS.TARGET_ANY_WE] = function(totalUnitArray, actionUnit, defendUnit) end,
	[CONSTANTS.TARGET_ANY_OPPONENT] = function(totalUnitArray, actionUnit, defendUnit) end,
	[CONSTANTS.TARGET_ALL_WE] = function(totalUnitArray, actionUnit, defendUnit) end,
	[CONSTANTS.TARGET_ALL_OPPONENT] = function(totalUnitArray, actionUnit, defendUnit) end,
	[CONSTANTS.TARGET_ME] = function(totalUnitArray, actionUnit, defendUnit) end,
	[CONSTANTS.TARGET_ALL_WE_NOT_ME] = function(totalUnitArray, actionUnit, defendUnit) end,
	-- 敌方全员非目标单位
	[CONSTANTS.TARGET_ALL_OPPONENT_NOT_TARGET] = function(totalUnitArray, actionUnit, defendUnit)
			assert(totalUnitArray and actionUnit and defendUnit, '')
			local retTbl = {}
			local groupID = actionUnit.groupID
			table.foreach(totalUnitArray, function(_, unit)
				if unit.groupID ~= groupID and unit ~= defendUnit then
					table.insert(retTbl, unit)
				end
			end)
			return retTbl
		end,
	-- 目前行动的单位
	[CONSTANTS.TARGET_ACTION_UNIT] = function(totalUnitArray, actionUnit, defendUnit) end,
	-- 目前防御的单位
	[CONSTANTS.TARGET_DEFEND_UNIT] = function(totalUnitArray, actionUnit, defendUnit) end,
	-- 己方行动单位
	[CONSTANTS.TARGET_WE_ACTION_UNIT] = function(totalUnitArray, actionUnit, defendUnit) end,
	-- 己方防御单位
	[CONSTANTS.TARGET_WE_DEFEND_UNIT] = function(totalUnitArray, actionUnit, defendUnit) end,
	-- 敌方行动单位
	[CONSTANTS.TARGET_OPPONENT_ACTION_UNIT] = function(totalUnitArray, actionUnit, defendUnit) end,
	-- 敌方防御单位
	[CONSTANTS.TARGET_OPPONENT_DEFEND_UNIT] = function(totalUnitArray, actionUnit, defendUnit) end,
}

-- 得到目标的对象的比对属性函数辅助表
local targetConditionAssistTable =
{
	-- 攻击力
	[CONSTANTS.ABILITY_CONDITION_INFLUENCE_PROPERTY.ATTACK] = function(conditionTargetUnitArray)
		local retTbl = {}
		table.foreach(conditionTargetUnitArray, function(_, unit)
			table.insert(retTbl, unit.attack)
		end)
		return retTbl
	end,
	-- 血量
	[CONSTANTS.ABILITY_CONDITION_INFLUENCE_PROPERTY.HITPOINT] = function(conditionTargetUnitArray) end,
	-- 速度
	[CONSTANTS.ABILITY_CONDITION_INFLUENCE_PROPERTY.SPEED] = function(conditionTargetUnitArray) end,
	-- 攻击者造成伤害
	[CONSTANTS.ABILITY_CONDITION_INFLUENCE_PROPERTY.ATTACK_HURT] = function(conditionTargetUnitArray) 
		-- 返回全局的当前行动后造成的伤害
		return BattleSummaryDataTbl.currentActionInjuryValue
	end,
	-- 是否受伤（血不满）
	[CONSTANTS.ABILITY_CONDITION_INFLUENCE_PROPERTY.GET_HURT] = function(conditionTargetUnitArray) 
		-- 返回目标是否少血
		if conditionTargetUnitArray.className == 'CARD' then
			return conditionTargetUnitArray:isHurt()
		else
			for _, unit in ipairs(conditionTargetUnitArray) do
				-- 这里只要有一个单位是满足受伤状态则返回true，否则返回false
				if unit:isHurt() then
					return true
				end
			end
		end
		return false
	end,
}

-- 异能作用目标函数辅助表，得到的是作用的单位
local abilityTargetAssistTable =
{
	[CONSTANTS.TARGET_ALL] = function() end,
	[CONSTANTS.TARGET_ANY] = function() end,
}

-- 用于得到比对函数的辅助表
-- 根据配置（条件标准）得到比对函数
local conditionCompareAssistTable =
{
	-- 等于
	[CONSTANTS.JUDGE_STANDARD.EQUALL] = function(a, b) return a == b end,
	-- 大于
	[CONSTANTS.JUDGE_STANDARD.GREAT_THAN] = function(a, b) return a > b end,
	-- 大于等于
	[CONSTANTS.JUDGE_STANDARD.GREAT_THAN_OR_EQUALL] = function(a, b) return a >= b end,
	-- 小于
	[CONSTANTS.JUDGE_STANDARD.LESS_THAN] = function(a, b) return a < b end,
	-- 小于等于
	[CONSTANTS.JUDGE_STANDARD.LESS_THAN_OR_EQUALL] = function(a, b) return a <= b end,
	-- a包含b
}

local propertyAssistTable =
{
	[CONSTANTS.ABILITY_INFLUENCE_PROPERTY_TARGET.ATTACK] = 'attack',
	[CONSTANTS.ABILITY_INFLUENCE_PROPERTY_TARGET.HITPOINT] = 'hitPoint',
	[CONSTANTS.ABILITY_INFLUENCE_PROPERTY_TARGET.SPEED] = 'speed',
}

-- 对属性修改的函数
-- @class function
-- @param target 影响的目标
-- @param effect 效果
-- @param nFixValue 如果是宏定义的效果值，则在外部修正后传入
local doAbilityEffect = function(targets, effect, nFixValue)
	-- 得到影响的属性
	local property = propertyAssistTable[tonumber(effect.influenceType)]
	assert(property, string.format('-- doAbilityEffect, effect.influenceType %s', effect.influenceType))
	local value = tonumber(effect.influenceValue)
	-- 由修正值修正作用值
	if nFixValue then
		-- value中的值仅仅用作判断正负
		if value < 0 then
			value = -1 * nFixValue
		else
			value = nFixValue
		end
	end
	
	-- target可能是多个的数组
	table.foreach(targets, function(_, unit)
		if property then
			print(string.format("异能起效，异能[%s], 修正值[%d]，影响单位[%s]", property, value, unit.name))
			unit:modifyProperty(property, value)
		end
	end)
	
end

-- 异能在响应窗口执行时遵循的规则
local answerTypeAssistTable = {
	-- 异能响应类型，只在自己行动的时候响应
	[CONSTANTS.ANSWER_TYPE_ACTION_ME] = function(ability, actionUnit, defendUnit, totalUnitArray) 
		-- 判断是否行动方就是异能所有者，一般用在只对自己有效的异能
		return ability.controler == actionUnit 
	end,
	-- 在己方行动时响应
	[CONSTANTS.ANSWER_TYPE_ACTION_WE] = function(ability, actionUnit, defendUnit, totalUnitArray)
		-- 判断是否行动方是己方行动
		return ability.controler.groupID == actionUnit.groupID
	end,
	-- 在己方非自己行动时
	[CONSTANTS.ANSWER_TYPE_ACTION_WE_NOT_ME] = function(ability, actionUnit, defendUnit, totalUnitArray)
		return ability.controler.groupID == actionUnit.groupID and ability.controler ~= actionUnit
	end,
	-- 在自己是防御方的时候允许响应
	[CONSTANTS.ANSWER_TYPE_DEFEND_ME] = function(ability, actionUnit, defendUnit, totalUnitArray)
		return ability.controler == defendUnit
	end,
	-- 在己方是防御方时响应
	[CONSTANTS.ANSWER_TYPE_DEFEND_WE] = function(ability, actionUnit, defendUnit, totalUnitArray)
		return ability.controler.groupID == defendUnit.groupID
	end,
	-- 在己方非自己是防御单位时
	[CONSTANTS.ANSWER_TYPE_DEFEND_WE_NOT_ME] = function(ability, actionUnit, defendUnit, totalUnitArray)
		return ability.controler.groupID == defendUnit.groupID and ability.controler ~= defendUnit
	end,
	-- 在敌方行动的时候响应
	[CONSTANTS.ANSWER_TYPE_OPPONENT] = function(ability, actionUnit, defendUnit, totalUnitArray)
		return ability.controler.groupID ~= actionUnit.groupID
	end,
	-- 在任意单位行动的时候皆可响应
	[CONSTANTS.ANSWER_TYPE_ACTION_ALL] = function(ability, actionUnit, defendUnit, totalUnitArray)
		return true
	end,
}

-- 异能结算
-- 异能结算是结算的一个大功能，因为异能多种多样，各自的效果也完全不同
-- @class function
-- @param ability 发动的异能（实例）
-- @param actionUnit 行动单位
-- @param defendUnit 当前防御单位，较少用到，在获取异能的目标范围为地方非防守单位时需要用到
-- @param totalUnitArray 所有参战单位
local depositeAbility = function(ability, actionUnit, defendUnit, totalUnitArray)
	-- TODO: 根据异能的响应条件挑选可响应的单位，这里的分组信息可以优化到战斗流程中维护独立的链表，避免每次生成的浪费

	-- TODO: 判断当前异能是否发动（有可能开始就不能发动此异能的情况存在，如某些异能指明某异能不能发动）
	if ability.invalid then
		return
	end
	
	-- 得到响应窗口规则
	local isAnswerValide = answerTypeAssistTable[ability.answerType]
	
	assert(isAnswerValide and type(isAnswerValide) == 'function', 
		string.format('isAnswerValide must be a function, please check the assist table if there is a function handle the "%s" RULE', tonumber(ability.answerType)))
	
	-- 这里判断是否异能符合响应类型，如是异能拥有者是行动者时发动，或者是防御者时发动等等
	if not isAnswerValide(ability, actionUnit, defendUnit, totalUnitArray) then return end
	
	print('-- depositeAbility actionUnit', actionUnit.name)
	
	-- TODO: 这里过滤出己方和敌方数组，可以提高判断效率
-- 	-- 敌方单位数组
-- 	local enemyUnitArray = {}
-- 	-- 己方单位数组
-- 	local selfUnitArray = {}

-- 	-- 循环分组
-- 	local groupID = ability.controler.groupID
-- 	table.foreach(totalUnitArray, function(_, unit)
-- 		if unit.groupID == groupID then
-- 			table.insert(selfUnitArray, unit)
-- 		else
-- 			table.insert(enemyUnitArray, unit)
-- 		end
-- 	end)

	-- 1.得到条件判断的目标单位
	local result = false
	-- 判断异能的发动条件是否满足（目前仅支持一种条件，所以只取第一个）
	local condition = ability.answerCondition[1]
	print('-- depositeAbility, condition.influenceType', condition.influenceType)
	if tonumber(condition.influenceType) == CONSTANTS.ABILITY_CONDITION_INFLUENCE_PROPERTY.INVALIDE then	
		-- 无效表示无条件发动
		result = true
	else
		local conditionTargetUnit = nil
		print('-- depositeAbility, condition.targetInfluenceRange', condition.targetInfluenceRange)
		-- 得到对应获取目标对象的函数
		local getTargetFunction = targetAssistTable[tonumber(condition.targetInfluenceRange)]
		print('-- depositeAbility, getTargetFunction', type(getTargetFunction))
		if type(getTargetFunction) == 'function' then
			-- 通过函数调用获取目标对象（数组）
			conditionTargetUnit = getTargetFunction(totalUnitArray, actionUnit, defendUnit)
			print('-- depositeAbility conditionTargetUnit num', #conditionTargetUnit)
		end

		if type(conditionTargetUnit) == 'table' then
			if conditionTargetUnit.className == 'CARD' then
				-- 表示是单个目标
				print('用于判断条件的目标是单个单位')
			else
				-- 表示多个目标
				print('用于判断条件的目标是多个单位')
			end
		end
		
		-- 2.得到目标条件属性（用于比对的值）
		
		local getConditionValueFunction = targetConditionAssistTable[tonumber(condition.influenceType)]

		print('-- depositeAbility condition.influenceType', condition.influenceType)
		
		local targetConditionValue = nil

		-- 得到目标条件值（用于比对）
		if type(getConditionValueFunction) == 'function' then
			targetConditionValue = getConditionValueFunction(conditionTargetUnit)
		end

		local judgeStandard = tonumber(condition.judgeStandard)
		if judgeStandard == 0 then
			-- 如果是无条件发动，则直接赋值为true
			print('-- despositeAbility ability lanuch MUST')
			result = true
		end
		
		-- 得到条件发动函数
		local getConditionCompareFunction = conditionCompareAssistTable[judgeStandard]
		
		print('-- depositeAbility condition.judgeStandard', condition.judgeStandard)
		print('-- depositeAbility condition.influenceValue', condition.influenceValue)
		print('-- depositeAbility getConditionCompareFunction', type(getConditionCompareFunction))
		
		if type(getConditionCompareFunction) == 'function' then
			-- 比对结果
			result = getConditionCompareFunction(tonumber(targetConditionValue), tonumber(condition.influenceValue))
		end
	end

	-- 3.判断是否可以发动异能
	if not result then
		return
	end

	-- 4.发动异能效果
		
	-- 异能作用数据
	local abilityEffect = ability.effect
	table.foreach(abilityEffect, function(_, effect)
		-- 得到异能作用目标获取函数
		local getAbilityTargetFunction = targetAssistTable[tonumber(effect.targetInfluenceRange)]
		assert(getAbilityTargetFunction and type(getAbilityTargetFunction) == 'function',
			string.format('effect.targetInfluenceRange:%s', effect.targetInfluenceRange))
		
		local target = getAbilityTargetFunction(totalUnitArray, actionUnit, defendUnit)
		print('-- depositeAbility abilityTarget num', #target)
		print('-- depositeAbility effect.mode', effect.mode)
		if tonumber(effect.mode) == CONSTANTS.EFFECT_TYPE_PROPERTY then
			-- 对属性的影响
			local nFixValue = nil
			-- 影响值是否是宏定义
			if tonumber(effect.influenceValueType) == CONSTANTS.EFFECT_PROPERTY_TYPE_MACRO then
				-- 确定修正值
				if tonumber(effect.valueMacro) == CONSTANTS.EFFECT_VALUE_MACRO.ACTION_UNIT_ATTACK then
					nFixValue = actionUnit.attack
				end
			end
			
			doAbilityEffect(target, effect, nFixValue)
		elseif tonumber(effect.mode) == CONSTANTS.EFFECT_TYPE_ABILITY then
			-- TODO: 异能影响的，暂未实现
		end
		
	end)
	
end

-- 死亡结算
-- 一般需要传入所有的单位进行轮询判断，某些特殊异能可以引发立即死亡结算，比如是会影响行动方的生命或者行动类
-- 这里涉及到行动方是以单体为目标还是以多个单位为目标
local depositeDeath = function(unit, defendUnit, totalUnit) -- 在每个行动后都需要死亡结算
	-- 这里暂时不判断unit是否是卡牌，由外部调用保证

	-- 当单位死亡时，才进行结算
	if not unit:isDead() then
		return
	end

	-- 得到死亡结算异能
	local deathAbilityArray = unit:getDeathAbilityArray()

	if deathAbilityArray then
		for _, deathAbility in ipairs(deathAbilityArray) do
			print(string.format("Card [%s]'s death Ability [%s] start...", unit.name, deathAbility.name))
			-- 结算异能
			depositeAbility(deathAbility, unit, defendUnit, totalUnit)
		end
	end
end

-- 整体死亡结算，循环每个对象
local deathDeposite = function(totalUnitArray, defendUnit)
	-- 拷贝一个全局数据给死亡清算函数中的异能结算函数使用
	local ttuArray = {}
	table.foreachi(totalUnitArray, function(_, unit)
		table.insert(ttuArray, unit)
	end)
	
	table.foreachi(totalUnitArray, function(_, unit)
		depositeDeath(unit, defendUnit, ttuArray)
	end)
end

-- 攻击结算，一般简单为攻击者的攻击力减去防御者的血
local depositeAttack = function(actionUnit, defendUnit, totalUnitArray)

	if defendUnit then
		-- 记录造成的伤害值（非造成的伤害值，非击穿，值计算实际伤害）
		if defendUnit.hitPoint < actionUnit.attack then
			BattleSummaryDataTbl.currentActionInjuryValue = defendUnit.hitPoint
		else
			BattleSummaryDataTbl.currentActionInjuryValue = actionUnit.attack 
		end
		
		defendUnit:getHurt(-actionUnit.attack)
	end
end

-- 清算函数辅助表
local Deposite =
{
	--  攻击清算函数
	['attack'] = depositeAttack,
	-- 异能清算（非死亡清算）
	['ability'] = depositeAbility,
	-- 死亡结算
	['death'] = depositeDeath,
}

-- 游戏流程控制表
local GameLogicTable =
{
	-- 流程
	flow =
	{
		-- 局开始
		{window = CONSTANTS.ANSWER_WINDOW.WINDOW_MATCH_START},
		-- 循环流程
		{
			--  表示是循环流程，这里的循环跳出标准为当局游戏结束，即场上只有一方阵营单位存在
			window = CONSTANTS.ANSWER_WINDOW.WINDOW_CIRCLE,
			-- 回合开始
			{window = CONSTANTS.ANSWER_WINDOW.WINDOW_ROUND_START},
			-- 表示是循环流程
			{
				-- 这里的循环跳出标准为所有单位行动结束
				window = CONSTANTS.ANSWER_WINDOW.WINDOW_CIRCLE,
				-- 行动开始
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_START},
				-- 指定阶段
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_TARGET_CHOOSE},
				-- 指定结束
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_TARGET_CHOOSE_AFTER},
				-- 攻击之前
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK_BEFORE},
				-- 攻击时
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK},
				-- 攻击之后
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK_AFTER},
				-- 防御之前
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_DEFEND_BEFORE},
				-- 防御之后
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_DEFEND_AFTER},
				-- 行动结束
				{window = CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_END},
			},
			-- 回合结束
			{window= CONSTANTS.ANSWER_WINDOW.WINDOW_ROUND_END},
		},
		-- 局结束
		{window = CONSTANTS.ANSWER_WINDOW.WINDOW_MATCH_END},
	},
}

-- 发动异能
local triggerAbility = function(ability)
	assert(ability.className == 'ABILITY', 'triggerAbility failed')
	-- 把当前异能按响应属性增加到对应列表中
	local answerWindowTable = answerWindowAssistTable[tonumber(ability.answerWindow)]
	if answerWindowTable then
		-- 把异能加入窗口响应表
		table.insert(answerWindowTable, ability)
	end
end

-- 判断比赛是否结束
-- @param aliveTbl 用以记录所有方面势力的存活单位数量
local isMatchOver = function(aliveTbl)
	local aliveCount = 0
	table.foreach(aliveTbl, function(_, count)
		if count > 0 then
			aliveCount = aliveCount + 1
		end
	end)
	
	-- 当只有阵营一方胜利的时候才认为游戏结束
	-- 可支持团队作战
	return aliveCount == 1
end

-- 在两组数据中得到速度最快的单位
local getActionUnit = function(round, cardOne, cardTwo)
	-- 根据当前的回合，得到速度最快的单位并返回
	
	-- 得到混合速度排序
	local actionSequence = comm.getActionSequence{cardOne, cardTwo}
	
	print('getActionUnit actionSequence:', actionSequence, #actionSequence)
	-- 得到第一个速度最快，并且round在当前回合的单位
	local unit = nil
	local firstAliveUnit = nil
	for _, card in ipairs(actionSequence) do
		if not card:isDead() then
			-- 记录第一个活着的速度最快的单位
			if not firstAliveUnit then
				firstAliveUnit = card
			end
			
			-- 选出活着的，当前未行动的单位
			if card.round < round then
				unit = card
				break
			end
		end
	end
	
	-- 如果没有当前回合的单位，则返回速度最快的活着的单位
	if not unit then
		unit = firstAliveUnit
	end
	
--	print('getActionUnit, unit', unit)
	
	return unit 
end

-- 得到防御的单位（被攻击）
-- @class function
-- @param attackUnit 攻击单位
-- @param totalUnitArray 整体单位数组
-- @return 返回指定攻击的单位，如果没有（异常状态下）则返回 nil
local getDefendUnit = function(attackUnit, totalUnitArray)
	local groupID = attackUnit.groupID
	local defendUnit = nil
	for _, unit in ipairs(totalUnitArray) do
		-- TODO: 这里还需要判断是否受异能指定的影响
		if unit.groupID ~= groupID and not unit:isDead() then
			defendUnit = unit
			break
		end
	end
	
	return defendUnit
end

-- 得到两个表合并后的数据
local getCombineData = function(tbl1, tbl2)
	local retTbl = {}
	table.foreach(tbl1, function(_, v) table.insert(retTbl, v) end)
	table.foreach(tbl2, function(_, v) table.insert(retTbl, v) end)
	return retTbl
end

-- 是否当前回合结束
-- @param round 当前回合
-- @param totalUnitArray 所有单位数组（这里如果是所有存活单位数组则效率更高）
local isRoundOver = function(round, totalUnitArray)
	for _, unit in ipairs(totalUnitArray) do
--		print(unit)
		-- 选择出活着的单位，并且该单位的回合数要小于当前回合数，表示回合未完结
--		print('isRoundOver unit.name:', unit.name, 'unit.id', unit.id, 'unit.round', unit.round, 'unit.hitPoint', unit.hitPoint, 'groupID', unit.groupID)
		if not unit:isDead() and unit.round < round then
			return false
		end
	end
	
	return true
end

-- 根据当前的窗口，执行对应的异能响应的列表
-- @class function
-- @param status 响应窗口
local getAnswerAbilityArray = function(status)
	local abilityArray = answerWindowAssistTable[status]
	if type(abilityArray) ~= "table" then
		return
	end
	return abilityArray
end

-- 得到卡牌堆
-- local CardHeap = comm.readCardData("card_data.txt")
local CardHeap = comm.readCardDataFromDB()

-- 异能响应窗口的结算
local function abilityDepositeByWindow(window, actionUnit, defendUnit, totalUnit)
	-- 得到当前窗口的异能响应列表，并逐一响应（这里只有回合开始和回合结束的两个窗口）
	local abilityArray = getAnswerAbilityArray(window)
	if type(abilityArray) == 'table' then
		table.foreach(abilityArray, function(_, ability)
			-- 响应异能
			depositeAbility(ability, actionUnit, defendUnit, totalUnit)
			
			-- 异能响应结束后要进行死亡窗口结算
			deathDeposite(totalUnit, defendUnit)
		end)
	end
end

-- 战斗函数
-- @class function
-- @param cardGroupOne 玩家1选取好的卡组
-- @param cardGroupTwo 玩家2选取好的卡组
-- @return 返回一次战斗的结果，谁赢得比赛、回合、步骤序列（用于回放）
local function doBattle(cardGroupOne, cardGroupTwo)
	local retData = {
		bFirstWin = false	-- 先默认定义非第一个胜利
	}
	
	--[[
		战斗流程
	]]
	-- 当前回合
	local nRound = 0
	
	-- 存活表
	local aliveTable = BattleSummaryDataTbl.aliveTable
	
	table.foreachi(GameLogicTable.flow, function(_, flowStep)
		-- 缓存下window，方便后面简化书写
		local window = flowStep.window
		
		if window == CONSTANTS.ANSWER_WINDOW.WINDOW_MATCH_START then
			print('Game Start...')
			-- 比赛开始
			-- 异能进场，数据初始化等操作
			-- //////////////////////
			-- 战斗前准备
			-- 1. 得到单位行动顺序
			local actionSequences = comm.getActionSequence{cardGroupOne, cardGroupTwo}
-- 			print('actionSequence...')
			-- 按照各个角色的异能特性，整理异能
			-- 2.按顺序结算异能发动
			table.foreachi(actionSequences, function(_, unit)
				if unit.className ~= "CARD" then
					-- 如果不是卡牌，则直接退出
					return
				end
				showUnit(unit)
				
				local abilityArray = unit.abilitys
				-- 判断下当前卡牌是否拥有异能
				if abilityArray and type(abilityArray) == 'table' then
					table.foreachi(abilityArray, function(_, ability)
						-- 把当前异能加入窗口响应列表
						triggerAbility(ability)
					end)
				end
			end)
			
			--  2.得到每一方存活数量
			table.foreach(actionSequences, function(_, unit)
				aliveTable[unit.groupID] = (aliveTable[unit.groupID] or 0) + 1
			end)
		-- 回合循环
		elseif window == CONSTANTS.ANSWER_WINDOW.WINDOW_CIRCLE then
			-- 开个死循环，直到某一方胜利后跳出
			-- 本回合行动单位
			local actionUnit = nil
			repeat
				-- 回合循环窗口
				for _, roundCircle in ipairs(flowStep) do
					
--					print('roundCircle.window', roundCircle.window)
					-- 首先判断是否不是循环
					if roundCircle.window ~= CONSTANTS.ANSWER_WINDOW.WINDOW_CIRCLE then
						
						-- 1.回合开始 回合数目自增
						if roundCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ROUND_START then
							-- 如果为回合开始，则把回合数加1
							nRound = nRound + 1
							print('Round:', nRound)
						elseif roundCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ROUND_END then
							
						end
						
-- 						print(string.format("当前窗口为[%s]", tostring(CONSTANTS.ANSWER_WINDOW_DESC[roundCircle.window])))
						
						-- 2.得到当前窗口的异能响应列表，并逐一响应（这里只有回合开始和回合结束的两个窗口）
-- 						local abilityArray = getAnswerAbilityArray(roundCircle.window)
-- 						
-- 						if type(abilityArray) == 'table' then
-- 							table.foreach(abilityArray, function(_, ability)
-- 								-- 响应异能
-- 								depositeAbility(ability, actionUnit, nil, getCombineData(cardGroupOne, cardGroupTwo))
-- 								
-- 								-- 异能响应结束后要进行死亡窗口结算
-- 								deathDeposite(getCombineData(cardGroupOne, cardGroupTwo), nil)
-- 							end)
-- 						end
						abilityDepositeByWindow(roundCircle.window, actionUnit, nil, getCombineData(cardGroupOne, cardGroupTwo))
					-- 行动循环
					else
						local defendUnit = nil
						repeat
							for _, actionCircle in ipairs(roundCircle) do
-- 								print('actionCircle.window:', actionCircle.window)
								print(string.format("当前窗口为[%s]", tostring(CONSTANTS.ANSWER_WINDOW_DESC[actionCircle.window])))
								-- 2.得到当前窗口的异能响应列表，并逐一响应
								abilityDepositeByWindow(actionCircle.window, actionUnit, defendUnit, getCombineData(cardGroupOne, cardGroupTwo))
								
								-- 对选出的单位进行动作
								if actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_START then
									-- 选出行动单位
									actionUnit = getActionUnit(nRound, cardGroupOne, cardGroupTwo)
									showAttackUnit(actionUnit)
									
									-- 清空攻击单位造成的伤害值
									BattleSummaryDataTbl.currentActionInjuryValue = 0
									
								elseif actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_TARGET_CHOOSE then
									-- 攻击前选出对手
									defendUnit = getDefendUnit(actionUnit, getCombineData(cardGroupOne, cardGroupTwo))
									showDefendUnit(defendUnit)
								elseif actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK then
									-- 判断当前是否不能攻击状态
									if actionUnit.stopRound and actionUnit.stopRound > 0 then
										-- 减少冻结回合数
										actionUnit:modifyProperty("stopRound", -1)
									else 
										-- 攻击后，对应防御单位受伤
										depositeAttack(actionUnit, defendUnit, getCombineData(cardGroupOne, cardGroupTwo))
									end
									
								elseif actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK_AFTER then
									if defendUnit:isDead() then
										-- 对象死亡后更新存活列表
										BattleSummaryDataTbl.aliveTable[defendUnit.groupID] = BattleSummaryDataTbl.aliveTable[defendUnit.groupID] - 1
										-- 死亡结算
										depositeDeath(actionUnit, defendUnit, totalUnitArray)
										
										showDefendUnit(defendUnit)
									end
								elseif actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_END then
-- 									print('actionUnit', actionUnit)
									if actionUnit then
										-- 设置当前单位本回合已经行动标志
										actionUnit:setRound(nRound)
-- 										showAttackUnit(actionUnit)
									end
								end
							end
						until isMatchOver(aliveTable) or isRoundOver(nRound, getCombineData(cardGroupOne, cardGroupTwo))
					end					
				end -- end of 循环回合窗口
			until isMatchOver(aliveTable)
			
		elseif window == CONSTANTS.ANSWER_WINDOW.WINDOW_MATCH_END then
			-- 比赛结束
			print("Game End.........")
			print("总回合数目:", nRound)
			local whichGroupWin = nil
			for groupID, aliveCount in pairs(aliveTable) do
				if aliveCount > 0 then
					whichGroupWin = groupID
					break
				end
			end
			print("胜利组别:", whichGroupWin)
		end
	end)

	return retData
end

-- 处理一次战役
-- @class function
-- @param playerOne 第一个玩家的ID
-- @param playerTwo 第二个玩家的ID
-- @return 返回战役的动作序列以及胜负
local function HandleBattle(playerOne, playerTwo)
	-- 1. 得到玩家牌组数据
	local cardTotalPlayerOne = CardHeap
	local cardTotalPlayerTwo = CardHeap

	-- 2. 通过玩家的总牌数据随机抽取12张卡牌作为牌库
	local cardLibPlayerOne = comm.chooseCardFromStore(cardTotalPlayerOne, 20)
	local cardLibPlayerTwo = comm.chooseCardFromStore(cardTotalPlayerTwo, 20)

-- 	local function pt(key, value)
-- 		print(key, value:getAddress(), value)
-- 	end

	-- 3. 从牌库中选择一局游戏中的需要的牌组
	--     可以是3组，每组3张，或者是1组，一组3张或者6张
	local cardBattleGroupPlayerOne = nil --comm.chooseActionCardGroupFromStore(cardLibPlayerOne, 1, 3)
	local cardBattleGroupPlayerTwo = nil --scomm.chooseActionCardGroupFromStore(cardLibPlayerTwo, 2, 3)

-- 	table.foreach(cardBattleGroupPlayerOne, print)
-- 	table.foreach(cardBattleGroupPlayerTwo, print)

	-- for test
	local cardOne = {}
	for i = 95, 97 do
		local singleCard = table.dup(CardHeap[i]);
		if singleCard == nil then
			error(string.format("cardNum is %d", i));
		end
		
		singleCard.groupID = 1
		local cardData = Card.CardPropertyClass:new(singleCard);
		table.insert(cardOne, cardData);
	end
	cardBattleGroupPlayerOne = cardOne
	
	local cardTwo = {}
	for i = 131, 133 do
		local singleCard = table.dup(CardHeap[i]);
		if singleCard == nil then
			error(string.format("cardNum is %d", i));
		end
		
		singleCard.groupID = 2
		local cardData = Card.CardPropertyClass:new(singleCard);
		table.insert(cardTwo, cardData);
	end
	
	cardBattleGroupPlayerTwo = cardTwo
	
	print('test cardOne num:', #cardOne, 'test cardTwo num:', #cardTwo)
	
	-- 4. 根据当前的配置决定进行几次对战
	local battleResult = doBattle(cardBattleGroupPlayerOne, cardBattleGroupPlayerTwo)

	-- 5. 分析多场战斗，得出胜利的玩家ID
	local winnerID = playerTwo.userID
	if battleResult.bFirstWin then
		winnerID = playerOne.userID
	end

	-- 6. 对多次战役打包返回
	local retData = {
		-- 战役结果
		battleResult = {
			-- 胜利者ID
			winnerID = 1000
		},
		-- 战斗数据，数组
		battleData = {
--			battleResult
		}
	}

	return retData
end

HandleBattle({userID = 111}, {userID = 222});

-- local a = Ability.GetAbilityObj(1)

-- print(a.name, a.description)

-- 以下代码测试原始数据表的数据是否会重复
-- print(string.rep('=', 50))
-- local singleCard = table.dup(CardHeap[10]);
-- if singleCard == nil then
-- 	error(string.format("cardNum is %d", 10));
-- end

-- singleCard.groupID = 1
-- local cardData = Card.CardPropertyClass:new(singleCard);

-- singleCard = table.dup(CardHeap[15]);
-- if singleCard == nil then
-- 	error(string.format("cardNum is %d", 15));
-- end
-- singleCard.groupID = 2
-- local cardData2 = Card.CardPropertyClass:new(singleCard);

-- showAttackUnit(cardData)
-- cardData:getHurt(-3)
-- showOriginalProperty(cardData, 'hitPoint')

-- showAttackUnit(cardData2)
-- cardData2:getHurt(-3)
-- showOriginalProperty(cardData2, 'hitPoint')
