#!/bin/bash

# Kong干净启动脚本 - 工作文件分离版

echo "🌈 启动Kong API网关 (干净版 - 工作文件分离)"
echo "==========================================="

# 设置目录变量
GATEWAY_DIR="/home/ubuntu/Rainbow-Hub/Rainbow-Gateway"
KONG_RUNTIME="/home/ubuntu/kong-runtime"

# 进入Gateway目录
cd "$GATEWAY_DIR"

# 创建Kong专用工作目录
echo "📁 创建Kong工作目录..."
mkdir -p "$KONG_RUNTIME"/{logs,pids,ssl,temp,temp/client_body_temp,temp/proxy_temp,temp/fastcgi_temp,temp/uwsgi_temp,temp/scgi_temp}

# 设置权限
chmod 755 "$KONG_RUNTIME"
chmod 755 "$KONG_RUNTIME"/*

# 设置ulimit
ulimit -n 4096

# 显示目录结构
echo "📊 目录结构:"
echo "  配置目录: $GATEWAY_DIR"
echo "  工作目录: $KONG_RUNTIME"

# 停止现有Kong
echo ""
echo "🛑 停止现有Kong..."
kong stop 2>/dev/null || true
pkill -f kong 2>/dev/null || true
sleep 2

# 清理旧的工作文件（如果在Gateway目录下）
echo "🧹 清理Gateway目录下的运行文件..."
rm -rf "$GATEWAY_DIR"/logs "$GATEWAY_DIR"/pids "$GATEWAY_DIR"/ssl \
       "$GATEWAY_DIR"/*_temp "$GATEWAY_DIR"/nginx*.conf \
       "$GATEWAY_DIR"/dbless.lmdb "$GATEWAY_DIR"/sockets \
       "$GATEWAY_DIR"/gui "$GATEWAY_DIR"/profiling 2>/dev/null

# 检查配置文件
if [ ! -f "clean-kong.conf" ]; then
    echo "❌ clean-kong.conf文件不存在"
    exit 1
fi

if [ ! -f "simple-kong.yml" ]; then
    echo "❌ simple-kong.yml文件不存在"
    exit 1
fi

echo "📋 使用配置:"
echo "  Kong配置: clean-kong.conf"
echo "  服务配置: simple-kong.yml"

# 启动Kong
echo ""
echo "🚀 启动Kong (工作文件将保存在 $KONG_RUNTIME)..."

if kong start -c clean-kong.conf; then
    echo "✅ Kong启动成功！"
    
    # 等待Kong完全启动
    echo "⏳ 等待Kong完全启动..."
    sleep 3
    
    # 验证Kong状态
    echo ""
    echo "🔍 验证Kong状态..."
    
    # 检查进程
    if pgrep -f kong > /dev/null; then
        echo "✅ Kong进程运行中"
        
        # 检查端口
        if netstat -tln 2>/dev/null | grep -q ":8001 "; then
            echo "✅ Kong管理端口(8001)已监听"
            
            if netstat -tln 2>/dev/null | grep -q ":8000 "; then
                echo "✅ Kong代理端口(8000)已监听"
                
                # 测试API
                sleep 2
                if timeout 5 curl -s http://127.0.0.1:8001/ > /dev/null; then
                    echo "✅ Kong API响应正常"
                else
                    echo "⚠️ Kong API响应慢，但服务已启动"
                fi
            fi
        fi
        
        # 显示目录内容
        echo ""
        echo "📁 工作目录内容:"
        ls -la "$KONG_RUNTIME"/ 2>/dev/null || echo "  工作目录访问失败"
        
        echo ""
        echo "📁 Gateway目录保持干净:"
        echo "  配置文件数量: $(ls -1 "$GATEWAY_DIR"/*.conf "$GATEWAY_DIR"/*.yml "$GATEWAY_DIR"/*.sh 2>/dev/null | wc -l)"
        echo "  运行文件: 已移至 $KONG_RUNTIME"
        
        echo ""
        echo "🌟 Kong API网关启动成功！"
        echo "============================="
        echo "📍 服务地址:"
        echo "  代理: http://127.0.0.1:8000"
        echo "  管理: http://127.0.0.1:8001"
        echo ""
        echo "📁 目录分离:"
        echo "  配置文件: $GATEWAY_DIR"
        echo "  运行文件: $KONG_RUNTIME"
        echo ""
        echo "🧪 测试命令:"
        echo "  curl http://127.0.0.1:8001/"
        echo "  curl http://127.0.0.1:8000/api/auth/"
        echo ""
        echo "📝 日志位置:"
        echo "  错误日志: tail -f $KONG_RUNTIME/logs/error.log"
        echo "  访问日志: tail -f $KONG_RUNTIME/logs/access.log"
        echo ""
        echo "🛑 停止命令:"
        echo "  kong stop -c clean-kong.conf"
        
    else
        echo "❌ Kong进程启动失败"
        echo "📝 查看日志: tail -f $KONG_RUNTIME/logs/error.log"
    fi
    
else
    echo "❌ Kong启动失败"
    echo ""
    echo "🔍 排查步骤:"
    echo "  1. 检查配置: kong config parse simple-kong.yml"
    echo "  2. 查看日志: tail -f $KONG_RUNTIME/logs/error.log"
    echo "  3. 检查权限: ls -la $KONG_RUNTIME"
    echo "  4. 手动启动: kong start -c clean-kong.conf --v"
    exit 1
fi