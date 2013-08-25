--[[
	服务器业务处理流程
	小写字母开头的函数表示本地函数，大写的函数表示全局函数
]]
package.path = ".\\?.lua;" .. package.path

require "comm"
require "card"

print(Card.CardProperty:new())
-- 按照各个角色的异能特性，整理异能

--- 战斗函数
-- @class function
-- @param cardGroupOne 玩家1选取好的卡组
-- @param cardGroupTwo 玩家2选取好的卡组
-- @return 返回一次战斗的结果，谁赢得比赛、回合、步骤序列（用于回放）
local function doBattle(cardGroupOne, cardGroupTwo)
	local retData = {
		bFirstWin = false	-- 先默认定义非第一个胜利
	}
	
	-- 定义一个动画序列表
	local sequences = {}
	
	--[[ 
		战斗流程
	]]
	
	--//////////////////////
	-- 进场阶段
	--//////////////////////
	-- 1. 进场技能结算，把所有单位的技能发动，技能的发动按照其响应阶段决定
	
	
	-- 2. 
	
	retData.sequences = sequences;
	
	return retData
end

--- 处理一次战役
-- @class function
-- @param playerOne 第一个玩家的ID
-- @param playerTwo 第二个玩家的ID
-- @return 返回战役的动作序列以及胜负
local function HandleBattle(playerOne, playerTwo)
	-- 1. 得到玩家牌组数据
	local cardTotalPlayerOne = nil
	local cardTotalPlayerTwo = nil
	
	-- 2. 通过玩家的总牌数据随机抽取12张卡牌作为牌库
	local cardLibPlayerOne = nil
	local cardLibPlayerTwo = nil
	
	-- 3. 从牌库中选择一局游戏中的需要的牌组
	--     可以是3组，每组3张，或者是1组，一组3张或者6张
	local cardBattleGroupPlayerOne = nil
	local cardBattleGroupPlayerTwo = nil
	
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
			battleResult
		}
	}
	
	return retData
end