-- Copyright (C) github.com/happyDom
--[[
👉首先，把本脚本放在你的方案下的lua文件夹内

🚩：如果你的脚本名称为 input_statistics ₂₀₂₅1208・A.lua，你需要把文件名改为 input_statistics.lua后再用

🚩：如果你第一次使用不早于 ₂₀₂₅1208・B 版本的本脚本，请把你原来lua文件夹下的 input_stats.lua删除

👉其次，如果你的方案可以输入 /fj 以输入特殊符号，可以忽略这条。否则你需要调整你的方案的 alphabet 设定（在补丁中调整），加入符号 /
  # 不需要与下面这条安全一样，但需要确认其中有符号 /
  speller/alphabet: "abcdefghijklmnopqrstuvwxyz;'/"
  # 如果你的方案中设置了 initials，请确认其中也包含符号 /，例如：
  speller/initials: ';abcdefghijklmnopqrstuvwxyz/'

👉再其次，在你的方案补丁文件中，在translators节点加入对 input_statistics 的引用，如下👇：
  engine/translators/+:				#定制translator如下
	- lua_translator@*input_statistics				# 统计输入速度等信息

👉再其次，为了让统计数据在输入 //01 时有响应，你需要在方案补丁文件中加入以下👇补丁（让方案捕捉/xx [xx为数字] 这类输入):
  recognizer/patterns/punct: '^/(/[0-9]+|[A-Za-z]+)$'

👉最后，做为选项，如果你希望在你的统计消息后追加一个随机的名言，你可以在本脚本所在的目录下创建一个 quote.txt 文档，
在文档内按行写入你想要展示的名句，本脚本会随机从其中的名句中挑选一个追加在统计消息后。

👉最后，重新部署你的rime/同文

🚩使用提示（例如/01 /rtj 两种方式均可）：
//1 //11 /rtj /rtjj	查看日统计
//2 //22 /ztj /ztjj	查看周统计
//3 //33 /ytj /ytjj	查看月统计
//4 //44 /ntj /ntjj	查看年统计
//5 /sztj	查看生字/词
//07 /qcjs	清除极速数据
//08 /qcsz	清除生字/词
//09 /qctj	清除所有统计数据
//60 /pf	查看统计进度条皮肤（消息会显示切换皮肤的命令用法）
]]

-- 卡壳时间门限(单位：s)，当上屏的字/词距离前一次上屏时间大于该门限时，该字/词被记录为生字/词组数据
local boggleThd_s = 3
-- 自动顶屏码数：四码顶字上屏，设置4；3码顶字上屏，设置为3；如果你不用顶字上屏功能，此处设置为0
-- 如果统计文件己经存在，则此处的设置不再生效，如果你要重新设置该值，请先删除对应方案的统计文件，重新部署rime，操作步骤如下：
-- 第一步，把统计文件删掉
-- 第二步，设置 codeLenOfAutoCommit={5,6}  -- 顶屏码数(5和6都视为自动顶屏)，如果不顶屏，这里设置为{0},可以增加或者减少
-- 第三步，重新部署rime
-- 第四步，切换输入方案到对应的方案，随便输入几个字，确保统计文件创建成功
-- 对于其它方案，重复以上步骤（只用设置需要顶屏的方案即可，设置完成后，重新设置codeLenOfAutoCommit=0，以便适用于其它不需要顶屏的方案）
local codeLenOfAutoCommit = { 4 }
-- 如果你想在平均码长后加以说明，请在这里自定义你的说明内容，可以使用 \n 换行
local avgCodeLenDesc = ''
-- 脚本版本常量
local SCRIPT_VERSION = '₂₀₂₆0404・A'
-- 如果脚本不能正确识别到你的设备类型，请在这里手动指定您的设备类型，仅符号📱(手机)和💻(电脑)有效
local deviceType = '' -- 📱 or 💻
-- 定义一个皮肤集合，以供选用，您可以往这里加入新自定义的皮肤〔idea from 落羽行歌〕
local skinList = {
	{ field = '▉', empty = '▁' }, -- 皮肤1：默认
	{ field = '━', empty = '┄' }, -- 皮肤2
	{ field = '●', empty = '○' }, -- 皮肤3
	{ field = '■', empty = '□' }, -- 皮肤4
	{ field = '▲', empty = '△' }, -- 皮肤5
	{ field = '◆', empty = '◇' }, -- 皮肤6
	{ field = '▶', empty = '▷' }, -- 皮肤7
	{ field = '◀', empty = '◁' }, -- 皮肤8
	{ field = '▼', empty = '▽' }, -- 皮肤9
	{ field = '▶', empty = '▁' }, -- 皮肤10
	{ field = '▉', empty = '┄' }, -- 皮肤11
	{ field = '━', empty = '▁' }, -- 皮肤12
	{ field = '●', empty = '▁' }, -- 皮肤13
	{ field = '■', empty = '┄' }, -- 皮肤14
	{ field = '▲', empty = '▁' }, -- 皮肤15
	{ field = '◆', empty = '┄' }, -- 皮肤16
	{ field = '▉', empty = '○' }, -- 皮肤17
	{ field = '━', empty = '□' }, -- 皮肤18
	{ field = '●', empty = '△' }, -- 皮肤19
	{ field = '■', empty = '◇' }, -- 皮肤20
	{ field = '★', empty = '☆' }, -- 皮肤21
	{ field = '✭', empty = '✩' }, -- 皮肤22
	{ field = '▓', empty = '░' }, -- 皮肤23
}

-- 支持的统计指令集合
local reportCommands = {
  ["//1"] = true,
  ["//11"] = true,
  ["//2"] = true,
  ["//22"] = true,
  ["//3"] = true,
  ["//33"] = true,
  ["//4"] = true,
  ["//44"] = true,
  ["/rtj"] = true,
  ["/rtjj"] = true,
  ["/ztj"] = true,
  ["/ztjj"] = true,
  ["/ytj"] = true,
  ["/ytjj"] = true,
  ["/ntj"] = true,
  ["/ntjj"] = true,
}

-- 分配一个变量，用于字符串拼接
local strTable = {}
-- 一个用于存放名人名言的表
local quotes = {}
local quoteCnt = 0
-- 分隔线
local splitorLen = 14
local splitorChar = '─'
-- local splitor = string.rep("─", splitorLen)
local splitor = string.rep(splitorChar, splitorLen)
-- 记录前一次的code字符
local lastCode = ''
local keyTouchCnt = 0 --记录编码键按下次数
-- 标记log版本
local verOfStatsFormat = 4
-- 报告风格， 0: 短款（默认），1: 长款
local reportStyle = 0

-- 下面的信息是自动获取的
local software_name = rime_api.get_distribution_code_name()
local software_version = rime_api.get_distribution_version()
local schema_name

-- 一个数据结构体，用于处理平均速度统计临时数据
local avgSpdInfo = {
	startTime = 0,               -- 如果正在记录，这里是开始的时间
	clickTime = 0,               -- 上次按键时间，通过记录按键间隔，判断是否输入超时
	commitTime = 0,              -- 这是最近一次上屏的时间
	gapThd = 5,                  -- 如果此次按键距离前一次按键的时间大于此门限值，则重新开始计时
	count = 0,                   -- 记录期间，上屏的字数
	codeLen = 0,                 -- 记录期间，输入的编码数量
}

