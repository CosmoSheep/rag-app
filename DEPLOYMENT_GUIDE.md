# 🚀 RAG App 部署指南

## ✅ 已完成的步骤

### 1. AWS 基础资源（已通过 Terraform 创建）
- ✅ ECR Repository: `bee-edu-rag-app`
- ✅ GitHub OIDC Provider (用于无密钥 CI/CD)
- ✅ IAM Roles:
  - `github-actions-deploy-role` (GitHub Actions 使用)
  - `bee-edu-apprunner-role` (App Runner 服务角色)
  - `bee-edu-apprunner-instance-role` (App Runner 实例角色)
- ✅ Secrets Manager: `bee-edu-openai-key-secret`
- ✅ Docker 镜像已推送: `924030134232.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:latest`

---

## ⏳ 待完成步骤

### Step 1: 订阅 App Runner 服务

由于您的 AWS 账户首次使用 App Runner，需要先订阅：

1. 访问 AWS App Runner 控制台：
   ```
   https://console.aws.amazon.com/apprunner/home?region=us-east-1
   ```

2. 点击 **"Get Started"** 或 **"Create Service"**

3. 如果提示需要订阅，点击订阅链接（通常是免费的）

4. 订阅完成后，继续下面的步骤

---

### Step 2: 创建 App Runner 服务（手动方式）

#### 方式 A: 通过 AWS Console（推荐）

1. **Source and deployment**
   - Repository type: `Container registry`
   - Provider: `Amazon ECR`
   - Container image URI: `924030134232.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:latest`
   - ECR access role: `bee-edu-apprunner-role`
   - Deployment trigger: `Manual`

2. **Configure service**
   - Service name: `bee-edu-rag-service`
   - Virtual CPU: `1 vCPU`
   - Memory: `2 GB`
   - Port: `8000`
   
   **Environment variables:**
   - Source: `Secrets Manager`
   - Name: `OPENAI_API_KEY`
   - Value: `arn:aws:secretsmanager:us-east-1:924030134232:secret:bee-edu-openai-key-secret-rZlJ96`
   
   **Security:**
   - Instance role: `bee-edu-apprunner-instance-role`
   
   **Health check:**
   - Protocol: `HTTP`
   - Path: `/health`
   - Interval: `10` seconds

3. 点击 **"Create & deploy"**

4. 等待 3-5 分钟，服务状态变为 `Running`

5. 记录 **Service ARN** 和 **Service URL**

#### 方式 B: 通过 AWS CLI（订阅后）

```bash
aws apprunner create-service \
  --service-name bee-edu-rag-service \
  --source-configuration '{
    "AuthenticationConfiguration": {
      "AccessRoleArn": "arn:aws:iam::924030134232:role/bee-edu-apprunner-role"
    },
    "ImageRepository": {
      "ImageIdentifier": "924030134232.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:latest",
      "ImageRepositoryType": "ECR",
      "ImageConfiguration": {
        "Port": "8000",
        "RuntimeEnvironmentSecrets": {
          "OPENAI_API_KEY": "arn:aws:secretsmanager:us-east-1:924030134232:secret:bee-edu-openai-key-secret-rZlJ96"
        }
      }
    },
    "AutoDeploymentsEnabled": false
  }' \
  --instance-configuration '{
    "Cpu": "1024",
    "Memory": "2048",
    "InstanceRoleArn": "arn:aws:iam::924030134232:role/bee-edu-apprunner-instance-role"
  }' \
  --region us-east-1
```

---

### Step 3: 获取 App Runner 服务信息

```bash
# 列出所有服务
aws apprunner list-services --region us-east-1

# 获取服务详情
aws apprunner describe-service \
  --service-arn YOUR_SERVICE_ARN \
  --region us-east-1
```

---

### Step 4: 配置 GitHub Secrets

在 GitHub 仓库 `CosmoSheep/rag-app` 中配置以下 Secrets：

