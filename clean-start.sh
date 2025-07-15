#!/bin/bash

# Kong干净启动脚本 - 工作文件分离版 + 证书自动生成

echo "🌈 启动Kong API网关 (干净版 - 工作文件分离)"
echo "==========================================="

# 设置目录变量
GATEWAY_DIR="/home/ubuntu/Rainbow-Hub/Rainbow-Gateway"
KONG_RUNTIME="/home/ubuntu/kong-runtime"
SSL_DIR="$KONG_RUNTIME/ssl"
LMDB_DIR="$KONG_RUNTIME/lmdb"



# 进入Gateway目录
cd "$GATEWAY_DIR"

# 创建Kong专用工作目录
echo "📁 创建Kong工作目录..."
mkdir -p "$KONG_RUNTIME"/{logs,pids,temp,temp/client_body_temp,temp/proxy_temp,temp/fastcgi_temp,temp/uwsgi_temp,temp/scgi_temp}
mkdir -p "$SSL_DIR"
mkdir -p "$LMDB_DIR"
chmod 755 "$LMDB_DIR"
export KONG_USER=$(whoami)
export TMPDIR="$LMDB_DIR"

# 设置权限
chmod 755 "$KONG_RUNTIME"
chmod 755 "$KONG_RUNTIME"/*

# 设置ulimit
ulimit -n 4096

# 自动生成 RSA + ECDSA 证书（避免企业版报错）
echo "🔐 检查并生成默认 SSL 证书..."
if [ ! -f "$SSL_DIR/admin-gui-kong-default.crt" ]; then
    echo "  ➤ 生成 RSA 证书..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/admin-gui-kong-default.key" \
        -out "$SSL_DIR/admin-gui-kong-default.crt" \
        -subj "/CN=localhost"
fi

if [ ! -f "$SSL_DIR/admin-gui-kong-default-ecdsa.crt" ]; then
    echo "  ➤ 生成 ECDSA 证书..."
    openssl ecparam -genkey -name prime256v1 \
        -out "$SSL_DIR/admin-gui-kong-default-ecdsa.key"

    openssl req -new -x509 \
        -key "$SSL_DIR/admin-gui-kong-default-ecdsa.key" \
        -out "$SSL_DIR/admin-gui-kong-default-ecdsa.crt" \
        -days 365 -subj "/CN=localhost"
fi

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
    
    echo "⏳ 等待Kong完全启动..."
    sleep 3
    
    echo ""
    echo "🔍 验证Kong状态..."
    
    if pgrep -f kong > /dev/null; then
        echo "✅ Kong进程运行中"
        
        if netstat -tln 2>/dev/null | grep -q ":8001 "; then
            echo "✅ 管理端口(8001)已监听"
            
            if netstat -tln 2>/dev/null | grep -q ":8000 "; then
                echo "✅ 代理端口(8000)已监听"
                
                sleep 2
                if timeout 5 curl -s http://127.0.0.1:8001/ > /dev/null; then
                    echo "✅ Kong API响应正常"
                else
                    echo "⚠️ Kong API响应慢，但服务已启动"
                fi
            fi
        fi
        
        echo ""
        echo "📁 工作目录内容:"
        ls -la "$KONG_RUNTIME"/ 2>/dev/null || echo "  工作目录访问失败"
        
        echo ""
        echo "🌟 Kong API网关启动成功！"
        echo "============================="
        echo "📍 服务地址:"
        echo "  代理: http://127.0.0.1:8000"
        echo "  管理: http://127.0.0.1:8001"
        echo ""
    else
        echo "❌ Kong进程未运行"
    fi
    
else
    echo "❌ Kong启动失败"
    echo ""
    echo "🔍 排查步骤:"
    echo "  1. kong config parse simple-kong.yml"
    echo "  2. tail -f $KONG_RUNTIME/logs/error.log"
    echo "  3. 检查权限: ls -la $KONG_RUNTIME"
    echo "  4. 手动启动: kong start -c clean-kong.conf --v"
    exit 1
fi