-- 初始化统计表（若未加载）
local input_stats = input_stats or {
	daily = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
	weekly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
	monthly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
	yearly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
	logVer = -1,
	daily_max = 0,
	newWords = { startTime = 0, words = {} },
	deviceType = deviceType,
	progressBarSkinIdx_word = 21, -- 指定字词统计条的皮肤索引（从1开始）
	progressBarSkinIdx_code = 21 -- 指定码长统计条的皮肤索引（从1开始）
}

local progressBarField_word = skinList[input_stats.progressBarSkinIdx_word].field
local progressBarEmpty_word = skinList[input_stats.progressBarSkinIdx_word].empty
local progressBarField_code = skinList[input_stats.progressBarSkinIdx_code].field
local progressBarEmpty_code = skinList[input_stats.progressBarSkinIdx_code].empty

function trim(str)
	if type(str) ~= "string" then
		return "" -- 非字符串返回空字符串，也可返回原值/报错，按需调整
	end
	return str:match("^%s*(.-)%s*$") or ""
end

local function currentDir()
	local info = debug.getinfo(2) --debug.getinfo(2), 2: 返回调用 currentDir 的函数的信息

	--解析info.source所在的路径
	local path = info.source
	path = string.sub(path, 2, -1)   -- 去掉开头的"@"
	path = string.gsub(path, '\\', '/') -- 路径格式由 c:\\Users\\san.zhang\\ 转换为 c:/Users/san.zhang/
	path = string.match(path, "^(.*)/") -- 捕获最后一个 "/" 之前的部分 就是我们最终要的目录部分

	return path
end

-- 定义平台检测函数
local function detect_platform()
	-- 1. 尝试从 RIME API 获取
	if rime_api and rime_api.get_distribution_code_name then
		local dist = rime_api.get_distribution_code_name()
		if dist and type(dist) == "string" then
			local lower_dist = dist:lower()
			if lower_dist == "trime" then return "android" end
			if lower_dist == "hamster" or lower_dist == "hamster3" then return "ios" end
			if lower_dist == "squirrel" then return "mac" end
			if lower_dist == "weasel" then return "windows" end
			if lower_dist == "ibus-rime" or lower_dist == "fcitx-rime" then
				-- 需要进一步区分
			end
		end
	end

	-- 2. 使用 LuaJIT 的 jit.os
	if jit and jit.os then
		local jit_os = jit.os:lower()
		if jit_os == "linux" then return "linux" end
		if jit_os == "osx" or jit_os == "macos" then return "mac" end
		if jit_os == "windows" then return "windows" end
	end

	-- 3. 初始化
	local is_mac = false
	local is_windows = false

	-- 检查路径分隔符
	if package.config:sub(1, 1) == "\\" then
		is_windows = true
	end

	-- 检查环境变量
	if not is_windows then
		local home = os.getenv("HOME")
		if home and (home:find("/Users/") or home:find("/home/")) then
			-- 检查是否 macOS
			local ok, file = pcall(io.open, "/Applications", "r")
			if ok and file then
				file:close()
				is_mac = true
			end
		end
	end

	if is_windows then return "windows" end
	if is_mac then return "mac" end

	-- 4. 默认unknown
	return "unknown"
end

-- 判断给定的utf8.codepoint值是否为汉字
local function IsChineseCharacter(codepoint)
	return (codepoint >= 0x4e00 and codepoint <= 0x9fff) -- 基本区
		or (codepoint >= 0x3400 and codepoint <= 0x4dbf) -- 扩A
		or (codepoint >= 0x20000 and codepoint <= 0x2a6df) -- 扩B
		or (codepoint >= 0x2a700 and codepoint <= 0x2b73f) -- 扩C
		or (codepoint >= 0x2b740 and codepoint <= 0x2b81f) -- 扩D
		or (codepoint >= 0x2b820 and codepoint <= 0x2ceaf) -- 扩E
		or (codepoint >= 0x2ceb0 and codepoint <= 0x2ebef) -- 扩F
		or (codepoint >= 0x30000 and codepoint <= 0x3134f) -- 扩G
		or (codepoint >= 0x31350 and codepoint <= 0x323af) -- 扩H
		or (codepoint >= 0x2ebf0 and codepoint <= 0x2ee5f) -- 扩I
		or (codepoint >= 0x31c0 and codepoint <= 0x31ef) -- 笔画
		or (codepoint >= 0x2e80 and codepoint <= 0x2eff) -- 部首扩展
		or (codepoint >= 0x2f00 and codepoint <= 0x2fdf) -- 康熙部首
		or (codepoint >= 0xf900 and codepoint <= 0xfadf) -- 兼容
		or (codepoint >= 0x2f800 and codepoint <= 0x2fa1f) -- 兼补
		or (codepoint >= 0x2ff0 and codepoint <= 0x2fff) -- 汉字结构
		or (codepoint >= 0x3100 and codepoint <= 0x312f) -- 注音
		or (codepoint >= 0x31a0 and codepoint <= 0x31bf) -- 注音扩展
end

-- 判断给定的字符串是否全部是汉字
local function isAllChineseCharacter(text)
	for _, c in utf8.codes(text) do
		if not IsChineseCharacter(c) then
			return false
		end
	end
	return true
end

local function getDeviceType()
	if ({ ['📱'] = true, ['💻'] = true })[deviceType] then
		return deviceType
	else
		local platform = detect_platform()
		if platform == "android" then
			return '📱'
		elseif platform == "ios" then
			return '📱'
		elseif platform == "mac" then
			return '💻'
		elseif platform == "windows" then
			return '💻'
		elseif platform == "linux" then
			return '💻'
		else
			if ({ ['📱'] = true, ['💻'] = true })[input_stats.deviceType] then
				return input_stats.deviceType
			else
				return ''
			end
		end
	end
end

-- 将指定的文档处理成行数组
local function files_to_lines(...)
	local tab = setmetatable({}, { __index = table })
	local index = 1
	for i, filename in next, { ... } do
		local fn = io.open(filename)
		if fn then
			for line in fn:lines() do
				if not line or #line > 0 then
					tab:insert(line)
				end
			end
			fn:close()
		end
	end
	return tab
end

-- 定义一个求和函数，用于求取一个table内的数字的和
local function tableSum(tb)
	local sum = 0
	for i = 1, #tb do
		sum = sum + tb[i]
	end
	return sum
end

-- 定义一个求和函数，用于求取一个table内尾部指定数量项的和
local function tableTailSum(tb, n)
	if type(tb) ~= "table" then return 0 end
	local len = #tb
	local n = tonumber(n) or 0 -- 非数字转 0
	if n < 1 or len < 1 then return 0 end

	local sum = 0
	local takeCount = math.min(n, len)
	for i = 1, takeCount do
		sum = sum + (tb[len - takeCount + i] or 0)
	end
	return sum
end

