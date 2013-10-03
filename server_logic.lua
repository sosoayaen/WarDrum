--[[
	服务器业务处理流程
	小写字母开头的函数表示本地函数，大写的函数表示全局函数
]]
package.path = ".\\?.lua;" .. package.path

require "comm"
require "card"

-- 死亡结算
-- 死亡结算并不是当一个单位血到0后立即发生，而是需要在行动方结束后进行
-- 一般需要传入所有的单位进行轮询判断，某些特殊异能可以引发立即死亡结算，比如是会影响行动方的生命或者行动类
-- 这里涉及到行动方是以单体为目标还是以多个单位为目标
local depositeDeath = function(unit) -- 在每个行动后都需要死亡结算
	-- 这里暂时不判断unit是否是卡牌，由外部调用保证
	
	-- 当单位死亡时，才进行结算
	if not unit:isDead() then
		return
	end
	
	-- TODO: 根据异能描述实现对应的效果
end

-- 攻击结算，一般简单为攻击者的攻击力减去防御者的血
local depositeAttack = function(attackUnit, defendUnit)
	defendUnit:getHurt(attackUnit.attack)
end

-- 异能结算
-- 异能结算是结算的一个大功能，因为异能多种多样，各自的效果也完全不同
-- @class function
-- @param ability 发动的异能（实例）
-- @param controlUnit 施法单位
-- @param affectedUnitArray 受影响的单位数组
local depositeAbility = function(ability, controlUnit, affectedUnitArray)
	
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
		{},
		-- 循环流程
		{
			-- 回合开始
			{},
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
		{},
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