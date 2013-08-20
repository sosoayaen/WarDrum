-- 种族设定
module(package.seeall, "Race")

-- 种族的常量
CONSTANTS = {
	-- 种族类型定义
	race_type = {
		-- 人类，ID = 1
		"Human",
		-- 不死，ID = 2
		"Undead",
		-- 恶魔，ID = 3
		"Evil",
		-- 半神，ID = 4
		"Demigod",
		-- 自然，ID = 5
		"Natural",
		-- 机械,，ID = 6
		"Mehanical"
	}
}

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

-- @brief 获取当前对象的种族
function RaceClass:getRace()
	if self.raceType
	end	
end

-- @brief 创建种族
-- @param raceType 可以是string，可以是number
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
