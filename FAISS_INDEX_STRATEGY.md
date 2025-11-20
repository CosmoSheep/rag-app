# 📦 FAISS 索引管理策略

## 当前采用策略：方案 A - 提交索引到 Git

### ✅ 为什么选择这个方案？

1. **符合课程要求**
   - 索引作为文件存在于 `faiss_index/` 文件夹
   - Docker 构建时直接 COPY 到镜像中
   - 与课上演示的方式一致

2. **简化 CI/CD**
   - ❌ 不需要在 GitHub Actions 中重新生成索引
   - ❌ 不需要在 GitHub Secrets 中配置 OPENAI_API_KEY
   - ✅ 构建更快（省略索引生成步骤）
   - ✅ 更稳定（不依赖外部 API）

3. **节省成本**
   - 不会在每次部署时调用 OpenAI API
   - 本地生成一次，多次使用

4. **索引文件很小**
   - `index.faiss`: 18KB
   - `index.pkl`: 3.5KB
   - 总计约 21.5KB，对 Git 仓库影响极小

---

## 📋 当前配置

### 文件结构
```
rag-app/
├── faiss_index/          # ✅ 已提交到 Git
│   ├── index.faiss
│   └── index.pkl
├── Dockerfile            # COPY faiss_index
├── ingest.py             # 本地运行生成索引
└── .github/workflows/
    └── deploy.yml        # ❌ 不生成索引
```

### Dockerfile (第 13 行)
```dockerfile
# 复制 FAISS 索引（必须在构建前已生成）
COPY faiss_index ./faiss_index
```

### GitHub Actions Workflow
```yaml
steps:
  - name: Checkout code        # ✅ 包含 faiss_index
  - name: Set up Python        # 不需要了
  - name: Install dependencies # 不需要了
  - name: Generate FAISS index # ❌ 已删除
  - name: Configure AWS...     # ✅ 直接构建
```

---

## 🔄 数据更新流程

当 `data.txt` 内容变化时，需要重新生成索引：

### 步骤 1：修改数据
```bash
cd /Users/heyang/Documents/Repos/rag-app

# 编辑数据文件
vim data.txt
```

### 步骤 2：本地重新生成索引
```bash
# 确保设置了 OPENAI_API_KEY
export OPENAI_API_KEY="sk-proj-..."

# 重新生成索引
python ingest.py
```

**预期输出：**
```
🔄 正在读取 data.txt...
✅ 成功读取 X 个字符
🔄 正在分割文本...
✅ 生成了 Y 个文本块
🔄 正在向量化并创建 FAISS 索引...
✅ FAISS 索引已保存到 faiss_index/
```

### 步骤 3：提交新索引
```bash
# 查看变化
git status

# 应该看到：
# modified: data.txt
# modified: faiss_index/index.faiss
# modified: faiss_index/index.pkl

# 提交变更
git add data.txt faiss_index/
git commit -m "Update: 更新知识库数据和索引"
git push origin master
```

### 步骤 4：自动部署
- GitHub Actions 自动触发
- 使用新的索引构建镜像
- 部署到 App Runner

---

## 🆚 方案对比

| 特性 | 方案 A（当前）| 方案 B（动态生成）|
|------|--------------|------------------|
| **索引存储** | Git 仓库 | 不存储 |
| **CI 生成索引** | ❌ 否 | ✅ 是 |
| **需要 OPENAI_API_KEY in GitHub** | ❌ 否 | ✅ 是 |
| **构建速度** | ⚡ 快 | 🐌 慢 |
| **API 调用费用** | 💰 零（本地生成） | 💰💰 每次部署 |
| **Git 仓库大小** | +21.5KB | 不变 |
| **稳定性** | 🛡️ 高 | ⚠️ 依赖外部 API |
| **适用场景** | 数据不常变 | 数据频繁变 |
| **符合课程要求** | ✅ 是 | ⚠️ 不完全 |

---

## 🔐 简化的 GitHub Secrets 配置

采用方案 A 后，只需配置 **4 个** Secrets（而不是 5 个）：

| Secret 名称 | 值 | 用途 |
|------------|---|------|
| ~~`OPENAI_API_KEY`~~ | ~~不需要~~ | ~~不需要~~ |
| `AWS_REGION` | `us-east-1` | AWS 区域 |
| `ECR_REPOSITORY` | `bee-edu-rag-app` | ECR 仓库名称 |
| `APP_RUNNER_ARN` | `arn:aws:apprunner:...` | App Runner 服务 ARN |
| `AWS_IAM_ROLE_TO_ASSUME` | `arn:aws:iam::...` | OIDC 角色 ARN |

**注意：** App Runner 运行时仍然需要 OPENAI_API_KEY，但通过 AWS Secrets Manager 配置，不在 GitHub Secrets 中。

---

## 🚀 优势总结

### 对于学生作业
- ✅ 符合课程"索引作为文件存在"的要求
- ✅ 展示对 Docker 分层构建的理解
- ✅ 简化 CI/CD 配置

### 对于生产实践
- ✅ 减少外部依赖
- ✅ 降低运维成本
- ✅ 提高部署速度
- ✅ 增强系统稳定性

---

## ⚠️ 何时考虑方案 B？

如果遇到以下情况，可以切换回动态生成：

1. **数据频繁变化**
   - 每天/每小时更新数据
   - 需要自动同步最新内容

2. **索引文件很大**
   - 超过 100MB
   - Git 仓库性能受影响

3. **多环境不同数据**
   - dev/staging/prod 使用不同数据
   - 需要在 CI 中根据环境生成

### 切换到方案 B 的步骤

```bash
# 1. 将 faiss_index 加回 .gitignore
echo "faiss_index/" >> .gitignore

# 2. 从 Git 中移除索引文件
git rm -r --cached faiss_index/

# 3. 恢复 workflow 中的生成步骤（参考 git history）

# 4. 在 GitHub Secrets 中添加 OPENAI_API_KEY
```

---

## 📚 相关文件

- `ingest.py` - 本地生成索引的脚本
- `Dockerfile` - Docker 构建配置
- `.github/workflows/deploy.yml` - CI/CD 配置
- `.gitignore` - Git 忽略规则

---

## ✅ 检查清单

完成以下确认：

- [x] `faiss_index/` 不在 `.gitignore` 中
- [x] `faiss_index/` 已提交到 Git
- [x] GitHub Actions workflow 不生成索引
- [x] Dockerfile 包含 `COPY faiss_index ./faiss_index`
- [ ] 只需配置 4 个 GitHub Secrets（不包括 OPENAI_API_KEY）
- [ ] App Runner 通过 AWS Secrets Manager 访问 OPENAI_API_KEY

---

## 🎓 课程要求对照

根据您提供的课程要求：

> "向量索引必须（像课上演示一样）作为文件 (faiss_index 文件夹) 存在，并能被 COPY 进 Docker 镜像中。"

✅ **完全符合：**
- faiss_index 文件夹存在 ✅
- 作为文件提交到 Git ✅
- Dockerfile 中 COPY 进镜像 ✅
- 与课上演示方式一致 ✅

这就是标准的做法！

