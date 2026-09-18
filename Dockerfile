# ComfyUI Docker 镜像
# RTX 50 系列（Blackwell）GPU 镜像

ARG PYTHON_BASE_IMAGE=python:3.10-slim-bookworm
FROM ${PYTHON_BASE_IMAGE} AS base

# 构建参数
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu130
ARG APT_MIRROR=
ARG APT_SECURITY_MIRROR=
ENV TORCH_INDEX_URL=${TORCH_INDEX_URL}

# 避免 Python 生成 .pyc 文件并开启无缓冲输出
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 安装系统依赖（包含 OpenCV、多媒体处理等常用库）
# libegl1/libgles2 是 MediaPipe 的 selfie_multiclass 分割（Easy-Use 抠图节点）所需，
# 缺了会报 libEGL.so.1: cannot open shared object file。
RUN if [ -n "${APT_MIRROR}" ]; then \
        sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}|g" /etc/apt/sources.list.d/debian.sources; \
    fi \
    && if [ -n "${APT_SECURITY_MIRROR}" ]; then \
        sed -i "s|http://deb.debian.org/debian-security|${APT_SECURITY_MIRROR}|g" /etc/apt/sources.list.d/debian.sources; \
    fi \
    && apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
    git \
    libgl1 \
    libegl1 \
    libgles2 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 先安装 PyTorch 相关重型依赖（利用构建缓存）
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir torch torchvision torchaudio --index-url ${TORCH_INDEX_URL}

# 安装项目 Python 依赖
# --extra-index-url 回退到官方 PyPI：阿里云等国内镜像同步滞后时，
# 新版 comfy-kitchen/comfy-aimdo 会取不到，导致整条 -r 安装中止。
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --extra-index-url https://pypi.org/simple -r /app/requirements.txt

# 安装随 docker-compose 挂载的 custom_nodes 常用运行依赖
COPY docker-extra-requirements.txt /app/docker-extra-requirements.txt
RUN pip install --no-cache-dir --extra-index-url https://pypi.org/simple -r /app/docker-extra-requirements.txt

# Triton 首次运行会即时编译 CUDA 驱动辅助模块，需要本地 C 工具链
RUN apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*
ENV CC=/usr/bin/gcc

# pip 装的 CUDA 运行库位于 site-packages，动态链接器默认不搜索该路径，
# llama-cpp-python 的 libllama.so 会因找不到 libcudart.so.13 而加载失败。
# 用通配匹配 cu13/cu14 等目录，避免将来重建镜像时路径失效。
RUN for d in /usr/local/lib/python3.10/site-packages/nvidia/*/lib; do \
        [ -d "$d" ] && echo "$d"; \
    done > /etc/ld.so.conf.d/nvidia-cuda.conf \
    && ldconfig

# huggingface.co 在部分网络下不可达，改用国内镜像；TIPO 等节点首次运行时
# 会经 huggingface_hub 拉取模型，没有这个变量会报 LocalEntryNotFoundError。
ENV HF_ENDPOINT=https://hf-mirror.com

# 复制项目源码
COPY . /app

# 创建 ComfyUI 所需的默认数据目录
RUN mkdir -p /app/models /app/output /app/input /app/user /app/temp /app/custom_nodes

# 暴露 ComfyUI 默认端口
EXPOSE 8188

# 入口脚本负责运行期补装漂移依赖与扩展依赖（custom_nodes 由 volume 挂载，
# 其依赖不在镜像内，重建容器后需要重新安装）
ENTRYPOINT ["/app/entrypoint.sh"]
