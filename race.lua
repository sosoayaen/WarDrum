--- 种族模块
-- @class module
-- @author Jason Tou sosoayaen@gmail.com
-- @copyright Jason Tou
module("Race", package.seeall)

local const_mt = {
	-- 不允许中途修改值
	__newindex = function(t, k, v) end
}

--- 种族的常量
-- @class table
-- @name CONSTANTS
-- @field raceType <vt>array</vt> 种族类型定义 1 - "Human" 2 - "Undead" 3 - "Evil" 4 - "DemiGod" 5 - "Natural" 6 - "Mehanical"
-- @see raceType
CONSTANTS = {
	--- 种族类型定义 
	raceType = {
		-- 人类，ID = 1
		"Human",
		-- 不死，ID = 2
		"Undead",
		-- 恶魔，ID = 3
		"Evil",
		-- 半神，ID = 4
		"DemiGod",
		-- 自然，ID = 5
		"Natural",
		-- 机械,，ID = 6
		"Mehanical"
	}
}

setmetatable(CONSTANTS, const_mt)

--- 种族基类
-- @class table
-- @name RaceClass
-- @field Evil <vt>table</vt> 恶魔
-- @field Undead <vt>table</vt> 不死
-- @field Human <vt>table</vt> 人类
-- @field DemiGod <vt>table</vt> 半神
-- @field Natural <vt>table</vt> 自然
-- @field Mehanical <vt>table</vt> 机械
RaceClass = {
	-- 恶魔
	Evil = {},
	-- 不死
	Undead = {},
	-- 人类
	Human = {},
	-- 半神
	DemiGod = {},
	-- 自然
	Natural = {},
	-- 机械
	Mehanical = {}
}

--- 获取当前对象的种族
-- @class function
-- @param nRaceType <vt>unsigned int</vt> 种族的ID，在每个卡牌的种族属性中
-- @return <vt>string</vt> 返回对应的种族类型描述
function RaceClass.GetRaceName(nRaceType)

	local race = CONSTANTS.raceType[nRaceType] or "Undefined Race"
	
	return race
end

--- 获取种族描述对应的种族对象
-- 入参一般为<a href="Card.html#CardPropertyClass">Card</a>属性中的 race 字段
-- @class function
-- @param raceType <vt>unsigned int, string</vt> 对应种族的key，可以是ID，可以使字符串描述
-- @return <vt>table</vt> 返回对应的种族对象结构体（表）
function RaceClass.GetRaceObj(raceType)

	local raceObj = nil
	
	-- 判断是否raceType有效
	local tp = type(raceType)
	
	if tp then
		if tp == 'string' then
			raceObj = RaceClass[tp]
		elseif tp == 'number' then
			raceObj = RaceClass[CONSTANTS.raceType[tp]];
		end
	end
	
	return raceObj
end

--- 创建种族
-- @class function
-- @param raceType 可以是string，可以是number
-- @return 返回一个种族的实例
function RaceClass:new(raceType)
	local tp = type(raceType)
	
	local race = nil
	-- 得到具体的对象
	if tp == "string" then
		race = self[raceType]
	elseif tp == "number" then
		race = self[CONSTANTS.raceType[raceType]]
	end
	
	if not race then return end
	
	local o = {}
	
	setmetatable(o, self)
	
	self.__index = self
	
	return o
end
