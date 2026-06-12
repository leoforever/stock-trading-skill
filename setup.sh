#!/bin/bash
# 小龙虾炒股 · 一键初始化脚本
# 运行方式：bash setup.sh

set -e

echo "========== 小龙虾炒股 · 一键初始化 =========="
echo ""

# 检查 OpenClaw 是否安装
if ! command -v openclaw &> /dev/null; then
    echo "❌ OpenClaw 未安装，请先安装"
    exit 1
fi
echo "✅ OpenClaw 已安装"

# ========== 1. 创建目录结构 ==========
echo ""
echo "【1/5】创建目录结构..."
mkdir -p ~/.openclaw/workspace/skills/stock-trading/logs
echo "✅ 目录创建完成"

# ========== 2. 初始化 portfolio.md ==========
echo ""
echo "【2/5】初始化持仓文件..."
cat > ~/.openclaw/workspace/skills/stock-trading/portfolio.md <<'EOF'
# portfolio.md - 模拟持仓记录

## 基本信息
- **初始资金：** 100,000 元
- **更新日期：** （建仓日填写）

## 持仓状态

| 代码 | 名称 | 持股数量 | 成本价 | 现价 | 浮动盈亏 |
|------|------|---------|-------|------|----------|
| | | | | | |

## 账户总盈亏
- **初始资金：** 100,000 元
- **当前总资产：** 100,000 元
- **净盈亏：** 0 元
EOF
echo "✅ portfolio.md 创建完成"

# ========== 3. 初始化 watchlist.md ==========
echo ""
echo "【3/5】初始化关注列表..."
cat > ~/.openclaw/workspace/skills/stock-trading/watchlist.md <<'EOF'
# watchlist.md - 跨日关注列表

## 今日关注

（每日收盘后由 AI 自动更新）
EOF
echo "✅ watchlist.md 创建完成"

# ========== 4. 配置定时任务 ==========
echo ""
echo "【4/5】配置定时任务..."

add_cron_task() {
    local name="$1"
    local schedule="$2"
    local message="$3"
    
    # 检查任务是否已存在
    if openclaw cron list | grep -q "$name"; then
        echo "  ⏭️ $name 已存在，跳过"
        return
    fi
    
    openclaw cron add \
        --name "$name" \
        --schedule "$schedule" \
        --tz "Asia/Shanghai" \
        --session-target "isolated" \
        --payload-kind "agentTurn" \
        --payload-message "$message" \
        --timeout-seconds 1200 > /dev/null 2>&1
    echo "  ✅ $name 创建成功"
}

MSG_BASE="你是一个严格的模拟操盘手。执行今日巡查：
1. 读取 skills/stock-trading/portfolio.md 了解当前持仓
2. web_search 搜索今日A股情况（主线板块、龙头情绪、重要消息）
3. 按SKILL.md规则决定是否操作
4. 更新持仓和日志 skills/stock-trading/logs/\$(date +%Y-%m-%d).md
5. 用 exec 发送邮件报告：
   python3 /home/loongson/.openclaw/workspace/skills/stock-trading/send_email.py \"【时间点】红心操盘日报\" \"<完整报告内容>\""

add_cron_task "炒股巡查 - 09:35" "35 9 * * 1-5" "$(echo "$MSG_BASE" | sed 's/【时间点】/【09:35巡查】/g')"
add_cron_task "炒股巡查 - 11:25" "25 11 * * 1-5" "$(echo "$MSG_BASE" | sed 's/【时间点】/【11:25巡查】/g')"
add_cron_task "炒股巡查 - 13:05" "5 13 * * 1-5" "$(echo "$MSG_BASE" | sed 's/【时间点】/【13:05巡查】/g')"
add_cron_task "炒股巡查 - 14:00" "0 14 * * 1-5" "$(echo "$MSG_BASE" | sed 's/【时间点】/【14:00巡查】/g')"
add_cron_task "炒股巡查 - 14:55" "55 14 * * 1-5" "$(echo "$MSG_BASE" | sed 's/【时间点】/【14:55收盘巡查】/g')"

# 20:00 总结任务
SUMMARY_MSG="你是一个严格的模拟操盘手。执行今日收盘总结：
1. 读取今日操作日志 skills/stock-trading/logs/\$(date +%Y-%m-%d).md
2. 读取当前持仓 skills/stock-trading/portfolio.md
3. 复盘今日操作：是否合规、盈亏分析
4. 找出不足之处，提出明日重点
5. 用 exec 发送邮件报告：
   python3 /home/loongson/.openclaw/workspace/skills/stock-trading/send_email.py \"【每日总结】红心操盘日报 \$(date +%Y-%m-%d)\" \"<完整总结报告>\""

add_cron_task "每日收盘总结（20:00）" "0 20 * * 1-5" "$SUMMARY_MSG"

echo "✅ 定时任务配置完成"

# ========== 5. 检查邮件配置 ==========
echo ""
echo "【5/5】检查邮件配置..."
if [ -f ~/.openclaw/secrets/mail_creds ]; then
    echo "✅ 邮件授权码已配置"
else
    echo "⚠️ 邮件授权码未配置，请手动执行："
    echo "   echo 'MAIL_APP_KEY=你的新浪授权码' > ~/.openclaw/secrets/mail_creds"
    echo "   chmod 600 ~/.openclaw/secrets/mail_creds"
fi

echo ""
echo "========== 初始化完成 =========="
echo ""
echo "下一步，手动配置以下内容："
echo ""
echo "1. 邮件授权码（必须）："
echo "   echo 'MAIL_APP_KEY=你的新浪邮箱授权码' > ~/.openclaw/secrets/mail_creds"
echo "   chmod 600 ~/.openclaw/secrets/mail_creds"
echo ""
echo "2. 微信公众号（在 TOOLS.md 中填写 AppID 和 AppSecret）"
echo ""
echo "3. 飞书机器人（在 config.yaml 中填写 app_id 和 app_secret）"
echo ""
echo "验证所有任务："
echo "   openclaw cron list"
echo ""
echo "测试邮件："
echo "   python3 ~/.openclaw/workspace/skills/stock-trading/send_email.py \"测试\" \"内容\""