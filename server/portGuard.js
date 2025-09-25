// portGuard.js
// 模块功能：检测可用端口（默认从 8080 开始最多尝试 8 个），成功后调用启动回调


const http = require('http');                   // 引入 Node.js 中 HTTP 模块，用于检测端口占用情况
const logger = require('./logger');             // 引入 日志 模块
/** @param {number} 检测后选定的服务器端口 */
let webSocketServerPort = null;                 // Websocket服务器使用端口

/**
 * 检测端口可用性，依次尝试备用端口，成功后调用 callback 启动服务器
 * @param {number} baseWebSocketServerPort - 起始端口（默认8080）
 * @param {number} maxAttempts - 最大尝试次数（默认8）
 * @param {function} startCallback - 成功选定端口后直接调用启动服务器函数（参数为 webSocketServerPort）
 */
function detectAvailablePort(baseWebSocketServerPort = 8080, maxAttempts = 8, startCallback) {
    // 检查参数合法性
    if (typeof baseWebSocketServerPort !== 'number' || typeof maxAttempts !== 'number') {
        logger.logError(`[portGuard]115-baseWebSocketServerPort 和 maxAttempts 必须是数字`);
        throw new Error('baseWebSocketServerPort 和 maxAttempts 必须是数字');
    }
    if (typeof startCallback !== 'function') {
        logger.logError(`[portGuard]116-startCallback 必须是函数`);
        throw new Error('startCallback 必须是函数');
    }

    /** 端口候选列表 */
    const candidatePorts = Array.from({ length: maxAttempts }, (_, i) => baseWebSocketServerPort + i);
    console.log(`候选列表：${candidatePorts}`);                     // 打印候选端口列表
    logger.logInfo(`[portGuard]候选端口列表：${candidatePorts}`);   // 打印候选端口列表

    // 递归尝试下一个端口
    function tryNext(ports) {
        if (ports.length === 0) {
            console.error('没有可用端口，服务器无法启动');
            logger.logError('[portGuard]111-没有可用端口，服务器无法启动');
            process.exit(111);
        }

        const port = ports.shift();             // 取出当前尝试的端口
        const tester = http.createServer();     // 创建测试服务器来监听端口

        tester.once('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                console.warn(`端口 ${port} 已被占用，尝试下一个`);
                logger.logWarn(`[portGuard]112-端口 ${port} 已被占用，尝试下一个`);
                tryNext(ports);                 // 尝试下一个端口
            } else {
                console.error(`检测端口 ${port} 时发生错误：`, err);
                logger.logError(`[portGuard]113-检测端口 ${port} 时发生错误：${err.message}`);
                process.exit(113);
            }
        });

        tester.listen(port, () => {
            console.log(`端口 ${port} 可用，临时服务器关闭`);
            logger.logInfo(`[portGuard]端口 ${port} 可用，临时服务器关闭`);
            webSocketServerPort = port;         // 设置服务器使用端口
            tester.close();                     // 关闭临时服务器
            startCallback(webSocketServerPort); // 调用外部提供的启动函数
        });
    }

    tryNext(candidatePorts);                          // 开始尝试检测端口可用性
}

module.exports = {
    detectAvailablePort,
    webSocketServerPort,
};
