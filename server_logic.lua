--[[
	������ҵ��������
	Сд��ĸ��ͷ�ĺ�����ʾ���غ�������д�ĺ�����ʾȫ�ֺ���
]]
package.path = ".\\?.lua;" .. package.path

require "comm"
require "card"

print(Card.CardProperty:new())
-- ���ո�����ɫ���������ԣ���������

-- ս������
-- @param cardGroupOne ���1ѡȡ�õĿ���
-- @param cardGroupTwo ���2ѡȡ�õĿ���
-- @return ����һ��ս���Ľ����˭Ӯ�ñ������غϡ��������У����ڻطţ�
local doBattle = function(cardGroupOne, cardGroupTwo)
	local retData = {
		bFirstWin = false	-- ��Ĭ�϶���ǵ�һ��ʤ��
	}
	
	-- ����һ���������б�
	local sequences = {}
	
	--[[ 
		ս������
	]]
	
	--//////////////////////
	-- �����׶�
	--//////////////////////
	-- 1. �������ܽ��㣬�����е�λ�ļ��ܷ��������ܵķ�����������Ӧ�׶ξ���
	
	
	-- 2. 
	
	retData.sequences = sequences;
	
	return retData
end

-- ����һ��ս��
-- @param playerOne ��һ����ҵ�ID
-- @param playerTwo �ڶ�����ҵ�ID
-- @return ����ս�۵Ķ��������Լ�ʤ��
local HandleBattle = function(playerOne, playerTwo)
	-- 1. �õ������������
	local cardTotalPlayerOne = nil
	local cardTotalPlayerTwo = nil
	
	-- 2. ͨ����ҵ��������������ȡ12�ſ�����Ϊ�ƿ�
	local cardLibPlayerOne = nil
	local cardLibPlayerTwo = nil
	
	-- 3. ���ƿ���ѡ��һ����Ϸ�е���Ҫ������
	--     ������3�飬ÿ��3�ţ�������1�飬һ��3�Ż���6��
	local cardBattleGroupPlayerOne = nil
	local cardBattleGroupPlayerTwo = nil
	
	-- 4. ���ݵ�ǰ�����þ������м��ζ�ս
	local battleResult = doBattle(cardBattleGroupPlayerOne, cardBattleGroupPlayerTwo)
	
	-- 5. �����ೡս�����ó�ʤ�������ID
	local winnerID = playerTwo.userID
	if battleResult.bFirstWin then
		winnerID = playerOne.userID
	end
	
	-- 6. �Զ��ս�۴������
	local retData = {
		-- ս�۽��
		battleResult = {
			-- ʤ����ID
			winnerID = 1000
		},
		-- ս�����ݣ�����
		battleData = {
			battleResult
		}
	}
	
	return retData
end