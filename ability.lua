--- 异能模块，从属于卡牌模块的一个属性
-- @class module
-- @author Jason Tou sosoayaen@gmail.com
-- @copyright Jason Tou
module("Ability", package.seeall)

-- 这里定义了这个模块对应的数据库中的表名称
DB_TABLE_NAME = "ability"

require "util"

require "config"

local CONSTANTS = Config.CONSTANTS

local const_mt = {
	-- 不允许中途修改值
	__newindex = function(t, k, v) end
}

-- 是否使用异能缓存标识（默认启用）
local bUseCache = true

-- 内部使用的异能数据缓存，默认为空，然后从数据库中获取数据后缓存在内存中
local AbilityCache = {}

-- 设置元表
setmetatable(CONSTANTS, const_mt)

--- 异能属性基类
-- @class table
-- @name AbilityClass
-- @field id <vt>int</vt> 异能的ID，唯一
-- @field keyWord <vt>string</vt> 异能关键字（暂时保留）
-- @field description <vt>string</vt> 当前异能的描述
-- @field action <vt>table</vt> 响应属性
-- @field property <vt>table</vt> 异能属性
-- @field targetList <vt>table</vt> 异能影响的目标列表
-- @see CONSTANTS
local AbilityClass = {
	-- 类属性
	className = "ABILITY",
	-- 异能的ID
	id = -1,

	-- 技能关键字
	keyWord = "null",

	-- 技能名称
	name = "",
	-- 技能描述
	description = "",

	-- 响应属性，运行时生成数据，提供变量的存储
	-- @runtime
	action = {
		-- ////////////
		-- 响应次数，首先从property.influenceResponseCount字段复制
		-- 等于0时表示不再响应
		counts = 0,
	},
	-- //////////////
	-- 异能属性
	-- @class table
	-- @field targetInfluenceRange 异能目标范围
--	property = {

		-- 异能种类
		typehood = CONSTANTS.ABILITY_TYPES.UNKNOW,
		-- 响应时机
		-- @see CONSTANTS.answerWindow
		answerWindow = CONSTANTS.ANSWER_WINDOW.WINDOW_INVALID,
		
		-- 响应类型，响应自己，响应他人，全响应
		answerType = CONSTANTS.ANSWER_TYPE_ME,

		-- 异能响应条件
		answerCondition =
		{
			{
				-- 异能用于判断条件是否成立的目标范围
				-- 表明此异能的目标是全体还是单体，还有己方和敌方
				-- @see CONSTANTS.targetInfluenceRange
				targetInfluenceRange = CONSTANTS.TAEGET_ANY, -- 默认单体

				-- 异能用于判断的条件
				-- 目前无非 『攻击力』、『速度』、『血量』
				influenceType = CONSTANTS.ABILITY_INFLUENCE_PROPERTY_TARGET.ATTACK,

				-- 异能影响的数值
				-- 表明此异能发动后，根据influenceType属性来结算效果值，值有正负之分，直接累加结算
				-- @example 1. influenceType == CONSTANTS.influencePropertyTarget.ATTACK
				--               2. influenceValue == 1
				--               3. action.answerWindow == CONSTANTS.answerWindow.WINDOW_ATTACK_BEFORE
				--               4. targetInfluenceRange == CONSTANTS.targetInfluenceRange.ALL_WE
				--               5. influenceResponseCount = 1
				--               7. liquidateRemoveAbility = true
				--               8. persistentHostUnit = -1 表示无需施法单位
				--               这表示在行动攻击前的窗口结算，在攻击前给己方所有单位增加1点攻击力BUFF，结算后取消
				influenceValue = 1,

				-- 条件标准，表示是大于、小于、等于
				judgeStandard = CONSTANTS.JUDGE_STANDARD.GT,
			},
		},

		-- 异能作用效果
		effect =
		{
			{
				-- 效果作用类型，目前仅有状态效果、属性效果
				-- 状态效果等同于增加一个异能，而属性则为在三围上有效果
				mode = CONSTANTS.EFFECT_TYPE_PROPERTY,

				targetInfluenceRange = CONSTANTS.TARGET_ME,

				influenceType = CONSTANTS.EFFECT_ATTACK,

				influenceValue = 1,
			}
		},

		-- 异能响应次数，-1表示无限响应
		influenceResponseCount = 1,

		-- 异能是否需要持续施法单位 -1 表示无需施法单位
		persistentHostUnit = -1,

		-- 是否发动后直接取消（在清算、结算阶段移除此技能）
		liquidateRemoveAbility = true,
--	},

	-- 异能起效对象列表，标记受该技能影响的单位（待定）
	-- @runtime
	targetList = {},
}

