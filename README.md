# 全自动服务器GPU占用脚本

## 📖 项目介绍

这是一个智能的GPU监控和占用脚本，能够自动管理服务器GPU资源的使用情况。

### 核心功能
- **智能监控**：每10秒检测一次所有GPU的利用率
- **自动占用**：当所有GPU利用率均为0%时，自动在最后一张GPU上启动占用程序
- **资源保护**：占用程序仅使用约1%的GPU算力和466MB显存，对系统影响极小
- **智能切换**：检测到其他程序使用GPU时，自动停止占用程序
- **时间限制**：支持设置禁用时间段，避免在特定时段造成GPU使用率异常
- **使用统计**：每日自动统计GPU使用率并生成报告

### ⚠️ 重要说明
**脚本默认在每天18:00-21:00时间段内禁用GPU占用程序，以避免造成GPU使用率100%的假象，然后被开盒。。。**

## 🚀 快速开始

### 环境准备
1. 确保系统已安装NVIDIA驱动和CUDA
2. 在`gpu_monitor.sh`中配置你的Conda环境：
```bash
CONDA_ENV_NAME="torch"  # 请替换为你的Conda环境名称
```

### 配置选项

#### 禁用时间段配置（可选）
如需修改禁用时间段，可在`gpu_monitor.sh`中修改以下变量：
```bash
RESTRICTED_START_HOUR=18  # 禁用开始时间（24小时制）
RESTRICTED_END_HOUR=21    # 禁用结束时间（24小时制）
```

## 💻 使用方法

### 前台运行
```bash
cd gpu_monitor
./gpu_monitor.sh
```

### 后台运行
脚本将在后台运行，输出日志保存至`log/monitor_output.log`：
```bash
cd gpu_monitor
./gpu_monitor_nohup.sh
```

## 🛑 停止脚本

### 方法一：使用专用停止脚本（推荐）
```bash
cd gpu_monitor
./stop_system.sh
```
这个脚本会自动：
- 查找并停止GPU监控脚本进程
- 查找并停止GPU占用程序进程
- 清理PID文件
- 提供彩色输出和详细状态信息

### 方法二：前台运行停止
如果脚本在前台运行，直接按 `Ctrl+C` 即可停止。

### 方法三：后台运行停止
如果脚本在后台运行，使用以下命令停止：

```bash
# 查找监控脚本进程
ps aux | grep gpu_monitor.sh

# 停止监控脚本（替换 <PID> 为实际进程ID）
kill <PID>

# 或者使用更强制的方式
kill -9 <PID>
```

### 方法四：停止GPU占用程序
如果只想停止GPU占用程序而不停止监控脚本：

```bash
# 查看占用程序进程ID
cat log/gpu_burner.pid

# 停止占用程序（替换 <PID> 为实际进程ID）
kill <PID>

# 或者直接删除PID文件，脚本会自动停止占用程序
rm log/gpu_burner.pid
```

### 方法五：一键停止所有相关进程
```bash
# 停止所有gpu_monitor相关进程
pkill -f gpu_monitor.sh

# 停止所有gpu_burner相关进程
pkill -f gpu_burner.py
```

## 🔧 手动操作

### 手动启动GPU占用程序
```bash
cd gpu_monitor
python gpu_burner.py
```

### 指定GPU设备
```bash
cd gpu_monitor
python gpu_burner.py <device_id>
```

### 存储进程号
```bash
cd gpu_monitor
python gpu_burner.py <device_id> <pid_file_path>
```

## 📊 日志文件

- `log/gpu_usage_YYYYMMDD.log`：每日GPU使用情况详细日志
- `log/gpu_daily_summary.log`：每日GPU使用率统计报告
- `log/gpu_burner.pid`：GPU占用程序进程ID文件
- `log/monitor_output.log`：后台运行时的监控脚本输出日志

## 🔍 故障排除

### 常见问题
1. **脚本无法启动**：检查Conda环境名称是否正确
2. **GPU占用程序无法启动**：确认PyTorch环境已正确安装
3. **权限问题**：确保脚本具有执行权限 `chmod +x gpu_monitor.sh`

### 查看运行状态
```bash
# 查看监控脚本是否运行
ps aux | grep gpu_monitor.sh

# 查看GPU占用程序是否运行
ps aux | grep gpu_burner.py

# 查看最新日志
tail -f log/gpu_usage_$(date +%Y%m%d).log
```
