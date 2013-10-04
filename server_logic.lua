--[[
	服务器业务处理流程
	小写字母开头的函数表示本地函数，大写的函数表示全局函数
]]
package.path = ".\\?.lua;" .. package.path
require "config"
require "comm"
require "card"

local CONSTANTS = Config.CONSTANTS

-- 得到目标对象的辅助表
local targetAssistTable =
{
	[CONSTANTS.TARGET_ALL] = function() end,
	[CONSTANTS.TARGET_ANY] = function() end,
}

-- 得到目标的对象的比对属性函数辅助表
local targetConditionAssistTable =
{
	-- 攻击力
	[1] = function(totalUnitArray) end,
	-- 血量
	[2] = function(totalUnitArray) end,
	-- 速度
	[3] = function(totalUnitArray) end,
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

-- 异能结算
-- 异能结算是结算的一个大功能，因为异能多种多样，各自的效果也完全不同
-- @class function
-- @param ability 发动的异能（实例）
-- @param controlUnit 施法单位
-- @param totalUnitArray 所有参战单位
local depositeAbility = function(ability, controlUnit, totalUnitArray)
	-- TODO: 根据异能的响应条件挑选可响应的单位，这里的分组信息可以优化到战斗流程中维护独立的链表，避免每次生成的浪费

	-- TODO: 判断当前异能是否发动（有可能开始就不能发动此异能的情况存在，如某些异能指明某异能不能发动）
	if ability.invalid then
		return
	end

	-- 敌方单位数组
	local enemyUnitArray = {}
	-- 己方单位数组
	local selfUnitArray = {}

	-- 循环分组
	local groupID = controlUnit.groupID
	table.foreach(totalUnitArray, function(_, unit)
		if unit.groupID == groupID then
			table.insert(selfUnitArray, unit)
		else
			table.insert(enemyUnitArray, unit)
		end
	end)

	-- 1.得到条件判断的目标单位
	local conditionTargetUnit = nil
	-- 判断异能的发动条件是否满足（目前仅支持一种条件，所以只取第一个）
	local condition = ability.answerCondition[1]
	-- 得到对应获取目标对象的函数
	local getTargetFunction = targetAssistTable[condition.targetInfluenceRange]

	if type(getTargetFunction) == 'function' then
		-- 通过函数调用获取目标对象（数组）
		conditionTargetUnit = getTargetFunction()
	end

	if type(conditionTargetUnit) == 'table' then
		if conditionTargetUnit.className == 'CARD' then
			-- 表示是单个目标
			print('用于判断条件的目标是单个单位')
		else
			-- 表示多个目标
		end
	end

	-- 2.得到目标条件属性（用于比对的值）
	local getConditionValueFunction = targetConditionAssistTable[condition.influenceType]

	local targetConditionValue = nil

	-- 得到目标条件值（用于比对）
	if type(getConditionValueFunction) == 'function' then
		targetConditionValue = getConditionValueFunction(conditionTargetUnit)
	end

	-- 得到条件发动函数
	local getConditionCompareFunction = conditionCompareAssistTable[condition.judgeStandard]

	local result = false
	if type(getConditionCompareFunction) == 'function' then
		-- 比对结果
		result = getConditionCompareFunction(targetConditionValue, condition.influenceValue)
	end

	-- 3.判断是否可以发动异能
	if not result then
		return
	end

	-- 4.发动异能效果
	-- 得到异能作用目标
	local target = nil
	-- 得到目标获取函数
	local getAbilityTargetFunction = 
end

-- 死亡结算
-- 死亡结算并不是当一个单位血到0后立即发生，而是需要在行动方结束后进行
-- 一般需要传入所有的单位进行轮询判断，某些特殊异能可以引发立即死亡结算，比如是会影响行动方的生命或者行动类
-- 这里涉及到行动方是以单体为目标还是以多个单位为目标
local depositeDeath = function(unit, totalUnit) -- 在每个行动后都需要死亡结算
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
			depositeAbility(deathAbility, unit, totalUnit)
		end
	end
end

-- 攻击结算，一般简单为攻击者的攻击力减去防御者的血
local depositeAttack = function(attackUnit, defendUnit)
	defendUnit:getHurt(attackUnit.attack)
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
			-- 回合开始
			{window = 1},
			-- 行动开始
			{},
			-- 指定阶段
			{},
			-- 攻击阶段
			{},
			-- 回合结束
			{},
		},
		-- 局结束
		{window = CONSTANTS.ANSWER_WINDOW.WINDOW_MATCH_END},
	},
}

-- 战斗函数
-- @class function
-- @param cardGroupOne 玩家1选取好的卡组
-- @param cardGroupTwo 玩家2选取好的卡组
-- @return 返回一次战斗的结果，谁赢得比赛、回合、步骤序列（用于回放）
local function doBattle(cardGroupOne, cardGroupTwo)
	local retData = {
		bFirstWin = false	-- 先默认定义非第一个胜利
	}

	-- //////////////////////
	-- 战斗前准备
	-- 1. 得到单位行动顺序
	local actionSequences = comm.getActionSequence{cardGroupOne, cardGroupTwo}

	-- 按照各个角色的异能特性，整理异能
	-- 2.按顺序结算异能发动
	table.foreachi(actionSequences, function(_, unit)
		if unit.className ~= "CARD" then
			-- 如果不是卡牌，则直接退出
			return
		end

		local abilityArray = unit.ability
		-- 判断下当前卡牌是否拥有异能
		if abilityArray and type(abilityArray) == 'table' then
			table.foreachi(abilityArray, function(_, abilityID)
				-- 通过异能的ID得到异能对象
				local ability = Ability.GetAbilityObj(abilityID)
				if ability then

				end
			end)
		end
	end)

	--[[
		战斗流程
	]]

	--//////////////////////
	-- 进场阶段
	-- 1. 进场技能结算，把所有单位的技能发动，技能的发动按照其响应阶段决定


	-- 2.

	-- retData.sequences = actionSequences;

	return retData
end

-- 得到卡牌堆
local CardHeap = comm.readCardData("card_data.txt")

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
	local cardBattleGroupPlayerOne = comm.chooseActionCardGroupFromStore(cardLibPlayerOne, 1, 3)
	local cardBattleGroupPlayerTwo = comm.chooseActionCardGroupFromStore(cardLibPlayerTwo, 2, 3)

-- 	table.foreach(cardBattleGroupPlayerOne, print)
-- 	table.foreach(cardBattleGroupPlayerTwo, print)

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

local a = Ability.GetAbilityObj(1)

print(a.name, a.description)