--- 对象创建
-- @class function
-- @param o 可传可不传
-- @return 返回一个AbilityClass的实例
-- @see CONSTANTS
function AbilityClass:new(o)
	o = o or {}

	-- 设置原数据拷贝
	util.SetMetaData(o, self)

	-- 设置元表
	setmetatable(o, self)

	-- 设置对应搜索路径为AbilityClass本身
	-- 使实例拥有对应的成员函数和成员变量
	self.__index = self

	-- 重写其输出格式
-- 	self.__tostring = function(t)
--
-- 	end

	-- 返回实例
	return o
end

-- 从数据库中获取对应ID的技能数据
local getAbilityTableFromDataBase = function(nID)
	local sqlTxt = string.format("select * from %s where id=%d", DB_TABLE_NAME, nID)
	local tbl, tpsTbl = util.GetDataFromDB("DB/WarDrum.s3db", sqlTxt)
	
	table.foreachi(tbl, function(_, rowData)
		table.foreach(tpsTbl, function(key, value)
			local bNumber = false
			value = string.lower(value)
			if string.find(value, 'int') then
				bNumber = true
			end
			if bNumber then
				rowData[key] = tonumber(rowData[key])
			end
		end)
	end)
	
	local retTbl = {}
	table.foreach(tbl[1], function(key, value)
		local subTblName, subKey = string.match(key, '([^_]+)_(%w+)')
		print(string.format('-- key %s, value %s, subTblName %s, subKey %s', key, value, tostring(subTblName), tostring(subKey)))
		
		if subKey then
			local subTbl = retTbl[subTblName]
			if not subTbl then
				subTbl = {}
			end
			
			-- 根据内容判断是否是数组
			if type(value) == 'string' then
				-- 循环得到每个值
				local cnt = 1
				for subValue in string.gmatch(value, "([^,]+)") do
					-- 得到子表，如果没有则创建
					local itemTbl = subTbl[cnt]
					if not itemTbl then
						itemTbl = {}
						table.insert(subTbl, itemTbl)
					end
					
					itemTbl[subKey] = subValue
					
					cnt = cnt + 1
				end
			else
				table.insert(subTbl, {[subKey] = value})
			end
			
			retTbl[subTblName] = subTbl
		else
			retTbl[key] = value
		end
	end)
	
	table.foreach(retTbl, print)
	return retTbl
end

--- 通过技能ID得到对应的技能实体</br>
-- 这个函数作为其他模块获得技能对象的入口
-- @class function
-- @param nID 技能的ID
-- @return <vt>Ability</vt> 得到技能对象
function GetAbilityObj(nID)
	local abilityObj = nil

	if nID and nID >= 0 then
		-- 先从缓存中获取，如果没有则从数据库中获取，并且把对应的对象加到缓存中
		abilityObj = AbilityCache[nID]

		if not abilityObj then

			abilityObj = getAbilityTableFromDataBase(nID)
			
			if bUseCache and abilityObj then
				-- 缓存数据
				AbilityCache[nID] = abilityObj
			end
		end
	end
	
	if not abilityObj then
		return nil
	end

	-- 根据元数据创建一个异能对象
	local ability = table.dup(abilityObj)	

	return AbilityClass:new(ability)
end

--- 清理异能缓存数据
-- @class function
function ClearCache()
	AbilityCache = {}
end

--- 设置是否启用缓存
-- @class function
-- @param bEnable <vt>bool</vt> 启用标识
function EnableCache(bEnable)
	bUseCache = bEnable
end
