import torch
import time
import os
import sys


def run_gpu_burner(device_id, pid_file_path=None):  # 添加 pid_file_path 参数
    if not torch.cuda.is_available():
        print("CUDA is not available. Exiting GPU burner.")
        return

    # --- 新增：写入PID到文件 ---
    if pid_file_path:
        try:
            current_pid = os.getpid()
            with open(pid_file_path, "w") as f:
                f.write(str(current_pid))
            print(f"GPU burner PID ({current_pid}) written to {pid_file_path}")
        except Exception as e:
            print(f"Error writing PID to file {pid_file_path}: {e}")
    # ---------------------------

    try:
        device = torch.device(f"cuda:{device_id}")

        print(f"Starting GPU burner on device {device_id}...")

        # 调整张量大小以控制占用率，例如 1024x1024
        a = torch.randn(1024, 1024).to(device)

        while True:
            # 执行矩阵乘法以确保非零占用
            _ = torch.matmul(a, a)
            time.sleep(0.02)  # 降低循环频率，减少CPU占用
    except KeyboardInterrupt:
        print(f"GPU burner on device {device_id} stopped manually.")
    except Exception as e:
        print(f"An error occurred in GPU burner on device {device_id}: {e}")
    finally:
        # --- 新增：进程退出时删除PID文件 ---
        if pid_file_path and os.path.exists(pid_file_path):
            try:
                os.remove(pid_file_path)
                print(f"Removed PID file: {pid_file_path}")
            except Exception as e:
                print(f"Error removing PID file {pid_file_path}: {e}")
        # -----------------------------------


if __name__ == "__main__":
    # 现在脚本需要两个参数：device_id 和 pid_file_path
    if len(sys.argv) == 3:
        device_id = int(sys.argv[1])
        pid_file = sys.argv[2]  # 获取PID文件路径
        run_gpu_burner(device_id, pid_file)
    elif len(sys.argv) == 2:
        device_id = int(sys.argv[1])
        run_gpu_burner(device_id)
    elif len(sys.argv) == 1:
        print("No device ID provided. Defaulting to device 0.")
        run_gpu_burner(0)
    else:
        print("Usage: python gpu_burner.py <device_id> <pid_file_path>")
        sys.exit(1)
