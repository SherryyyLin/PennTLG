// startServer.js
// 模块功能：创建并启动 WebSocket 服务器，并对服务器连接等事件进行响应。

const http = require('http');           // 引入 Node.js 中 HTTP 模块，用于创建基础 HTTP 服务器
const ws = require('ws');               // 引入 Node.js 中 ws 模块，用于创建 WebSocket 服务器
const logger = require('./logger');     // 引入日志模块
const portGuard = require('./portGuard'); // 引入端口检测模块


/**
 * 启动 WebSocket 服务器
 * @param {number} port - 端口号（由 portGuard 检测后传入）
 * @param {function} [onReadyCallback=null] - 可选参数，服务器成功启动后执行的回调函数，参数为 webSocketServer 实例
 * @returns {object} - 返回包含 HTTP server 和 WebSocket server 的对象，便于后续管理
 */
function startServer(port, onReadyCallback = null) {

    // 创建 HTTP 服务器
    const httpServer = http.createServer();

    // 基于 HTTP 服务器创建 WebSocket 服务器实例
    const webSocketServer = new ws.Server({ server: httpServer });

    // 监听新的 WebSocket 客户端连接
    webSocketServer.on('connection', (wsConnection, req) => {
        const clientIP = req.socket.remoteAddress; // 获取客户端的 IP 地址
        console.log(`[startServer]客户端已连接：${clientIP}`);
        logger.log(`[startServer]客户端已连接：${clientIP}`);

        // 监听客户端发送的消息
        wsConnection.on('message', (message) => {
            console.log(`[startServer]收到消息：${message}`);
            logger.logInfo(`[startServer]收到消息：${message}`);
            wsConnection.send(`[startServer]服务器收到：${message}`); // 原样返回收到的消息(回声回应)
        });

        // 监听客户端断开连接事件
        wsConnection.on('close', () => {
            console.log(`[startServer]客户端断开连接：${clientIP}`);
            logger.logInfo(`[startServer]客户端断开连接：${clientIP}`);
        });
    });

    // 启动服务器监听指定端口
    httpServer.listen(port, () => {
        console.log(`[startServer]服务器已启动，地址为 ws://localhost:${port}`);
        logger.logInfo(`[startServer]服务器已启动，监听端口 ${port}`); // 启动成功提示
        // 如果传入了回调函数，则在服务器启动后执行
        if (onReadyCallback) onReadyCallback(webSocketServer);
    });

    // 返回 WebSocket 和 HTTP 服务实例，方便外部模块操作（例如关闭或广播）
    return { httpServer, webSocketServer };
}


// 导出 startServer 函数供外部调用（如 server.js）
module.exports = startServer;
