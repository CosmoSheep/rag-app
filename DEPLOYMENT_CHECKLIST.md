# ✅ RAG App 完整部署检查清单

本文档帮助您确认 RAG 应用的所有配置步骤已正确完成。

---

## 📦 1. GitHub Workflow 配置

### 1.1 Workflow 文件
- [x] 文件路径：`.github/workflows/deploy.yml`
- [x] 触发条件：push 到 main 分支
- [x] 权限配置：`id-token: write` 和 `contents: read`

### 1.2 OIDC 认证
- [x] 使用 `aws-actions/configure-aws-credentials@v4`
- [x] 使用 `role-to-assume` 而非 Access Key
- [x] 配置了 `AWS_IAM_ROLE_TO_ASSUME` secret

### 1.3 Pipeline 步骤
- [x] Checkout code
- [x] Set up Python 3.11
- [x] Install dependencies
- [x] Generate FAISS index（使用 OPENAI_API_KEY）
- [x] Configure AWS Credentials（OIDC）
- [x] Log in to Amazon ECR
- [x] Build and push Docker image（使用 github.sha 作为 tag）
- [x] Get App Runner IAM roles（动态获取）
- [x] Deploy to App Runner（使用 awslabs/amazon-app-runner-deploy@main）

---

## 🔐 2. GitHub Secrets 配置

访问：`https://github.com/CosmoSheep/rag-app/settings/secrets/actions`

检查以下 5 个 Secrets 是否已配置：

- [ ] **OPENAI_API_KEY**
  - 格式：`sk-proj-...`
  - 用途：向量化和 RAG 问答

- [ ] **AWS_REGION**
  - 值：`us-east-1`
  - 用途：AWS 服务区域

- [ ] **ECR_REPOSITORY**
  - 值：`bee-edu-rag-app`
  - 用途：ECR 仓库名称

- [ ] **APP_RUNNER_ARN**
  - 值：`arn:aws:apprunner:us-east-1:924030134232:service/rag-app/9ea667871d30400ea99b286d734103b4`
  - 用途：App Runner 服务标识

- [ ] **AWS_IAM_ROLE_TO_ASSUME**
  - 值：`arn:aws:iam::924030134232:role/github-actions-deploy-role`
  - 用途：GitHub Actions OIDC 角色

---

## 🔄 3. 测试自动部署

### 3.1 推送代码触发部署

```bash
cd /Users/heyang/Documents/Repos/rag-app

# 确认当前分支
git branch

# 添加并提交更改（如果有）
git add .
git commit -m "Test deployment workflow"

# 推送到 master 分支
git push origin master
```

### 3.2 监控部署过程

- [ ] 访问 GitHub Actions：`https://github.com/CosmoSheep/rag-app/actions`
- [ ] 查看最新的 workflow run
- [ ] 确认所有步骤都显示绿色 ✅

### 3.3 预期的 Workflow 输出

```
✅ Checkout code
✅ Set up Python
✅ Install dependencies
✅ Generate FAISS index
✅ Configure AWS Credentials
✅ Log in to Amazon ECR
✅ Build and push Docker image
✅ Get App Runner IAM roles
✅ Deploy to App Runner
```

---

## 🌐 4. 验证应用部署

### 4.1 检查 App Runner 服务状态

- [ ] 访问 AWS App Runner Console：`https://console.aws.amazon.com/apprunner/`
- [ ] 选择服务：`rag-app`
- [ ] 确认状态：`Running`
- [ ] 确认最新部署时间与 GitHub Actions 运行时间一致

### 4.2 测试默认域名

```bash
# 测试健康检查
curl https://z4nxuhfhkn.us-east-1.awsapprunner.com/health

# 预期输出：
# {"status": "healthy"}
```

```bash
# 测试 RAG API
curl -X POST https://z4nxuhfhkn.us-east-1.awsapprunner.com/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "这个RAG Demo使用了什么技术栈？"}'

# 预期输出：
# {"answer": "...", "sources": [...]}
```

### 4.3 浏览器测试

- [ ] 访问：`https://z4nxuhfhkn.us-east-1.awsapprunner.com`
- [ ] 确认页面正常加载
- [ ] 确认 HTTPS 证书有效

---

## ☁️ 5. Cloudflare 自定义域名（可选）

如果需要配置自定义域名（如 `rag.yourdomain.com`），请参考 `CLOUDFLARE_SETUP.md`。

### 5.1 在 App Runner 中添加自定义域名

- [ ] 打开 App Runner Console
- [ ] 选择服务：`rag-app`
- [ ] 点击 "Custom domains" 标签
- [ ] 添加域名：`rag.yourdomain.com`
- [ ] 获取验证和指向的 CNAME 记录

### 5.2 在 Cloudflare 中配置 DNS

- [ ] 登录 Cloudflare Dashboard
- [ ] 添加验证 CNAME 记录（用于 SSL 证书验证）
- [ ] 添加指向 CNAME 记录（指向 App Runner 域名）
- [ ] 确保 Proxy status 为 "DNS only"（灰色云朵）

### 5.3 等待 SSL 证书生成

- [ ] DNS 传播完成（5-15 分钟）
- [ ] App Runner 域名状态变为 "Active"
- [ ] 证书状态变为 "Issued"

### 5.4 测试自定义域名

```bash
# 测试 HTTPS 访问
curl https://rag.yourdomain.com/health

# 浏览器访问
# https://rag.yourdomain.com
```

---

## 🔍 6. 故障排查

### 6.1 GitHub Actions 失败

