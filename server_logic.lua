--[[
	服务器业务处理流程
	小写字母开头的函数表示本地函数，大写的函数表示全局函数
]]
package.path = ".\\?.lua;" .. package.path

require "comm"
require "card"

-- 按照各个角色的异能特性，整理异能

-- 战斗函数
-- @class function
-- @param cardGroupOne 玩家1选取好的卡组
-- @param cardGroupTwo 玩家2选取好的卡组
-- @return 返回一次战斗的结果，谁赢得比赛、回合、步骤序列（用于回放）
local function doBattle(cardGroupOne, cardGroupTwo)
	local retData = {
		bFirstWin = false	-- 先默认定义非第一个胜利
	}
	
	-- //////////////////////
	-- 战斗前准备
	-- 1. 得到单位行动顺序
	local actionSequences = comm.getActionSequence{cardGroupOne, cardGroupTwo}

	-- 2.按顺序结算异能发动
	table.foreachi(actionSequences, function(_, unit)
		if unit.className ~= "CARD" then
			-- 如果不是卡牌，则直接退出
			return
		end
		local abilityArray = unit.ability
		-- 判断下当前卡牌是否拥有异能
		if abilityArray and type(abilityArray) == 'table' then
			table.foreachi(abilityArray, function(_, abilityID)
				-- 通过异能的ID得到异能对象
				local ability = Ability.GetAbilityObj(abilityID)
				if ability then
					
				end
			end)
		end
	end)
	
	--[[ 
		战斗流程
	]]
	
	--//////////////////////
	-- 进场阶段
	-- 1. 进场技能结算，把所有单位的技能发动，技能的发动按照其响应阶段决定
	
	
	-- 2. 
	
	-- retData.sequences = actionSequences;
	
	return retData
end

-- 得到卡牌堆
local CardHeap = comm.readCardData("card_data.txt")

-- 处理一次战役
-- @class function
-- @param playerOne 第一个玩家的ID
-- @param playerTwo 第二个玩家的ID
-- @return 返回战役的动作序列以及胜负
local function HandleBattle(playerOne, playerTwo)
	-- 1. 得到玩家牌组数据
	local cardTotalPlayerOne = CardHeap
	local cardTotalPlayerTwo = CardHeap
	
	-- 2. 通过玩家的总牌数据随机抽取12张卡牌作为牌库
	local cardLibPlayerOne = comm.chooseCardFromStore(cardTotalPlayerOne, 20)
	local cardLibPlayerTwo = comm.chooseCardFromStore(cardTotalPlayerTwo, 20)
	
-- 	local function pt(key, value)
-- 		print(key, value:getAddress(), value)
-- 	end
	
	-- 3. 从牌库中选择一局游戏中的需要的牌组
	--     可以是3组，每组3张，或者是1组，一组3张或者6张
	local cardBattleGroupPlayerOne = comm.chooseActionCardGroupFromStore(cardLibPlayerOne, 1, 3)
	local cardBattleGroupPlayerTwo = comm.chooseActionCardGroupFromStore(cardLibPlayerTwo, 2, 3)
	
	table.foreach(cardBattleGroupPlayerOne, print)
	table.foreach(cardBattleGroupPlayerTwo, print)
	
	-- 4. 根据当前的配置决定进行几次对战
	local battleResult = doBattle(cardBattleGroupPlayerOne, cardBattleGroupPlayerTwo)
	
	-- 5. 分析多场战斗，得出胜利的玩家ID
	local winnerID = playerTwo.userID
	if battleResult.bFirstWin then
		winnerID = playerOne.userID
	end
	
	-- 6. 对多次战役打包返回
	local retData = {
		-- 战役结果
		battleResult = {
			-- 胜利者ID
			winnerID = 1000
		},
		-- 战斗数据，数组
		battleData = {
			battleResult
		}
	}
	
	return retData
end

HandleBattle({userID = 111}, {userID = 222});

