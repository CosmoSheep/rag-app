# 🐳 本地 Docker 构建与测试指南

## 系统架构说明

- **您的本地环境：** ARM64 (Apple Silicon)
- **AWS App Runner：** x86_64/AMD64
- **解决方案：** 使用 `--platform linux/amd64` 进行跨平台构建

---

## 📦 本地构建兼容 AWS 的镜像

### 前提条件

1. ✅ Docker Desktop 已安装并运行
2. ✅ FAISS 索引已生成（`faiss_index/` 目录存在）
3. ✅ 设置 OPENAI_API_KEY 环境变量

```bash
# 设置环境变量（如果还未设置）
export OPENAI_API_KEY="sk-proj-..."
```

### 构建步骤

```bash
cd /Users/heyang/Documents/Repos/rag-app

# 构建 x86_64 架构镜像（兼容 AWS App Runner）
docker build --platform linux/amd64 -t rag-app:local-amd64 .
```

**说明：**
- `--platform linux/amd64` 确保构建 x86_64 架构镜像
- 构建时间约 1-2 分钟（取决于网络速度）
- 镜像大小约 500MB-1GB

---

## 🧪 本地测试

### 1. 启动容器

```bash
# 启动容器并映射到本地 8000 端口
docker run -d \
  --name rag-app-test \
  --platform linux/amd64 \
  -p 8000:8000 \
  -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
  rag-app:local-amd64
```

### 2. 查看日志

```bash
# 查看容器日志
docker logs rag-app-test

# 实时跟踪日志
docker logs -f rag-app-test
```

**预期输出：**
```
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### 3. 测试 API

#### 健康检查
```bash
curl http://localhost:8000/health
```

**预期响应：**
```json
{"status":"healthy"}
```

#### RAG 问答测试
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "这个RAG Demo使用了什么技术栈？"}'
```

**预期响应：**
```json
{
  "answer": "这个RAG Demo使用的核心技术包括：\n\n1. LangChain：负责把向量检索和大模型调用串成一个 chain。\n2. FAISS：用来做向量相似度搜索，并把索引持久化到 faiss_index 目录。\n3. FastAPI：提供 Web API 服务。\n4. Docker：把应用和 faiss_index 一起打包成容器镜像。\n5. AWS App Runner：用来部署容器并提供托管服务。\n6. GitHub Actions + OIDC：在代码 push 到 main 分支时自动构建并部署。"
}
```

### 4. 停止并清理

```bash
# 停止容器
docker stop rag-app-test

# 删除容器
docker rm rag-app-test

# （可选）删除镜像
docker rmi rag-app:local-amd64
```

---

## 🔍 验证镜像架构

### 检查镜像信息

```bash
# 查看镜像详细信息
docker image inspect rag-app:local-amd64 | grep Architecture
```

**预期输出：**
```json
"Architecture": "amd64",
```

### 验证镜像是否可在 ARM64 上运行

在 Apple Silicon Mac 上，Docker Desktop 会自动通过 Rosetta 2 模拟运行 x86_64 镜像：

```bash
# 查看运行中的容器架构
docker inspect rag-app-test | grep Architecture
```

**说明：**
- ✅ ARM64 系统可以运行 x86_64 镜像（通过模拟）
- ⚠️ 性能会比原生 ARM64 镜像略低，但功能完全正常
- ✅ 这与 AWS App Runner 运行的环境完全一致

---

## 🚀 推送到 ECR（可选）

如果您想手动推送镜像到 ECR：

### 1. 登录 ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  924030134232.dkr.ecr.us-east-1.amazonaws.com
```

### 2. 标记镜像

```bash
# 使用 git commit SHA 作为 tag
COMMIT_SHA=$(git rev-parse HEAD)

docker tag rag-app:local-amd64 \
  924030134232.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:${COMMIT_SHA}

# 也可以使用 latest tag
docker tag rag-app:local-amd64 \
  924030134232.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:latest
```

### 3. 推送镜像

```bash
# 推送特定版本
docker push 924030134232.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:${COMMIT_SHA}

# 推送 latest
docker push 924030134232.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:latest
```

---

## 📋 常用命令

### 镜像管理

```bash
# 列出所有镜像
docker images | grep rag-app

# 查看镜像大小
docker images rag-app:local-amd64

# 删除镜像
docker rmi rag-app:local-amd64

# 清理未使用的镜像
docker image prune -a
```

### 容器管理

```bash
# 列出所有容器（包括已停止）
docker ps -a | grep rag-app

# 查看容器资源使用
docker stats rag-app-test

# 进入容器 shell
docker exec -it rag-app-test /bin/bash

# 查看容器内的文件
docker exec rag-app-test ls -la /app/faiss_index
```

### 调试命令

```bash
# 交互式运行容器（用于调试）
docker run -it --rm \
  --platform linux/amd64 \
  -p 8000:8000 \
  -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
  rag-app:local-amd64 \
  /bin/bash

# 查看容器网络信息
docker inspect rag-app-test | grep IPAddress

# 查看容器端口映射
docker port rag-app-test
```

---

## ⚠️ 常见问题

### Q1: 构建时提示 "no matching manifest for linux/amd64"

**原因：** 基础镜像不支持 AMD64 架构

**解决方案：**
```bash
# 确认使用的基础镜像支持 AMD64
# python:3.11-slim 是多架构镜像，支持 ARM64 和 AMD64
```

### Q2: 容器启动后立即退出

**排查步骤：**

```bash
# 查看容器日志
docker logs rag-app-test