**症状：** Workflow run 显示红色 ❌

**排查步骤：**
1. 点击失败的步骤查看详细日志
2. 常见问题：
   - OIDC 认证失败 → 检查 `AWS_IAM_ROLE_TO_ASSUME`
   - ECR 推送失败 → 检查 IAM 权限
   - FAISS 生成失败 → 检查 `OPENAI_API_KEY`

### 6.2 App Runner 部署失败

**症状：** Service 状态为 "Operation in progress" 很久

**排查步骤：**
```bash
# 查看 App Runner 日志
aws apprunner describe-service \
  --service-arn arn:aws:apprunner:us-east-1:924030134232:service/rag-app/9ea667871d30400ea99b286d734103b4 \
  --region us-east-1
```

### 6.3 API 返回 500 错误

**症状：** 应用部署成功但 API 调用失败

**排查步骤：**
1. 检查 App Runner 日志
2. 验证环境变量：
   - OpenAI API Key 是否配置在 AWS Secrets Manager
   - App Runner Instance Role 是否有权限访问 Secrets Manager

### 6.4 Cloudflare 域名无法访问

**症状：** 自定义域名配置后无法访问

**排查步骤：**
```bash
# 检查 DNS 解析
dig rag.yourdomain.com

# 应该返回 App Runner 的 CNAME
# 而不是 Cloudflare 的 IP（如果是 DNS only 模式）
```

---

## 📊 7. 监控和维护

### 7.1 定期检查项

- [ ] **每周检查：** App Runner 服务健康状态
- [ ] **每月检查：** OpenAI API 使用量和费用
- [ ] **每月检查：** AWS 服务费用（ECR、App Runner、Secrets Manager）
- [ ] **季度检查：** 依赖包更新（requirements.txt）

### 7.2 日志查看

```bash
# 查看最近的 GitHub Actions 运行
# https://github.com/CosmoSheep/rag-app/actions

# 查看 App Runner 日志（通过 CloudWatch）
aws logs tail /aws/apprunner/rag-app/service \
  --follow \
  --region us-east-1
```

### 7.3 成本优化

- **ECR 镜像清理：** 定期删除旧镜像
  ```bash
  # 查看所有镜像
  aws ecr list-images \
    --repository-name bee-edu-rag-app \
    --region us-east-1
  ```

- **App Runner 实例配置：** 根据实际负载调整 CPU/内存
  - 当前配置：1 vCPU, 2 GB Memory
  - 可在 `.github/workflows/deploy.yml` 中调整

---

## 📝 8. 文档清单

确认以下文档都已查看并理解：

- [ ] `README.md` - 项目概览
- [ ] `GITHUB_SECRETS_SETUP.md` - GitHub Secrets 配置详解
- [ ] `CLOUDFLARE_SETUP.md` - Cloudflare 域名配置详解
- [ ] `DEPLOYMENT_GUIDE.md` - 完整部署指南
- [ ] `DEPLOYMENT_CHECKLIST.md` - 本检查清单
- [ ] `.github/workflows/deploy.yml` - CI/CD 配置

---

## 🎯 9. 最终验证

完成所有配置后，运行以下完整测试：

```bash
# 1. 健康检查
curl https://z4nxuhfhkn.us-east-1.awsapprunner.com/health

# 2. RAG 问答测试
curl -X POST https://z4nxuhfhkn.us-east-1.awsapprunner.com/chat \
  -H "Content-Type: application/json" \
  -d '{
    "question": "这个RAG Demo使用了什么技术栈？"
  }'

# 3. 如果配置了自定义域名，也测试自定义域名
curl https://rag.yourdomain.com/health
```

---

## ✨ 10. 完成标志

当以下所有项都完成时，您的 RAG 应用就已经成功部署：

- [x] GitHub Workflow 文件配置正确
- [x] 所有 5 个 GitHub Secrets 已配置
- [ ] 推送代码后 GitHub Actions 自动运行成功
- [ ] App Runner 服务状态为 "Running"
- [ ] 默认域名可通过 HTTPS 访问
- [ ] API 健康检查返回正常
- [ ] RAG 问答功能正常工作
- [ ] （可选）自定义域名配置成功

---

## 🚀 下一步

部署完成后，您可以：

1. **扩展功能**
   - 添加更多数据源到 `data.txt`
   - 优化 RAG 检索策略
   - 添加用户认证
   - 集成更多 LLM 模型

2. **性能优化**
   - 调整 FAISS 索引参数
   - 优化向量相似度搜索
   - 添加缓存机制
   - 实现并发请求处理

3. **生产就绪**
   - 添加日志聚合
   - 配置告警和监控
   - 实现 A/B 测试
   - 添加速率限制

---

## 📞 获取帮助

如果遇到问题：

1. **查看文档：** 本仓库的所有 .md 文件
2. **查看日志：** GitHub Actions 和 App Runner 日志
3. **AWS 文档：** 
   - App Runner: https://docs.aws.amazon.com/apprunner/
   - ECR: https://docs.aws.amazon.com/ecr/
4. **GitHub Actions 文档：** https://docs.github.com/actions

---

## 🎉 恭喜！

如果您完成了所有检查项，您已经成功部署了一个：

- ✅ 全自动 CI/CD 的 RAG 应用
- ✅ 无密钥认证（OIDC）
- ✅ 容器化部署（Docker + ECR）
- ✅ 弹性扩缩容（App Runner）
- ✅ HTTPS 加密访问
- ✅ （可选）自定义域名

这是一个生产级别的部署架构！🚀


