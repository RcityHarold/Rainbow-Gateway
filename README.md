# Rainbow Hub Kong API网关

## 概述

这是Rainbow Hub项目的统一API网关，基于Kong Enterprise 3.10.0.3构建。

## 文件说明

| 文件 | 用途 |
|------|------|
| `clean-kong.conf` | Kong主配置文件（工作文件分离） |
| `simple-kong.yml` | 服务和路由声明式配置 |
| `clean-start.sh` | 启动Kong网关 |
| `stop-kong.sh` | 优雅停止Kong |
| `force-stop.sh` | 强制停止Kong |
| `README-Kong-Gateway.md` | 详细使用指南 |

## 快速使用

### 启动网关
```bash
./clean-start.sh
```

### 停止网关
```bash
./stop-kong.sh
```

### 强制停止（如果正常停止失败）
```bash
./force-stop.sh
```

## 网关地址

- **代理入口**: http://127.0.0.1:8000
- **管理API**: http://127.0.0.1:8001

## 路由配置

- `/api/auth/*` → Rainbow-Auth服务 (localhost:8080)
- `/api/docs/*` → Rainbow-Docs服务 (localhost:3000)

## 目录结构

```
Rainbow-Gateway/          # 配置文件目录（干净）
├── clean-kong.conf       # Kong配置
├── simple-kong.yml       # 服务配置
├── clean-start.sh        # 启动脚本
├── stop-kong.sh          # 停止脚本
├── force-stop.sh         # 强制停止脚本
└── README.md             # 本文档

/home/ubuntu/kong-runtime/  # Kong工作目录
├── logs/                   # 日志文件
├── pids/                   # 进程文件
├── ssl/                    # SSL证书
└── temp/                   # 临时文件
```

## 故障排除

1. **启动失败**：查看日志 `tail -f /home/ubuntu/kong-runtime/logs/error.log`
2. **端口占用**：使用 `./force-stop.sh` 强制停止
3. **权限问题**：确保当前用户有读写kong-runtime目录的权限

## 下一步

1. 启动后端服务：Rainbow-Auth (8080) 和 Rainbow-Docs (3000)
2. 启动前端应用，配置代理到 Kong 网关 (8000)
3. 测试完整的微服务架构

更多详细信息请参考 `README-Kong-Gateway.md`。