-- 根据传入的百分比，生成一个进度条
local function progressBar_code(p)
	if p >= 95.0 then return string.rep(progressBarField_code, 10) end
	if p >= 85.0 then return string.rep(progressBarField_code, 9) .. string.rep(progressBarEmpty_code, 1) end
	if p >= 75.0 then return string.rep(progressBarField_code, 8) .. string.rep(progressBarEmpty_code, 2) end
	if p >= 65.0 then return string.rep(progressBarField_code, 7) .. string.rep(progressBarEmpty_code, 3) end
	if p >= 55.0 then return string.rep(progressBarField_code, 6) .. string.rep(progressBarEmpty_code, 4) end
	if p >= 45.0 then return string.rep(progressBarField_code, 5) .. string.rep(progressBarEmpty_code, 5) end
	if p >= 35.0 then return string.rep(progressBarField_code, 4) .. string.rep(progressBarEmpty_code, 6) end
	if p >= 25.0 then return string.rep(progressBarField_code, 3) .. string.rep(progressBarEmpty_code, 7) end
	if p >= 15.0 then return string.rep(progressBarField_code, 2) .. string.rep(progressBarEmpty_code, 8) end
	if p >= 5.0 then return string.rep(progressBarField_code, 1) .. string.rep(progressBarEmpty_code, 9) end
	return string.rep(progressBarEmpty_code, 10)
end

local function progressBar_word(p)
	if p >= 95.0 then return string.rep(progressBarField_word, 10) end
	if p >= 85.0 then return string.rep(progressBarField_word, 9) .. string.rep(progressBarEmpty_word, 1) end
	if p >= 75.0 then return string.rep(progressBarField_word, 8) .. string.rep(progressBarEmpty_word, 2) end
	if p >= 65.0 then return string.rep(progressBarField_word, 7) .. string.rep(progressBarEmpty_word, 3) end
	if p >= 55.0 then return string.rep(progressBarField_word, 6) .. string.rep(progressBarEmpty_word, 4) end
	if p >= 45.0 then return string.rep(progressBarField_word, 5) .. string.rep(progressBarEmpty_word, 5) end
	if p >= 35.0 then return string.rep(progressBarField_word, 4) .. string.rep(progressBarEmpty_word, 6) end
	if p >= 25.0 then return string.rep(progressBarField_word, 3) .. string.rep(progressBarEmpty_word, 7) end
	if p >= 15.0 then return string.rep(progressBarField_word, 2) .. string.rep(progressBarEmpty_word, 8) end
	if p >= 5.0 then return string.rep(progressBarField_word, 1) .. string.rep(progressBarEmpty_word, 9) end
	return string.rep(progressBarEmpty_word, 10)
end

-- 时间戳工具函数
local function get_timezone() -- 计算时区偏移
	local local_t = os.date("*t")
	local local_ts = os.time(local_t)
	local utc_ts = os.time(os.date("!*t", local_ts))
	local offset_min = (local_ts - utc_ts) / 60
	local offset_hour = math.floor(offset_min / 60)
	local offset_minute = math.abs(offset_min % 60)
	return string.format("UTC%+03d:%02d", offset_hour, offset_minute)
end
local function start_of_day(t)
	return os.time { year = t.year, month = t.month, day = t.day, hour = 0 }
end
local function start_of_week(t)
	local d = t.wday == 1 and 6 or (t.wday - 2)
	return os.time { year = t.year, month = t.month, day = t.day - d, hour = 0 }
end
local function start_of_month(t)
	return os.time { year = t.year, month = t.month, day = 1, hour = 0 }
end
local function start_of_year(t)
	return os.time { year = t.year, month = 1, day = 1, hour = 0 }
end

-- 更新统计数据
local function update_stats(input_length, codeLen, codeLenWithoutSpace, avgAvailable)
	local now = os.date("*t")
	local now_ts = os.time(now)

	local day_ts = start_of_day(now)
	local week_ts = start_of_week(now)
	local month_ts = start_of_month(now)
	local year_ts = start_of_year(now)

	if input_stats.daily.ts ~= day_ts then
		input_stats.daily = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = day_ts, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 }
		input_stats.daily_max = 0
	end
	if input_stats.weekly.ts ~= week_ts then
		input_stats.weekly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts =
		week_ts, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 }
	end
	if input_stats.monthly.ts ~= month_ts then
		input_stats.monthly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts =
		month_ts, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 }
	end
	if input_stats.yearly.ts ~= year_ts then
		input_stats.yearly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts =
		year_ts, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 }
	end

	-- 更新平均分速统计数据
	if 1 == avgAvailable then
		-- 更新时间数据
		local delt = avgSpdInfo.commitTime - avgSpdInfo.startTime
		table.insert(input_stats.daily.avgGaps, delt)
		table.insert(input_stats.weekly.avgGaps, delt)
		table.insert(input_stats.monthly.avgGaps, delt)
		table.insert(input_stats.yearly.avgGaps, delt)

		-- 更新编码长度数据
		table.insert(input_stats.daily.avgCodeLen, avgSpdInfo.codeLen)
		table.insert(input_stats.weekly.avgCodeLen, avgSpdInfo.codeLen)
		table.insert(input_stats.monthly.avgCodeLen, avgSpdInfo.codeLen)
		table.insert(input_stats.yearly.avgCodeLen, avgSpdInfo.codeLen)

		-- 更新上屏字数
		table.insert(input_stats.daily.avgCnts, avgSpdInfo.count)
		table.insert(input_stats.weekly.avgCnts, avgSpdInfo.count)
		table.insert(input_stats.monthly.avgCnts, avgSpdInfo.count)
		table.insert(input_stats.yearly.avgCnts, avgSpdInfo.count)

		-- 最后累计10s的提交数据，计算平均速度做为最大分速的参考
		local latestGapsSum = 0
		local latestCntsSum = 0
		local latestCodeLenSum = 0
		local latestSpd = 0
		local latestKeyTouchSpd = 0
		local latestAvgCodeLen = 0
		local len = #input_stats.yearly.avgGaps
		for i = 0, len - 1 do
			latestGapsSum = latestGapsSum + input_stats.yearly.avgGaps[len - i]
			latestCntsSum = latestCntsSum + input_stats.yearly.avgCnts[len - i]
			latestCodeLenSum = latestCodeLenSum + input_stats.yearly.avgCodeLen[len - i]
			if latestGapsSum >= 10 then -- 最后10s的平均速度做为瞬时速度
				break
			end
		end
		if latestGapsSum >= 10 then -- 如果数据的时长小于10s，则不计算最大速度，避免瞬时偏差过大
			latestSpd = latestCntsSum / latestGapsSum * 60
			latestKeyTouchSpd = latestCodeLenSum / latestGapsSum
			if latestCntsSum > 0 then
				latestAvgCodeLen = latestCodeLenSum / latestCntsSum
			end

			-- 更新最大分速值
			if latestSpd > input_stats.daily.fastest.spd then
				input_stats.daily.fastest.spd = latestSpd
				input_stats.daily.fastest.keyTouchSpd = latestKeyTouchSpd
				input_stats.daily.fastest.avgCodeLen = latestAvgCodeLen
			end
			if latestSpd > input_stats.weekly.fastest.spd then
				input_stats.weekly.fastest.spd = latestSpd
				input_stats.weekly.fastest.keyTouchSpd = latestKeyTouchSpd
				input_stats.weekly.fastest.avgCodeLen = latestAvgCodeLen
			end
			if latestSpd > input_stats.monthly.fastest.spd then
				input_stats.monthly.fastest.spd = latestSpd
				input_stats.monthly.fastest.keyTouchSpd = latestKeyTouchSpd
				input_stats.monthly.fastest.avgCodeLen = latestAvgCodeLen
			end
			if latestSpd > input_stats.yearly.fastest.spd then
				input_stats.yearly.fastest.spd = latestSpd
				input_stats.yearly.fastest.keyTouchSpd = latestKeyTouchSpd
				input_stats.yearly.fastest.avgCodeLen = latestAvgCodeLen
			end
		end

		avgSpdInfo.count = 0
		avgSpdInfo.codeLen = 0
	end

	-- 如果输入字/词长度小于1（即为空），则不做后续的处理
	if input_length < 1 then return end

	-- 更新总按键数
	input_stats.daily.keyTouchCnt = input_stats.daily.keyTouchCnt + keyTouchCnt
	input_stats.weekly.keyTouchCnt = input_stats.weekly.keyTouchCnt + keyTouchCnt
	input_stats.monthly.keyTouchCnt = input_stats.monthly.keyTouchCnt + keyTouchCnt
	input_stats.yearly.keyTouchCnt = input_stats.yearly.keyTouchCnt + keyTouchCnt
	keyTouchCnt = 0

	-- 更新不含空格的编码数量
	input_stats.daily.totalCodeLenWithoutSpace = input_stats.daily.totalCodeLenWithoutSpace + codeLenWithoutSpace
	input_stats.weekly.totalCodeLenWithoutSpace = input_stats.weekly.totalCodeLenWithoutSpace + codeLenWithoutSpace
	input_stats.monthly.totalCodeLenWithoutSpace = input_stats.monthly.totalCodeLenWithoutSpace + codeLenWithoutSpace
	input_stats.yearly.totalCodeLenWithoutSpace = input_stats.yearly.totalCodeLenWithoutSpace + codeLenWithoutSpace

	-- 更新记录
	local update = function(stat)
		stat.count = stat.count + 1
		stat.length = stat.length + input_length
	end
	update(input_stats.daily)
	update(input_stats.weekly)
	update(input_stats.monthly)
	update(input_stats.yearly)

	if input_length > input_stats.daily_max then
		input_stats.daily_max = input_length
	end

	-- 更新输入字/词组数据
	input_stats.daily.lengths[input_length] = (input_stats.daily.lengths[input_length] or 0) + 1
	input_stats.weekly.lengths[input_length] = (input_stats.weekly.lengths[input_length] or 0) + 1
	input_stats.monthly.lengths[input_length] = (input_stats.monthly.lengths[input_length] or 0) + 1
	input_stats.yearly.lengths[input_length] = (input_stats.yearly.lengths[input_length] or 0) + 1

	-- 更新输入码长数据
	input_stats.daily.codeLengths[codeLen] = (input_stats.daily.codeLengths[codeLen] or 0) + 1
	input_stats.weekly.codeLengths[codeLen] = (input_stats.weekly.codeLengths[codeLen] or 0) + 1
	input_stats.monthly.codeLengths[codeLen] = (input_stats.monthly.codeLengths[codeLen] or 0) + 1
	input_stats.yearly.codeLengths[codeLen] = (input_stats.yearly.codeLengths[codeLen] or 0) + 1
