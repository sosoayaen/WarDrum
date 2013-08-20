module("Ablity", package.seeall)

local const_mt = {
	-- ��������;�޸�ֵ
	__newindex = function(t, k, v) end
}

-- ��̬�����Ķ����
CONSTANTS = {
	-- ����
	LIMITLESS = -1,
	
	-- ������Ӧ����
	answerWindow = {
		-- ��Ч���ڣ�����
		WINDOW_INVALID = 0,
		-- �غϿ�ʼ
		WINDOW_ROUND_START = 1,
		-- �ж���ʼ
		WINDOW_ACTION_START = 2,
		-- Ŀ��ָ��ǰ
		WINDOW_TARGET_CHOOSE = 3,
		-- Ŀ��ָ��ʱ
		WINDOW_TARGET_CHOOSE_AFTER = 4,
		-- ����֮ǰ
		WINDOW_ATTACK_BEFORE = 5,
		-- ����֮��
		WINDOW_ATTACK_AFTER = 6,
		-- ����֮ǰ
		WINDOW_DEFEND_BEFORE = 7,
		-- ����֮��
		WINDOW_DEFEND_AFTER = 8,
		-- �غϽ���
		WINDOW_ROUND_END = 9,
		-- �ֽ���
		WINDOW_MATCH_END = 10,
		-- ��������
		WINDOW_DEATH = 100
	},
	-- �������õ�����
	influenceProperty = {
		-- ���κ�Ӱ��
		INVALIDE = 0,
		-- Ӱ�칥����
		ATTACK = 1,
		-- Ӱ��Ѫ��
		HP = 2,
		-- Ӱ���ٶ�
		SPEED = 3
	},
	-- ����Ӱ��ĵ�λ��Χ��ȫԱ�͵���
	targetInfluenceRange = {
		-- ȫ����Ч�����ţ���λЧ��
		ALL = 0,
		-- ���ⵥ��
		ANY = 1,
		-- �������ⵥ��Ч��
		ANY_WE = 2,
		-- �з����ⵥ��
		ANY_OPPONENT = 3,
		-- ����ȫԱ
		ALL_WE = 4,
		-- �з�ȫԱ
		ALL_OPPONENT = 5
	},
	-- ����ѡ��Ŀ�굥λ���Ͳ���
	targetChooseTactics = {
		-- ��Ч��λ��������
		INVALID = 0,
		-- Ŀǰ�ж��ĵ�λ
		ACTIVE_UNIT = 1,
		-- Ŀǰ�����ĵ�λ
		DEFEND_UNIT = 2,
		-- ��������
		RACE_LIMIT = 3,
		-- ������������
		ATTACK_TYPE_LIMIT = 4,
		-- ����������
		ATTACK_LIMIT = 5,
		-- �ٶ�����
		SPEED_LIMIT = 6,
		-- Ѫ������
		HP_LIMIT = 7,
		-- �ض�����
		CARD_NO_LIMIT = 8,
		-- �ڳ��˾���������
		UNIT_NUM_LIMIT = 9,
		-- Ѫ����
		HP_SUMMATION = 10,
		-- ��������
		ATTACK_SUMMATION = 11,
	},
	-- ����ѡ������жϣ��Ƿ�ȡ����
	targetChooseTacticsExt = {
		-- Ĭ��ֵ
		NORMAL_FLAG = 0,
		-- ȡ��
		NOT_FLAG = 1,
	}
}

-- ����Ԫ��
setmetatable(CONSTANTS, const_mt)


-- �������Ա�
local ExceptionalAbilityClass = {
	-- ���ܹؼ���
	keyWord = "null",
	
	-- ��������
	description = "",
	
	-- ��Ӧ���ԣ���ʲôʱ����Ӧ
	action = {
		-- ////////////
		-- ��Ӧ����
		-- ����0��ʾ������-1��ʾ������Ӧ, 0 ��ʾ����Ӧ
		counts = 0,
		
		-- ///////////
		-- ��Ӧʱ��
		-- @see CONSTANTS.answerWindow
		answerWindow = CONSTANTS.answerWindow.WINDOW_INVALID,
	},
	-- //////////////
	-- ��������
	property = {
		-- ����Ŀ�귶Χ
		-- ���������ܵ�Ŀ����ȫ�廹�ǵ��壬���м����͵ط�
		-- @see CONSTANTS.targetInfluenceRange
		targetInfluenceRange = CONSTANTS.targetInfluenceRange.ANY, -- Ĭ�ϵ���
		
		-- ������������
		-- ���������ܻ�ı�����ԣ�Ŀǰ�޷� ���������������ٶȡ�����Ѫ����
		-- @see CONSTANTS.influenceProperty
		influenceType = CONSTANTS.influenceProperty.ATTACK,
		
		-- ����Ӱ�����ֵ
		-- ���������ܷ����󣬸���influenceType����������Ч��ֵ��ֵ������֮�֣�ֱ���ۼӽ���
		-- @example 1. influenceType == CONSTANTS.influenceProperty.ATTACK
		--               2. influenceValue == 1
		--               3. action.answerWindow == CONSTANTS.answerWindow.WINDOW_ATTACK_BEFORE
		--               4. targetInfluenceRange == CONSTANTS.targetInfluenceRange.ALL_WE
		--               5. influenceResponseCount = 1
		--               7. liquidateRemoveAbility = true
		--               8. persistentHostUnit = -1 ��ʾ����ʩ����λ
		--               ���ʾ���ж�����ǰ�Ĵ��ڽ��㣬�ڹ���ǰ���������е�λ����1�㹥����BUFF�������ȡ��
		influenceValue = 1,
		
		-- ������Ӧ������-1��ʾ������Ӧ
		influenceResponseCount = 1,
		
		-- �����Ƿ���Ҫ����ʩ����λ -1 ��ʾ����ʩ����λ
		persistentHostUnit = -1,
		
		-- �Ƿ񷢶���ֱ��ȡ���������㡢����׶��Ƴ��˼��ܣ�
		liquidateRemoveAbility = true,
	}
	
	-- ������Ч�����б�
	-- @runtime
	targetList = {},
}

-- ���󴴽�
function ExceptionalAbilityClass:new(o)
	o = o or {}
	
	-- ����Ԫ��
	setmetatable(o, self)
	
	-- ���ö�Ӧ����·��ΪExceptionalAbilityClass����
	-- ʹʵ��ӵ�ж�Ӧ�ĳ�Ա�����ͳ�Ա����
	self.__index = self
	
	-- ��д�������ʽ
	self.__tostring = function(t)
		
	end
	
	-- ����ʵ��
	return o
end

-- ���ع�����
return ExceptionalAbilityClass