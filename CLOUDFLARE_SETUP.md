# ☁️ Cloudflare 自定义域名配置指南

## 前提条件
- ✅ App Runner 服务已成功部署
- ✅ App Runner 默认域名可访问: `z4nxuhfhkn.us-east-1.awsapprunner.com`
- ✅ 您拥有一个域名（例如：`yourdomain.com`）
- ✅ 域名已添加到 Cloudflare 账户

---

## 📋 配置步骤

### 第一步：在 AWS App Runner 中添加自定义域名

1. **打开 AWS App Runner Console**
   ```
   https://console.aws.amazon.com/apprunner/
   ```

2. **选择您的服务**
   - 点击服务名称：`rag-app`
   - 进入服务详情页面

3. **添加自定义域名**
   - 点击 "Custom domains" 标签
   - 点击 "Link domain" 按钮
   - 输入您想要的子域名，例如：`rag.yourdomain.com`
   - 点击 "Add domain"

4. **获取验证记录**
   
   App Runner 会生成两个需要添加到 DNS 的记录：
   
   **记录 1 - 域名验证（CNAME）：**
   ```
   Name: _[随机字符串].rag.yourdomain.com
   Type: CNAME
   Value: _[App Runner提供的验证值].acm-validations.aws.
   ```
   
   **记录 2 - 域名指向（CNAME）：**
   ```
   Name: rag.yourdomain.com
   Type: CNAME
   Value: z4nxuhfhkn.us-east-1.awsapprunner.com
   ```

---

### 第二步：在 Cloudflare 中添加 DNS 记录

1. **登录 Cloudflare Dashboard**
   ```
   https://dash.cloudflare.com/
   ```

2. **选择您的域名**
   - 在左侧菜单中选择您的域名

3. **添加 DNS 记录**
   - 点击 "DNS" → "Records"
   - 点击 "Add record" 添加以下两条记录

#### 记录 1：域名验证记录

```
Type: CNAME
Name: _[从 App Runner 复制的随机字符串].rag
Value: _[从 App Runner 复制的验证值].acm-validations.aws.
Proxy status: DNS only（关闭橙色云朵）
TTL: Auto
```

#### 记录 2：域名指向记录

```
Type: CNAME
Name: rag
Value: z4nxuhfhkn.us-east-1.awsapprunner.com
Proxy status: DNS only（关闭橙色云朵）
TTL: Auto
```

⚠️ **重要提示：**
- 必须将 Proxy status 设置为 "DNS only"（灰色云朵）
- 不要启用 Cloudflare 的代理（橙色云朵），否则 SSL 验证会失败

---

### 第三步：等待 SSL 证书生成

1. **验证 DNS 传播**
   
   使用以下命令检查 DNS 是否已生效：
   ```bash
   # 检查域名指向
   nslookup rag.yourdomain.com
   
   # 或使用 dig
   dig rag.yourdomain.com
   ```

2. **等待 App Runner 验证**
   - 返回 App Runner Console
   - 在 "Custom domains" 页面查看状态
   - 状态会从 "Pending certificate" → "Active"
   - 通常需要 5-15 分钟

3. **验证完成标志**
   - Status: `Active`
   - Certificate status: `Issued`

---

### 第四步：测试自定义域名

1. **测试 HTTPS 访问**
   ```bash
   # 测试健康检查
   curl https://rag.yourdomain.com/health
   
   # 测试 RAG API
   curl -X POST https://rag.yourdomain.com/chat \
     -H "Content-Type: application/json" \
     -d '{"question": "这个RAG Demo使用了什么技术栈？"}'
   ```

2. **浏览器访问**
   ```
   https://rag.yourdomain.com
   ```
   
   应该看到：
   - ✅ 自动重定向到 HTTPS
   - ✅ SSL 证书有效（由 AWS 自动颁发）
   - ✅ 应用正常响应

---

## 🔧 高级配置（可选）

### 启用 Cloudflare 代理（需要额外配置）

如果您想启用 Cloudflare 的 CDN 和防护功能（橙色云朵）：

1. **在 Cloudflare 中启用代理**
   - 将 CNAME 记录的 Proxy status 改为 "Proxied"（橙色云朵）