end

-- 表序列化工具
table.serialize = function(tbl)
	local lines = { "{" }
	for k, v in pairs(tbl) do
		local key = (type(k) == "string") and ("[\"" .. k .. "\"]") or ("[" .. k .. "]")
		local val
		if type(v) == "table" then
			val = table.serialize(v)
		elseif type(v) == "string" then
			val = '"' .. v .. '"'
		else
			val = tostring(v)
		end
		table.insert(lines, string.format("	%s = %s,", key, val))
	end
	table.insert(lines, "}")
	return table.concat(lines, "\n")
end

-- 保存至文件
local function save_stats(schema_id)
	local path = rime_api.get_user_data_dir() .. "/lua/input_stats_" .. schema_id .. ".lua"
	local file = io.open(path, "w")
	if not file then return end
	file:write("input_stats = " .. table.serialize(input_stats) .. "\n")
	file:close()
end

-- 将一段文字嵌入 splitor 中间
local function embedTextIntoSplitor(myText)
	local myTextNew = myText
	local tmpLen = utf8.len(myText)
	local halfLen = 0
	local halfLenFloor = 0

	if splitorLen > tmpLen + 1 then
		halfLen = 0.5 * (splitorLen - tmpLen)
		halfLenFloor = math.floor(halfLen)
		myTextNew = string.rep(splitorChar, halfLenFloor) ..
		myText .. string.rep(splitorChar, splitorLen - tmpLen - halfLenFloor)
	end

	return myTextNew
end

-- 格式化皮肤列表〔from 落羽行歌〕
local function formatSkinList()
	local skinListText = {}
	table.insert(skinListText, "※ 可用皮肤列表：")

	local pfIdxa = 0
	local pfIdxb = 0

	for i = 1, #skinList do
		local prefix = (input_stats.progressBarSkinIdx_word == i) and '-w-' or '--- '
		prefix = prefix .. ((input_stats.progressBarSkinIdx_code == i) and '-c-' or '---')
		pfIdxa = math.floor(i / 10)
		pfIdxb = i - pfIdxa * 10
		local skinStr = string.format("%s%02d %s%s %s%s", prefix, i, string.char(97 + pfIdxa), string.char(97 + pfIdxb),
			string.rep(skinList[i].field, 4), string.rep(skinList[i].empty, 4))
		table.insert(skinListText, skinStr)
	end

	table.insert(skinListText, "w 当前字词统计皮肤 / c 当前码长统计皮肤")
	table.insert(skinListText, "输入 //60 或 /pf 查看皮肤列表")
	table.insert(skinListText, "输入 /6xx1 或 /hfwyy 或 /pfwyy 切换字词统计皮肤(xx为数字，yy为字母)")
	table.insert(skinListText, "输入 /6xx2 或 /hfcyy 或 /pfcyy 切换码长统计皮肤(xx为数字，yy为字母)")

	return table.concat(skinListText, "\n"):gsub("\n+", "\n"):gsub("^%n", ""):gsub("%n$", "")
end

-- 格式化统计头部信息〔from 落羽行歌〕
local function format_statistics_header(stat_type, s, fastest, avgV, avgCodeLen, avgCodeLenDesc)
	strTable[1] = embedTextIntoSplitor(string.format('🚩 %s 🚩', stat_type))
	strTable[2] = os.date("%Y/%m/%d %H:%M:%S", os.time()) .. get_timezone()
	strTable[4] = string.format('上屏 %d 次，输入 %d 字', s.count, s.length)
	-- 显示击键信息 〔from Chopper〕
	strTable[5] = string.format('极速 %.1f，击键%.1f，码长%.1f', fastest.spd, fastest.keyTouchSpd, fastest.avgCodeLen)
	strTable[6] = string.format('均速 %.1f，击键%.1f，码长%.1f', avgV, avgV * avgCodeLen / 60, avgCodeLen)

	local errKeyCnt = s.keyTouchCnt - s.totalCodeLenWithoutSpace
	if errKeyCnt < 0 then errKeyCnt = 0 end
	local errKeyRatio = 0
	if s.keyTouchCnt > 0 then
		errKeyRatio = 100 * errKeyCnt / s.keyTouchCnt
	end
	strTable[6] = strTable[6] .. string.format('\n误触按键 %d 次，误触率 %.0f%%', errKeyCnt, errKeyRatio)
	
	if 0 ~= reportStyle then
		-- 如果不是短款，则加上用户自定义的相关描述
		strTable[6] = strTable[6] .. '\n' .. avgCodeLenDesc
	else
		-- 如果是短款，不要头部信息
		strTable[1] = ''
		strTable[2] = ''
	end
