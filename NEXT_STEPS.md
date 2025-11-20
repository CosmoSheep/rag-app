# 🎯 接下来要做什么

您的 GitHub Workflow 配置已经完成！现在只需要完成以下步骤即可实现自动部署。

---

## ⚡ 快速开始（3 个步骤）

### 步骤 1️⃣：配置 GitHub Secrets（5 分钟）

访问：`https://github.com/CosmoSheep/rag-app/settings/secrets/actions`

点击 "New repository secret" 依次添加以下 5 个 secrets：

| Secret 名称 | 值 |
|------------|---|
| `OPENAI_API_KEY` | `sk-proj-...`（您的 OpenAI API Key）|
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `bee-edu-rag-app` |
| `APP_RUNNER_ARN` | `arn:aws:apprunner:us-east-1:924030134232:service/rag-app/9ea667871d30400ea99b286d734103b4` |
| `AWS_IAM_ROLE_TO_ASSUME` | `arn:aws:iam::924030134232:role/github-actions-deploy-role` |

---

### 步骤 2️⃣：推送代码触发部署（1 分钟）

```bash
cd /Users/heyang/Documents/Repos/rag-app

# 如果有未提交的更改
git add .
git commit -m "Setup complete: ready for deployment"

# 推送到 main 分支触发自动部署
git push origin main
```

---

### 步骤 3️⃣：验证部署成功（5 分钟）

1. **查看 GitHub Actions 运行状态：**
   ```
   https://github.com/CosmoSheep/rag-app/actions
   ```
   等待所有步骤显示绿色 ✅（约 3-5 分钟）

2. **测试应用：**
   ```bash
   # 健康检查
   curl https://z4nxuhfhkn.us-east-1.awsapprunner.com/health
   
   # RAG 问答
   curl -X POST https://z4nxuhfhkn.us-east-1.awsapprunner.com/chat \
     -H "Content-Type: application/json" \
     -d '{"question": "这个RAG Demo使用了什么技术栈？"}'
   ```

---

## 🎉 完成！

完成以上 3 个步骤后，您的 RAG 应用就会：
- ✅ 每次推送代码到 main 分支自动部署
- ✅ 自动构建 Docker 镜像
- ✅ 自动推送到 ECR
- ✅ 自动更新 App Runner 服务
- ✅ 通过 HTTPS 安全访问

---

## 🌐（可选）配置自定义域名

如果您想使用自己的域名（如 `rag.yourdomain.com`），请查看：
- **详细指南：** `CLOUDFLARE_SETUP.md`

**快速步骤：**
1. 在 App Runner Console 中添加自定义域名
2. 在 Cloudflare 中添加两条 CNAME 记录
3. 等待 SSL 证书生成（5-15 分钟）

---

## 📚 详细文档

- `GITHUB_SECRETS_SETUP.md` - GitHub Secrets 详细说明
- `CLOUDFLARE_SETUP.md` - 自定义域名配置指南
- `DEPLOYMENT_CHECKLIST.md` - 完整部署检查清单
- `.github/workflows/deploy.yml` - CI/CD Workflow 配置

---

## ✅ 当前状态

- [x] **GitHub Workflow 配置** - 已完成
  - 文件：`.github/workflows/deploy.yml`
  - OIDC 认证：已配置
  - Pipeline 步骤：完整

- [ ] **GitHub Secrets 配置** - 待完成（步骤 1）
  - 需要添加 5 个 secrets

- [ ] **首次部署** - 待完成（步骤 2 & 3）
  - 推送代码触发部署

- [ ] **自定义域名** - 可选
  - 参考 `CLOUDFLARE_SETUP.md`

---

## 🔑 Workflow 特性

您的 Workflow 已配置以下最佳实践：

1. **安全认证：**
   - ✅ 使用 OIDC（无密钥认证）
   - ✅ 不存储永久 Access Key
   - ✅ 临时凭证，权限受限

2. **自动化流程：**
   - ✅ 代码推送自动触发
   - ✅ 自动生成 FAISS 索引
   - ✅ 自动构建 Docker 镜像
   - ✅ 自动部署到 App Runner

3. **镜像管理：**
   - ✅ 使用 git SHA 作为镜像 tag
   - ✅ 每次部署都有唯一标识
   - ✅ 便于回滚和追踪

4. **角色动态获取：**
   - ✅ 自动获取 access-role-arn
   - ✅ 自动获取 instance-role-arn
   - ✅ 无需手动配置角色

---

## 💡 使用提示

### 日常开发流程

```bash
# 1. 修改代码
vim app.py

# 2. 本地测试
python app.py

# 3. 提交并推送
git add .
git commit -m "Update: feature description"
git push origin main

# 4. 自动部署（无需任何操作）
# GitHub Actions 会自动运行并部署
```

### 监控部署

- **GitHub Actions:** `https://github.com/CosmoSheep/rag-app/actions`
- **AWS App Runner:** `https://console.aws.amazon.com/apprunner/`
- **应用 URL:** `https://z4nxuhfhkn.us-east-1.awsapprunner.com`

---

## ❓ 常见问题

**Q: Secrets 配置后多久生效？**
A: 立即生效。配置完成后，下一次 git push 就会使用新的 secrets。

**Q: 如果部署失败怎么办？**
A: 查看 GitHub Actions 的日志，找到失败的步骤，根据错误信息排查。常见问题见 `DEPLOYMENT_CHECKLIST.md` 第 6 节。

**Q: 可以回滚到之前的版本吗？**
A: 可以。每个 git commit 都会生成一个唯一的 Docker 镜像（使用 commit SHA 作为 tag）。您可以在 ECR 中找到历史镜像并手动部署。

**Q: 部署需要多长时间？**
A: 通常 3-5 分钟完成整个流程（构建 + 推送 + 部署）。

---

## 🚀 准备好了吗？

现在就开始：

1. 打开 GitHub Secrets 页面
2. 添加 5 个 secrets
3. 推送代码
4. 观察自动部署！

祝部署顺利！🎊


