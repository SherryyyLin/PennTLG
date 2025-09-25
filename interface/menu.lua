-- interface/menu.lua
-- 游戏开始菜单界面
-- Game menu interface

local langManager = require("modules.langManager")           -- 引入语言管理模块
local gameStateManager = require("modules.gameStateManager") -- 引入游戏状态管理器
local buttonManager = require("modules.buttonManager")       -- 引入按钮模块
local settings = require("modules.userSettings")             -- 引入设置模块

local createRoomUI = require("interface.createRoom")         -- 引入创建房间界面模块
local firstStage = require("interface.firstStage")           -- 引入第一阶段模块
-- local joinRoomUI = require("interface.joinRoomUI")           -- 引入加入房间界面模块(未开发)
-- local settingsUI = require("interface.settingsUI")           -- 引入设置界面模块(未开发)

local menu = {}

--- 按钮列表
--- Button list
local buttons = {}

--------------------------------------------------
--- @brief 加载函数：初始化菜单界面资源和按钮配置
--- @brief Load function: initialize menu resources and button configurations
---
--- 加载字体部分待修改
--------------------------------------------------
function menu.load()
    -- 加载背景图片
    -- Load background image
    menu.background = love.graphics.newImage("resources/menu/background.png")

    -- 加载中文字体
    -- Load Chinese font
    menu.font = love.graphics.newFont("resources/fonts/msyh.ttc", 28)

    --- 初始化页面按钮
    --- Initialize page buttons
    buttonManager.init("menu")
end

------------------------------------------------------
--- 更新函数：更新按钮状态（如悬停、点击）
------------------------------------------------------
function menu.update(dt)
    --- 更新按钮状态
    --- Update button states
    buttonManager.update(dt)
end

---------------------------------------------------
-- 绘制函数：绘制背景和所有按钮
---------------------------------------------------
function menu.draw()
    -- 绘制背景图像（拉伸填满屏幕）
    love.graphics.draw(menu.background, 0, 0, 0,
        love.graphics.getWidth() / menu.background:getWidth(),
        love.graphics.getHeight() / menu.background:getHeight()
    )

    -- 设置字体
    love.graphics.setFont(menu.font)

    --- 绘制按钮
    --- Draw button
    buttonManager.draw("menu")

    -- 恢复绘图颜色
    love.graphics.setColor(1, 1, 1, 1)
end

return menu
