#!/bin/bash

# 配置
LOG_DIR="log"
LOG_FILE="$LOG_DIR/gpu_usage_$(date +%Y%m%d).log"
SUMMARY_LOG="$LOG_DIR/gpu_daily_summary.log"
INTERVAL=10
GPU_BURNER_SCRIPT="gpu_burner.py" # 替换为gpu_burner.py的实际路径
GPU_BURNER_PID_FILE="$LOG_DIR/gpu_burner.pid"
LAST_GPU_INDEX=$(( $(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | tail -n 1) - 1 ))

# >>>>>> 指定你的 Conda 环境名称 <<<<<<
CONDA_ENV_NAME="torch" # 请将此替换为你的 Conda 环境名称

# >>>>>> 禁用时间段配置 <<<<<<
RESTRICTED_START_HOUR=18  # 禁用开始时间（24小时制）
RESTRICTED_END_HOUR=21    # 禁用结束时间（24小时制）

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 获取当前日期，用于每日统计
CURRENT_DATE=$(date +%Y%m%d)

# 初始化今日GPU使用时长 (单位：秒)
GPU_USED_TODAY_SECONDS=0

# 函数：启动GPU占用程序
start_gpu_burner() {
    if [ ! -f "$GPU_BURNER_PID_FILE" ]; then
        echo "$(date): Starting GPU burner on GPU $LAST_GPU_INDEX using Conda env: $CONDA_ENV_NAME..." | tee -a "$LOG_FILE"

        # 检查conda环境是否存在
        if ! conda env list | grep -q "^$CONDA_ENV_NAME "; then
            echo "$(date): ERROR: Conda environment '$CONDA_ENV_NAME' not found. Please check your conda environment configuration." | tee -a "$LOG_FILE"
            echo "$(date): Available environments:" | tee -a "$LOG_FILE"
            conda env list | tee -a "$LOG_FILE"
            return 1
        fi
        
        # 测试conda环境是否能正常运行Python
        if ! conda run -n "$CONDA_ENV_NAME" python --version > /dev/null 2>&1; then
            echo "$(date): ERROR: Cannot run Python in conda environment '$CONDA_ENV_NAME'. Environment may be corrupted." | tee -a "$LOG_FILE"
            return 1
        fi
        
        # 测试conda环境是否能导入torch
        if ! conda run -n "$CONDA_ENV_NAME" python -c "import torch; print('PyTorch version:', torch.__version__)" > /dev/null 2>&1; then
            echo "$(date): ERROR: Cannot import torch in conda environment '$CONDA_ENV_NAME'. PyTorch may not be installed." | tee -a "$LOG_FILE"
            echo "$(date): Please install PyTorch in the '$CONDA_ENV_NAME' environment." | tee -a "$LOG_FILE"
            return 1
        fi
        
        # 测试CUDA是否可用
        if ! conda run -n "$CONDA_ENV_NAME" python -c "import torch; print('CUDA available:', torch.cuda.is_available())" > /dev/null 2>&1; then
            echo "$(date): WARNING: CUDA may not be available in conda environment '$CONDA_ENV_NAME'." | tee -a "$LOG_FILE"
        fi
        
        # 将 PID 文件路径作为第二个参数传递给 Python 脚本
        # nohup 让程序在后台运行，> /dev/null 2>&1 隐藏输出
        nohup conda run -n "$CONDA_ENV_NAME" python "$GPU_BURNER_SCRIPT" "$LAST_GPU_INDEX" "$GPU_BURNER_PID_FILE" > /dev/null 2>&1 &
        
        # 等待一小段时间，确保Python进程有时间写入PID文件
        sleep 5

        # 直接从 PID 文件中读取进程号
        if [ -f "$GPU_BURNER_PID_FILE" ]; then
            BURNER_PID=$(cat "$GPU_BURNER_PID_FILE")
            # 再次检查 PID 是否真实存在，防止读取到旧的或不正确的PID
            if ps -p "$BURNER_PID" > /dev/null; then
                echo "$(date): GPU burner started with actual Python PID $BURNER_PID" | tee -a "$LOG_FILE"
            else
                echo "$(date): ERROR: PID file contains $BURNER_PID, but process not found. Script might not have started correctly." | tee -a "$LOG_FILE"
                rm "$GPU_BURNER_PID_FILE" # 清理无效的PID文件
            fi
        else
            echo "$(date): ERROR: PID file ($GPU_BURNER_PID_FILE) not created. Script might not have started correctly." | tee -a "$LOG_FILE"
        fi
    else
        echo "$(date): GPU burner is already running (PID $(cat "$GPU_BURNER_PID_FILE"))" | tee -a "$LOG_FILE"
    fi
}

# 函数：停止GPU占用程序
stop_gpu_burner() {
    if [ -f "$GPU_BURNER_PID_FILE" ]; then
        PID=$(cat "$GPU_BURNER_PID_FILE")
        if ps -p $PID > /dev/null; then
            echo "$(date): Stopping GPU burner (PID $PID)..." | tee -a "$LOG_FILE"
            kill $PID
            rm "$GPU_BURNER_PID_FILE"
            echo "$(date): GPU burner stopped." | tee -a "$LOG_FILE"
        else
            echo "$(date): GPU burner PID file found, but process $PID not running. Cleaning up." | tee -a "$LOG_FILE"
            rm "$GPU_BURNER_PID_FILE"
        fi
    fi
}

# 函数：检查是否在暂停时间段内
is_restricted_time() {
    local current_hour=$(date +%H)
    if [ "$current_hour" -ge "$RESTRICTED_START_HOUR" ] && [ "$current_hour" -lt "$RESTRICTED_END_HOUR" ]; then
        return 0  # 在限制时间内，返回true
    else
        return 1  # 不在限制时间内，返回false
    fi
}

