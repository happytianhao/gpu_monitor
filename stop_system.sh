#!/bin/bash

# GPU监控系统停止工具
# 用于停止gpu_monitor.sh和gpu_burner.py进程

echo "🛑 GPU监控系统停止工具"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 停止GPU监控脚本
echo -e "${YELLOW}正在查找GPU监控脚本进程...${NC}"
MONITOR_PIDS=$(pgrep -f "gpu_monitor.sh" | grep -v $$)

if [ -n "$MONITOR_PIDS" ]; then
    echo -e "${YELLOW}找到GPU监控脚本进程: $(echo $MONITOR_PIDS | tr '\n' ' ')${NC}"
    kill $MONITOR_PIDS 2>/dev/null
    sleep 2
    if ! pgrep -f "gpu_monitor.sh" | grep -v $$ >/dev/null; then
        echo -e "${GREEN}✓ GPU监控脚本已停止${NC}"
    else
        echo -e "${RED}✗ GPU监控脚本停止失败${NC}"
    fi
else
    echo -e "${GREEN}✓ GPU监控脚本未在运行${NC}"
fi

# 停止GPU占用程序
echo -e "${YELLOW}正在查找GPU占用程序进程...${NC}"
BURNER_PIDS=$(pgrep -f "gpu_burner.py" | grep -v $$)

if [ -n "$BURNER_PIDS" ]; then
    echo -e "${YELLOW}找到GPU占用程序进程: $(echo $BURNER_PIDS | tr '\n' ' ')${NC}"
    kill $BURNER_PIDS 2>/dev/null
    sleep 2
    if ! pgrep -f "gpu_burner.py" | grep -v $$ >/dev/null; then
        echo -e "${GREEN}✓ GPU占用程序已停止${NC}"
    else
        echo -e "${RED}✗ GPU占用程序停止失败${NC}"
    fi
else
    echo -e "${GREEN}✓ GPU占用程序未在运行${NC}"
fi

# 清理PID文件
echo -e "${YELLOW}清理PID文件...${NC}"
if [ -f "log/gpu_burner.pid" ]; then
    rm -f "log/gpu_burner.pid"
    echo -e "${GREEN}✓ 已删除 log/gpu_burner.pid${NC}"
fi

echo ""
echo "================================"
echo -e "${GREEN}🎉 GPU监控系统已停止! ${NC}"
echo ""
echo "如需重新启动，请运行："
echo "  ./gpu_monitor.sh          # 前台运行"
echo "  ./gpu_monitor_nohup.sh    # 后台运行"
