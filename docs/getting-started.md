# 快速开始：本地开发

目标：新人可以按本文在本机启动 Docker 基础设施、后端、用户端和管理后台。

本文推荐的本地模式是：Docker 运行 PostgreSQL、Redis、MongoDB、MinIO；本机运行 backend、frontend、admin。

如果只需要在本机快速验收完整 Docker 部署，使用 `./start.sh --docker`，详见 [部署指南](./deployment.md#本机一键-docker-部署验收)。

---

## 环境要求

| 工具 | 要求 |
|------|------|
| 操作系统 | macOS 或 Linux |
| Git | 可 clone、fork、管理 upstream |
| Docker | Docker Desktop 或 Docker Engine |
| Docker Compose | `docker compose` 子命令可用 |
| Python | Python 3.10+，推荐 Python 3.11 |
| Poetry | 用于后端依赖管理 |
| Node.js | `>=20` |
| npm | `>=10` |

检查命令：

```bash
git --version
docker version
docker compose version
python --version
poetry --version
node --version
npm --version
```

---

## Fork 和 clone

推荐使用 fork 协作：`origin` 指向个人 fork，`upstream` 指向主仓库。

```bash
git clone git@github.com:<your-user>/nspox.git
cd nspox
git remote add upstream https://github.com/nspox-project/nspox.git
git remote -v
```

同步主仓库：

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

创建工作分支：

```bash
git checkout -b docs/local-startup-notes
```

---

## 准备环境变量

从仓库根目录执行：

```bash
cp docker/.env.example docker/.env
cp backend/.env.example backend/.env
```

本地开发重点：

- `docker/.env` 给 Docker infra 使用。
- `backend/.env` 给本机 backend 使用。
- `POSTGRES_USER`、`POSTGRES_PASSWORD`、`POSTGRES_DB` 需要在两个文件中保持一致。
- `MINIO_ACCESS_KEY`、`MINIO_SECRET_KEY` 需要在两个文件中保持一致。
- `BACKEND_CORS_ORIGINS` 和 `ALLOWED_HOSTS` 必须是 JSON 数组格式，不是逗号字符串。

本地示例：

```env
BACKEND_CORS_ORIGINS='["http://localhost:5173","http://127.0.0.1:5173","http://localhost:5174","http://127.0.0.1:5174","http://localhost:8889"]'
ALLOWED_HOSTS='["localhost","127.0.0.1","0.0.0.0"]'
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=example-placeholder-do-not-use
POSTGRES_DB=writerai
```

真实 API key、token、密码、内部地址不要写入 `.env.example`、README 或 docs。

---

## 启动 Docker infra

启动必要基础设施：

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox up -d postgres redis mongodb minio
```

查看状态：

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox ps
```

可选启动 Qdrant 和 Neo4j：

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox up -d qdrant neo4j
```

---

## 启动 backend

使用 conda 的示例：

```bash
conda activate nspox-py311
cd backend
poetry install --extras all --with dev --with test
export PYTHONPATH="$PWD/src"
poetry run uvicorn memos.api.ai_api:app --host 0.0.0.0 --port 8000 --reload
```

不使用 conda 时，确保当前 shell 使用 Python 3.10+，推荐 Python 3.11，然后执行同样的 `poetry install` 和 `uvicorn` 命令。

当前推荐后端入口：

```text
memos.api.ai_api:app
```

当前推荐后端端口：

```text
8000
```

---

## 启动 frontend

新开一个终端，从仓库根目录执行：

```bash
cd frontend
npm ci
npm run dev
```

如果你正在主动更新依赖，才使用：

```bash
cd frontend
npm install
```

---

## 启动 admin

新开一个终端，从仓库根目录执行：

```bash
cd admin
npm ci
npm run dev
```

如果你正在主动更新依赖，才使用：

```bash
cd admin
npm install
```

---

## 访问地址

| 服务 | 地址 |
|------|------|
| Backend docs | http://localhost:8000/docs |
| Frontend 用户端 | http://localhost:5173 |
| Admin 管理后台 | http://localhost:5174 |

打开 `http://localhost:5174` 看到 Admin Login 是正常的；用户端是 `http://localhost:5173`。

---

## 注册和邀请码

本地注册需要邀请码。干净数据库初始化时，`docker/postgres/init/01-init.sql` 已包含一批未使用的邀请码 seed。

查询邀请码：

```bash
docker exec -it qiuqiuwriter-postgres psql -U postgres -d writerai -c "SELECT code, used FROM invitation_codes ORDER BY id LIMIT 10;"
```

如果你已经用掉了 seed 邀请码，可以通过管理后台生成新的邀请码。

---

## 干净数据库验证

仅本地验证初始化流程时使用。`down -v` 会删除当前 `nspox` Docker volume 中的数据库数据。

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox down -v
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox up -d postgres redis mongodb minio
```

然后重新启动 backend：

```bash
cd backend
export PYTHONPATH="$PWD/src"
poetry run uvicorn memos.api.ai_api:app --host 0.0.0.0 --port 8000 --reload
```

验证步骤：

```bash
docker exec -it qiuqiuwriter-postgres psql -U postgres -d writerai -c "\d users"
docker exec -it qiuqiuwriter-postgres psql -U postgres -d writerai -c "SELECT code FROM invitation_codes WHERE used = 0 LIMIT 1;"
```

用未使用邀请码注册新用户，确认注册流程不再报 `column users.plan does not exist`。

---

## 停止服务

停止本机业务服务：

```text
在 backend、frontend、admin 对应终端按 Ctrl+C
```

停止 Docker infra，保留数据：

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox down
```

停止 Docker infra，并删除本地数据库数据：

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox down -v
```

---

## 清理本地依赖

清理前端依赖：

```bash
rm -rf frontend/node_modules admin/node_modules
```

不要删除 `package-lock.json`。lockfile 已纳入版本控制，用于可复现安装。

清理后端虚拟环境时，确认当前没有在使用它：

```bash
rm -rf backend/.venv
```

---

## 常见问题

### BACKEND_CORS_ORIGINS 或 ALLOWED_HOSTS JSONDecodeError

原因通常是写成逗号字符串。正确格式：

```env
BACKEND_CORS_ORIGINS='["http://localhost:5173","http://127.0.0.1:5173"]'
ALLOWED_HOSTS='["localhost","127.0.0.1","0.0.0.0"]'
```

### greenlet 缺失

后端使用 SQLAlchemy async engine。请确认已安装 lockfile 中声明的依赖：

```bash
cd backend
poetry install --extras all --with dev --with test
poetry run python -c "import greenlet; print(greenlet.__version__)"
```

### PostgreSQL Connection refused

确认 Docker infra 已启动，且 `backend/.env` 使用本机映射地址：

```env
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
```

检查容器：

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox ps postgres
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox logs postgres
```

### users.plan does not exist

这是旧初始化 SQL 导致的干净数据库 schema 漂移。更新代码后执行干净数据库验证流程，确认 `users` 表包含 `plan`、`token_remaining`、`token_reset_at`、`plan_expires_at` 和 `media_credits`。

### macOS arm64 native binding 缺失

如果启动 frontend 或 admin 时报 Rollup、Lightning CSS、Tailwind oxide native binding 缺失，在对应目录执行：

```bash
ROLLUP_VERSION=$(node -p "require('./node_modules/rollup/package.json').version")
LIGHTNINGCSS_VERSION=$(node -p "require('./node_modules/lightningcss/package.json').version")
TAILWIND_OXIDE_VERSION=$(node -p "require('./node_modules/@tailwindcss/oxide/package.json').version")
npm install --no-save \
  "@rollup/rollup-darwin-arm64@$ROLLUP_VERSION" \
  "lightningcss-darwin-arm64@$LIGHTNINGCSS_VERSION" \
  "@tailwindcss/oxide-darwin-arm64@$TAILWIND_OXIDE_VERSION" \
  --registry=https://registry.npmjs.org/
```

不要使用 `npm audit fix --force` 作为本地启动修复手段。

### 端口混淆

- `5173` 是用户端。
- `5174` 是管理后台。
- `8000` 是后端 API 和 API docs。
