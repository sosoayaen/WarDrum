--- 通用函数模块
-- @class module
-- @author Jason Tou sosoayaen@gmail.com
-- @copyright Jason Tou
module("comm", package.seeall)

require "util"

require "card"

-- 速度属性，可以不显示影响，通过负重属性
local prop_speed_tbl =
{
	minium = 1,	-- 最小值
	maxium = 10	-- 最大值
}

local prop_attack_tbl =
{
	minium = 1,	-- 最小值
	maxium = 7
}

local prop_hitpoint_tbl =
{
	minium = 1, -- 最小值
	maxium = 10
}

--- 生成随机牌库
-- @class function
-- @param total 生成的牌库数量
-- @return <code>array</code> 返回卡牌堆数组 @see Card
generate_card_heap = function(total)
	local card_heap = {};
	
	for i = 1, total do
		local speed = util.genRand(prop_speed_tbl.maxium, prop_speed_tbl.minum);
		local attack = util.genRand(prop_attack_tbl.maxium, prop_attack_tbl.minium);
		local hp = util.genRand(prop_hitpoint_tbl.maxium, prop_hitpoint_tbl.minium);
		
		local card_data =
		{
			speed = speed,
			attack = attack,
			hp = hp
		};
		
		table.insert(card_heap, card_data);
	end
	
	return card_heap;
end

--- 保存卡牌数据到文件
-- @class function
-- @param card_heap 生成的牌库
-- @param dataFileName 保存文件名称
-- @return
storeDataToFile = function(card_heap, dataFileName)
	local data = {};
	for idx, card in ipairs(card_heap) do
		local c_data = string.format("%d\t%d\t%d\t%d", idx, card.attack, card.hp, card.speed);
		print(c_data);
		table.insert(data, c_data);
	end
	
	local file = io.open(dataFileName or "card_data.txt", "w+b");

	if file then
		file:write(table.concat(data, "\n"));
		file:close();
	end
end

--- 从文件中读取卡牌数据到内存
-- @class function
-- @param dataFileName 数据文件
-- @return <code>array</code> 返回卡牌堆数据 @see Card.CardClass
readCardData = function(dataFileName)

	local readFile = io.open(dataFileName or "card_data.txt", "r+b");
	
	local card_heap = {};
	
	if readFile then
		-- 读取文件数据（按行）
		local card_data = readFile:read("*l");
		
		while (card_data ~= nil) do
--			print(card_data);
			local card = {};
			card.id, card.attack, card.hitPoint, card.speed = string.match(card_data, "(%d+)%s(%d+)%s(%d+)%s(%d+)");
--			print(card.num, card.attack, card.hp, card.speed);

			-- 增加胜利次数和战败次数
			card.winCnts = 0;
			card.loseCnts = 0;
			table.insert(card_heap, card);
