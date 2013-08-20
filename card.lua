module("Card", package.seeall)

CardProperty = {
	-- 攻击力
	attack = 0,
	-- 血量
	hitPoint = 1,
	-- 速度
	speed = 0,
	-- 卡牌唯一编号
	id = -1,
	-- 卡牌名称
	name = "",
	-- 种族
	race = "",
	-- 卡牌登记
	level = 0,
	-- 异能，可以多个
	ablity = {},
	-- 组牌限制，牌组中可以拥有的数量
	numberLimit = 3,
	
}

-- @return 返回是否单位已经死亡
function CardProperty:isDead()
	return self.hitPoint <= 0
end

-- 创建一个卡牌对象
-- @return CardProperty Instance
function CardProperty:new(o)
	o = o or {}
	
	setmetatable(o, self)
	
	self.__index = self
	
	-- 不允许新增不存在的数据
	self.__newindex = function(t, k) end
	
	self.__tostring = function(t)
		local tbl = {}
		table.foreach(self, function(key, value)
			local tps = type(value)
			if tps == 'table' then
				if key == 'ablity' then
					-- 输出一张卡牌对应的技能属性
					table.insert(tbl, string.format("%s=%s", key, table.concat(value, "/")))
				end
			elseif type(value) ~= 'function' then
				table.insert(tbl, string.format("%s=%s", key, tostring(value)))
			end
		end)
	return table.concat(tbl, ", ") end
	
	return o
end

return CardProperty