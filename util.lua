--- 工具函数模块
-- 和业务逻辑完全没有关系，仅仅提供基本的功能和操作，如表的浅拷贝以及深拷贝。</br>
-- 在需要使用这些工具功能需要在文件头部require这模块。</br>
-- 有些功能是util模块内提供，有些则直接覆盖了原来的功能，如表的拷贝，直接在table中提供该功能
-- @class module
-- @author Jason Tou sosoayaen@gmail.com
-- @copyright Jason Tou
module("util", package.seeall)

-- 表格深层次拷贝，共享metatable
-- @class function
-- @param object 待拷贝的表
-- @return 新拷贝的表
local deepcopy = function (object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end  -- if
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end  -- for
        return setmetatable(new_table, getmetatable(object))
    end  -- function _copy
    return _copy(object)
end  -- function deepcopy

--- 表的浅拷贝
local dup = nil
dup = function(ori_tab)
    if (type(ori_tab) ~= "table") then
        return nil;
    end
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = dup(v);
        elseif (vtyp == "thread") then
            -- TODO: dup or just point to?
            new_tab[i] = v;
        elseif (vtyp == "userdata") then
            -- TODO: dup or just point to?
            new_tab[i] = v;
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end

_G.table.dup = dup
_G.table.deepcopy = deepcopy

--- 创建原始数据到基类的拷贝<br/>
-- <warn>注意：</warn>内部调用，外部不要直接调用，除非你清楚知道其功能
-- @param ot 目标表
-- @param o 原始数据表，即self对象
function SetMetaData(ot, o)
	table.foreach(ot, function(k, v)
		-- 暂时不拷贝函数
		local tps = type(v)
		
		if tps == 'table' then
			-- 拷贝表数据（只拷贝表内的数据）
			local t = table.dup(v)
			o[k] = t
		elseif tps ~= 'function' then
			-- 原样复制
			o[k] = v
		end
	end)
end

-- 加载 sqlite3 操作
require 'luasql.sqlite3'

local dbEnv = luasql.sqlite3()

assert(dbEnv)

--- 从数据库中查询数据，并返回对应的表结构<br/>
-- <warn>注意：</warn>此函数不直接调用，在其他模块中会操作对应的表来调用此功能，除非你清楚知道如何操作
-- @class function
-- @param dbName 数据库文件的路径
-- @param sqlTxt 对应的sql语句
-- @return <ul><li>table 如果有数据则返回对应的表，没有则返回nil</li><li>errmsg 当第一个返回值为nil时，可能会有错误信息</li></ul>
function GetDataFromDB(dbName, sqlTxt)
	local ret = nil
	
	-- 校验下环境是否OK
	if not dbEnv then
		return ret, 'dbEnv is nil, You should call function InitDBEnv() to initial Database environment first.'
	end
	
	local dbConn, err = dbEnv:connect(dbName)
	assert(dbConn, err)
	
	local cur, err = dbConn:execute(sqlTxt)
	assert(cur, err)
	
	local t = {}
	repeat
--		table.foreach(t, print)
		-- 返回的表格按照key-value模式存储，key为列名
		t = cur:fetch(t, 'a')
		
		if t then
			if not ret then
				ret = {}
			end
			table.insert(ret, table.dup(t))
		end
	until not t
	
	cur:close()
	
	-- 关闭连接，释放资源
	if dbConn then dbConn:close() end
	
	return ret
end

-- GetDataFromDB('DB/WarDrum.s3db', "select * from ability where id = 0")
-- GetDataFromDB('DB/WarDrum.s3db', "select sql from sqlite_master where type='table' and name='ability'")

--- 导数据入数据库
-- @class function
-- @param dbName 数据库路径
-- @param tableName 导入数据的表名
-- @param data 数据表
-- @param checkKey 用于校验表中是否有符合当前匹配数据的字段名
-- @param jumpIfExist <ul><li>true 表示当通过checkKey匹配到的同样的数据存在时，不更新，直接跳过</li><li>false 表示不跳过，根据checkKey的校验的值更新</li></ul>
-- @return 返回操作数据库受影响的行数
function ImportDataToDB(dbName, tableName, data, checkKey, jumpIfExist)
	local dbConn, err = dbEnv:connect(dbName)
	assert(dbConn, err)
	
	-- 得到赌赢表结构
	local result = GetDataFromDB(dbName, string.format(
		"select sql from sqlite_master where type='table' and name='%s'",
		tableName))
	-- 对应表结构的辅助表，记录了当前表结构内的字段名称
	local tableScheme = {}
	if result and type(result[1]) == 'table' then
		local sql = result[1].sql
		print(sql)
		for colName in string.gmatch(sql, '%[(.-)%]') do
			print('colName', colName)
			tableScheme[colName] = true
		end
	end
	
	-- 受影响的行数
	local nAffectLines = 0
	
	-- 循环待导入数据库的数据表
	table.foreachi(data, function(_, rowData)
		-- 处理得到字段名和字段值的集合
		local colNamesTbl = {}
		local colValuesTbl = {}
		-- 用于更新表用的辅助表
		local updateTbl = {}
		-- 处理行数据
		table.foreach(rowData, function(colName, colValue)
			if type(colValue) == 'string' then
				colValue = string.format("'%s'", colValue)
			end
			-- 消除非表内的列数据，以免插入或者更新失败
			if tableScheme[colName] then
				table.insert(colNamesTbl, colName)
				table.insert(colValuesTbl, colValue)
				table.insert(updateTbl, string.format("%s=%s", colName, colValue))
			end
		end)
		
		-- 默认是插入模式
		local bInsertMode = true
		local updateValue = nil;
		-- 先判断下对应ID的异能是否存在，如果存在则更新，否则直接插入
		-- 校验 checkKey 是否在表中是有效字段（是否存在该列）
		if checkKey and type(checkKey) == 'string' and tableScheme[checkKey] then
			local colValue = rowData[checkKey]
			if type(colValue) == 'string' then
				colValue = string.format("'%s'", colValue)
			end
			
			local sqlTxt = string.format("select %s from %s where %s=%s",
					checkKey, tableName, checkKey, colValue)
					
			local cur, err = dbConn:execute(sqlTxt)
				
			assert(cur, err)
			
			-- 如果有数据则更新数据否则插入
			if type(cur) ~= 'number' then
				if cur:fetch() then	-- 看下是否有数据
					bInsertMode = false
					updateValue = colValue
				end
				-- 关闭游标
				cur:close()
			end
		end
		
		-- 定义最终的sql语句
		local sqlTxt = nil
		
		-- 先判断是否是插入模式
		if bInsertMode then
			-- 插入模式表示表内不存在相同数据
			sqlTxt = string.format("insert into %s (%s) values (%s)",
					tableName,
					table.concat(colNamesTbl, ', '), 
					table.concat(colValuesTbl, ', '))
			
			print('sqlTxt', sqlTxt)
			
			-- 执行sql语句
			local cur, err = dbConn:execute(sqlTxt)
				
			assert(cur == 1, err)
			
			nAffectLines = nAffectLines + 1
			
		elseif not jumpIfExist then
			-- 这里是更新模式，设置了非跳过的标志
			sqlTxt = string.format("update %s set %s where %s=%s",
					tableName,
					table.concat(updateTbl, ', '),
					checkKey,
					updateValue)
			
			print('sqlTxt', sqlTxt)
			-- 执行sql语句
			local cur, err = dbConn:execute(sqlTxt)
			assert(cur == 1, err)
			
			nAffectLines = nAffectLines + 1
		end
		
	end)
	
	-- 关闭连接释放资源
	if dbConn then dbConn:close() end
	
	return nAffectLines
end

--- 释放数据库环境资源
-- @class function
function ReleaseDBEnv()
	if dbEnv then
		dbEnv:close()
		dbEnv = nil
	end
end

--- 初始化数据库环境资源
function InitDBEnv()
	if not dbEnv then
		dbEnv = luasql.sqlite3()
	end
end

-- 初始化随机种子
math.randomseed(os.time());

--- 得到随机数，最大和最小值设定
-- @class function
-- @param maxnum 不考虑基值的最大值
-- @param baseNumber 基值，如不传，则默认为0
-- @return 返回随机值
genRand = function(maxnum, baseNumber)
	baseNumber = baseNumber or 0;
	return math.floor(math.random()*100000 % maxnum + baseNumber);
end

