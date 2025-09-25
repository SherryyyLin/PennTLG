-- modules/roomIDGenerator.lua
-- 用于生成四位房间ID

local roomIDGenerator = {}

-- 生成一个四位数字的房间ID
-- @return string 形如 "3729" 的ID
function roomIDGenerator.generate()
    -- 当前时间（秒）转换为毫秒 + 微秒扰动
    local timeMs = os.time() * 1000
    local micro = math.floor(os.clock() * 1000000)
    local rand = math.random(0, 999)

    -- 组合成一个原始基数
    local raw = timeMs + micro + rand

    -- 使用简单扰动算法，用余数+逆序取位法打乱原始数值
    local scramble = ((raw % 97) * 37 + (raw % 89)) % 10000

    -- 格式化为四位数字，前面补0
    return string.format("%04d", scramble)
end

return roomIDGenerator
