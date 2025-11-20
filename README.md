# RAG Demo - W1001a 作业

一个基于 LangChain 的简单 RAG 问答应用，包含完整的 CI/CD 流程。

## 快速开始

### 1. 本地运行

```bash
# 设置 API Key
export OPENAI_API_KEY="your-openai-api-key"

# 安装依赖
pip install -r requirements.txt

# 生成向量索引
python ingest.py

# 启动服务
python app.py
```

访问 http://localhost:8000 查看 API 文档。

### 2. 测试 API

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "这个 RAG demo 是做什么用的？"}'
```

## 部署流程

### 步骤 1: 使用 Terraform 创建 AWS 资源

```bash
cd terraform
terraform init
terraform apply
```

记录 outputs 中的值，后续配置 GitHub Secrets 需要用到。

### 步骤 2: 配置 GitHub Secrets

在 GitHub 仓库的 Settings > Secrets and variables > Actions 中添加以下 Secrets：

- `OPENAI_API_KEY`: 你的 OpenAI API Key
- `AWS_REGION`: AWS 区域（如 us-east-1）
- `ECR_REPOSITORY`: ECR 仓库名称（来自 Terraform output）
- `APP_RUNNER_ARN`: App Runner 服务 ARN（来自 Terraform output）
- `AWS_IAM_ROLE_TO_ASSUME`: GitHub Actions OIDC 角色 ARN（来自 Terraform output）

### 步骤 3: 推送代码触发部署

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

GitHub Actions 会自动构建并部署到 AWS App Runner。

### 步骤 4: 配置 Cloudflare 域名

1. 在 Cloudflare 添加 CNAME 记录
2. 指向 App Runner 的默认域名（格式：xxx.awsapprunner.com）
3. 等待 DNS 生效

## 项目结构

```
rag-app/
├── data.txt              # 知识库文本
├── ingest.py             # 向量化脚本
├── app.py                # FastAPI 应用
├── requirements.txt      # Python 依赖
├── Dockerfile            # 容器配置
├── .gitignore           
├── faiss_index/          # FAISS 索引（本地生成，不提交）
└── .github/
    └── workflows/
        └── deploy.yml    # CI/CD 配置
```

## 技术栈

- **LangChain**: RAG 框架
- **FAISS**: 向量存储
- **FastAPI**: Web API
- **Docker**: 容器化
- **AWS App Runner**: 托管服务
- **GitHub Actions**: CI/CD
- **Cloudflare**: CDN 和域名

## API 端点

- `GET /`: API 信息
- `GET /health`: 健康检查
- `POST /chat`: 问答接口

## 注意事项

1. 构建 Docker 镜像前必须先运行 `ingest.py` 生成 `faiss_index` 目录
2. GitHub Actions 会在每次部署时自动运行 `ingest.py`
3. 更新知识库后需要重新部署才能生效
4. 使用 OIDC 认证，不需要在 Secrets 中存储永久 Access Key

## 常见问题

**Q: 向量索引为什么不提交到 Git？**  
A: 向量索引会在 CI/CD 流程中动态生成，避免提交大文件到仓库。

**Q: 如何更新知识库？**  
A: 修改 `data.txt` 后推送代码，GitHub Actions 会自动重新生成索引并部署。

**Q: 部署失败怎么办？**  
A: 检查 GitHub Actions 日志，确认所有 Secrets 配置正确，IAM 角色权限充足。

