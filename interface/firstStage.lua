-- modules/first_stage.lua
-- 第一阶段逻辑模块
-- ==========================
-- 第一阶段有六名（未来数量可能扩展）固定的教育学家，每位教育学家都有特定的名字和额外八条与身份相关的信息。
-- 游戏中每个轮次系统会从后台的六名教育学家中随机抽取一名，对于每个游戏玩家而言抽取的是同一个教育学家。
-- 随着时间的推移，教育学家的相关信息会逐渐展示，从最开始的一条，到最终的八条。
-- 游戏过程中由各位玩家进行猜测教育学家的姓名，每个轮次中每个玩家只有一次猜测的机会，每个人可以自行决定在何时输入名字，但只有第一个猜测出准确姓名的玩家获胜
-- ==========================


-- 加载教育学家 ID 列表（不含文字信息）
local educators = require("educators")
-- 加载当前语言包（此处使用简体中文，可替换为其他语言包）
local localization = require("localization.en_US")
local Font = love.graphics.newFont("resources/fonts/msyh.ttc", 20)

-- 创建模块表，用于封装所有功能函数
local first_stage = {}

-- ======================= 模块内部状态变量 =======================

local CurrentEducatorId       -- 当前轮次被选中的教育学家的 ID，例如 "dewey"
local CurrentEducatorLangData -- 当前教育学家在语言包中的内容（包含 name 和 info 表）
local CurrentInfoIndex        -- 当前已揭示的信息条数，从 1 开始，最大为 8
local InfoTimer               -- 信息揭示计时器（累计时间）
local InfoInterval = 5        -- 每隔 5 秒揭示一条信息（可根据需要修改）
local GuessedPlayers = {}     -- 玩家猜测记录表（key 是 playerId，value 是 true）
local Winner = nil            -- 胜利者的 playerId（只有第一个猜对的玩家才会被记录）
local RoundOver = false       -- 标志当轮次是前否已经结束

-- ======================= 初始化函数 =======================

-- 初始化并开始新一轮游戏
function first_stage.start()
    -- 从教育学家列表中随机选出一名（获取其 ID）
    local idx = math.random(#educators)
    CurrentEducatorId = educators[idx].id

    -- 从语言包中获取对应教育学家的语言数据（包括名字和8条信息）
    CurrentEducatorLangData = localization.descriptions.educators[CurrentEducatorId] or { name = "???", info = {} }

    -- 重置本轮信息揭示状态为第1条
    CurrentInfoIndex = 1
    -- 重置计时器
    InfoTimer = 0
    -- 清空猜测记录
    GuessedPlayers = {}
    -- 清除上轮胜利者记录
    Winner = nil
    -- 标记轮次为“未结束”
    RoundOver = false
end

-- ======================= 每帧更新函数 =======================

-- 更新函数由 love.update(dt) 每帧调用
-- 负责信息揭示节奏的推进
function first_stage.update(dt)
    -- 如果轮次已经结束，则不再更新
    if RoundOver then return end

    -- 累加计时器
    InfoTimer = InfoTimer + dt

    -- 如果累计时间超过揭示间隔，并且还有信息未展示完
    if InfoTimer >= InfoInterval and CurrentInfoIndex < #CurrentEducatorLangData.info then
        -- 减去已用的时间（支持时间累计）
        InfoTimer = InfoTimer - InfoInterval
        -- 增加已揭示信息数量
        CurrentInfoIndex = CurrentInfoIndex + 1
    end
end

-- ======================= 绘制界面函数 =======================

-- 绘制函数由 love.draw() 每帧调用
-- 显示当前揭示的信息内容和胜利提示
function first_stage.draw()
    love.graphics.setFont(Font)
    -- ======================= 调试 =======================
    love.graphics.print("[TEST]A: " .. CurrentEducatorId, 50, 400)
    love.graphics.print("[TEST]B: " .. tostring(#CurrentEducatorLangData.info), 50, 450)
    love.graphics.print("[TEST]C: " .. tostring(CurrentInfoIndex), 50, 470)
    -- ======================= 调试 =======================
    
    -- 打印标题，例如“教育学家信息：”
    love.graphics.print(localization.ui.firstStage.title, 50, 50)

    -- 依次绘制已揭示的教育学家信息（每行偏移 20 像素）
    for i = 1, CurrentInfoIndex do
        love.graphics.print("- " .. (CurrentEducatorLangData.info[i] or ""), 50, 50 + i * 20)
    end

    -- 如果游戏已结束且有胜利者，显示胜者提示信息
    if RoundOver and Winner then
        love.graphics.print(string.format(localization.ui.winner, Winner), 50, 300)
    end
end

-- ======================= 玩家猜测函数 =======================

-- 玩家进行姓名猜测
-- 参数 name 是玩家输入的名字，playerId 是玩家唯一标识
function first_stage.tryGuess(name, playerId)
    -- 若轮次已结束，或玩家已猜测过，直接忽略
    if RoundOver or GuessedPlayers[playerId] then return end

    -- 标记该玩家已猜测
    GuessedPlayers[playerId] = true

    -- 检查玩家的猜测是否与目标教育学家名字一致
    if name == CurrentEducatorLangData.name then
        -- 正确猜中：记录胜利者并结束轮次
        Winner = playerId
        RoundOver = true
    end
    -- 猜错不做处理，玩家失去本轮继续猜测资格
end

-- ======================= 对外接口导出 =======================

-- 将模块中的函数暴露出去，供外部调用
first_stage.start = first_stage.start                     -- 启动新一轮
first_stage.update = first_stage.update                   -- 每帧更新信息状态
first_stage.draw = first_stage.draw                       -- 每帧绘制界面
first_stage.tryGuess = first_stage.tryGuess               -- 处理玩家猜测
first_stage.isRoundOver = function() return RoundOver end -- 查询是否结束
first_stage.getWinner = function() return Winner end      -- 获取胜利者 ID

-- 返回整个模块表
return first_stage
