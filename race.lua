-- �����趨
module(package.seeall, "Race")

-- ����ĳ���
CONSTANTS = {
	-- �������Ͷ���
	race_type = {
		-- ���࣬ID = 1
		"Human",
		-- ������ID = 2
		"Undead",
		-- ��ħ��ID = 3
		"Evil",
		-- ����ID = 4
		"Demigod",
		-- ��Ȼ��ID = 5
		"Natural",
		-- ��е,��ID = 6
		"Mehanical"
	}
}

RaceClass = {
	-- ��ħ
	Evil = {},
	-- ����
	Undead = {},
	-- ����
	Human = {},
	-- ����
	DemiGod = {},
	-- ��Ȼ
	Natural = {},
	-- ��е
	Mehanical = {}
}

-- @brief ��ȡ��ǰ���������
function RaceClass:getRace()
	if self.raceType
	end	
end

-- @brief ��������
-- @param raceType ������string��������number
function RaceClass:new(raceType)
	local tp = type(raceType)
	
	local race = nil
	-- �õ�����Ķ���
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
