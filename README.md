# 全自动服务器GPU占用脚本
### 介绍
当服务器所有GPU利用率均为0%时，自动在最后一张GPU上启动GPU占用程序`gpu_burner.py`，占用大约1%的GPU和466MB显存，并将进程号存储在`log/gpu_burner.pid`中，若有其他程序占用GPU，则自动杀死该GPU占用程序。每10s检查一次，每日会统计当日GPU利用率。

### 准备
在`gpu_monitor.sh`中第13行设置一个有pytorch的conda环境。
```python
CONDA_ENV_NAME="torch"
```

### 终端运行
```bash
cd gpu_monitor
./gpu_monitor.sh
```

### 后台运行
输出至`log/monitor_output.log`。
```bash
cd gpu_monitor
./gpu_monitor_nohup.sh
```
