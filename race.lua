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
-- @field race_type <b>array</b> 种族类型定义 1 - "Human" 2 - "Undead" 3 - "Evil" 4 - "DemiGod" 5 - "Natural" 6 - "Mehanical"
-- @see race_type
CONSTANTS = {
	--- 种族类型定义 
	race_type = {
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
-- @field Evil <b>table</b> 恶魔
-- @field Undead <b>table</b> 不死
-- @field Human <b>table</b> 人类
-- @field DemiGod <b>table</b> 半神
-- @field Natural <b>table</b> 自然
-- @field Mehanical <b>table</b> 机械
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
-- @return 返回对应的种族类型
function RaceClass:getRace()
	if self.raceType then
	end	
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
		race = self[CONSTANTS.race_type[raceType]]
	end
	
	if not race then return end
	
	local o = {}
	
	setmetatable(o, self)
	
	self.__index = self
	
	return o
end