end

-- 格式化字长统计（单字、2字、>2字）〔from 落羽行歌〕
local function format_word_length_stats(ratioTable)
	if 0 == reportStyle then
		strTable[8] = ''
		if ratioTable[1] > 0 then
			strTable[8] = strTable[8] .. string.format('单字%.0f%%', ratioTable[1])
		end
		if ratioTable[2] > 0 then
			if utf8.len(strTable[8]) > 0 then
				strTable[8] = strTable[8] .. string.format('; 2字%.0f%%', ratioTable[2])
			else
				strTable[8] = string.format('; 2字%.0f%%', ratioTable[2])
			end
		end
		if ratioTable[3] > 0 then
			if utf8.len(strTable[8]) > 0 then
				strTable[8] = strTable[8] .. string.format('; >2字%.0f%%', ratioTable[3])
			else
				strTable[8] = string.format('; 2字%.0f%%', ratioTable[3])
			end
		end
		
		strTable[9] = ''
		strTable[10] = ''
	else
		if ratioTable[1] > 0 then
			strTable[8] = string.format('%s单字%3.0f%%', progressBar_word(ratioTable[1]), ratioTable[1])
		else
			strTable[8] = ''
		end
		if ratioTable[2] > 0 then
			strTable[9] = string.format('%s 2字%3.0f%%', progressBar_word(ratioTable[2]), ratioTable[2])
		else
			strTable[9] = ''
		end
		if ratioTable[3] > 0 then
			strTable[10] = string.format('%s>2字%3.0f%%', progressBar_word(ratioTable[3]), ratioTable[3])
		else
			strTable[10] = ''
		end
	end
end

-- 格式化码长统计 〔from 落羽行歌〕
local function format_code_length_stats(codeTableFirstN)
	if 0 == reportStyle then
		strTable[12] = ''
		if codeTableFirstN[1].ratio > 0 then
			strTable[12] = string.format('%s码%.0f%%', codeTableFirstN[1].codeLen, codeTableFirstN[1].ratio)
		end
		if codeTableFirstN[2].ratio > 0 then
			if utf8.len(strTable[12]) > 0 then
				strTable[12] = strTable[12] .. string.format('; %s码%.0f%%', codeTableFirstN[2].codeLen, codeTableFirstN[2].ratio)
			else
				strTable[12] = string.format('%s码%.0f%%', codeTableFirstN[2].codeLen, codeTableFirstN[2].ratio)
			end
		end
		if codeTableFirstN[3].ratio > 0 then
			if utf8.len(strTable[12]) > 0 then
				strTable[12] = strTable[12] .. string.format('; %s码%.0f%%', codeTableFirstN[3].codeLen, codeTableFirstN[3].ratio)
			else
				strTable[12] = string.format('%s码%.0f%%', codeTableFirstN[3].codeLen, codeTableFirstN[3].ratio)
			end
		end
		if codeTableFirstN[4].ratio > 0 then
			if utf8.len(strTable[12]) > 0 then
				strTable[12] = strTable[12] .. string.format('; 其它%.0f%%', codeTableFirstN[4].ratio)
			else
				strTable[12] = string.format('其它%.0f%%', codeTableFirstN[4].ratio)
			end
		end
		strTable[13] = ''
		strTable[14] = ''
		strTable[15] = ''
	else
		if codeTableFirstN[1].ratio > 0 then
			local codeLenStr1 = codeTableFirstN[1].codeLen < 10 and ' ' .. codeTableFirstN[1].codeLen or codeTableFirstN[1].codeLen
			strTable[12] = string.format('%s%s码%3.0f%%', progressBar_code(codeTableFirstN[1].ratio), codeLenStr1, codeTableFirstN[1].ratio)
		else
			strTable[12] = ''
		end
		if codeTableFirstN[2].ratio > 0 then
			local codeLenStr2 = codeTableFirstN[2].codeLen < 10 and ' ' .. codeTableFirstN[2].codeLen or codeTableFirstN[2].codeLen
			strTable[13] = string.format('%s%s码%3.0f%%', progressBar_code(codeTableFirstN[2].ratio), codeLenStr2, codeTableFirstN[2].ratio)
		else
			strTable[13] = ''
		end
		if codeTableFirstN[3].ratio > 0 then
			local codeLenStr3 = codeTableFirstN[3].codeLen < 10 and ' ' .. codeTableFirstN[3].codeLen or codeTableFirstN[3].codeLen
			strTable[14] = string.format('%s%s码%3.0f%%', progressBar_code(codeTableFirstN[3].ratio), codeLenStr3, codeTableFirstN[3].ratio)
		else
			strTable[14] = ''
		end
		if codeTableFirstN[4].ratio > 0 then
			strTable[15] = string.format('%s其它%3.0f%%', progressBar_code(codeTableFirstN[4].ratio), codeTableFirstN[4].ratio)
		else
			strTable[15] = ''
		end
	end
end

-- 格式化统计尾部（名人名言）〔from 落羽行歌〕
local function format_statistics_footer()
	if quoteCnt < 1 then
		strTable[21] = ''
	elseif 0 == reportStyle then
		-- 如果是短款，不要尾部信息
		strTable[21] = ''
	else
		strTable[21] = splitor .. '\n' .. quotes[math.floor(math.random() * quoteCnt) + 1]
	end
end

-- 根据给定的样本，计算并返回统计指标
local function statisticsCal(s)
	-- 记录最大值
	local fastest = { spd = s.fastest.spd, keyTouchSpd = s.fastest.keyTouchSpd, avgCodeLen = s.fastest.avgCodeLen }

	-- 统计各类输入组合的占比
	local val1 = s.lengths[1] or 0 -- 防止索引不存在时报错，默认0
	local val2 = (s.lengths[2] or 0) * 2
	local val3 = 0
	local total = 0               -- 总字数
	for key, value in pairs(s.lengths) do
		total = total + key * value -- 累加所有值
	end
	if total == 0 then total = 1 end -- 防止除以0报错
	val3 = total - val1 - val2
	local ratio1 = (val1 / total) * 100
	local ratio2 = (val2 / total) * 100
	local ratio3 = (val3 / total) * 100
	local ratioTable = { ratio1, ratio2, ratio3 } -- 和输入字符长度的占比：1字词占比，2字词占比，其它长度词占比

	-- 统计码长的占比（分类为：频率最高的3种码长，和其它码长）
	local codeTable_sorted = {}
	local totalCodeLen = 0 -- 总码长
	local totalCodeCnt = 0 -- 总码数
	local codeTypeCnt = 0 -- 码长的种类数量
	for k, v in pairs(s.codeLengths) do
		totalCodeLen = totalCodeLen + v * k
		totalCodeCnt = totalCodeCnt + v
		codeTypeCnt = codeTypeCnt + 1
		table.insert(codeTable_sorted, { clen = k, count = v })
	end
	-- 平均码长
	local avgCodeLen = totalCodeLen / total

	-- 统计码长占比
	table.sort(codeTable_sorted, function(a, b)
		return a.count > b.count
	end)
	if totalCodeCnt == 0 then totalCodeCnt = 1 end -- 防止除以0报错
	local codeTableFirstN = {}                  -- 输入码长最多的前N码（4码）码长占比数据
	local ratioSumOfFirstN = 0
	for i = 1, 3 do
		if i <= codeTypeCnt then
			codeTableFirstN[i] = { codeLen = codeTable_sorted[i].clen, ratio = codeTable_sorted[i].count / totalCodeCnt *
			100 }
		else
			codeTableFirstN[i] = { codeLen = 0, ratio = 0 }
		end
		ratioSumOfFirstN = ratioSumOfFirstN + codeTableFirstN[i].ratio
	end
	codeTableFirstN[4] = { codeLen = 0, ratio = 100 - ratioSumOfFirstN }

	-- 计算平均分速
	local avgDelt = tableSum(s.avgGaps)
	local avgSpd = 0
	if avgDelt > 1 then
		avgSpd = tableSum(s.avgCnts) / avgDelt * 60
		if avgSpd > fastest.spd then
			fastest.spd = avgSpd
			fastest.keyTouchSpd = avgSpd * avgCodeLen / 60
			fastest.avgCodeLen = avgCodeLen
		end
	end

	return fastest, avgSpd, avgCodeLen, ratioTable, codeTableFirstN