local abilityLst =
{
	{id = 1, keyWord = '背水一战', description = '对方盟军总数比已方盟军多时，每多一个，此盟军攻击+1。'},
	{id = 2, keyWord = '势如破竹', description = '我方盟军总数比对方盟军多时，此盟军速度+100，攻击力+1。'},
	{id = 3, keyWord = '远程瞄准', description = '此盟军获得速度+300，攻击力+1。一次效果。'},
	{id = 4, keyWord = '精力充沛', description = '此盟军获得攻击力+3，速度+100。一次效果。'},
	{id = 5, keyWord = '冲锋陷阵', description = '目标友方盟军获得攻击力+2速度+200。一次效果'},
	{id = 6, keyWord = '坚守阵地', description = '目标友方盟军获得反击，生命力+2。一次效果，优先施放在没有反击的目标上'},
	{id = 7, keyWord = '种族加持', description = '多个特定种族目标获得攻击力+2.持续效果。持续直到失去特定种族加持异能'},
	{id = 8, keyWord = '元素加持', description = '多个特定属性攻击的目标获得攻击+2.持续效果。持续直到失去特定属性加持异能'},
	{id = 9, keyWord = '变羊术', description = '目标盟军不能攻击。失去嘲讽。受到伤害时解除变羊术效果'},
	{id = 10, keyWord = '迟缓术', description = '目标盟军速度-100，失去闪避。'},
	{id = 11, keyWord = '锁定目标', description = '目标盟军受到的伤害+1，失去隐匿。'},
	{id = 12, keyWord = '虚弱诅咒', description = '目标盟军攻击力-1。失去反击。'},
	{id = 13, keyWord = '攻击光环', description = '所有友方盟军攻击力+1。持续效果直到失去所有攻击光环异能'},
	{id = 14, keyWord = '速度光环', description = '所有友方盟军速度+100。持续效果直到失去所有速度光环异能'},
	{id = 15, keyWord = '体力光环', description = '所有友方盟军生命力+1，持续效果直到失去所有体力光环异能'},
	{id = 16, keyWord = '神圣护盾', description = '所有友方盟军下一次将要受到伤害时，减免一点伤害。一次效果'},
	{id = 17, keyWord = '战术布置', description = '对方所有盟军失去隐匿、嘲讽。持续效果直到失去所有战术布置异能'},
	{id = 18, keyWord = '突然袭击', description = '对方所有盟军失去反击、闪避。持续效果直到失去所有突然袭击异能'},
	{id = 19, keyWord = '泥沼术', description = '对方所有盟军速度-100。一次效果'},
	{id = 20, keyWord = '疲劳诅咒', description = '对方所有盟军攻击力-1。一次效果'},
	{id = 21, keyWord = '召唤术', description = '对方盟军总数比己方盟军多时，每多一个，就召唤出一个1攻1血100速的精灵。一次效果'},
	{id = 22, keyWord = '分身术', description = '对方盟军总数比己方盟军多时，以自己为目标，复制一个自己。一次效果'},
	{id = 23, keyWord = '召唤傀儡', description = '进场时，召唤1个0攻3血0速带嘲讽的木偶傀儡。'},
	{id = 24, keyWord = '召唤动物', description = '进场时，召唤一个1攻1血500速带隐匿的猫。'},
	{id = 25, keyWord = '血怒', description = '行动开始时，除非体力不足2点，否则扣除一点体力。增加一点攻击。'},
	{id = 26, keyWord = '成长', description = '行动开始时，攻击力+1，体力+1，速度+100。'},
	{id = 27, keyWord = '止血', description = '行动开始时，除非体力上限不足2点，否则扣除1点体力上限，回复1点体力。'},
	{id = 28, keyWord = '净化', description = '行动开始时，驱散自身所有负面效果。'},
	{id = 29, keyWord = '嫁祸', description = '目标盟军具有嘲讽。优先施放在没有嘲讽的目标上'},
	{id = 30, keyWord = '掩护', description = '目标盟军具有隐匿。优先施放在没有隐匿的目标上'},
	{id = 31, keyWord = '邪能转换', description = '目标盟军当前体力和攻击力互换。'},
	{id = 32, keyWord = '潜能转移', description = '将自己的攻击力加持在目标友方盟军身上。结束回合。'},
	{id = 33, keyWord = '吸取生命', description = '目标盟军扣除2点生命，此盟军回复1点生命'},
	{id = 34, keyWord = '毒镖', description = '目标盟军受到2点伤害，并获得状态。中毒'},
	{id = 35, keyWord = '魅惑术', description = '若对方不止一个目标，目标对方盟军对他的盟友造成攻击力的伤害，结束回合，否则正常攻击。'},
	{id = 36, keyWord = '能量吸取', description = '目标盟军攻击力-1，此盟军攻击力+1.'},
	{id = 37, keyWord = '神圣净化', description = '驱散所有友方盟军的负面效果。'},
	{id = 38, keyWord = '暴怒', description = '行动开始时，若此盟军是我方唯一盟军，则攻击力增加5'},
	{id = 39, keyWord = '精力旺盛', description = '行动开始时，若此盟军没有受伤，则增加2点攻击力。'},
	{id = 40, keyWord = '程式化', description = '第一回合增加速度100.第二回合增加生命力2，第三回合增加攻击力3'},
	{id = 41, keyWord = '护盾', description = '行动开始时，指定友方盟军，免疫下一次攻击伤害。只可发动一次。'},
	{id = 42, keyWord = '隐匿', description = '若有另一个非隐匿的友方盟军存在，则对方盟军不能指定此盟军为攻击目标'},
	{id = 43, keyWord = '双重攻击', description = '可以指定至多两个合法的目标进行攻击'},
	{id = 44, keyWord = '溅射伤害', description = '对一个目标对方盟军造成伤害后，对其他所有对方盟军造成1点伤害'},
	{id = 45, keyWord = '嘲讽', description = '若有带嘲讽的盟军存在。对方必须优先攻击带嘲讽的盟军'},
	{id = 46, keyWord = '范围攻击', description = '攻击对方所有盟军。无需指定。'},
	{id = 47, keyWord = '舍命攻击', description = '若体力不低于2点。可以扣除1点体力。使此次攻击伤害+2。'},
	{id = 48, keyWord = '忍耐', description = '受到伤害时，减免1点伤害。但至少受到1点伤害。'},
	{id = 49, keyWord = '钢筋铁骨', description = '受到伤害时，减免1点以上的所有伤害。'},
	{id = 50, keyWord = '闪避', description = '躲过一次伤害后，移除闪避异能'},
	{id = 51, keyWord = '反击', description = '受到攻击伤害后，反击目标一次。'},
	{id = 52, keyWord = '复仇', description = '受到伤害时，你给伤害来源添加一个标记。你对拥有你添加过标记的目标造成的伤害+1'},
	{id = 53, keyWord = '暴怒', description = '受到伤害时，你给自己增加1点攻击力'},
	{id = 54, keyWord = '挑衅', description = '对目标盟军造成伤害后。给目标盟军一个标记。目标盟军下一次攻击时，必须选择此盟军。优先于嘲讽'},
	{id = 55, keyWord = '冰冻', description = '收到伤害的盟军获得状态：异能：冰冻状态，目标速度-200.'},
	{id = 56, keyWord = '双刃剑', description = '对目标造成伤害后。自己扣除1点生命。优先结算目标生死。可能导致自己死亡。'},
	{id = 57, keyWord = '施毒', description = '受到伤害的盟军获得状态：异能：中毒状态，行动开始时，生命力-1。'},
	{id = 58, keyWord = '亡者转生', description = '死亡后获得一个转生标记，在下一局对战中复活。变成一个2攻2血200速度的亡灵。'},
	{id = 59, keyWord = '化石', description = '受到伤害时，以移除一个化石指示物替代。若移除了3个化石指示物。则生成一个3攻3血300速度的化石兽'},
	{id = 60, keyWord = '疲惫', description = '此盟军速度-200，一次效果。'},
	{id = 61, keyWord = '复仇之魂', description = '此盟军死亡后变成一个2攻2血200速度的复仇之魂'},
	{id = 62, keyWord = '狂怒', description = '目标友方盟军死亡时，你增加1点攻击100速度。'},
	{id = 63, keyWord = '自爆', description = '死亡时，若你不是你方最后的盟军。则对敌方全体造成1点伤害'},
	{id = 64, keyWord = '奉献', description = '死亡时，若你不是你方最后的盟军。则给所有友方盟军治疗1点伤害'},
	{id = 65, keyWord = '灵魂灌注', description = '死亡时，给目标友方盟军增加1点攻击力100点速度。'},
	{id = 66, keyWord = '反叛', description = '其他友方盟军都死亡后，此盟军变成一个2攻2血200速度的叛军，加入对方下一局。'},
	{id = 67, keyWord = '奴役亡灵', description = '对方盟军死亡后。召唤一个1攻1血100速度的亡灵'},
	{id = 68, keyWord = '圣灵', description = '友方盟军死亡后。召唤一个1攻1血100速度的幽魂'},
	{id = 69, keyWord = '分裂', description = '死亡时变成2个1攻1血100速度的史莱姆'},
	{id = 70, keyWord = '无情碾压', description = '全员少血1（机械人）'},
	{id = 71, keyWord = '借尸还魂', description = '重生（亡灵）'},
	{id = 72, keyWord = '借刀杀人', description = '只能控制人类盟军，若无人类则无效'},
	{id = 73, keyWord = '趁火打劫', description = '对手上盟军攻击+2'},
	{id = 74, keyWord = '暗度陈仓', description = '查看对方手牌'},
	{id = 75, keyWord = '釜底抽薪', description = '消灭目标受伤盟军'},
	{id = 76, keyWord = '电磁脉冲', description = '对所有机械人造成降速百分百'},
	{id = 77, keyWord = '空气腐蚀', description = '对所有地方造成2点伤害（元素）'},
	{id = 78, keyWord = '死亡火焰', description = '死亡后生成1/1的小火球（元素）'},
	{id = 79, keyWord = '凤凰涅槃', description = '重生一次'},
	{id = 80, keyWord = '反客为主', description = '全体队友加速300'},
	{id = 81, keyWord = '缓兵之计', description = '指定对方目标降速百分百'},
	{id = 82, keyWord = '藤之搅扰', description = '使敌方目标本回合无法攻击（妖魔）'},
	{id = 83, keyWord = '金属保护', description = '指定目标盟军+3血（机械人）'},
	{id = 84, keyWord = '氧气泡泡', description = '友方全员+1血'},
	{id = 85, keyWord = '迷幻杂技', description = '复制敌方的一个进场效果并使其失去效果，若敌方所有效果都已发动，则无效'},
-- 		86	进场	召唤鹊群	织女						敌方全员少1血
-- 		87	进场	神牛相助	牛郎	两牌同时上场，全员加1血					指定目标具有+2攻
	{id = 88, keyWord = '永恒五指山', description = '使敌方未发动的效果全部失效'},
	{id = 89, keyWord = '天外飞仙', description = '操控敌方目标盟军'},
	{id = 90, keyWord = '善良的精灵', description = '0攻，进场无法被攻击，回合结束给指定盟军奶满后自动离场'},
	{id = 91, keyWord = '绷带缠绕 ', description = '使目标盟军降速300（木乃伊）'},
	{id = 92, keyWord = '地狱小僧', description = '查看对手手牌'},
	{id = 93, keyWord = '友善的河童', description = '0攻，进场无法被攻击，回合结束给指定盟军奶满后自动离场'},
	{id = 94, keyWord = '黑夜锦衣卫', description = '一回合无法被攻击'},
	{id = 95, keyWord = '昆仑雪女', description = '冰冻，敌方全员降速500'},
	{id = 96, keyWord = '咆哮威慑', description = '对人类造成百分百降速（东北虎）'},
	{id = 97, keyWord = '恶犬之血', description = '对亡灵造成百分百降速（黑狗）'},
	{id = 98, keyWord = '狼牙之殇', description = '被攻击时会反击'},
	{id = 99, keyWord = '暴怒瞎熊', description = '只能攻击它'},
	{id = 100, keyWord = '无敌铁拳', description = '制定目标加2攻（机械人）'},
	{id = 101, keyWord = '空间探测一号', description = '看对方手牌'},
	{id = 102, keyWord = '手雷投掷者', description = '被攻击是自爆消灭自己和对方盟军'},
	{id = 103, keyWord = '爱神之箭', description = '0攻 场上若有男女同时存在，则两张牌本回合沉默'},
	{id = 104, keyWord = '盘丝蛛女', description = '目标盟军降速百分百'},
	{id = 105, keyWord = '死亡陷阱', description = '消灭目标血量为4的盟军'},
}

require 'util'

print("受影响的行数:", util.ImportDataToDB('DB/WarDrum.s3db', 'ability', abilityLst))