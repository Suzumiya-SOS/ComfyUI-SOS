#!/bin/sh
set -e

# 国内镜像同步存在滞后：镜像上缺某个新版本时，pip 会整条安装失败，导致
# ComfyUI 起不来（例如镜像还没有 comfy-kitchen==0.2.35）。追加官方 PyPI 作为
# 回退源，镜像上有的仍走镜像，缺的自动从官方拉。
PIP_FALLBACK="--extra-index-url https://pypi.org/simple"

# 补装源码 requirements 的漂移部分（已满足的依赖会直接跳过）
if [ -f /app/requirements.txt ]; then
  pip install -q --no-cache-dir $PIP_FALLBACK -r /app/requirements.txt || \
    echo "[entrypoint] warning: main requirements install failed, continuing"
fi

# custom_nodes 由 docker-compose 挂载，其 Python 依赖装在容器可写层，重建容器
# 会丢失，因此每次启动扫描并补装各扩展的 requirements.txt
for req in /app/custom_nodes/*/requirements.txt; do
  [ -f "$req" ] || continue
  echo "[entrypoint] installing custom node deps: $req"
  pip install -q --no-cache-dir $PIP_FALLBACK -r "$req" || \
    echo "[entrypoint] warning: failed to install $req, continuing"
done

# z-tipo-extension 的 llama-cpp-python 不随 requirements 安装：它需要按 GPU 选预编译
# 轮子，由插件自己的 tipo_installer 解析。这里在 ComfyUI 启动前先行装好，因为 kgen
# 在导入时就把 Llama 绑定一次；若等到首次执行节点才装，kgen 已绑成 None，必须再重启
# 一次 ComfyUI 才能用。轮子已存在时该调用只做一次 import 检查，开销可忽略。
if [ -d /app/custom_nodes/z-tipo-extension ]; then
  python -c "
import sys
sys.path.insert(0, '/app/custom_nodes/z-tipo-extension')
try:
    from tipo_installer import ensure_llama_cpp
    ensure_llama_cpp()
except Exception as exc:
    print(f'[entrypoint] warning: TIPO runtime bootstrap failed: {exc}')
" || echo "[entrypoint] warning: TIPO runtime bootstrap failed, continuing"
fi

exec python /app/main.py --listen 0.0.0.0 --port 8188 "$@"
