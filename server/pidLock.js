// PidLock.js
// 模块功能：检测和管理服务器进程的 PID 锁文件，防止服务器重复启动

const fs = require('fs');
const process = require('process');
const path = require('path');
const logger = require('./logger');

/** PID锁文件路径 */
const lockFilePath = path.join(__dirname, '.server.lock');

/** 获取锁文件 */
function acquireLock() {
    if (fs.existsSync(lockFilePath)) {
        /** 尝试读取到的锁文件PID */
        const pid = parseInt(fs.readFileSync(lockFilePath, 'utf-8'));                   // 读取锁文件中的PID值
        try {
            process.kill(pid, 0);                                                       // 检查进程是否存活
            console.error(`检测到已有服务器进程PID=${pid}，终止启动。`);
            logger.logError(`[pidLock]101-检测到已有服务器进程PID=${pid}，终止启动。`);
            process.exit(101);                                                          // 服务器进程运行中，错误码：101
        } catch (e) {
            // 进程不存在，脏锁文件，继续启动
            console.warn(`检测到旧锁文件，对应进程PID=${pid} 不存在，继续启动。`);
            logger.logWarn(`[pidLock]102-检测到旧锁文件，对应进程PID=${pid} 不存在，继续启动。`);
            fs.unlinkSync(lockFilePath);                                                // 删除无效锁文件
        }
    }

    fs.writeFileSync(lockFilePath, process.pid.toString(), 'utf-8');                    // 写入当前进程PID到锁文件
    console.log(`写入服务器PID锁文件，进程PID=${process.pid}`);
    logger.logInfo(`[pidLock]写入服务器PID锁文件，进程PID=${process.pid}`);
}

/** 释放锁文件 */
function releaseLock() {
    if (fs.existsSync(lockFilePath)) {
        fs.unlinkSync(lockFilePath);
        console.log('服务器准备关闭，已清理 PID 锁文件');
        logger.logInfo('[pidLock]服务器准备关闭，已清理 PID 锁文件');
    }
}

module.exports = {
    acquireLock,
    releaseLock,
    lockFilePath
};
