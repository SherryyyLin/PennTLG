-- config/buttonConfig.lua
-- button 配置文件：集中存放按钮、布局、样式等设定。
-- button config: central definitions for button layout, styles, labels, etc.

local langManager = require("modules.langManager") -- 引入语言管理模块 / Load language manager module

local buttonConfig = {}

buttonConfig.default = {
    --- meta = {                                                          -- 元信息 / Meta Information
    ---     id = "untitled-id",                                           -- -- 按钮唯一ID / Unique button ID
    ---     interface = "default",                                        -- -- 所属界面 / Interface this button belongs to
    ---     group = "default",                                            -- -- 分组名 / Group for batch control
    ---     tags = {},                                                    -- -- 标签 / Tags for classification
    ---     dependencies = {},                                            -- -- 依赖模块列表 / List of required modules
    ---     shouldDestroyOnExit = true                                    -- -- 是否在界面退出时销毁 / Whether to destroy this button when exiting the interface
    --- },
    content = {                                                       -- 内容配置 / Content Configuration
        label = "untitled",                                           -- -- 按钮文本 / Button text
        iconImage = nil,                                              -- -- 可选图标 / Optional icon image
    },
    layout = {                                                        -- 布局配置 / Layout Configuration
        anchor = "center",                                            -- -- 锚点位置 / Anchor point
        offsetX = 0,                                                  -- -- X轴偏移量 / Horizontal offset
        offsetY = 0,                                                  -- -- Y轴偏移量 / Vertical offset
        zIndex = 10,                                                  -- -- 绘制层级（值越高越晚绘制） / Drawing order (higher = top)
    },
    displayControl = {                                                -- 显示控制 / Display Control
        visible = true,                                               -- -- 是否显示 / Whether to display the button
    },
    style = {                                                         -- 基础样式 / Visual Style
        font = love.graphics.newFont("resources/fonts/msyh.ttc", 20), -- -- 字体 / Font
        textColor = { 1, 1, 1 },                                      -- -- 字体颜色 / Text color (RGB 0~1)
        shadow = false,                                               -- -- 是否有阴影 / Enable shadow
        width = 180,                                                  -- -- 按钮宽度 / Width
        height = 50,                                                  -- -- 按钮高度 / Height
        padding = 8,                                                  -- -- 内边距 / Inner padding

        backgroundColor = { 0.1, 0.6, 0.9 },                          -- -- 背景颜色 / Background color
        backgroundImage = nil,                                        -- -- 背景图像 / Optional background image

        borderColor = { 0.8, 0.8, 0.8 },                              -- -- 边框颜色 / Border color
        borderWidth = 2,                                              -- -- 边框宽度 / Border width

        roundedCorners = true,                                        -- -- 是否启用圆角 / Enable rounded corners
        cornerRadius = 10,                                            -- -- 圆角半径 / Radius in pixels
    },
    hoverStyle = {                                                    -- 悬停时样式 / Style to apply when mouse is over button
        hoverBackgroundColor = { 0.2, 0.7, 1.0 },                     -- -- 悬停时背景颜色 / Hover background
    },
    pressedStyle = {                                                  -- 按下时样式 / Style to apply when button is pressed
        pressedBackgroundColor = { 0.0, 0.4, 0.8 }                    -- -- 按下时背景颜色 / Pressed background
    },
    logic = {                                                         -- 逻辑配置 / Logic Handlers
        onClick = function() print("Button clicked") end,             -- -- 点击时的函数 / Function to execute on click
        onHold = function() print("Button onHold") end,               -- -- 可选：长按触发 / Optional: Trigger on hold
        onHoverEnter = function() print("Mouse entered button") end,  -- -- 鼠标悬停进入时的函数 / Function when mouse enters button
        onHoverExit = function() print("Mouse exited button") end,    -- -- 鼠标悬停离开时的函数 / Function when mouse exits button
        checkEnabled = function() return true end,                    -- -- 可动态控制是否禁用 / Dynamically enable/disable（如当玩家资源不足时禁用按钮。）
    },
    access = {                                                        -- 访问控制 / Access Control
        tooltip = nil,                                                -- -- 鼠标悬停提示文本 / Tooltip text when hovered
        hotkey = nil,                                                 -- -- 绑定的快捷键 / Keyboard shortcut key
        cooldown = 0,                                                 -- -- 冷却时间，单位为秒 / Time in seconds to block repeated clicks
        repeatable = false,                                           -- -- 是否支持长按重复触发点击 / Enable click repeat when held
        locked = false,                                               -- -- 是否为锁定状态 / Whether it is locked or not
        disabled = false,                                             -- -- 是否禁用按钮 / Whether to disable the button
        clickSound = nil,                                             -- -- 点击音效 / Sound effect to play on click
    },
}

buttonConfig.button = {
    menu = {
        start_game = {
            meta = {
                id = "start_game",
                interface = "menu",
                group = "menu_basic",
                tags = { "game", "start" },
                dependencies = {
                    "modules.gameStateManager",
                    "interface.firstStage",
                },
            },
            content = {
                label = function() return langManager.getText("ui.menu.start_game") end,
            },
            layout = {
                anchor = "center",
                offsetX = 0,
                offsetY = 100
            },
            onClick = {
                "gameStateManager.switchState('firstStage')",
                "firstStage.start()"
            }

        },

        create_room = {
            meta = {
                id = "create_room",
                interface = "menu",
                group = "menu_basic",
                tags = { "game", "create_room" },
                dependencies = {
                    "modules.gameStateManager",
                    "interface.createRoom",
                },
            },
            content = {
                label = function() return langManager.getText("ui.menu.create_room") end,
            },
            layout = {
                anchor = "center",
                offsetX = 0,
                offsetY = 170
            },
            onClick = {}

        },

        quit = {
            meta = {
                id = "quit",
                interface = "menu",
                group = "menu_basic",
                tags = { "quit" },
                dependencies = {},
            },
            content = {
                label = function() return langManager.getText("ui.menu.exit_game") end,
            },
            layout = {
                anchor = "center",
                offsetX = 0,
                offsetY = 240
            },
            onClick = {
                "love.event.quit()"
            }
        },

        settings = {
            meta = {
                id = "settings",
                interface = "menu",
                group = "menu_auxiliary",
                tags = { "settings" },
                dependencies = {},
            },
            content = {
                label = function() return langManager.getText("ui.menu.settings") end,
            },
            layout = {
                anchor = "bottom-left",
                offsetX = 40,
                offsetY = -80,
            },
            onClick = {},
        },

        switchLang = {
            meta = {
                id = "switchLang",
                interface = "menu",
                group = "menu_auxiliary",
                tags = { "language" },
                dependencies = { "modules.langManager" },
            },
            content = {
                label = function() return langManager.getText("ui.menu.switch_lang") end,
            },
            layout = {
                anchor = "bottom-left",
                offsetX = 40,
                offsetY = -140,
            },
            onClick = {
                "langManager.switchLanguage()" -- 切换语言
            },
        },
    },


    createRoomUI = {

    },


    firstStage = {

    }
}

return buttonConfig