2. **配置 SSL/TLS 模式**
   - 在 Cloudflare Dashboard 中：`SSL/TLS` → `Overview`
   - 选择 `Full (strict)` 模式

3. **添加 Origin 规则**
   - 在 `Rules` → `Origin Rules` 中添加：
   - Host Header Override: `z4nxuhfhkn.us-east-1.awsapprunner.com`

### 配置多个域名

您可以为同一个 App Runner 服务添加多个自定义域名：

```
rag.yourdomain.com    → 主域名
api.yourdomain.com    → API 专用域名
demo.yourdomain.com   → 演示环境
```

每个域名都需要：
1. 在 App Runner 中添加
2. 在 Cloudflare 中添加对应的 CNAME 记录
3. 等待 SSL 证书生成

---

## 📊 域名配置清单

完成以下检查项：

- [ ] App Runner 中添加了自定义域名
- [ ] 获取了两个 DNS 记录（验证记录 + 指向记录）
- [ ] Cloudflare 中添加了验证 CNAME 记录
- [ ] Cloudflare 中添加了域名指向 CNAME 记录
- [ ] DNS 记录的 Proxy status 设置为 "DNS only"
- [ ] App Runner 域名状态变为 "Active"
- [ ] SSL 证书已颁发
- [ ] 浏览器可通过 HTTPS 访问
- [ ] API 测试正常

---

## ❓ 常见问题

### Q1: DNS 记录添加后，App Runner 一直显示 "Pending"

**可能原因：**
- DNS 传播需要时间（通常 5-15 分钟）
- Cloudflare 代理已启用（橙色云朵）

**解决方案：**
```bash
# 检查 DNS 是否生效
dig rag.yourdomain.com

# 确保返回的是 App Runner 的域名
# 而不是 Cloudflare 的 IP
```

### Q2: SSL 证书验证失败

**可能原因：**
- 验证 CNAME 记录配置错误
- Cloudflare 代理干扰了 ACM 验证

**解决方案：**
1. 确认验证 CNAME 记录完全正确
2. 将 Proxy status 改为 "DNS only"
3. 等待 15 分钟后重试

### Q3: 浏览器显示 SSL 错误

**可能原因：**
- SSL 证书尚未完全生成
- DNS 缓存问题

**解决方案：**
```bash
# 清除 DNS 缓存
# macOS:
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# Windows:
ipconfig /flushdns

# Linux:
sudo systemd-resolve --flush-caches
```

### Q4: 想要同时使用根域名 (yourdomain.com)

**方案：**

App Runner 不支持根域名（Apex Domain），需要使用 CloudFront 或 ALB：

1. **简单方案：** 使用 Cloudflare Page Rules 重定向
   - `yourdomain.com` → `rag.yourdomain.com`

2. **完整方案：** 通过 AWS CloudFront
   - 创建 CloudFront Distribution
   - Origin 指向 App Runner 域名
   - 在 Cloudflare 中添加 A/AAAA 记录指向 CloudFront

---

## 🌐 架构图

```
用户浏览器
    ↓
rag.yourdomain.com (Cloudflare DNS)
    ↓
z4nxuhfhkn.us-east-1.awsapprunner.com (AWS App Runner)
    ↓
Docker Container (您的 RAG 应用)
    ↓
OpenAI API (向量化 + 问答)
```

---

## 📚 相关资源

- **App Runner 自定义域名文档：**
  https://docs.aws.amazon.com/apprunner/latest/dg/manage-custom-domains.html

- **Cloudflare DNS 配置：**
  https://developers.cloudflare.com/dns/

- **AWS Certificate Manager (ACM)：**
  https://docs.aws.amazon.com/acm/

---

## ✅ 配置完成！

完成所有配置后，您的 RAG 应用将通过以下方式访问：

1. **默认域名（始终可用）：**
   ```
   https://z4nxuhfhkn.us-east-1.awsapprunner.com
   ```

2. **自定义域名（配置后可用）：**
   ```
   https://rag.yourdomain.com
   ```

两个域名指向同一个服务，功能完全相同。

---

## 🎯 下一步

配置完成后，您可以：

1. **更新文档和代码**中的域名引用
2. **在 API 文档**中使用自定义域名
3. **配置 CORS** 允许您的前端域名
4. **添加更多子域名**用于不同环境（dev/staging/prod）