**路径：** `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

| Secret 名称 | 值 | 说明 |
|------------|---|------|
| `OPENAI_API_KEY` | `sk-proj-...` | OpenAI API Key |
| `AWS_REGION` | `us-east-1` | AWS 区域 |
| `ECR_REPOSITORY` | `bee-edu-rag-app` | ECR 仓库名 |
| `APP_RUNNER_ARN` | `arn:aws:apprunner:us-east-1:924030134232:service/...` | 从 Step 2 获取 |
| `AWS_IAM_ROLE_TO_ASSUME` | `arn:aws:iam::924030134232:role/github-actions-deploy-role` | GitHub Actions 角色 |

---

### Step 5: 推送代码到 GitHub

```bash
cd /Users/heyang/Documents/Repos/AI_native_product/rag-app

# 初始化 Git（如果还没有）
git init

# 添加 .gitignore
echo "terraform.tfvars" >> .gitignore
echo ".terraform/" >> .gitignore
echo "terraform.tfstate*" >> .gitignore
echo "*.tfplan" >> .gitignore

# 提交代码
git add .
git commit -m "Initial commit: RAG App with CI/CD"

# 添加远程仓库
git remote add origin https://github.com/CosmoSheep/rag-app.git

# 推送到 main 分支
git branch -M main
git push -u origin main
```

---

### Step 6: 验证自动部署

1. 推送代码后，GitHub Actions 会自动触发

2. 查看工作流状态：
   ```
   https://github.com/CosmoSheep/rag-app/actions
   ```

3. 工作流会：
   - ✅ 生成 FAISS 向量索引
   - ✅ 构建 Docker 镜像
   - ✅ 推送到 ECR
   - ✅ 更新 App Runner 服务

4. 等待部署完成（约 5 分钟）

---

## 🧪 测试部署

```bash
# 获取服务 URL
SERVICE_URL=$(aws apprunner describe-service \
  --service-arn YOUR_SERVICE_ARN \
  --query 'Service.ServiceUrl' \
  --output text)

# 测试健康检查
curl https://$SERVICE_URL/health

# 测试问答接口
curl -X POST https://$SERVICE_URL/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "这个 RAG demo 是做什么用的？"}'
```

---

## 🌐 配置 Cloudflare 域名（可选）

1. 获取 App Runner 默认域名（格式：`xxxxx.us-east-1.awsapprunner.com`）

2. 在 Cloudflare 添加 CNAME 记录：
   - **Type**: `CNAME`
   - **Name**: `rag` (或其他子域名)
   - **Target**: App Runner 默认域名
   - **Proxy status**: DNS only (灰色云朵)

3. 等待 DNS 生效，然后可以通过自定义域名访问

---

## 📊 已创建的资源汇总

### Terraform Outputs
```
ecr_repository_name     = "bee-edu-rag-app"
github_actions_role_arn = "arn:aws:iam::924030134232:role/github-actions-deploy-role"
```

### 账户信息
- AWS Account ID: `924030134232`
- AWS Region: `us-east-1`
- GitHub Repository: `CosmoSheep/rag-app`

---

## 🔧 维护命令

```bash
# 更新知识库
# 1. 修改 data.txt
# 2. 推送到 GitHub，自动触发部署

# 手动触发部署
aws apprunner start-deployment --service-arn YOUR_SERVICE_ARN

# 查看服务日志（在 AWS Console）
https://console.aws.amazon.com/apprunner/

# 查看 ECR 镜像
aws ecr list-images --repository-name bee-edu-rag-app

# 销毁所有资源（谨慎使用）
cd /Users/heyang/Documents/Repos/AI_native_product/rag-app
terraform destroy
```

---

## ⚠️ 重要提示

1. **安全**：
   - ✅ 使用 OIDC，无需永久 Access Key
   - ✅ API Key 存储在 Secrets Manager
   - ✅ terraform.tfvars 已加入 .gitignore

2. **成本**：
   - ECR: 免费套餐 0.5GB/月
   - App Runner: 按使用量计费（~$25/月起）
   - Secrets Manager: $0.40/月/secret

3. **限制**：
   - 冷启动时间：~30秒
   - 单次请求超时：120秒
   - 并发请求：可扩展

---

## 🎉 完成！

完成上述所有步骤后，你将拥有：
- ✅ 完全自动化的 CI/CD 流程
- ✅ 基于 ECR + App Runner 的容器化部署
- ✅ 无服务器、可扩展的 RAG 应用
- ✅ 安全的密钥管理
- ✅ 自定义域名支持（可选）

如有问题，请查看：
- GitHub Actions 日志
- App Runner 服务日志
- CloudWatch Logs

