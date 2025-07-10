#!/bin/bash

# Kong强制停止脚本

echo "🔥 强制停止Kong API网关"
echo "====================="

echo "🔍 查找Kong/Nginx进程..."

# 查找所有相关进程
KONG_PIDS=$(pgrep -f kong 2>/dev/null)
NGINX_PIDS=$(pgrep -f "nginx.*Rainbow-Hub" 2>/dev/null)

echo "Kong进程: ${KONG_PIDS:-无}"
echo "Nginx进程: ${NGINX_PIDS:-无}"

# 强制停止Kong进程
if [ -n "$KONG_PIDS" ]; then
    echo "💀 强制终止Kong进程..."
    echo "$KONG_PIDS" | xargs kill -9 2>/dev/null
    echo "✅ Kong进程已终止"
fi

# 强制停止相关的nginx进程
if [ -n "$NGINX_PIDS" ]; then
    echo "💀 强制终止Nginx进程..."
    echo "$NGINX_PIDS" | xargs sudo kill -9 2>/dev/null || echo "$NGINX_PIDS" | xargs kill -9 2>/dev/null
    echo "✅ Nginx进程已终止"
fi

# 特殊处理：直接终止特定的nginx进程
if ps aux | grep "nginx.*Rainbow-Hub" | grep -v grep > /dev/null; then
    echo "💀 发现遗留的nginx进程，强制终止..."
    pkill -9 -f "nginx.*Rainbow-Hub" 2>/dev/null
fi

# 等待进程完全停止
sleep 2

echo ""
echo "🔍 验证停止状态..."

# 检查进程
if pgrep -f kong > /dev/null || pgrep -f "nginx.*Rainbow-Hub" > /dev/null; then
    echo "❌ 仍有进程在运行:"
    ps aux | grep -E "(kong|nginx.*Rainbow-Hub)" | grep -v grep
    echo ""
    echo "🔧 手动终止命令:"
    echo "  sudo pkill -9 -f kong"
    echo "  sudo pkill -9 -f nginx"
else
    echo "✅ 所有进程已停止"
fi

# 检查端口
echo ""
echo "🔍 检查端口状态..."
if netstat -tln | grep -E ":800[01] " > /dev/null; then
    echo "⚠️ 端口仍被占用:"
    netstat -tln | grep -E ":800[01] "
    echo ""
    echo "💡 端口通常会在进程停止后自动释放，请等待几秒钟"
else
    echo "✅ 端口已释放"
fi

echo ""
echo "🧹 清理工作目录..."

# 清理可能的lock文件
rm -f /home/ubuntu/Rainbow-Hub/Rainbow-Gateway/pids/nginx.pid 2>/dev/null
rm -f /home/ubuntu/kong-runtime/pids/nginx.pid 2>/dev/null

echo "✅ 临时文件已清理"

echo ""
echo "✨ Kong强制停止完成！"
echo "现在可以重新启动Kong了"