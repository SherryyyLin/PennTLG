// logger.js
// 模块功能：用于记录服务器运行日志

const fs = require('fs');       // 引入 Node.js 中 文件系统 模块
const path = require('path');   // 引入 Node.js 中 路径 模块


// -------------------- 日志文件大小限制（单位：字节） --------------------
const MAX_LOG_SIZE = 1024 * 1024 * 5;                                   // 5MB
// -------------------- 日志文件大小限制（单位：字节） --------------------


// 日志目录文件夹存在检查
const logDir = path.join(__dirname, '..', 'logs');  // 日志目录文件夹路径，TLG/logs/
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });      // 检查 logs/ 目录，若不存在则创建，recursive: true 表示递归创建父目录
}


// 日志基础文件名生成
const baseTimestamp = new Date().toISOString().replace(/:/g, '-');      // 获取当前时间戳，格式化为 ISO 字符串，并替换冒号为短横线
const baseFileName = `server_${baseTimestamp}.log`;  // 日志文件基础名称，格式为 server_YYYY-MM-DDTHH-MM-SS.log
let part = 1;                                                           // 日志文件分割标记，默认为 1


/** 当前日志文件路径及名称 */
function getCurrentLogPath() {
    return path.join(logDir, `${baseFileName}_part${part}.log`);        // 返回当前日志文件路径及名称
}

// 检查日志文件大小，如果超过限制则分割
/** 获取当前日志文件的大小（单位：字节） */
function getCurrentFileSize() {
    try {
        return fs.statSync(getCurrentLogPath()).size;
    } catch (err) {
        return 0; // 文件还没创建，视为0
    }
}


/**
 * 写入日志
 * @param {string} logMessage - 日志信息
 * @param {string} logLevel - 日志等级（INFO, WARN, ERROR）
 */
function log(logMessage, logLevel = 'INFO') {
    const logTime = new Date().toISOString().replace(/:/g, '-');    // 获取当前时间戳，格式化为 ISO 字符串，并替换冒号为短横线
    const logLine = `[${logLevel}] [${logTime}] ${logMessage}\n`;   // 构建日志行，格式为 [等级] [时间戳] 消息内容，并自动换行
    // 如果当前日志文件大小超过阈值切换到新文件
    if (getCurrentFileSize() + Buffer.byteLength(logLine, 'utf8') > MAX_LOG_SIZE) {
        part++;                                                     // 增加 part 编号
    }
    fs.appendFileSync(getCurrentLogPath(), logLine);                // 将日志行写入当前日志文件，不存在日志文件则创建
}


// 快捷调用封装
/** 写入Info日志
 *  @param {string} logMessage - 日志信息
 */
function logInfo(logMessage) { log(logMessage, 'INFO'); }

/** 写入Warn日志
 *  @param {string} logMessage - 日志信息
 */
function logWarn(logMessage) { log(logMessage, 'WARN'); }

/** 写入Error日志
 *  @param {string} logMessage - 日志信息
 */
function logError(logMessage) { log(logMessage, 'ERROR'); }


// 暴露模块接口
module.exports = {
    log,
    logInfo,
    logWarn,
    logError
};