--			print(#card_heap);
			card_data = readFile:read("*l");
		end
		
		readFile:close();
	end
	
	return card_heap;
end

--- 从选好的可出战牌库中选择当前局出战卡牌序列，简单的table
-- @class function
-- @param card_store 玩家所有用的牌库
-- @param counts 组成牌库的数量
chooseCardFromStore = function(card_store, counts)
	counts = counts or 10	-- 至少10张组成牌库
	
	if not card_store then
		return
	end
	
	-- 牌库
	local card_lib = {};
	
	local cn = {};
	local cn_a = {} -- 辅助表，用来保存是否选中的标志
	local maxRange = #card_store
	
	repeat
		local num = util.genRand(maxRange, 1)
		-- 只有不重复的ID卡牌才能入库
		if not cn_a[num] then
			table.insert(cn, num)
			cn_a[num] = true
		end
	until #cn >= counts
	
	for idx, cardNum in ipairs(cn) do
		-- 这里直接索引拷贝，不会修改内部值
		local singleCard = card_store[cardNum];
		if singleCard == nil then
			error(string.format("cardNum is %d", cardNum));
		end
		
		table.insert(card_lib, singleCard);
	end
	
	return card_lib;
	
end

--- 从牌库中获得N张卡牌
-- @class function
-- @param card_store 牌库
-- @param side 分组ID，一般是1和2，表示两个对立面，也可以用户ID，主要是用来区分卡牌的归属
-- @param counts 取几张卡牌，默认3张
-- @return <code>array</code> 返回选好的卡组 @see Card.CardPropertyClass
chooseActionCardGroupFromStore = function(card_store, side, counts)

	counts = counts or 3;
	
	if not card_store then
		return
	end
--	print(#card_store);
	
	local battle_cards = {};
	
	local cn = {};
	local cn_a = {} -- 辅助表，用来保存是否选中的标志
	local maxRange = #card_store
	repeat
		local num = util.genRand(maxRange, 1)
		-- 只有不重复的ID卡牌才能入库
		if not cn_a[num] then
			table.insert(cn, num)
			cn_a[num] = true
		end
	until #cn >= counts
	
	for idx, cardNum in ipairs(cn) do
		local singleCard = table.dup(card_store[cardNum]);
		if singleCard == nil then
			error(string.format("cardNum is %d", cardNum));
		end
		
		singleCard.side = side
		local cardData = Card.CardPropertyClass:new(singleCard);
		
		table.insert(battle_cards, cardData);
	end
	
	return battle_cards;
end

--- 速度排序。按照速度从大到小的顺序排序
--  注意，这里的排序只是把卡牌对象直接放到一个新的序列中，不会生成新的对象
-- @class function
-- @param card_array 牌组数组，可以有多个牌组组成，几个牌组表示一个玩家
-- @return 返回一个卡牌行动序列表
getActionSequence = function(card_array)

	-- 合并牌，得到action_sequence总体行动顺序
	local action_sequence = {};
	
	for idx, card_group in ipairs(card_array) do
		
		for k, v in ipairs(card_group) do
			table.insert(action_sequence, v)
		end
		
	--	print("action_sequence's count", #action_sequence);
	end
	
	-- 循环牌库，得到速度比值
	table.sort(action_sequence, function(one, two)
		return one.speed > two.speed
	end);
	
	return action_sequence;
end

--- 普通攻击测试
-- @class function
-- @param card1 第一组卡牌
-- @param card2 第二组卡牌
-- @param card_store 总卡牌表，用以记录每张卡牌的战斗数据
attackNormalTest = function(card1, card2, card_store)
	-- 得到攻击对象的速度排序列表
	local sequence = speedSort(card1, card2);
	
--	showBattleCard(sequence);
	
	local idx = nil;
	-- 计算总血量
	local nTotalHP1 = 0;
	local nTotalHP2 = 0;
	for idx = 1, 6 do
		local card = sequence[idx];
		if card.side == 1 then
			nTotalHP1 = nTotalHP1 + card.hp;
		elseif card.side == 2 then
			nTotalHP2 = nTotalHP2 + card.hp;
		end
	end
	
-- 	print("Player1 total HP is ", nTotalHP1);
-- 	print("Player2 total HP is ", nTotalHP2);
	
	local nCircle = 1;
	local nAttackCnt = 0;
	-- 循环攻击者
	idx = 1;
	while idx <= 6 do
		-- 攻击方
		local cardAttacker = sequence[idx];
		-- 阵营
		local sideAttack = cardAttacker.side;
		if cardAttacker.hp > 0 then	-- 活着攻击方的单位
			--[[ 战斗中，攻击方随机挑选地方单位攻击策略
				使用随机选择敌方来攻击的算法
				1. 首先得到1～3的随机数
				2.访问敌方卡牌，得到对应的num
				3.遍历对战表
			--]]
			local cardDefenderGroup = nil
			if sideAttack == 1 then
				cardDefenderGroup = card2
			else
				cardDefenderGroup = card1
			end
			
			-- 得到一个攻击优先顺序辅助队列
			local defenderSequence = getDefenderSequence(cardDefenderGroup)
			
			-- 最多循环3次（防守队列的长度），只要攻击到一个即刻结束
			for idxDefender, cardDefender in ipairs(defenderSequence) do
				
				assert(cardDefender.side ~= sideAttack, "Defender side wrong")

				-- 判断防守方是否存活，如果死亡则选择下一个防守方
				if cardDefender.hp > 0 then
					-- 本次战斗攻击次数加1
					nAttackCnt = nAttackCnt + 1
					
					-- 计算组内扣血量
					local deltaBlood = 0;
					if cardAttacker.attack < cardDefender.hp then
						deltaBlood = cardAttacker.attack
					else
						deltaBlood = cardDefender.hp
					end
					
					-- 防守方扣血，减去攻击方攻击力，可以击穿
					cardDefender.hp = cardDefender.hp - cardAttacker.attack
					
					-- 防守方团队扣血
					if cardDefender.side == 1 then
						nTotalHP1 = nTotalHP1 - deltaBlood
					elseif cardDefender.side == 2 then
						nTotalHP2 = nTotalHP2 - deltaBlood
					end
					
					-- 攻击过后则跳出防守扣血循环，开始选出下一个攻击对手
					break
				end
			end
		end		
		-- 是否有一方的血到0则结束战斗
		if nTotalHP1 <= 0 then
-- 			print("Winner is Player1, circle", nCircle, "Attacks", nAttackCnt);
			break;
		elseif nTotalHP2 <= 0 then
-- 			print("Winner is Player2, circle", nCircle, "Attacks", nAttackCnt);
			break;
		end
		
		idx = idx + 1;
		-- 开始新的一轮
		if idx > 6 then
			nCircle = nCircle + 1;
			idx = 1;
		end
	end
	
	-- 循环表格，得到对应的ID，然后增加升级和失败次数
	if card_store then
		if nTotalHP1 <= 0 then
			-- 增加2组牌的胜利次数
			markCardFightResult(card_store, card2, "win");
			markCardFightResult(card_store, card1, "lose");
		else
			markCardFightResult(card_store, card1, "win");
			markCardFightResult(card_store, card2, "lose");
		end
	end
--	print("=============================Attack=============================");
	return sequence;
end

--- 正式版的攻击测试
-- @class function
attackTest = function()

end
