module("Card", package.seeall)

CardProperty = {
	-- ������
	attack = 0,
	-- Ѫ��
	hitPoint = 1,
	-- �ٶ�
	speed = 0,
	-- ����Ψһ���
	id = -1,
	-- ��������
	name = "",
	-- ����
	race = "",
	-- ���ƵǼ�
	level = 0,
	-- ���ܣ����Զ��
	ablity = {},
	-- �������ƣ������п���ӵ�е�����
	numberLimit = 3,
	
}

-- @return �����Ƿ�λ�Ѿ�����
function CardProperty:isDead()
	return self.hitPoint <= 0
end

-- ����һ�����ƶ���
-- @return CardProperty Instance
function CardProperty:new(o)
	o = o or {}
	
	setmetatable(o, self)
	
	self.__index = self
	
	-- ���������������ڵ�����
	self.__newindex = function(t, k) end
	
	self.__tostring = function(t)
		local tbl = {}
		table.foreach(self, function(key, value)
			local tps = type(value)
			if tps == 'table' then
				if key == 'ablity' then
					-- ���һ�ſ��ƶ�Ӧ�ļ�������
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