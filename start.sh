#!/usr/bin/env bash
# QiuQiuWriter 统一启动脚本

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"
DOCKER_ENV_FILE="${DOCKER_DIR}/.env"

# 参数解析
USE_DOCKER=false
START_INFRA=false
START_APP=false
BUILD_FRONTEND=false
BUILD_ADMIN=false
BUILD_BACKEND=false
REBUILD=false
FOLLOW_LOGS=false

docker_compose() {
    docker compose --env-file "$DOCKER_ENV_FILE" "$@"
}

wait_for_docker() {
    if ! command -v docker > /dev/null 2>&1; then
        echo "✗ Docker 未安装，请先安装 Docker Desktop 和 Docker Compose"
        exit 1
    fi

    if docker info > /dev/null 2>&1; then
        return
    fi

    if [[ "${OSTYPE:-}" == "darwin"* ]] && command -v open > /dev/null 2>&1; then
        echo "Docker daemon 未运行，正在启动 Docker Desktop..."
        open -a Docker
    fi

    echo "等待 Docker daemon 就绪..."
    for _ in {1..60}; do
        if docker info > /dev/null 2>&1; then
            echo "✓ Docker daemon 已就绪"
            return
        fi
        sleep 2
    done

    echo "✗ Docker daemon 在 120 秒内未就绪"
    exit 1
}

require_docker_env() {
    if [ ! -f "$DOCKER_ENV_FILE" ]; then
        echo "✗ 缺少 docker/.env"
        echo "请先执行: cp docker/.env.example docker/.env"
        echo "然后按本机环境修改占位符；不要提交 docker/.env"
        exit 1
    fi
}

ensure_app_artifacts() {
    if ! docker image inspect qiuqiuwriter-backend:latest > /dev/null 2>&1; then
        echo "ℹ️  未找到后端镜像，将自动构建"
        BUILD_BACKEND=true
    fi

    if [ ! -f "${PROJECT_ROOT}/frontend/dist/index.html" ]; then
        echo "ℹ️  未找到 frontend/dist，将自动构建"
        BUILD_FRONTEND=true
    fi

    if [ ! -f "${PROJECT_ROOT}/admin/dist/index.html" ]; then
        echo "ℹ️  未找到 admin/dist，将自动构建"
        BUILD_ADMIN=true
    fi
}

smoke_test_url() {
    local name="$1"
    local url="$2"

    echo "  - 检查 ${name}: ${url}"
    curl --fail --silent --show-error \
        --connect-timeout 3 \
        --max-time 10 \
        --retry 30 \
        --retry-connrefused \
        --retry-delay 2 \
        "$url" > /dev/null
}

# 检查参数
for arg in "$@"; do
    case $arg in
        --docker)
            USE_DOCKER=true
            ;;
        --infra)
            START_INFRA=true
            ;;
        --app)
            START_APP=true
            ;;
        --build-frontend)
            BUILD_FRONTEND=true
            ;;
        --build-admin)
            BUILD_ADMIN=true
            ;;
        --build-backend)
            BUILD_BACKEND=true
            ;;
        --build-all)
            BUILD_FRONTEND=true
            BUILD_ADMIN=true
            ;;
        --rebuild)
            REBUILD=true
            USE_DOCKER=true
            START_INFRA=true
            START_APP=true
            BUILD_FRONTEND=true
            BUILD_ADMIN=true
            BUILD_BACKEND=true
            ;;
        --follow)
            FOLLOW_LOGS=true
            ;;
        *)
            echo "未知参数: $arg"
            exit 1
            ;;
    esac
done

# 如果指定了 --docker 但没有指定 infra 或 app，默认启动全部
if [ "$USE_DOCKER" = true ] && [ "$START_INFRA" = false ] && [ "$START_APP" = false ]; then
    START_INFRA=true
    START_APP=true
fi

if [ "$USE_DOCKER" = true ]; then
    require_docker_env
    wait_for_docker

    if [ "$START_APP" = true ]; then
        ensure_app_artifacts
    fi
fi

# ---------- 停止旧容器 (Rebuild 模式) ----------
if [ "$REBUILD" = true ]; then
    echo "🛑 正在停止应用容器以进行重建..."
    # 仅停止 app 相关的容器
    docker_compose -f "${DOCKER_DIR}/docker-compose.app.yml" -p qiuqiuwriter-app down
fi

# ---------- 构建后端 Docker 镜像 ----------
if [ "$BUILD_BACKEND" = true ]; then
    echo "📦 构建 Backend Docker 镜像..."
    docker build \
        -t qiuqiuwriter-backend:latest \
        -f "${PROJECT_ROOT}/backend/docker/Dockerfile" \
        "${PROJECT_ROOT}/backend"
    echo "✅ Backend 镜像构建完成"
fi

# ---------- 构建前端项目 ----------
# 使用 npm ci（如有 package-lock.json）保证可复现构建；否则回退到 npm install
npm_install_cmd() {
    if [ -f "package-lock.json" ]; then
        npm ci
    else
        echo "⚠️  未找到 package-lock.json，回退到 npm install（请提交 lockfile 以获得可复现安装）"
        npm install
    fi
}

if [ "$BUILD_FRONTEND" = true ]; then
    echo "📦 构建 Frontend..."
    cd "${PROJECT_ROOT}/frontend"
    npm_install_cmd && npm run build
    echo "✅ Frontend 构建完成"
    cd "$PROJECT_ROOT"