end

-- 显示函数（日统计）
local function format_daily_summary()
	local s = input_stats.daily
	if s.count == 0 then return "※ 今天没有任何记录。" end

	local fastest, avgSpd, avgCodeLen, ratioTable, codeTableFirstN = statisticsCal(s)

	-- 使用辅助函数格式化统计头部信息
	format_statistics_header("日统计", s, fastest, avgSpd, avgCodeLen, avgCodeLenDesc)
	-- 使用辅助函数格式化字长统计
	format_word_length_stats(ratioTable)
	-- 使用辅助函数格式化码长统计
	format_code_length_stats(codeTableFirstN)
	-- 使用辅助函数格式化统计尾部
	format_statistics_footer()

	return trim(table.concat(strTable, '\n'):gsub("\n+", "\n"):gsub("^%n", ""):gsub("%n$", ""))
end

-- 显示函数（周统计）
local function format_weekly_summary()
	local s = input_stats.weekly
	if s.count == 0 then return "※ 本周没有任何记录。" end

	local fastest, avgSpd, avgCodeLen, ratioTable, codeTableFirstN = statisticsCal(s)

	-- 使用辅助函数格式化统计头部信息
	format_statistics_header("周统计", s, fastest, avgSpd, avgCodeLen, avgCodeLenDesc)
	-- 使用辅助函数格式化字长统计
	format_word_length_stats(ratioTable)
	-- 使用辅助函数格式化码长统计
	format_code_length_stats(codeTableFirstN)
	-- 使用辅助函数格式化统计尾部
	format_statistics_footer()

	return trim(table.concat(strTable, '\n'):gsub("\n+", "\n"):gsub("^%n", ""):gsub("%n$", ""))
end

-- 显示函数（月统计）
local function format_monthly_summary()
	local s = input_stats.monthly
	if s.count == 0 then return "※ 本月没有任何记录。" end

	local fastest, avgSpd, avgCodeLen, ratioTable, codeTableFirstN = statisticsCal(s)

	-- 使用辅助函数格式化统计头部信息
	format_statistics_header("月统计", s, fastest, avgSpd, avgCodeLen, avgCodeLenDesc)
	-- 使用辅助函数格式化字长统计
	format_word_length_stats(ratioTable)
	-- 使用辅助函数格式化码长统计
	format_code_length_stats(codeTableFirstN)
	-- 使用辅助函数格式化统计尾部
	format_statistics_footer()

	return trim(table.concat(strTable, '\n'):gsub("\n+", "\n"):gsub("^%n", ""):gsub("%n$", ""))
end

-- 显示函数（年统计）
local function format_yearly_summary()
	local s = input_stats.yearly
	if s.count == 0 then return "※ 本年没有任何记录。" end

	local fastest, avgSpd, avgCodeLen, ratioTable, codeTableFirstN = statisticsCal(s)

	-- 使用辅助函数格式化统计头部信息
	format_statistics_header("年统计", s, fastest, avgSpd, avgCodeLen, avgCodeLenDesc)
	-- 使用辅助函数格式化字长统计
	format_word_length_stats(ratioTable)
	-- 使用辅助函数格式化码长统计
	format_code_length_stats(codeTableFirstN)
	-- 使用辅助函数格式化统计尾部
	format_statistics_footer()

	return trim(table.concat(strTable, '\n'):gsub("\n+", "\n"):gsub("^%n", ""):gsub("%n$", ""))
end

