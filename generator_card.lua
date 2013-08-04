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

-- 初始化随机种子
math.randomseed(os.time());

-- 得到随机数，最大和最小值设定
-- @param maxnum 随机值的最大值
-- @param minium 随机值的最小值
local genRand = function(maxnum, minium)
	minium = minium or 0;
	return math.floor(math.random()*100000 % maxnum + minium);
end

-- 生成随机牌库
-- @param total 生成的牌库数量
local generate_card_heap = function(total)
	local card_heap = {};
	
	for i = 1, total do
		local speed = genRand(prop_speed_tbl.maxium, prop_speed_tbl.minum);
		local attack = genRand(prop_attack_tbl.maxium, prop_attack_tbl.minium);
		local hp = genRand(prop_hitpoint_tbl.maxium, prop_hitpoint_tbl.minium);
		
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

-- 保存卡牌数据到文件
-- @param card_heap 生成的牌库
local storeDataToFile = function(card_heap)
	local data = {};
	for idx, card in ipairs(card_heap) do
		local c_data = string.format("%d\t%d\t%d\t%d", idx, card.attack, card.hp, card.speed);
		print(c_data);
		table.insert(data, c_data);
	end
	
	local file = io.open("card_data.txt", "w+b");

	if file then
		file:write(table.concat(data, "\n"));
		file:close();
	end
end

-- 从文件中读取卡牌数据到内存
local readCardData = function()

	local readFile = io.open("card_data.txt", "r+b");
	
	local card_heap = {};
	
	if readFile then
		-- 读取文件数据（按行）
		local card_data = readFile:read("*l");
		
		while (card_data ~= nil) do
--			print(card_data);
			local card = {};
			card.num, card.attack, card.hp, card.speed = string.match(card_data, "(%d+)%s(%d+)%s(%d+)%s(%d+)");
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

-- 从牌库中获得3张卡牌
-- @param card_store 牌库
-- @param side 分组ID，一般是1和2，表示两个对立面
-- @param counts 取几张卡牌，默认3张
local chooseCardFromStore = function(card_store, side, counts)

	counts = counts or 3;