# 函数：计算每日GPU使用率
calculate_daily_usage() {
    local day_to_calculate=$1
    local total_seconds_in_day=86400 # 24 * 60 * 60

    # 从当天的日志文件中 grep 出包含 "GPU in use" 的行，并计算行数
    local usage_intervals=$(grep "GPU in use" "$LOG_DIR/gpu_usage_${day_to_calculate}.log" | wc -l)
    local used_seconds=$((usage_intervals * INTERVAL))
    local usage_percentage=$(awk "BEGIN {printf \"%.2f\", ($used_seconds / $total_seconds_in_day) * 100}")

    echo "---" >> "$SUMMARY_LOG"
    echo "$(date): Daily GPU usage summary for $day_to_calculate:" | tee -a "$SUMMARY_LOG"
    echo "  Total GPU usage time: $((used_seconds / 3600)) hours $(( (used_seconds % 3600) / 60 )) minutes $((used_seconds % 60)) seconds" | tee -a "$SUMMARY_LOG"
    echo "  GPU usage percentage: ${usage_percentage}%" | tee -a "$SUMMARY_LOG"
    echo "---" >> "$SUMMARY_LOG"
}

# 主循环
while true; do
    # 检查日期是否改变，如果改变则计算前一天的使用率并重置
    NEW_DATE=$(date +%Y%m%d)
    if [ "$NEW_DATE" != "$CURRENT_DATE" ]; then
        echo "$(date): Date changed from $CURRENT_DATE to $NEW_DATE. Calculating daily usage for $CURRENT_DATE." | tee -a "$LOG_FILE"
        calculate_daily_usage "$CURRENT_DATE"
        CURRENT_DATE=$NEW_DATE
        LOG_FILE="$LOG_DIR/gpu_usage_$(date +%Y%m%d).log"
        GPU_USED_TODAY_SECONDS=0 # 重置每日统计
    fi

    # 检查是否在限制时间内，如果是则停止GPU占用程序
    if is_restricted_time; then
        if [ -f "$GPU_BURNER_PID_FILE" ] && ps -p $(cat "$GPU_BURNER_PID_FILE") > /dev/null; then
            echo "$(date): Entering restricted time period (${RESTRICTED_START_HOUR}:00-${RESTRICTED_END_HOUR}:00). Stopping GPU burner." | tee -a "$LOG_FILE"
            stop_gpu_burner
        fi
    fi

    # 获取所有GPU的利用率，只取Usage
    GPU_USAGES=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    
    # 记录当前时间到日志
    echo "$(date):" | tee -a "$LOG_FILE"

    GPU_IS_USED=false
    OTHER_PROGRAM_USING_GPU=false # 判断是否有除burner外的其他程序使用GPU

    # 遍历每张GPU的利用率
    IFS=$'\n' read -r -d '' -a usage_array <<< "$GPU_USAGES"
    num_gpus=${#usage_array[@]}

    for i in "${!usage_array[@]}"; do
        usage=${usage_array[$i]}
        echo "  GPU $i Usage: ${usage}%" | tee -a "$LOG_FILE"
        if [ "$usage" -ne 0 ]; then
            GPU_IS_USED=true
            # 检查当前GPU是否是burner占用的GPU
            if [ "$i" -ne "$LAST_GPU_INDEX" ]; then
                OTHER_PROGRAM_USING_GPU=true
            else
                # 如果是burner占用的GPU，需要进一步检查是否有其他进程在使用这张卡
                # nvidia-smi 默认会显示所有进程，可以通过检查进程列表来判断
                # 暂时简化为：如果最后一张卡使用率不为0，且没有其他卡使用，则认为是burner
                # 更严谨的判断需要解析 nvidia-smi 的进程列表
                # 例如：nvidia-smi pmon -c 1 | grep "G\[$LAST_GPU_INDEX\]"
                # 这里我们假设如果LAST_GPU_INDEX使用率不为0且GPU_BURNER_PID_FILE存在，就是burner
                if [ -f "$GPU_BURNER_PID_FILE" ] && ps -p $(cat "$GPU_BURNER_PID_FILE") > /dev/null; then
                     # 如果burner在运行，且当前是burner占用的那张卡，我们认为它没有被“其他程序”占用
                     : # Do nothing, this is the burner
                else
                    OTHER_PROGRAM_USING_GPU=true
                fi
            fi
        fi
    done

    # 判断并执行操作
    if [ "$GPU_IS_USED" = true ]; then
        echo "  GPU in use by some program(s)." | tee -a "$LOG_FILE"
        GPU_USED_TODAY_SECONDS=$((GPU_USED_TODAY_SECONDS + INTERVAL))
        if [ "$OTHER_PROGRAM_USING_GPU" = true ]; then
            stop_gpu_burner # 有其他程序使用GPU，停止占用程序
        fi
    else
        echo "  No GPU activity detected." | tee -a "$LOG_FILE"
        stop_gpu_burner
        
        # 检查是否在限制时间内
        if is_restricted_time; then
            echo "  Currently in restricted time period (${RESTRICTED_START_HOUR}:00-${RESTRICTED_END_HOUR}:00). Skipping GPU burner start." | tee -a "$LOG_FILE"
        else
            start_gpu_burner # 没有程序使用GPU且不在限制时间内，启动占用程序
        fi
    fi

    echo "-------------------------------------" | tee -a "$LOG_FILE"

    sleep "$INTERVAL"
done