-- 显示记录的生字/词
local function format_shengzi()
	if input_stats.newWords == nil then
		return string.format("※ 未发现生字/词记录。")
	end
	if input_stats.newWords.words == nil then
		return string.format("※ 未发现生字/词记录。")
	end

	local verStr = strTable[#strTable - 1]
	local newWords = {}
	for k, v in pairs(input_stats.newWords.words) do
		table.insert(newWords, k)
	end
	local wordsCnt = #newWords
	if wordsCnt < 1 then
		return string.format("※ 未发现生字/词记录。")
	end

	local tmpTable = {}
	tmpTable[1] = embedTextIntoSplitor('🚩 生字/词本 🚩')
	tmpTable[2] = ''
	if input_stats.newWords.startTime > 0 then
		tmpTable[2] = os.date("自 %Y/%m/%d %H:%M:%S 以来，", input_stats.newWords.startTime)
	end
	tmpTable[3] = string.format("共记录到生字/词 %d 个", wordsCnt)

	tmpTable[4] = splitor
	tmpTable[5] = table.concat(newWords, '，')
	tmpTable[6] = splitor
	tmpTable[7] = verStr

	return trim(table.concat(tmpTable, '\n'):gsub("\n+", "\n"):gsub("^%n", ""):gsub("%n$", ""))
end

-- 加载保存的统计数据（input_stats.lua）
local function load_stats_from_lua_file(schema_id)
	local path = rime_api.get_user_data_dir() .. "/lua/input_stats_" .. schema_id .. ".lua"
	local ok, result = pcall(function()
		local env = {}
		local f = loadfile(path, "t", env)
		if f then f() end
		return env.input_stats
	end)
	if ok and type(result) == "table" then
		input_stats = result
	end

	-- 如果log的版本过低，则更新 input_stats 结构
	if nil == input_stats.logVer or input_stats.logVer < verOfStatsFormat then
		local int1 = 21
		local int2 = 21
		local deviceType = ''
		if nil ~= input_stats.progressBarSkinIdx_word then
			int1 = input_stats.progressBarSkinIdx_word
			int2 = input_stats.progressBarSkinIdx_code
		end
		if nil ~= input_stats.deviceType then
			deviceType = input_stats.deviceType
		end

		input_stats = {
			daily = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			weekly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			monthly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			yearly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			logVer = verOfStatsFormat,
			daily_max = 0,
			newWords = { startTime = 0, words = {} },
			deviceType = deviceType,
			progressBarSkinIdx_word = int1,
			progressBarSkinIdx_code = int2
		}
	end

	-- 识别设备类型
	input_stats.deviceType = getDeviceType()
end

-- 翻译器：处理统计命令
local function translator(input, seg, env)
	-- 判断是否在连续输入状态下
	local timeNow = os.time()
	if timeNow - avgSpdInfo.clickTime > avgSpdInfo.gapThd then
		-- 如果距离上次按键超时了，即输入已经中断，这是重新开始的输入行为
		if avgSpdInfo.commitTime - avgSpdInfo.startTime >= 1 and avgSpdInfo.count > 0 then
			-- 此时的统计数据是有效
			update_stats(0, 0, 0, 1)
		end

		-- 清除计时
		avgSpdInfo.startTime = timeNow
		avgSpdInfo.commitTime = timeNow
	end
	avgSpdInfo.clickTime = timeNow

	-- 判断用户是否按下的新的按键
	if lastCode ~= input and input:sub(1, 1) ~= "/" then
		local inputLen = string.len(input)
		local lastLen = string.len(lastCode)

		if inputLen > lastLen then
			-- 如果编码变长了，则肯定是用户按下了新的按键了
			keyTouchCnt = keyTouchCnt + 1
		elseif inputLen == 1 then
			-- 如果按键没有变长，而且这是第一个编码，则根据情况做如下处理
			if lastLen == 1 then
				-- 如果前一码长为1，本次码长也是1，则认为前一编码被取消了（通过BackSpace 或者 esc），本次的编码是新按下的
				keyTouchCnt = keyTouchCnt + 1
			elseif lastLen > 2 then
				-- 如果前一码长大于2，本次码长只有1，则认为这是前一编码通过esc取消了，本次的编码是新按下的
				keyTouchCnt = keyTouchCnt + 1
			else
				-- 如果前一码长为2，本次码长为1，则存在两种不同的情况
				-- 情况1、前一码长为2，按了BackSpace使码长缩减为1，此情况下，当前的编码是上一编码的残留
				-- 情况2、前一码长为2，按了esc使编码归零，用户重新按了一个键，此情况下，本次的一个码是用户新按的按键
				-- 以上两种情况，只有第2种情况下，需要使 keyTouchCnt 做 +1 处理
				-- 但是目前的输入法框架无法获取到BackSpace和esc的输入，所以只能在以下特殊情况下猜测出用户做了情况2的操作：
				if lastCode:sub(1, 1) ~= input then
					-- 如果前一编码的第1个字符与当前编码不相等，则可以肯定用户是操作了情况2
					keyTouchCnt = keyTouchCnt + 1
				else
					-- 如果前一编码的第1个字符与当前编码相等，则无法判断用户的操作是情况1，还是情况2，这个根据客户要求做统一处理了
					-- 暂时做 +0 处理
					keyTouchCnt = keyTouchCnt + 0
				end
			end
		end
	end

	if input:sub(1, 1) ~= "/" then
		lastCode = input
		return
	else
		-- 如果输入是以/引导的，则不检测是否回改
		lastCode = ''
	end

	local summary = ""
	local avgAvailable = 0
	if avgSpdInfo.commitTime - avgSpdInfo.startTime >= 1 and avgSpdInfo.count > 0 then avgAvailable = 1 end
	
	if reportCommands[input] then
		if avgAvailable == 1 then -- 如果此时已经有统计数据，则记录该统计数据
			update_stats(0, 0, 0, 1)
			-- 清除计时
			avgSpdInfo.startTime = timeNow
			avgSpdInfo.commitTime = timeNow
		end
		
		if #input > 1 then
			if input:sub(-2,-2) == input:sub(-1,-1) then
				reportStyle = 1
				strTable[3] = '📈' .. string.rep(splitorChar, splitorLen - 1)
				strTable[7] = '📊' .. string.rep(splitorChar, splitorLen - 1)
				strTable[11] = '📊' .. string.rep(splitorChar, splitorLen - 1)
				strTable[16] = splitor
				strTable[17] = '◉ 方案：' .. schema_name
				strTable[18] = '◉ 平台：' .. getDeviceType() .. software_name .. ' ' .. software_version
				strTable[19] = splitor
				strTable[20] = '脚本：🐐🪶' .. SCRIPT_VERSION
			else
				reportStyle = 0
				strTable[3] = ''
				strTable[7] = splitor
				strTable[11] = ''
				strTable[16] = splitor
				strTable[17] = getDeviceType()..'・'..schema_name
				strTable[18] = ''
				strTable[19] = ''
				strTable[20] = ''
			end
		end
		
		if ({ ['📱'] = true, ['💻'] = true })[input_stats.deviceType] then
			if ({['//1'] = true, ['/rtj'] = true, ['//11'] = true, ['/rtjj'] = true})[input] then
				summary = format_daily_summary()
			elseif ({['//2'] = true, ['/ztj'] = true, ['//22'] = true, ['/ztjj'] = true})[input] then
				summary = format_weekly_summary()
			elseif ({['//3'] = true, ['/ytj'] = true, ['//33'] = true, ['/ytjj'] = true})[input] then
				summary = format_monthly_summary()
			elseif ({['//4'] = true, ['/ntj'] = true, ['//44'] = true, ['/ntjj'] = true})[input] then
				summary = format_yearly_summary()
			else
				summary = '未识别的统计指令'
			end
		else
			summary = 'deviceType识别失败，请设置deviceType后重新部署'
		end
	elseif input == "//5" or input == "/sztj" then
		if avgAvailable == 1 then -- 如果此时已经有统计数据，则记录该统计数据
			update_stats(0, 0, 0, 1)

			-- 清除计时
			avgSpdInfo.startTime = timeNow
			avgSpdInfo.commitTime = timeNow
		end
		summary = format_shengzi()
	elseif input == "//07" or input == "/qcjs" then
		input_stats.daily.fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }
		input_stats.weekly.fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }
		input_stats.monthly.fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }
		input_stats.yearly.fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }
		save_stats(env.engine.schema.schema_id)
		summary = '※ 极速数据已清空。'
	elseif input == "//08" or input == "/qcsz" then
		input_stats.newWords = { startTime = 0, words = {} }
		save_stats(env.engine.schema.schema_id)
		summary = "※ 生字词已清空。"
	elseif input == "//09" or input == "/qctj" then
		local int1 = input_stats.progressBarSkinIdx_code
		local int2 = input_stats.progressBarSkinIdx_word
		local deviceType = input_stats.deviceType
		local logV = input_stats.logVer
		keyTouchCnt = 0
		lastCode = 0
		input_stats = {
			daily = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			weekly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			monthly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			yearly = { count = 0, length = 0, fastest = { spd = 0, keyTouchSpd = 0, avgCodeLen = 0 }, ts = 0, lengths = {}, codeLengths = {}, avgGaps = {}, avgCnts = {}, avgCodeLen = {}, keyTouchCnt = 0, totalCodeLenWithoutSpace = 0 },
			logVer = logV,
			daily_max = 0,
			newWords = { startTime = 0, words = {} },
			deviceType = deviceType,
			progressBarSkinIdx_word = 21,
			progressBarSkinIdx_code = 21
		}
		input_stats.progressBarSkinIdx_code = int1
		input_stats.progressBarSkinIdx_word = int2
		save_stats(env.engine.schema.schema_id)

		avgSpdInfo.count = 0
		avgSpdInfo.codeLen = 0

		summary = "※ 所有统计数据已清空。"
	elseif ({ ['//6'] = true, ['/pf'] = true })[input:sub(1, 3)] or ({ ['/pfw'] = true, ['/pfc'] = true, ['/hfw'] = true, ['/hfc'] = true })[input:sub(1, 4)] then
		if (input == "//60") or (input == "/pf") then -- 展示皮肤列表
			summary = formatSkinList()
		elseif input:match("^//6(%d%d)1$") then -- 设置字词统计皮肤
			local skinIndex = tonumber(input:match("^//6(%d%d)1$"))
			if skinIndex and skinIndex >= 1 and skinIndex <= #skinList then
				input_stats.progressBarSkinIdx_word = skinIndex
				progressBarField_word = skinList[input_stats.progressBarSkinIdx_word].field
				progressBarEmpty_word = skinList[input_stats.progressBarSkinIdx_word].empty
				summary = string.format("※ 字词统计皮肤已切换至：//6%02d1 %s%s",
					skinIndex, progressBarField_word, progressBarEmpty_word)

				save_stats(env.engine.schema.schema_id)
			else
				summary = "※ 无效的皮肤编号〔" .. input:sub(4, 5) .. '〕'
			end
		elseif input:match("^//6(%d%d)2$") then -- 设置码长统计皮肤
			local skinIndex = tonumber(input:match("^//6(%d%d)2$"))
			if skinIndex and skinIndex >= 1 and skinIndex <= #skinList then
				input_stats.progressBarSkinIdx_code = skinIndex
				progressBarField_code = skinList[input_stats.progressBarSkinIdx_code].field
				progressBarEmpty_code = skinList[input_stats.progressBarSkinIdx_code].empty
				summary = string.format("※ 码长皮肤已切换至：//6%02d2 %s%s",
					skinIndex, progressBarField_code, progressBarEmpty_code)

				save_stats(env.engine.schema.schema_id)
			else
				summary = "※ 无效的皮肤编号〔" .. input:sub(4, 5) .. '〕'
			end
		elseif input:match("^/[hp]fw[a-z][a-z]$") then -- 设置字词统计皮肤
			local skinIndex = (string.byte(input:sub(5, 5)) - 97) * 10 + string.byte(input:sub(6, 6)) - 97
			if skinIndex and skinIndex >= 1 and skinIndex <= #skinList then
				input_stats.progressBarSkinIdx_word = skinIndex
				progressBarField_word = skinList[input_stats.progressBarSkinIdx_word].field
				progressBarEmpty_word = skinList[input_stats.progressBarSkinIdx_word].empty
				summary = string.format("※ 字词统计皮肤已切换至：/[ph]fw%s %s%s",
					input:sub(5, 6), progressBarField_word, progressBarEmpty_word)

				save_stats(env.engine.schema.schema_id)
			else
				summary = "※ 无效的皮肤编号〔" .. input:sub(5, 6) .. '〕'
			end
		elseif input:match("^/[hp]fc[a-z][a-z]$") then -- 设置字词统计皮肤
			local skinIndex = (string.byte(input:sub(5, 5)) - 97) * 10 + string.byte(input:sub(6, 6)) - 97
			if skinIndex and skinIndex >= 1 and skinIndex <= #skinList then
				input_stats.progressBarSkinIdx_code = skinIndex
				progressBarField_code = skinList[input_stats.progressBarSkinIdx_code].field
				progressBarEmpty_code = skinList[input_stats.progressBarSkinIdx_code].empty
				summary = string.format("※ 码长皮肤已切换至：/[ph]fc%s %s%s",
					input:sub(5, 6), progressBarField_code, progressBarEmpty_code)

				save_stats(env.engine.schema.schema_id)
			else
				summary = "※ 无效的皮肤编号〔" .. input:sub(5, 6) .. '〕'
			end
		end
	end

	if summary ~= "" then
		yield(Candidate("stat", seg.start, seg._end, summary, ""))
	end
