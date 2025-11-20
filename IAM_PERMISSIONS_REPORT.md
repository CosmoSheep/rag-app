# IAM 权限配置报告

**生成时间：** 2025-11-20  
**项目：** RAG App - AWS 部署  
**账户 ID：** 924030134232  
**区域：** us-east-1

---

## ✅ 修复内容

### 1. 端口配置错误 ⚠️ → ✅
**问题：** `main.tf` 第 220 行配置端口为 8080，但 Dockerfile 暴露的是 8000  
**修复：** 已更改为 `port = "8000"`  
**状态：** ✅ 已修复

### 2. ECR 权限增强 🔄 → ✅
**添加权限：**
- `ecr:BatchDeleteImage` - 允许删除旧镜像
- `ecr:ListImages` - 允许列出镜像

**用途：** 便于清理旧的 Docker 镜像，控制存储成本  
**状态：** ✅ 已添加

---

## 📋 IAM 角色和权限清单

### 1️⃣ **GitHub Actions Role**
**角色名称：** `github-actions-deploy-role`  
**ARN：** `arn:aws:iam::924030134232:role/github-actions-deploy-role`

#### 信任策略（Trust Policy）
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::924030134232:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:sub": "repo:CosmoSheep/rag-app:ref:refs/heads/main"
      }
    }
  }]
}
```

**安全特性：**
- ✅ 使用 OIDC（无需永久密钥）
- ✅ 仅限特定仓库：`CosmoSheep/rag-app`
- ✅ 仅限 `main` 分支
- ✅ 无法从其他分支或仓库使用

#### 权限策略（Permissions Policy）

**ECR 操作权限：**
| 权限 | 资源范围 | 用途 |
|------|---------|------|
| `ecr:GetAuthorizationToken` | `*` | 获取 ECR 登录令牌（必须全局）|
| `ecr:BatchCheckLayerAvailability` | `bee-edu-rag-app` | 检查镜像层是否存在 |
| `ecr:CompleteLayerUpload` | `bee-edu-rag-app` | 完成层上传 |
| `ecr:InitiateLayerUpload` | `bee-edu-rag-app` | 初始化层上传 |
| `ecr:PutImage` | `bee-edu-rag-app` | 推送镜像 |
| `ecr:UploadLayerPart` | `bee-edu-rag-app` | 上传镜像层 |
| `ecr:BatchDeleteImage` | `bee-edu-rag-app` | 删除旧镜像 ✨新增 |
| `ecr:ListImages` | `bee-edu-rag-app` | 列出镜像 ✨新增 |

**App Runner 操作权限：**
| 权限 | 资源范围 | 用途 |
|------|---------|------|
| `apprunner:StartDeployment` | `*` | 触发新部署 |
| `apprunner:DescribeService` | `*` | 查看服务状态 |
| `apprunner:UpdateService` | `*` | 更新服务配置 |
| `apprunner:ListOperations` | `*` | 列出操作历史 |
| `apprunner:ListServices` | `*` | 列出所有服务 |
| `apprunner:CreateService` | `*` | 创建新服务 |

**IAM 操作权限：**
| 权限 | 资源范围 | 用途 |
|------|---------|------|
| `iam:PassRole` | 仅限 2 个 App Runner 角色 | 传递角色给 App Runner |

---

### 2️⃣ **App Runner Service Role**
**角色名称：** `bee-edu-apprunner-role`  
**用途：** App Runner 用于从 ECR 拉取 Docker 镜像

#### 信任策略
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "build.apprunner.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

**安全特性：**
- ✅ 仅允许 App Runner 构建服务使用
- ✅ 其他 AWS 服务无法使用此角色

#### 权限策略

**ECR 拉取权限：**
| 权限 | 资源范围 | 用途 |
|------|---------|------|
| `ecr:GetAuthorizationToken` | `*` | 获取 ECR 登录令牌 |
| `ecr:GetDownloadUrlForLayer` | `bee-edu-rag-app` | 获取镜像层下载 URL |
| `ecr:BatchGetImage` | `bee-edu-rag-app` | 批量获取镜像 |
| `ecr:BatchCheckLayerAvailability` | `bee-edu-rag-app` | 检查层可用性 |
| `ecr:DescribeImages` | `bee-edu-rag-app` | 描述镜像信息 |

---

### 3️⃣ **App Runner Instance Role**
**角色名称：** `bee-edu-apprunner-instance-role`  
**用途：** 容器运行时用于访问 AWS 服务（如 Secrets Manager）

#### 信任策略
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "tasks.apprunner.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

**安全特性：**
- ✅ 仅允许 App Runner 任务使用
- ✅ 遵循最小权限原则

#### 权限策略

**Secrets Manager 权限：**
| 权限 | 资源范围 | 用途 |
|------|---------|------|
| `secretsmanager:GetSecretValue` | `bee-edu-openai-key-secret` | 读取 OpenAI API Key |

---

## 🔒 安全最佳实践

### ✅ 已实现的安全措施

1. **OIDC 认证**
   - ✅ 无需在 GitHub 存储永久 AWS 密钥
   - ✅ 临时凭证，自动过期
   - ✅ 限定特定仓库和分支

2. **最小权限原则**
   - ✅ 每个角色仅有必需权限
   - ✅ 大部分权限限定了资源范围
   - ✅ 角色间职责明确分离

3. **密钥管理**
   - ✅ OpenAI API Key 存储在 Secrets Manager
   - ✅ 容器通过环境变量注入（不在代码中）
   - ✅ Instance Role 仅能读取特定 Secret

4. **信任边界**
   - ✅ 每个角色的信任策略严格限制
   - ✅ Service Principal 正确配置
   - ✅ 无跨账户访问风险

---

## ⚠️ 已知限制和注意事项

### 1. App Runner 权限范围较宽
**当前状态：** App Runner 相关权限使用 `Resource: "*"`  
**原因：** App Runner ARN 在服务创建前未知  
**风险等级：** 🟡 低-中  
**缓解措施：** 
- 信任策略限制了谁可以使用此角色
- 仅限 GitHub Actions 从特定仓库触发

**可选改进（服务创建后）：**
```terraform
Resource = "arn:aws:apprunner:us-east-1:924030134232:service/bee-edu-rag-service/*"
```

### 2. ECR GetAuthorizationToken 必须全局
**当前状态：** `Resource: "*"`  
**原因：** AWS ECR 的 `GetAuthorizationToken` 操作不支持资源级权限  
**风险等级：** 🟢 极低  
**说明：** 这是 AWS 的设计限制，符合最佳实践

---

## 📊 权限审计检查清单

### GitHub Actions Role
- [x] 信任策略限制特定仓库
- [x] 信任策略限制特定分支
- [x] ECR 权限限定具体仓库
- [x] 包含镜像清理权限
- [x] IAM PassRole 限定具体角色

### App Runner Service Role
- [x] 信任策略限制 App Runner 服务
- [x] ECR 拉取权限完整
- [x] 权限限定具体 ECR 仓库

### App Runner Instance Role
- [x] 信任策略限制 App Runner 任务
- [x] Secrets Manager 权限限定具体 Secret
- [x] 无多余权限

---

## 🛠️ 验证命令

### 检查角色配置
```bash
# GitHub Actions 角色
aws iam get-role --role-name github-actions-deploy-role
aws iam list-attached-role-policies --role-name github-actions-deploy-role

