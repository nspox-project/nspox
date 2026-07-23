<div align="center">

<img src="frontend/public/logo.svg" width="64" height="64" alt="logo" />

# nspox

### AI 助力人类构筑专属内心世界

**让创作更简单，让故事更精彩**

nspox 是一款开源 AI 写作平台，帮助创作者管理作品、章节、素材与协作编辑流程，并通过 AI 辅助完成分析、续写、润色和创作管理。

项目主题是「AI 助力人类构筑专属内心世界」，开源版本聚焦本地开发、私有化部署和可扩展 AI 写作工作流。

[![GitHub](https://img.shields.io/badge/GitHub-nspox--project%2Fnspox-181717?logo=github&logoColor=white)](https://github.com/nspox-project/nspox)
[![Edition](https://img.shields.io/badge/Edition-%E5%BC%80%E6%BA%90%E7%89%88-2ea44f?style=flat-square)](#项目声明)
[![Free](https://img.shields.io/badge/Free-%E5%85%8D%E8%B4%B9-3178C6?style=flat-square)](#项目声明)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=white)](https://react.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)](https://postgresql.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[GitHub 仓库](https://github.com/nspox-project/nspox) · [Issues](https://github.com/nspox-project/nspox/issues) · [Discussions](https://github.com/nspox-project/nspox/discussions)

</div>

![hero](docs/screenshots/hero.png)

---

## 项目声明

本仓库源码基于 [MIT 协议](LICENSE) 开源，可用于学习、研究、二次开发以及商业部署。

开源版本不包含任何真实生产密钥。提交代码前请确认没有提交 `.env`、真实 API key、token、密码、内部地址、`node_modules`、`dist`、`.DS_Store`、`.trae` 或 `.venv`。

---

## 功能亮点

### 智能写作工作台

从作品规划、章节拆分到正文编辑，nspox 提供围绕长篇创作流程设计的工作台，帮助作者集中管理项目结构和创作状态。

![workbench](docs/screenshots/workbench.png)

### 核心功能一览

平台内置作品管理、章节管理、AI 辅助、素材组织、协作编辑和后台管理等能力，适合小说、剧本、设定集和长文档创作场景。

![features](docs/screenshots/features.png)

### 沉浸式编辑器

编辑器面向连续写作和结构化创作场景，支持章节化内容管理，并与 AI 写作、素材上下文和协作能力配合使用。

![editor](docs/screenshots/editor.png)

### AI 协作助手

AI 能力可用于续写、润色、分析、总结和灵感生成。具体模型供应商由本地环境变量配置，仓库不会提供真实 API key。

![ai-assistant](docs/screenshots/ai-assistant.png)

### 创作场景支持

nspox 适用于个人写作、团队共创、世界观设定、长篇内容管理和私有化 AI 写作实验等场景。

![usecases](docs/screenshots/usecases.png)

---

## 技术栈

| 模块 | 技术 | 默认端口 |
|------|------|----------|
| `backend/` | FastAPI + Python 3.10+ + Poetry + SQLAlchemy async | `8000` |
| `frontend/` | React 19 + TypeScript + Vite + TipTap/Yjs | `5173` |
| `admin/` | React 18 + Ant Design + Vite | `5174` |
| `docker/` | PostgreSQL, Redis, MongoDB, MinIO, optional Qdrant/Neo4j | service ports |

当前本地推荐后端入口是：

```bash
poetry run uvicorn memos.api.ai_api:app --host 0.0.0.0 --port 8000 --reload
```

---

## 项目结构

```text
nspox/
├── frontend/        # 用户端前端，Vite dev server: http://localhost:5173
├── admin/           # 管理后台，Vite dev server: http://localhost:5174
├── backend/         # FastAPI 后端，API docs: http://localhost:8000/docs
├── docker/          # Docker Compose、Nginx、PostgreSQL 初始化 SQL
├── deploy/          # 部署辅助文件和历史数据导出
├── docs/            # 项目文档
└── start.sh         # 本机 Docker 一键部署与健康检查入口
```

---

## 文档入口

| 目标 | 文档 |
|------|------|
| 新人本地启动 | [docs/getting-started.md](docs/getting-started.md) |
| 环境变量和配置项 | [docs/configuration.md](docs/configuration.md) |
| 服务器部署 | [docs/deployment.md](docs/deployment.md) |
| 开发协作、测试、PR 检查 | [docs/development.md](docs/development.md) |
| 后端单独说明 | [backend/README.md](backend/README.md) |

---

## 快速本地启动

完整步骤见 [快速开始](docs/getting-started.md)。最短路径如下，命令默认从仓库根目录执行。

需要快速完成本机 Docker 部署验收时：

```bash
cp docker/.env.example docker/.env
# 修改 docker/.env 中的本地占位凭证后执行
./start.sh --docker
```

该命令会在缺少构建产物时自动构建 backend、frontend 和 admin，启动 Docker 基础设施与应用容器，等待容器健康，并检查 backend、frontend、admin 的 HTTP 入口。成功后命令退出，容器继续运行。

Docker 模式访问地址：

| 服务 | 地址 |
|------|------|
| Backend docs | http://localhost:8000/docs |
| Frontend 用户端 | http://localhost:81 |
| Admin 管理后台 | http://localhost:8889 |

强制重建使用 `./start.sh --rebuild`，跟随应用日志使用 `./start.sh --docker --follow`。该入口用于本机验收，不替代 [生产部署指南](docs/deployment.md)。

日常开发仍推荐 Docker 运行基础设施、本机运行三个业务服务：

```bash
cp docker/.env.example docker/.env
cp backend/.env.example backend/.env
```

```bash
docker compose --env-file docker/.env -f docker/docker-compose.infra.yml -p nspox up -d postgres redis mongodb minio
```

```bash
cd backend
poetry install --extras all --with dev --with test
export PYTHONPATH="$PWD/src"
poetry run uvicorn memos.api.ai_api:app --host 0.0.0.0 --port 8000 --reload
```

```bash
cd frontend
npm ci
npm run dev
```

```bash
cd admin
npm ci
npm run dev
```

访问地址：

| 服务 | 地址 |
|------|------|
| Backend docs | http://localhost:8000/docs |
| Frontend 用户端 | http://localhost:5173 |
| Admin 管理后台 | http://localhost:5174 |

注册需要邀请码。本地初始化 SQL 已包含未使用的邀请码种子，查询方式见 [docs/getting-started.md](docs/getting-started.md#注册和邀请码)。

---

## 部署入口

负责人部署服务器前请先阅读 [docs/deployment.md](docs/deployment.md)。生产环境必须显式设置：

- `ENVIRONMENT=production`
- 强随机 `SECRET_KEY`
- 明确的 `BACKEND_CORS_ORIGINS` JSON 数组
- 明确的 `ALLOWED_HOSTS` JSON 数组
- 数据库、Redis、MongoDB、MinIO、Neo4j 的强凭证
- AI provider key 或本地模型配置

生产环境不能使用 `example-placeholder-do-not-use` 或任何弱口令占位符。

---

## 安全提醒

- `.env` 只在本机或服务器保存，不提交到 Git。
- `backend/.env.example` 和 `docker/.env.example` 只能保留占位符。
- `BACKEND_CORS_ORIGINS` 和 `ALLOWED_HOSTS` 必须使用 JSON 数组格式。
- 如果真实密钥曾进入 Git 历史，需要先在供应商后台轮换，再清理历史记录。

---

## 许可证

[MIT](LICENSE)
