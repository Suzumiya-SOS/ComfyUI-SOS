FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=120 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git ffmpeg libgomp1 libgl1 libglib2.0-0 libegl1 libsndfile1 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 comfy \
    && useradd --uid 1000 --gid 1000 --create-home comfy \
    && python -m venv /opt/venv \
    && mkdir -p /app /opt/comfyui-build \
    && chown -R comfy:comfy /opt/venv /opt/comfyui-build /app

USER comfy
WORKDIR /app

RUN python -m pip install --upgrade pip \
    && python -m pip install torch==2.14.1+cu130 torchvision==0.29.1+cu130 --index-url https://download.pytorch.org/whl/cu130

COPY --chown=comfy:comfy requirements.txt manager_requirements.txt ./
RUN python -m pip install -r requirements.txt -r manager_requirements.txt \
    && python -m pip check \
    && python -m pip freeze > /opt/comfyui-build/requirements.freeze.txt

COPY --chown=comfy:comfy . .
ARG COMFYUI_REVISION
LABEL org.opencontainers.image.source="https://github.com/Suzumiya-SOS/ComfyUI-SOS" \
      org.opencontainers.image.revision=$COMFYUI_REVISION

EXPOSE 8188
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-manager", "--temp-directory", "/tmp/comfyui"]
