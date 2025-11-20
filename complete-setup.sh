#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       🚀 RAG App 自动完成剩余部署步骤                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查 AWS 账户信息
echo "📊 检查 AWS 账户信息..."
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "  Account ID: $ACCOUNT_ID"
echo ""

# 尝试创建 App Runner 服务
echo "⏳ 步骤 1: 创建 App Runner 服务..."
echo ""
echo -e "${YELLOW}注意：如果这是首次使用 App Runner，可能需要先订阅服务${NC}"
echo "订阅链接: https://console.aws.amazon.com/apprunner/"
echo ""

APP_RUNNER_RESULT=$(aws apprunner create-service \
  --service-name bee-edu-rag-service \
  --source-configuration '{
    "AuthenticationConfiguration": {
      "AccessRoleArn": "arn:aws:iam::'"$ACCOUNT_ID"':role/bee-edu-apprunner-role"
    },
    "ImageRepository": {
      "ImageIdentifier": "'"$ACCOUNT_ID"'.dkr.ecr.us-east-1.amazonaws.com/bee-edu-rag-app:latest",
      "ImageRepositoryType": "ECR",
      "ImageConfiguration": {
        "Port": "8000",
        "RuntimeEnvironmentSecrets": {
          "OPENAI_API_KEY": "arn:aws:secretsmanager:us-east-1:'"$ACCOUNT_ID"':secret:bee-edu-openai-key-secret-rZlJ96"
        }
      }
    },
    "AutoDeploymentsEnabled": false
  }' \
  --instance-configuration '{
    "Cpu": "1024",
    "Memory": "2048",
    "InstanceRoleArn": "arn:aws:iam::'"$ACCOUNT_ID"':role/bee-edu-apprunner-instance-role"
  }' \
  --region us-east-1 2>&1) || {
  
  if echo "$APP_RUNNER_RESULT" | grep -q "SubscriptionRequiredException"; then
    echo -e "${RED}❌ 需要订阅 App Runner 服务${NC}"
    echo ""
    echo "请按照以下步骤操作："
    echo "1. 访问: https://console.aws.amazon.com/apprunner/home?region=us-east-1"
    echo "2. 点击 'Get Started' 或 'Create Service'"
    echo "3. 完成订阅流程（通常是免费的）"
    echo "4. 然后重新运行此脚本"
    echo ""
    echo "或者手动创建服务，详见 DEPLOYMENT_GUIDE.md"
    exit 1
  else
    echo -e "${RED}❌ 创建失败: $APP_RUNNER_RESULT${NC}"
    exit 1
  fi
}

echo -e "${GREEN}✅ App Runner 服务创建成功！${NC}"
echo ""

# 获取服务信息
echo "⏳ 步骤 2: 获取服务信息..."
sleep 5  # 等待服务初始化

SERVICE_ARN=$(echo "$APP_RUNNER_RESULT" | jq -r '.Service.ServiceArn')
SERVICE_URL=$(echo "$APP_RUNNER_RESULT" | jq -r '.Service.ServiceUrl')

echo -e "${GREEN}✅ 服务信息获取成功${NC}"
echo "  Service ARN: $SERVICE_ARN"
echo "  Service URL: https://$SERVICE_URL"
echo ""

# 等待服务部署完成
echo "⏳ 步骤 3: 等待服务部署完成（可能需要 3-5 分钟）..."
echo ""

MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  STATUS=$(aws apprunner describe-service \
    --service-arn "$SERVICE_ARN" \
    --query 'Service.Status' \
    --output text)
  
  echo -n "."
  
  if [ "$STATUS" = "RUNNING" ]; then
    echo ""
    echo -e "${GREEN}✅ 服务部署完成！${NC}"
    break
  fi
  
  if [ "$STATUS" = "CREATE_FAILED" ] || [ "$STATUS" = "DELETE_FAILED" ]; then
    echo ""
    echo -e "${RED}❌ 服务部署失败${NC}"
    exit 1
  fi
  
  sleep 5
  ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo ""
  echo -e "${YELLOW}⏰ 部署超时，请手动检查 App Runner 控制台${NC}"
fi

echo ""

# 保存配置信息
echo "⏳ 步骤 4: 保存配置信息..."
cat > github-secrets.txt << EOF
╔════════════════════════════════════════════════════════════╗
║           📝 GitHub Secrets 配置信息                     ║
╚════════════════════════════════════════════════════════════╝

请在 GitHub 仓库 CosmoSheep/rag-app 中配置以下 Secrets:
路径: Settings → Secrets and variables → Actions → New repository secret

1. OPENAI_API_KEY
   值: (你的 OpenAI API Key)

2. AWS_REGION
   值: us-east-1

3. ECR_REPOSITORY
   值: bee-edu-rag-app

4. APP_RUNNER_ARN
   值: $SERVICE_ARN

5. AWS_IAM_ROLE_TO_ASSUME
   值: arn:aws:iam::$ACCOUNT_ID:role/github-actions-deploy-role

════════════════════════════════════════════════════════════

Service URL: https://$SERVICE_URL

测试命令:
  curl https://$SERVICE_URL/health
  curl -X POST https://$SERVICE_URL/chat \\
    -H "Content-Type: application/json" \\
    -d '{"question": "这个 RAG demo 是做什么用的？"}'

════════════════════════════════════════════════════════════
EOF

cat github-secrets.txt
echo ""
echo -e "${GREEN}✅ 配置信息已保存到 github-secrets.txt${NC}"
echo ""

# 测试服务
echo "⏳ 步骤 5: 测试服务..."
echo ""

echo "测试健康检查接口..."
HEALTH_CHECK=$(curl -s https://$SERVICE_URL/health) || {
  echo -e "${YELLOW}⚠️  健康检查失败，服务可能还在启动中${NC}"
  echo "请稍后手动测试: curl https://$SERVICE_URL/health"
}

if [ ! -z "$HEALTH_CHECK" ]; then
  echo -e "${GREEN}✅ 健康检查成功: $HEALTH_CHECK${NC}"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║               🎉 部署完成！                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "下一步操作:"
echo "  1. 配置 GitHub Secrets (参考上方信息)"
echo "  2. 推送代码到 GitHub"
echo "  3. GitHub Actions 会自动部署"
echo ""
echo "详细文档: DEPLOYMENT_GUIDE.md"
echo ""

