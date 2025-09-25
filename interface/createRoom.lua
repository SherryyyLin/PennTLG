-- createRoomUI.lua
-- 创建房间界面逻辑模块，负责绘制房间设置界面并响应用户操作

local langManager = require("modules.langManager")           -- 引入语言管理模块
local gameStateManager = require("modules.gameStateManager") -- 用于状态跳转
local button = require("modules.buttonManager")                     -- 引入按钮模块
local roomIDGenerator = require("modules.roomIDGenerator")   -- 引入房间ID生成模块
local firstStage = require("interface.firstStage")           -- 引入第一阶段模块


-- 定义模块表
local createRoomUI = {}

-- 按钮列表
local buttons = {}

-- UI界面参数
local playerCountOptions = { 2, 3, 4, 5, 6 }
local panelX, panelY = 200, 100
local panelWidth, panelHeight = 400, 400

-- 字体资源
local titleFont = love.graphics.newFont("resources/fonts/msyh.ttc", 32)
local subFont = love.graphics.newFont("resources/fonts/msyh.ttc", 20)
local textFont = love.graphics.newFont("resources/fonts/msyh.ttc", 18)

-- 状态变量（在 load 中初始化）
local roomID, roomName, maxPlayers, needPassword, roomPassword, playerCountIndex



--------------------------------------------------
-- 初始化函数：重置房间参数
--------------------------------------------------
function createRoomUI.load()
    roomID = roomIDGenerator.generate()
    roomName = "My Room"
    maxPlayers = 4
    playerCountIndex = 3 -- 对应4人
    needPassword = false
    roomPassword = ""
    button.clear() -- 清除旧按钮状态
    firstStage.start()



    -- menu.lua 中定义按钮表
    buttons = {
        {
            id = "create_room",
            label = langManager.getText("ui.createRoomUI.create_room"),
            x = panelX + 50,
            y = panelY + 320,
            w = 140,
            h = 40,
            action = function()
                gameStateManager.switchState("firstStage")
            end
        },
        {
            id = "exit_game",
            label = langManager.getText("ui.createRoomUI.back_to_menu"),
            x = panelX + 230,
            y = panelY + 320,
            w = 140,
            h = 40,
            action = function()
                gameStateManager.switchState("menu")
            end
        }
    }
end

---------------------------------------------------
-- 更新逻辑
---------------------------------------------------
function createRoomUI.update(dt)
    button.update(dt) -- 更新所有按钮的状态

    -- 遍历按钮，检查是否被点击，执行其 action
    for _, btn in ipairs(buttons) do
        if button.isClicked(btn.id) then
            btn.action()
        end
    end
end

---------------------------------------------------
-- 主绘制函数
---------------------------------------------------
function createRoomUI.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    -- 背景板
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 12, 12)

    -- 标题与房间号
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Create Room", panelX, panelY + 20, panelWidth, "center")

    love.graphics.setFont(subFont)
    love.graphics.printf(langManager.getText("ui.createRoomUI.room_id") .. (roomID or "0000"),
        panelX, panelY + 60,
        panelWidth, "center")

    -- 房间设置内容
    love.graphics.setFont(textFont)
    love.graphics.print(langManager.getText("ui.createRoomUI.room_name") .. roomName,
        panelX + 30, panelY + 110)
    love.graphics.print(langManager.getText("ui.createRoomUI.number_of_players") .. maxPlayers, panelX + 30, panelY + 150)

    love.graphics.print(langManager.getText("ui.createRoomUI.require_password"), panelX + 30, panelY + 190)
    love.graphics.rectangle("line", panelX + 130, panelY + 190, 20, 20)
    if needPassword then
        love.graphics.rectangle("fill", panelX + 180, panelY + 190, 20, 20)
    end

    if needPassword then
        love.graphics.print("密码：" .. roomPassword, panelX + 30, panelY + 230)
    end

    -- 遍历按钮列表绘制按钮
    for _, btn in ipairs(buttons) do
        button.draw(btn.id, btn.label, btn.x, btn.y, btn.w, btn.h)
    end
end

---------------------------------------------------
-- 鼠标点击处理函数（使用封装按钮检测）
---------------------------------------------------
function createRoomUI.mousepressed(x, y, mouseButton)
    if mouseButton == 1 then
        -- 密码勾选框点击
        if x >= panelX + 150 and x <= panelX + 180 and y >= panelY + 190 and y <= panelY + 210 then
            needPassword = not needPassword
        end
    end
end

---------------------------------------------------
-- 返回模块表
---------------------------------------------------
return createRoomUI
