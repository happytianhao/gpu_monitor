#!/bin/bash

# 配置
LOG_DIR="log"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 使用 nohup 命令确保脚本在终端关闭后继续运行
# 将标准输出（>）和标准错误（2>&1）重定向到指定的日志文件
# 最后使用 & 符号将整个命令放到后台执行
nohup ./gpu_monitor.sh > "$LOG_DIR/monitor_output.log" 2>&1 &
