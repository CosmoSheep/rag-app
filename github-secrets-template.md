# GitHub Secrets 配置模板

## 配置路径
`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

---

## 需要配置的 Secrets

### 1. OPENAI_API_KEY
```
Secret 名称: OPENAI_API_KEY
值: sk-proj-... (你的 OpenAI API Key)
说明: 用于向量化和 RAG 问答
```

### 2. AWS_REGION
```
Secret 名称: AWS_REGION
值: us-east-1
说明: AWS 区域
```

### 3. ECR_REPOSITORY
```
Secret 名称: ECR_REPOSITORY
值: bee-edu-rag-app
说明: ECR 仓库名称
```

### 4. APP_RUNNER_ARN
```
Secret 名称: APP_RUNNER_ARN
值: [待填写 - 创建 App Runner 服务后获取]
说明: App Runner 服务的完整 ARN
格式: arn:aws:apprunner:us-east-1:924030134232:service/bee-edu-rag-service/...
```

**如何获取 APP_RUNNER_ARN:**

方式 1 - AWS Console:
1. 访问 https://console.aws.amazon.com/apprunner/
2. 点击服务名称 `bee-edu-rag-service`
3. 在 "Overview" 页面复制 "Service ARN"

方式 2 - AWS CLI:
```bash
aws apprunner list-services --region us-east-1 \
  --query "ServiceSummaryList[?ServiceName=='bee-edu-rag-service'].ServiceArn" \
  --output text
```

### 5. AWS_IAM_ROLE_TO_ASSUME
```
Secret 名称: AWS_IAM_ROLE_TO_ASSUME
值: arn:aws:iam::924030134232:role/github-actions-deploy-role
说明: GitHub Actions 使用的 IAM 角色（通过 OIDC 认证）
```

---

## 验证配置

配置完成后，所有 5 个 Secrets 应该在列表中可见：

- [x] OPENAI_API_KEY
- [x] AWS_REGION
- [x] ECR_REPOSITORY
- [x] APP_RUNNER_ARN
- [x] AWS_IAM_ROLE_TO_ASSUME

---

## 测试自动部署

1. 推送代码到 main 分支：
```bash
git add .
git commit -m "Test deployment"
git push origin main
```

2. 查看 GitHub Actions 工作流：
```
https://github.com/CosmoSheep/rag-app/actions
```

3. 工作流应该自动运行并完成以下步骤：
   - ✅ Checkout code
   - ✅ Set up Python
   - ✅ Install dependencies
   - ✅ Generate FAISS index
   - ✅ Configure AWS Credentials (通过 OIDC)
   - ✅ Log in to Amazon ECR
   - ✅ Build and push Docker image
   - ✅ Deploy to App Runner

---

## 常见问题

### Q: OIDC 认证失败
**错误信息:** `Error: Not authorized to perform sts:AssumeRoleWithWebIdentity`

**解决方案:**
- 确认 GitHub 仓库名称正确: `CosmoSheep/rag-app`
- 确认只在 main 分支触发
- 检查 IAM Role 的信任策略是否正确

### Q: ECR 推送失败
**错误信息:** `denied: User is not authorized to perform: ecr:PutImage`

**解决方案:**
- 确认 AWS_IAM_ROLE_TO_ASSUME 配置正确
- 检查 IAM Role 是否有 ECR 推送权限

### Q: App Runner 部署失败
**错误信息:** `Service update failed`

**解决方案:**
- 确认 APP_RUNNER_ARN 正确
- 确认镜像成功推送到 ECR
- 检查 App Runner 服务日志

---

## 相关链接

- **GitHub Actions 文档:** https://docs.github.com/actions
- **AWS OIDC 文档:** https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
- **App Runner 文档:** https://docs.aws.amazon.com/apprunner/