fi

if [ "$BUILD_ADMIN" = true ]; then
    echo "📦 构建 Admin..."
    cd "${PROJECT_ROOT}/admin"
    npm_install_cmd && npm run build
    echo "✅ Admin 构建完成"
    cd "$PROJECT_ROOT"
fi

echo "=========================================="
echo "启动 QiuQiuWriter 项目"
if [ "$USE_DOCKER" = true ]; then
    echo "运行模式: Docker 容器化"
    if [ "$START_INFRA" = true ]; then echo "  - 包含: 基础设施 (DBs)"; fi
    if [ "$START_APP" = true ]; then echo "  - 包含: 应用服务 (App)"; fi
else
    echo "运行模式: 本地开发"
fi
echo "=========================================="
echo ""

# ---------- Docker 模式 ----------
if [ "$USE_DOCKER" = true ]; then
    echo "🐳 正在启动 Docker 容器..."
    cd "$DOCKER_DIR"
    
    # 基础设施
    if [ "$START_INFRA" = true ]; then
        echo "  - 启动基础设施 (postgres, redis, mongodb...)"
        docker_compose \
            -f docker-compose.infra.yml \
            -p qiuqiuwriter-infra \
            up -d --remove-orphans --wait --wait-timeout 180
    fi
    
    # 应用容器
    if [ "$START_APP" = true ]; then
        echo "  - 启动应用服务 (backend, frontend, admin)"
        docker_compose \
            -f docker-compose.app.yml \
            -p qiuqiuwriter-app \
            up -d --remove-orphans --wait --wait-timeout 180

        if ! command -v curl > /dev/null 2>&1; then
            echo "✗ 缺少 curl，无法执行部署后健康检查"
            exit 1
        fi

        echo "🔎 正在执行部署后健康检查..."
        smoke_test_url "Backend API" "http://127.0.0.1:8000/ai/health"
        smoke_test_url "Frontend" "http://127.0.0.1:81/"
        smoke_test_url "Admin" "http://127.0.0.1:8889/"
    fi
    
    echo ""
    echo "=========================================="
    echo "✅ 指定的服务已在 Docker 中启动！"
    echo "=========================================="
    if [ "$START_APP" = true ]; then
        echo "前端: http://localhost:81"
        echo "管理后台: http://localhost:8889"
        echo "后端 API: http://localhost:8000"
        echo "API 文档: http://localhost:8000/docs"
    fi
    echo ""
    echo "使用 './start.sh --docker --follow' 查看实时应用日志"
    echo ""
    
    if [ "$FOLLOW_LOGS" = true ]; then
        if [ "$START_APP" = true ]; then
            docker_compose -f docker-compose.app.yml -p qiuqiuwriter-app logs -f
        elif [ "$START_INFRA" = true ]; then
            docker_compose -f docker-compose.infra.yml -p qiuqiuwriter-infra logs -f
        fi
    fi
    exit 0
fi

# ---------- 本地模式 (默认) ----------

# 启动依赖服务 (Infra)
if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
    echo "检查依赖服务..."
    require_docker_env
    cd "$DOCKER_DIR"
    # 只启动基础设施
    docker_compose -f docker-compose.infra.yml -p qiuqiuwriter-infra up -d
    cd "$PROJECT_ROOT"
    echo "✓ 依赖服务已启动"
fi

# 启动后端
echo "启动后端服务..."
# 尝试定位后端目录
if [ -d "${PROJECT_ROOT}/backend" ]; then
    cd "${PROJECT_ROOT}/backend"
elif [ -d "${PROJECT_ROOT}/memos" ]; then
    cd "${PROJECT_ROOT}/memos"
else
    echo "✗ 找不到 backend 或 memos 目录"
    exit 1
fi

if [ ! -d ".venv" ]; then
    echo "✗ 虚拟环境不存在，请先运行: python -m venv .venv && source .venv/bin/activate && pip install -e ."
    exit 1
fi

source .venv/bin/activate
export ENABLE_PREFERENCE_MEMORY=false
# 添加 src 到 PYTHONPATH (适配 backend/src/memos 结构)
export PYTHONPATH="${PYTHONPATH:-}:$(pwd)/src"

echo "启动 MemOS API 服务器..."
echo "后端将在 http://localhost:8000 运行"
echo ""

# 在后台启动后端
uvicorn memos.api.ai_api:app --host 0.0.0.0 --port 8000 --workers 1 &
BACKEND_PID=$!

echo "后端进程 ID: $BACKEND_PID"
echo ""

# 等待后端启动
sleep 3

# 启动前端
echo "启动前端服务..."
cd "${PROJECT_ROOT}/frontend"

if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm_install_cmd
fi

echo "前端将在 http://localhost:5173 运行"
echo ""
echo "=========================================="
echo "服务已启动！"
echo "=========================================="
echo "前端: http://localhost:5173"
echo "后端: http://localhost:8000"
echo "API 文档: http://localhost:8000/docs"
echo ""
echo "按 Ctrl+C 停止所有服务"
echo ""

# 清理：当脚本退出时停止后端
trap "kill $BACKEND_PID 2>/dev/null" EXIT

# 启动前端（前台运行，方便查看日志）
npm run dev
