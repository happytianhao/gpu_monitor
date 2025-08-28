#!/bin/bash

# GPU监控脚本停止工具
# 用于停止gpu_monitor.sh和gpu_burner.py进程

echo "🛑 GPU监控脚本停止工具"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数：停止进程
stop_process() {
    local process_name=$1
    local display_name=$2
    
    echo -e "${YELLOW}正在查找 $display_name 进程...${NC}"
    
    # 查找进程
    local pids=$(pgrep -f "$process_name")
    
    if [ -z "$pids" ]; then
        echo -e "${GREEN}✓ $display_name 未在运行${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}找到以下进程:${NC}"
    echo "$pids" | while read pid; do
        echo "  PID: $pid"
    done
    
    # 尝试优雅停止
    echo -e "${YELLOW}正在停止 $display_name 进程...${NC}"
    echo "$pids" | while read pid; do
        kill "$pid" 2>/dev/null
    done
    
    # 等待3秒
    sleep 3
    
    # 检查是否还有进程在运行
    local remaining_pids=$(pgrep -f "$process_name")
    if [ -n "$remaining_pids" ]; then
        echo -e "${YELLOW}进程仍在运行，使用强制停止...${NC}"
        echo "$remaining_pids" | while read pid; do
            kill -9 "$pid" 2>/dev/null
        done
        sleep 1
    fi
    
    # 最终检查
    local final_check=$(pgrep -f "$process_name")
    if [ -z "$final_check" ]; then
        echo -e "${GREEN}✓ $display_name 已成功停止${NC}"
    else
        echo -e "${RED}✗ $display_name 停止失败${NC}"
        return 1
    fi
}

# 函数：清理PID文件
cleanup_pid_files() {
    echo -e "${YELLOW}清理PID文件...${NC}"
    
    if [ -f "log/gpu_burner.pid" ]; then
        rm -f "log/gpu_burner.pid"
        echo -e "${GREEN}✓ 已删除 log/gpu_burner.pid${NC}"
    fi
}

# 主程序
main() {
    # 停止GPU监控脚本
    stop_process "gpu_monitor.sh" "GPU监控脚本"
    
    # 停止GPU占用程序
    stop_process "gpu_burner.py" "GPU占用程序"
    
    # 清理PID文件
    cleanup_pid_files
    
    echo ""
    echo "================================"
    echo -e "${GREEN}🎉 所有相关进程已停止！${NC}"
    echo ""
    echo "如需重新启动，请运行："
    echo "  ./gpu_monitor.sh          # 前台运行"
    echo "  ./gpu_monitor_nohup.sh    # 后台运行"
}

# 检查是否在正确的目录
if [ ! -f "gpu_monitor.sh" ]; then
    echo -e "${RED}错误: 请在gpu_monitor目录下运行此脚本${NC}"
    exit 1
fi

# 运行主程序
main
