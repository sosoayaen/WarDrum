--[[
	服务器业务处理流程
	小写字母开头的函数表示本地函数，大写的函数表示全局函数
]]
package.path = ".\\?.lua;" .. package.path
require "config"
require "comm"
require "card"
require "util"

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
}

-- 得到目标对象的辅助表
local targetAssistTable =
{
	[CONSTANTS.TARGET_ALL] = function(totalUnitArray, selfGroupID) end,
	[CONSTANTS.TARGET_ANY] = function(totalUnitArray, selfGroupID) end,
	[CONSTANTS.TARGET_ANY_WE] = function(totalUnitArray, selfGroupID) end,
	[CONSTANTS.TARGET_ANY_OPPONENT] = function(totalUnitArray, selfGroupID) end,
	[CONSTANTS.TARGET_ALL_WE] = function(totalUnitArray, selfGroupID) end,
	[CONSTANTS.TARGET_ALL_OPPONENT] = function(totalUnitArray, selfGroupID) end,
	[CONSTANTS.TARGET_ME] = function(totalUnitArray, selfGroupID) end,
	[CONSTANTS.TARGET_ALL_WE_NOT_ME] = function(totalUnitArray, selfGroupID) end,
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

local propertyAssistTable =
{
	[1] = 'attack',
	[2] = 'hitPoint',
	[3] = 'speed',
}

-- 对属性修改的函数
-- @class function
-- @param target 影响的目标
-- @param effect 效果
local doAbilityEffect = function(target, effect)
	-- 得到影响的属性
	local property = propertyAssistTable[effect.influenceType]
	local value = effect.influenceValue
	
	if property then
		print(string.format("异能起效，异能[%s], 修正值[%d]", property, value))
		target[property] = target[property] + value
	end
end

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
		
	-- 异能作用数据
	local abilityEffect = ability.effect
	table.foreach(abilityEffect, function(_, effect)
		-- 得到异能作用目标获取函数
		local getAbilityTargetFunction = targetAssistTable(effect.targetInfluenceRange)
		
		local target = getAbilityTargetFunction(totalUnitArray, controlUnit.groupID)
		
		if effect.effectType == CONSTANTS.EFFECT_TYPE_PROPERTY then
			-- 对属性的影响
			doAbilityEffect(target, effect) 
		elseif effect.effectType == CONSTANTS.EFFECT_TYPE_ABILITY then
			-- 异能影响的，暂未实现
		end
		
	end)
	
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

-- 整体死亡结算，循环每个对象
local deathDeposite = function(totalUnitArray)
	-- 拷贝一个全局数据给死亡清算函数中的异能结算函数使用
	local ttuArray = {}
	table.foreachi(totalUnitArray, function(_, unit)
		table.insert(ttuArray, unit)
	end)
	
	table.foreachi(totalUnitArray, function(_, unit)
		depositeDeath(unit, ttuArray)
	end)
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
	local answerWindowTable = answerWindowAssistTable[ability.answerWindow]
	if answerWindowAssistTable then
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

-- 攻击单位数据输出
local showAttackUnit = function(unit)
	if unit then
		print('攻击单位 name', unit.name, 'round', unit.round, 'groupID', unit.groupID, 'hitPoint', unit.hitPoint, 'attack', unit.attack)
	end
end

-- 防御单位数据输出
local showDefendUnit = function(unit)
	if unit then
		print('防御单位 name', unit.name, 'round', unit.round, 'groupID', unit.groupID, 'hitPoint', unit.hitPoint)
	end
end

-- 显示单位数据
local showUnit = function(unit)
	if unit then
		print(unit.name, 'groupID', unit.groupID, 'attack', unit.attack, 'speed', unit.speed, 'hitPoint', unit.hitPoint)
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
	local aliveTable = {}
	
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
				
				local abilityArray = unit.ability
				-- 判断下当前卡牌是否拥有异能
				if abilityArray and type(abilityArray) == 'table' then
					table.foreachi(abilityArray, function(_, abilityID)
						-- 通过异能的ID得到异能对象
						local ability = Ability.GetAbilityObj(abilityID)
						if ability then
							-- 把当前异能加入窗口响应列表
							triggerAbility(ability)
						end
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
						local abilityArray = getAnswerAbilityArray(roundCircle.window)
						
						if type(abilityArray) == 'table' then
							table.foreach(abilityArray, function(_, ability)
								-- 响应异能
								depositeAbility(ability, ability.controler, getCombineData(cardGroupOne, cardGroupTwo))
								
								-- 异能响应结束后要进行死亡窗口结算
								deathDeposite(getCombineData(cardGroupOne, cardGroupTwo))
							end)
						end
					-- 行动循环
					else
						local defendUnit = nil
						repeat
							for _, actionCircle in ipairs(roundCircle) do
-- 								print('actionCircle.window:', actionCircle.window)
								-- 2.得到当前窗口的异能响应列表，并逐一响应
								local abilityArray = getAnswerAbilityArray(actionCircle.window)
								if type(abilityArray) == 'table' then
									table.foreach(abilityArray, function(_, ability)
										-- 响应异能
										depositeAbility(ability, ability.controler, getCombineData(cardGroupOne, cardGroupTwo))
										
										-- 异能响应结束后要进行死亡窗口结算
										deathDeposite(getCombineData(cardGroupOne, cardGroupTwo))
									end)
								end
								
 								print(string.format("当前窗口为[%s]", tostring(CONSTANTS.ANSWER_WINDOW_DESC[actionCircle.window])))
								
								-- 对选出的单位进行动作
								if actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_START then
									-- 选出行动单位
									actionUnit = getActionUnit(nRound, cardGroupOne, cardGroupTwo)
									showAttackUnit(actionUnit)
								elseif actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_TARGET_CHOOSE then
									-- 攻击前选出对手
									defendUnit = getDefendUnit(actionUnit, getCombineData(cardGroupOne, cardGroupTwo))
									showDefendUnit(defendUnit)
								elseif actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ATTACK_AFTER then
									-- 攻击后，对应防御单位受伤
									if defendUnit then
										defendUnit:getHurt(actionUnit.attack)
										if defendUnit:isDead() then
											-- 对象死亡后更新存活列表
											aliveTable[defendUnit.groupID] = aliveTable[defendUnit.groupID] - 1
											showDefendUnit(defendUnit)
										end
									end
								elseif actionCircle.window == CONSTANTS.ANSWER_WINDOW.WINDOW_ACTION_END then
-- 									print('actionUnit', actionUnit)
									if actionUnit then
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

-- 得到卡牌堆
-- local CardHeap = comm.readCardData("card_data.txt")
local CardHeap = comm.readCardDataFromDB()

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

-- local a = Ability.GetAbilityObj(1)

-- print(a.name, a.description)
