-- 初始化随机种子
math.randomseed(os.time());

-- 得到随机数，最大和最小值设定
local genRand = function(maxnum, minium)
	minium = minium or 0;
	return math.floor(math.random()*100000 % (maxnum) + minium);
end

for i=0, 100000 do
	local value = genRand(200, 1);
	if value >= 201 or value <= 0 then
		print(value);
	end
end

-- 得到防守顺序辅助队列（内部数据全是引用）
local getDefenderSequence = function(cardDefenderGroup)
	-- 得到一个攻击优先顺序辅助队列
	local defenderSequence = {};
	-- 生成两个顺序的数组，用来生成最终随机的排序，供乱序防守卡牌到防守辅助队列中决定防守的顺序
	local assistSequence1 = {1, 2, 3}
	local assistSequence2 = {}
	
	-- 循环拷贝辅助顺序
	while #assistSequence1 > 0 do
		-- 随机一个位置
		local rnd = genRand(#assistSequence1, 1)
		-- 将随机得出的位置的卡牌放入顺序队列中
		table.insert(assistSequence2, assistSequence1[rnd]);
		-- 决定顺序的卡牌出队列
		table.remove(assistSequence1, rnd);
	end
		
	-- 根据决定的顺序生成防守辅助队列
	for key, value in ipairs(assistSequence2) do
		table.insert(defenderSequence, cardDefenderGroup[value])
	end
		
	return defenderSequence
end

local cardGroup = {100, 200, 300}

for idx = 1, 100 do
	local seq = getDefenderSequence(cardGroup)

	table.foreach(seq, print)
	print(idx, "=====================")
end
