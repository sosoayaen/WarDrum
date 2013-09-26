--- 卡牌模块
-- @class module
-- @author Jason Tou sosoayaen@gmail.com
-- @copyright Jason Tou
module("Card", package.seeall)

--- 卡牌基类，定义了卡牌的一些基础属性
-- @class table
-- @name CardPropertyClass
-- @field attack <vt>int</vt> 定义了此张卡牌的攻击力指
-- @field attackType <vt>int</vt> 攻击属性（近战、远程、魔法、混乱） @see AttackType
-- @field hitPoint <vt>int</vt> 定义了此张卡牌的血量
-- @field speed <vt>int</vt> 定义了此张卡牌的速度
-- @field id <vt>unsigned int</vt> 卡牌的编号（唯一）
-- @field name <vt>string</vt> 卡牌的名称
-- @field race <vt>string</vt> 卡牌的种族	<a href=Race.html#RaceClass>RaceClass</a>
-- @field rare <vt>int</vt> 卡牌的稀有度 @see Rare
-- @field abilitys <vt>array</vt>异能，可以有多个，数组。属性详见异能列表 <a href=Ablity.html#ExceptionalAbilityClass>ExceptionalAbilityClass</a>
-- @field numberLimit <vt>int</vt> 牌组限制，此卡牌可以在牌组中出现的次数
CardPropertyClass = {
	-- 攻击力
	attack = 0,
	-- 攻击类型
	attackType = 0,
	-- 血量
	hitPoint = 1,
	-- 速度
	speed = 0,
	-- 卡牌唯一编号
	id = -1,
	-- 卡牌名称
	name = "Undefined card",
	-- 种族
	race = -1,
	-- 卡牌稀有度
	rare = 0,
	-- 异能，可以多个，内部为异能的ID，不允许重复
	ablitys = {},
	-- 组牌限制，牌组中可以拥有的数量
	numberLimit = 3,
	-- 附属属性
	side = 0
}

--- 判断当前卡牌是否已经死亡
-- @class function
-- @return <vt>bool</vt> 返回是否单位已经死亡
function CardPropertyClass:isDead()
	return self.hitPoint <= 0
end

--- 获得对象的地址
-- @class function
-- @return 返回对象的类型和地址
function CardPropertyClass:getAddress()
	local mt = getmetatable(self)
	local ts = mt.__tostring
	mt.__tostring = nil
	local ret = tostring(self)
	mt.__tostring = ts
	return ret
end

--- 创建一个卡牌对象，所有的卡牌都要通过此函数生成
-- @class function
-- @param o 设置对应初始属性表，会拷贝一份
-- @return CardPropertyClass 返回卡牌实例
function CardPropertyClass:new(o)
	o = o or {}
	
	setmetatable(o, self)
	
	self.__index = self
	
	-- 不允许新增不存在的数据
	self.__newindex = function(t, k) print('can`t create new field') end
	
	self.__tostring = function(t)
		local tbl = {}
		table.foreach(self, function(key, _)
			local value = t[key]
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
		return table.concat(tbl, ", ")
	end
	
	return o
end

--- 获得卡牌原始数值，通常可以用作一些状态等的恢复或者原始数值的比对
-- @class function
-- @param key 键
function CardPropertyClass:getOriginalValue(key)
	return self[key]
end

--- 设置对象是否不能添加自定义成员
-- @class function
-- @param isAllow bool 变量
function CardPropertyClass:setAllowNewField(isAllow)
	local mt = getmetatable(self)
	if isReadOnly then
		mt.__newindex = function(t, k) end
	else
		mt.__newindex = nil
	end
end

--- 判断当前对象是否可创建新成员<br><b>example:</b> Card.newfield = 0，如果不允许，则此类操作不会把newfield这个对象放到卡牌对象中
-- @class function
-- @return true or false
function CardPropertyClass:isAllowNewField()
	local mt = getmetatable(self)
	return not mt.__newindex
end