--	print(#card_store);
	
	local battle_cards = {};
	
	local cn = {};
	for i=1,counts do
		table.insert(cn, genRand(#card_store, 1));
	end
	
	for idx, cardNum in ipairs(cn) do
		local cardData = {};
		local cd = card_store[cardNum];
		if cd == nil then
			error(string.format("cardNum is %d", cardNum));
		end
		for k, v in pairs(cd) do
			cardData[k] = tonumber(v);
		end
		
		cardData.side = side;
		--  插入选出的牌中
		table.insert(battle_cards, cardData);
	end
	
	return battle_cards;
end

local copyTbl = function(tbl)
	local retTbl = {};
	for k, v in pairs(tbl) do
		retTbl[k] = v;
	end
	return retTbl;
end

-- 速度排序
-- @param bc1 牌组1
-- @param bc2 牌组2
local speedSort = function(bc1, bc2)
	-- 合并牌，得到总体攻击顺序
	local attack_sequence = {};
	
	for k, v in ipairs(bc1) do
		table.insert(attack_sequence, v);
	end
	
	for k, v in ipairs(bc2) do
		table.insert(attack_sequence, v);
	end
	
--	print("attack_sequence's count", #attack_sequence);
		
	-- 循环牌库，得到速度比值
	table.sort(attack_sequence, function(one, two)
		return one.speed > two.speed
	end);
	
	return attack_sequence;
end

-- 可以根据战斗方来显示对应的攻击、血量、速度等数据
-- @param sequence 序列表
-- @param side 可选参数，显示对应一方的数据
local showBattleCard = function(sequence, side)
	for k, v in ipairs(sequence) do
		if side then
			if v.side == side then
				print(string.format("cardNum:%d\tattack:%d\thp:%d\tspeed:%d\tside:%d", v.num, v.attack, v.hp, v.speed, v.side));
			end
		else
			print(string.format("cardNum:%d\tattack:%d\thp:%d\tspeed:%d\tside:%d", v.num, v.attack, v.hp, v.speed, v.side));
		end
	end
end

-- 显示战后有战绩的卡牌（隐藏未出战）
-- @param card_store 牌库
-- @param bExcel 用作excel输出，中间以tab键分隔
local showDataAfterBattle = function(card_store, bExcel)
	for k, card in ipairs(card_store) do
		-- 过滤未出战
		if card.winCnts + card.loseCnts > 0 then
			if bExcel then
				print(card.num, card.attack, card.hp, card.speed, (card.attack + card.hp + math.floor(card.speed/100)), card.winCnts, card.loseCnts, card.winCnts/(card.winCnts + card.loseCnts))
			else
				print(string.format("CardID:%04d, Attack:%d, HP:%d, Speed:%d, TotalAbility:%d, WinCnts:%d, LoseCnt:%d, WinPercent:%.2f%%", 
				card.num, card.attack, card.hp, card.speed, (card.attack + card.hp + math.floor(card.speed/100)), card.winCnts, card.loseCnts, card.winCnts/(card.winCnts + card.loseCnts)*100));
			end
		end
	end
end

-- 设置单卡的胜利和失败次数
-- @param cardStore 用来设定记录每张卡牌的战斗数据的表，下标就是牌的ID
-- @param card_group 对应的牌组
-- @param winOrLose 表示当前组的输赢 值 win 表示胜利，其余表示失败
local markCardFightResult = function(cardStore, card_groupe, winOrLose)

	for k, card in ipairs(card_groupe) do
		local cardID = card.num
		
		local cardData = cardStore[cardID];
		
		if not cardData then
			error("cardData is nil");
			return
		end
		
		if winOrLose and winOrLose == "win" then
			cardData.winCnts = cardData.winCnts + 1;
		else
			cardData.loseCnts = cardData.loseCnts + 1;
		end
	end
end

-- 得到防守顺序辅助队列（内部数据全是引用）
-- @param 防御组牌表
local getDefenderSequence = function(cardDefenderGroup)
	-- 得到一个攻击优先顺序辅助队列
	local defenderSequence = {};
	-- 生成两个顺序的数组，用来生成最终随机的排序，供乱序防守卡牌到防守辅助队列中决定防守的顺序
	local assistSequence = {}
	local assistRndSequence = {}
	-- 根据对战组的卡牌多少来生成序列数组
	for idx = 1, #cardDefenderGroup do
		table.insert(assistSequence, idx)
	end
	
	-- 循环拷贝辅助顺序
	while #assistSequence > 0 do
		-- 随机一个位置
		local rnd = genRand(#assistSequence, 1)
		-- 将随机得出的位置的卡牌放入顺序队列中
		table.insert(assistRndSequence, assistSequence[rnd]);
		-- 决定顺序的卡牌出队列
		table.remove(assistSequence, rnd);
	end
		
	-- 根据决定的顺序生成防守辅助队列
	for key, value in ipairs(assistRndSequence) do
		table.insert(defenderSequence, cardDefenderGroup[value])
	end
		
	return defenderSequence
end

-- 攻击测试
-- @param card1 第一组卡牌
-- @param card2 第二组卡牌
-- @param card_store 总卡牌表，用以记录每张卡牌的战斗数据
local attackTest = function(card1, card2, card_store)
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
			
--[[			战斗中，统一挑选敌方第一张卡牌作为攻击对象策略

			-- 循环得到第一个活着的敌对单位
			for idxInside = 1, 6 do
				local cardTmp = sequence[idxInside];
				
				if sideAttack ~= cardTmp.side and cardTmp.hp > 0 then
					nAttackCnt = nAttackCnt + 1;
-- 					print(string.format("=============circle %d=============", nCircle));
-- 					print(string.format("attacker's id is %d, defender's id is %d", cardAttacker.num, cardTmp.num));
					local delta = 0;
					if cardAttacker.attack < cardTmp.hp then
						delta = cardAttacker.attack
					else
						delta = cardTmp.hp
					end
					
-- 					print("===>Delta is ", delta);
-- 					print(string.format("Attacker side is %d, Defender side is %d", cardAttacker.side, cardTmp.side));
-- 					print(string.format("Attacker card is %d, Defender card is %d", cardAttacker.num, cardTmp.num));
					
					-- 减去攻击力
					cardTmp.hp = cardTmp.hp - cardAttacker.attack;
					
					if cardTmp.side == 1 then
						nTotalHP1 = nTotalHP1 - delta;
					elseif cardTmp.side == 2 then
						nTotalHP2 = nTotalHP2 - delta;
					end

-- 					print("Player1's total HP", nTotalHP1);
-- 					print("Player2's total HP", nTotalHP2);		
-- 					showBattleCard(sequence);
-- 					print("=============circle end=============");
					break
				end
			end
--]]
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

-- 保存生成的随机牌库到文件
-- storeDataToFile(generate_card_heap(200));

-- 得到从文件中的牌库到内存表
local card_store = readCardData();

-- print("card_store's count", #card_store);

-- 得到两个对战牌表
-- local card_1 = chooseCardFromStore(card_store, 1)
-- local card_2 = chooseCardFromStore(card_store, 2)

-- 得到经过攻击序列结束后的表
-- local sequence = attackTest(card_1, card_2, card_store);

-- 输出战后的结果
-- showBattleCard(sequence);

for i = 1, 200000 do
	attackTest(chooseCardFromStore(card_store, 1), chooseCardFromStore(card_store, 2), card_store);
end

showDataAfterBattle(card_store, true);