# 常见原因：
# 1. OPENAI_API_KEY 未设置或无效
# 2. FAISS 索引文件缺失或损坏
# 3. 端口 8000 已被占用
```

### Q3: API 调用返回 500 错误

**排查步骤：**

```bash
# 1. 检查 OpenAI API Key 是否有效
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer ${OPENAI_API_KEY}"

# 2. 查看容器详细日志
docker logs rag-app-test

# 3. 检查 FAISS 索引是否正确加载
docker exec rag-app-test ls -la /app/faiss_index
```

### Q4: 在 ARM64 上运行 AMD64 镜像性能慢

**说明：**
- Docker Desktop 使用 Rosetta 2 模拟 x86_64
- 性能略低于原生，但功能完全正常
- 这是为了保证与 AWS 生产环境一致

**如需本地高性能测试：**
```bash
# 构建原生 ARM64 镜像
docker build -t rag-app:local-arm64 .

# 注意：ARM64 镜像不能推送到 ECR 用于 AWS App Runner
```

### Q5: 如何在 Intel Mac 上构建？

**Intel Mac (x86_64)：**
```bash
# 不需要指定 --platform，默认就是 AMD64
docker build -t rag-app:local .
```

---

## 🎯 最佳实践

### 1. 开发流程

```bash
# 1. 修改代码
vim app.py

# 2. 重新生成 FAISS 索引（如果数据变化）
python ingest.py

# 3. 重新构建镜像
docker build --platform linux/amd64 -t rag-app:local-amd64 .

# 4. 本地测试
docker run -d --name test --platform linux/amd64 \
  -p 8000:8000 -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
  rag-app:local-amd64

# 5. 验证功能
curl http://localhost:8000/health

# 6. 清理
docker stop test && docker rm test

# 7. 提交并推送代码（触发 GitHub Actions 自动部署）
git add .
git commit -m "Update: feature description"
git push origin master
```

### 2. 使用 Docker Compose（可选）

创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  rag-app:
    build:
      context: .
      platforms:
        - linux/amd64
    image: rag-app:local-amd64
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    platform: linux/amd64
```

使用 Docker Compose：

```bash
# 构建并启动
docker-compose up --build

# 后台运行
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止并清理
docker-compose down
```

### 3. 多阶段构建优化（高级）

如果想优化镜像大小，可以修改 Dockerfile：

```dockerfile
# 构建阶段
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# 运行阶段
FROM python:3.11-slim

WORKDIR /app

# 从构建阶段复制依赖
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# 复制应用文件
COPY app.py .
COPY faiss_index ./faiss_index

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 📊 架构对比

| 环境 | 架构 | 用途 |
|------|------|------|
| **本地开发 (Apple Silicon)** | ARM64 | 原生运行，高性能开发 |
| **本地构建 (--platform amd64)** | x86_64 | 兼容 AWS，用于测试 |
| **GitHub Actions (ubuntu-latest)** | x86_64 | CI/CD 自动构建 |
| **AWS App Runner** | x86_64 | 生产环境运行 |

---

## ✅ 完成检查清单

构建和测试完成后，确认：

- [ ] 镜像成功构建（`docker images` 可看到）
- [ ] 容器成功启动（`docker ps` 可看到）
- [ ] 健康检查返回 `{"status":"healthy"}`
- [ ] RAG 问答功能正常
- [ ] 镜像架构为 `amd64`
- [ ] 清理测试容器和镜像

---

## 🔄 与 GitHub Actions 的关系

### 本地构建 vs. GitHub Actions

| 项目 | 本地构建 | GitHub Actions |
|------|----------|----------------|
| **触发方式** | 手动执行 | git push 自动触发 |
| **构建环境** | 您的 Mac | Ubuntu x86_64 |
| **架构** | 需指定 --platform | 默认 x86_64 |
| **FAISS 索引** | 需提前生成 | Workflow 自动生成 |
| **推送 ECR** | 需手动推送 | 自动推送 |
| **部署** | 不自动部署 | 自动部署到 App Runner |
| **用途** | 本地测试验证 | 生产部署 |

### 推荐工作流

**日常开发：**
1. 本地修改代码
2. 本地构建和测试（本指南）
3. 确认功能正常后提交代码
4. 推送到 GitHub（master 分支）
5. GitHub Actions 自动部署到生产环境

**这样可以确保推送的代码已经过本地验证，减少生产环境出错的可能。**

---

## 📚 相关文档

- `README.md` - 项目概览
- `NEXT_STEPS.md` - 快速开始指南
- `GITHUB_SECRETS_SETUP.md` - GitHub Secrets 配置
- `DEPLOYMENT_CHECKLIST.md` - 部署检查清单
- `.github/workflows/deploy.yml` - CI/CD 配置

---

## 🎉 总结

您现在已经掌握：

- ✅ 在 Apple Silicon Mac 上构建 x86_64 镜像
- ✅ 本地测试 Docker 容器
- ✅ 验证 RAG 应用功能
- ✅ 理解本地构建与 GitHub Actions 的区别

这为您的开发和调试工作提供了完整的本地环境！

