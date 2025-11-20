# 🔐 GitHub Secrets 配置指南

## 前提条件
- ✅ AWS 资源已创建（ECR、IAM、Secrets Manager）
- ✅ App Runner 服务已创建: `rag-app`
- ✅ 服务 URL: `z4nxuhfhkn.us-east-1.awsapprunner.com`
- ✅ 端口配置正确: `8000`

---

## 📝 需要配置的 5 个 GitHub Secrets

访问你的 GitHub 仓库设置页面：
https://github.com/CosmoSheep/rag-app/settings/secrets/actions

点击 "New repository secret" 添加以下 5 个 secrets：

### 1. AWS_REGION
```
us-east-1
```

### 2. ECR_REGISTRY
```
924030134232.dkr.ecr.us-east-1.amazonaws.com
```

### 3. ECR_REPOSITORY
```
bee-edu-rag-app
```

### 4. IAM_ROLE_ARN
```
arn:aws:iam::924030134232:role/github-actions-deploy-role
```

### 5. APPRUNNER_SERVICE_ARN
```
arn:aws:apprunner:us-east-1:924030134232:service/rag-app/9ea667871d30400ea99b286d734103b4
```

---

## 🚀 配置完成后的操作

### 步骤 1: 推送代码到 GitHub
```bash
cd /Users/heyang/Documents/Repos/AI_native_product/rag-app

# 初始化 Git 仓库（如果还未初始化）
git init

# 添加远程仓库
git remote add origin https://github.com/CosmoSheep/rag-app.git

# 添加所有文件（.gitignore 会自动排除敏感文件）
git add .

# 提交
git commit -m "Initial commit: RAG app with CI/CD setup"

# 推送到 master 分支
git push -u origin master
```

### 步骤 2: 验证 CI/CD 流程

1. 推送代码后，访问 GitHub Actions 页面：
   https://github.com/CosmoSheep/rag-app/actions

2. 观察工作流运行状态：
   - ✅ Checkout code
   - ✅ Set up Python
   - ✅ Install dependencies
   - ✅ Generate FAISS index
   - ✅ Configure AWS credentials
   - ✅ Login to ECR
   - ✅ Build Docker image
   - ✅ Push to ECR
   - ✅ Deploy to App Runner

3. 部署成功后，访问你的应用：
   https://z4nxuhfhkn.us-east-1.awsapprunner.com

### 步骤 3: 测试 API 端点

```bash
# 测试健康检查
curl https://z4nxuhfhkn.us-east-1.awsapprunner.com/health

# 测试 RAG 问答
curl -X POST https://z4nxuhfhkn.us-east-1.awsapprunner.com/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "这个RAG Demo使用了什么技术栈？"}'
```

---

## 🔄 后续更新流程

每次代码修改后：
```bash
git add .
git commit -m "Update: 描述你的修改"
git push origin main
```

GitHub Actions 会自动：
1. 重新生成 FAISS 索引
2. 构建新的 Docker 镜像
3. 推送到 ECR
4. 触发 App Runner 自动部署

---

## 🌐 （可选）配置 Cloudflare 自定义域名

如果你想使用自己的域名（如 `rag.yourdomain.com`）：

1. 在 App Runner 中添加自定义域名
2. 获取 DNS 验证记录
3. 在 Cloudflare 中添加 CNAME 记录
4. 等待 SSL 证书自动生成

详细步骤参考: DEPLOYMENT_GUIDE.md

---

## 📊 资源清单

### AWS Resources
- ECR Repository: `bee-edu-rag-app`
- App Runner Service: `rag-app`
- IAM Roles: 3 个（GitHub Actions, App Runner Service, Instance）
- Secrets Manager: `bee-edu-openai-key-secret`

### GitHub
- Repository: `CosmoSheep/rag-app`
- Workflow: `.github/workflows/deploy.yml`
- Secrets: 5 个配置项

---

## ❓ 故障排查

### GitHub Actions 失败
- 检查 Secrets 是否配置正确
- 查看 Actions 日志详细错误信息
- 验证 IAM 权限是否充足

### App Runner 部署失败
- 检查 ECR 镜像是否成功推送
- 验证端口配置是否为 8000
- 查看 App Runner 服务日志

### API 调用失败
- 检查 OpenAI API Key 是否有效
- 验证 FAISS 索引是否正确生成
- 查看 App Runner 应用日志

---

## 🎉 完成！

配置完成后，你的 RAG 应用将实现：
✅ 代码推送即部署
✅ 自动构建 Docker 镜像
✅ 自动更新 App Runner
✅ HTTPS 访问
✅ 自动扩缩容

