const fs = require('fs');   // 引入 Node.js 中 文件系统 模块

// Map 用于保存所有当前正在运行的房间信息
// Key 是房间 ID（字符串），Value 是房间详细信息对象
const rooms = new Map();

// Set 用于记录已使用过的房间 ID，防止重复
const usedRoomIds = new Set();

/**
 * 生成唯一的纯数字房间 ID，4～5位数字，防止重复
 * @returns {string} 返回如 "5821" 或 "92345" 的字符串形式房间 ID
 */
function generateNumericRoomId() {
    let id;
    do {
        // 生成一个 1000 到 99999 之间的随机整数（4～5位）
        id = Math.floor(Math.random() * 90000) + 1000;
    } while (usedRoomIds.has(id)); // 如果已经使用过，则重新生成

    usedRoomIds.add(id); // 添加到已使用集合中，防止重复
    return id.toString(); // 统一用字符串处理
}

/**
 * 创建一个新房间，并记录其信息到内存和日志
 * @param {string} userDefinedName 用户输入的房间名（可重复）
 * @param {WebSocket} socket WebSocket 连接对象，用于提取创建者 IP
 * @returns {string} 返回生成的唯一房间 ID
 */
function createRoom(userDefinedName, socket) {
    const roomId = generateNumericRoomId(); // 生成唯一的数字房间 ID
    const roomName = userDefinedName || '默认房间'; // 若未传入房间名，则使用默认名
    const creatorIp = socket._socket?.remoteAddress || 'unknown'; // 获取 IP 地址（安全处理）
    const timestamp = new Date().toISOString(); // 当前时间戳

    // 构建房间信息结构
    const roomInfo = {
        roomId,        // 房间唯一 ID（纯数字）
        roomName,      // 用户设定的房间名称
        createdAt: timestamp, // 房间创建时间
        creatorIp,     // 创建者 IP 地址
        users: new Map(), // 该房间内用户列表，后续可加入用户对象
    };

    // 把房间信息保存到全局 rooms Map 中
    rooms.set(roomId, roomInfo);

    // 写入日志文件，便于后期追溯和审计
    const logLine = `[${timestamp}] 房间已创建：ID=${roomId}，房名="${roomName}"，IP=${creatorIp}\n`;
    fs.appendFileSync('room_log.txt', logLine);

    // 控制台打印确认信息
    console.log(`房间已创建：${roomId} - ${roomName}`);
    return roomId; // 返回房间 ID 给调用方（通常发送给客户端）
}

module.exports = {
    createRoom,               // 创建房间函数
    rooms,                    // 当前所有房间 Map（可供其它模块访问）
    generateNumericRoomId,    // 若需要手动调用可单独暴露
};
