#!/bin/bash

# Kong停止脚本

echo "🛑 停止Kong API网关"
echo "=================="

cd /home/ubuntu/Rainbow-Hub/Rainbow-Gateway

# 尝试优雅停止
echo "正在停止Kong..."
if kong stop -c clean-kong.conf 2>/dev/null; then
    echo "✅ Kong已优雅停止"
else
    echo "⚠️ 优雅停止失败，尝试强制停止..."
    
    # 强制停止进程
    pkill -f kong 2>/dev/null && echo "✅ Kong进程已终止" || echo "ℹ️ 没有Kong进程在运行"
fi

# 等待进程完全停止
sleep 2

# 验证停止状态
echo ""
echo "🔍 验证停止状态:"

if pgrep -f kong > /dev/null; then
    echo "❌ Kong进程仍在运行"
    echo "进程ID: $(pgrep -f kong | tr '\n' ' ')"
    echo "强制终止: sudo kill -9 $(pgrep -f kong)"
else
    echo "✅ Kong进程已完全停止"
fi

# 检查端口
if netstat -tln 2>/dev/null | grep -q ":800[01] "; then
    echo "❌ 端口仍被占用"
    netstat -tln | grep ":800[01] "
else
    echo "✅ 端口已释放"
fi

echo ""
echo "🧹 是否清理工作目录? (y/N)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "清理工作目录..."
    rm -rf /home/ubuntu/kong-runtime/*
    echo "✅ 工作目录已清理"
fi

echo ""
echo "✨ Kong已完全停止"