--- 攻击属性模块
-- @class module
module("Attack", package.seeall)

local const_mt = {
	-- 不允许中途修改值
	__newindex = function(t, k, v) end
}

--- 攻击属性模块常量定义
-- @class table
-- @name CONSTANT
-- @field attackType 攻击类型
CONSTANT = {
	-- 攻击类型
	attackType = {
		-- 近战攻击
		meelee = 1,
		-- 远程攻击
		range = 2,
		-- 魔法攻击
		magic = 3
	}
}

setmetatable(CONSTANT, const_mt)