end

-- 加载文档里的短语短句
local function quoteLoad()
	local quoteFile = currentDir() .. "/quote.txt"

	local lines = files_to_lines(quoteFile)
	for i, line in next, lines do
		table.insert(quotes, line)
		quoteCnt = quoteCnt + 1
	end
end

local function init(env)
	schema_name = env.engine.schema.schema_name or '未知'
	local ctx = env.engine.context
	-- 加载指定输入方案的历史统计数据
	load_stats_from_lua_file(env.engine.schema.schema_id)
	-- 更新皮肤
	progressBarField_word = skinList[input_stats.progressBarSkinIdx_word].field
	progressBarEmpty_word = skinList[input_stats.progressBarSkinIdx_word].empty
	progressBarField_code = skinList[input_stats.progressBarSkinIdx_code].field
	progressBarEmpty_code = skinList[input_stats.progressBarSkinIdx_code].empty
	-- 加载名人名言
	quoteLoad()

	-- 初始化随机数种子
	math.randomseed(os.time())

	-- 注册提交通知回调
	env.notifier = env.engine.context.commit_notifier:connect(function(ctx)
		-- 提交的时候，把 lastCode 清除
		lastCode = ''

		local commit_text = ctx:get_commit_text()
		local returnFlg = 0
		if not commit_text or commit_text == "" then returnFlg = 1 end

		-- 如果输入与上屏内容一致，例如编码上屏，则不统计此项
		if ctx.input == commit_text then returnFlg = 1 end

		-- 如果输入是以 / 引导的，则不统计这个输入项
		if ctx.input:find("^/") then returnFlg = 1 end

		-- 如果上屏的字符串中存在非汉字，则放弃统计这一次的提交
		if not isAllChineseCharacter(commit_text) then returnFlg = 1 end

		if 1 == returnFlg then
			keyTouchCnt = 0
			return
		end

		-- 如果是标点符号，则不进行统计
		if commit_text:match("^[！!@#$％^&?,.;？，。；/0123456789]+$") then return end

		local codeLen = string.len(ctx.input)
		local input_length = utf8.len(commit_text) or string.len(commit_text)
		-- 统计平均分速
		local timeNow = os.time()
		local delt = timeNow - avgSpdInfo.commitTime

		-- 修正码长
		local codeLenMatched = 0
		for i = 1, #codeLenOfAutoCommit do
			if codeLenOfAutoCommit[i] == codeLen then
				codeLenMatched = 1
				break
			end
		end
		if codeLenMatched ~= 1 then
			codeLen = codeLen + 1
		end

		-- 更新上屏时间
		avgSpdInfo.commitTime = timeNow
		-- 记录输入字数
		avgSpdInfo.count = avgSpdInfo.count + input_length
		-- 记录编码数量
		avgSpdInfo.codeLen = avgSpdInfo.codeLen + codeLen

		-- 如果卡壳了(但是间隔时间小于Xs)，记录这个字/词
		if delt >= boggleThd_s then
			if input_stats.newWords.startTime == nil then
				input_stats.newWords.startTime = timeNow
			elseif input_stats.newWords.startTime < 1 then
				input_stats.newWords.startTime = timeNow
			elseif #input_stats.newWords.words < 1 then
				input_stats.newWords.startTime = timeNow
			end

			input_stats.newWords.words[commit_text] = 1
		else
			input_stats.newWords.words[commit_text] = nil
		end

		-- 上屏统计
		update_stats(input_length, codeLen, string.len(ctx.input), 0)
		save_stats(env.engine.schema.schema_id)
	end)
end
function finit(env)
	if env.notifier then
		env.notifier:disconnect()
		env.notifier = nil
	end
end

return { init = init, fini = finit, func = translator }