# App Runner Service 角色
aws iam get-role --role-name bee-edu-apprunner-role
aws iam list-role-policies --role-name bee-edu-apprunner-role

# App Runner Instance 角色
aws iam get-role --role-name bee-edu-apprunner-instance-role
aws iam list-role-policies --role-name bee-edu-apprunner-instance-role
```

### 检查 Secrets Manager
```bash
aws secretsmanager describe-secret --secret-id bee-edu-openai-key-secret
```

### 检查 ECR 仓库
```bash
aws ecr describe-repositories --repository-names bee-edu-rag-app
aws ecr get-repository-policy --repository-name bee-edu-rag-app
```

---

## 📈 合规性和审计

### AWS 安全最佳实践符合度
| 检查项 | 状态 | 说明 |
|--------|------|------|
| 使用 IAM 角色而非用户 | ✅ | 所有访问通过角色 |
| 最小权限原则 | ✅ | 权限限定到具体资源 |
| 使用临时凭证 | ✅ | OIDC 提供临时令牌 |
| 分离职责 | ✅ | 3 个独立角色各司其职 |
| 密钥轮换 | ⚠️ | 需手动轮换 OpenAI Key |
| 日志记录 | ✅ | CloudTrail 自动记录 |
| 加密存储 | ✅ | Secrets Manager 加密 |

### CIS AWS Foundations Benchmark
- ✅ 1.16 - 确保 IAM 策略附加到组或角色
- ✅ 1.20 - 确保支持 AssumeRole 的策略有 MFA 或外部 ID（OIDC 满足）
- ✅ 3.1 - 确保启用了 CloudTrail

---

## 🔄 维护和更新

### 定期审查（建议每季度）
1. 检查未使用的权限
2. 审查 CloudTrail 日志
3. 验证信任关系
4. 更新权限范围（特别是 App Runner `*` 资源）

### 权限变更流程
1. 修改 `main.tf`
2. 运行 `terraform plan` 审查变更
3. 运行 `terraform apply` 应用变更
4. 更新此文档
5. 提交到版本控制

---

## 📞 联系和支持

**项目仓库：** https://github.com/CosmoSheep/rag-app  
**AWS 账户：** 924030134232  
**Terraform 状态：** 本地文件（terraform.tfstate）

---

## 📝 变更历史

| 日期 | 变更内容 | 修改人 |
|------|---------|--------|
| 2025-11-20 | 修复端口配置 (8080→8000) | AI Assistant |
| 2025-11-20 | 添加 ECR 镜像清理权限 | AI Assistant |
| 2025-11-20 | 创建初始权限报告 | AI Assistant |

---

**文档状态：** ✅ 最新  
**最后更新：** 2025-11-20  
**下次审查：** 2026-02-20

