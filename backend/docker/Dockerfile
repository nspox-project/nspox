# ==========================================
# qiuqiuwriter 后端生产环境 Dockerfile
# ==========================================

# 1. 基础镜像
FROM docker.m.daocloud.io/library/python:3.11-slim

# 2. 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src \
    HF_ENDPOINT=https://hf-mirror.com

# 3. 配置国内镜像源 (Debian)
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# 4. 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    libffi-dev \
    python3-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 4. 设置工作目录
WORKDIR /app

# 5. 安装 Python 依赖
# 先拷贝 requirements.txt 以利用 Docker 缓存
COPY docker/requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 5. CPU 部署固定使用项目锁定的 Torch 版本，避免 pip 解析到带 CUDA 的新版本。
ARG TORCH_VERSION=2.7.1
ARG PYTORCH_CPU_INDEX_URL=https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir \
    --index-url "${PYTORCH_CPU_INDEX_URL}" \
    "torch==${TORCH_VERSION}"

# 6. 安装 Python 依赖（带镜像源和超时）
RUN pip install --no-cache-dir \
    -i https://mirrors.aliyun.com/pypi/simple/ \
    --default-timeout=600 \
    -r requirements.txt

# 7. 拷贝应用源码
# .dockerignore 会过滤掉不需要的文件
COPY . .

# 8. 暴露端口
EXPOSE 8000

# 9. 启动脚本
# 生产环境不使用 --reload
CMD ["uvicorn", "memos.api.ai_api:app", "--host", "0.0.0.0", "--port", "8000"]
