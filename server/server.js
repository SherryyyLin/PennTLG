const fs = require('fs');                                   // 引入 Node.js 中 文件系统 模块
const process = require('process');                         // 引入 Node.js 中 进程 模块，用于获取当前进程信息配合锁文件检测进程是否重复
const path = require('path');                               // 引入 Node.js 中 路径 模块
const ws = require('ws');                                   // 引入 Node.js 中 WebSocket 模块


const logger = require('./logger');                         // 引入 日志 模块
const pidLock = require('./pidLock');                       // 引入 PID锁 模块
const portGuard = require('./portGuard');                   // 引入 端口检测 模块
const startServer = require('./startServer');               // 引入 启动 模块

// ---------- 待制作房间管理模块 ----------
// const roomManager = require('./roomManager');               // 引入 房间管理 模块
// const createRoom = roomManager.createRoom;                  // 引入 房间管理 中 创建房间 函数


logger.logInfo('[server]服务器尝试启动');                   // 日志模块初始化，记录服务器启动尝试
pidLock.acquireLock();                                     // 获取服务器PID锁文件，检查进程是否重复


function main() {
    // 调用 portGuard 检查端口并启动服务器
    portGuard.detectAvailablePort(8080, 8, (webSocketServerPort) => {
        startServer(webSocketServerPort);
    });
}


main();