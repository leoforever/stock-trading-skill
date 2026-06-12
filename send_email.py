#!/usr/bin/env python3
"""发送邮件报告到老板邮箱"""
import smtplib
import ssl
import sys
import os
from pathlib import Path

# 邮件配置
SMTP_HOST = "smtp.sina.com"
SMTP_PORT = 465  # 465 = SSL, 587 = STARTTLS (not supported by Sina)
EMAIL_FROM = "loongsoncloud@sina.com"
EMAIL_TO = "loongsoncloud@sina.com"  # 发送给自己

def load_auth_code():
    """从 secrets 文件加载授权码"""
    secrets_file = Path.home() / ".openclaw" / "secrets" / "mail_creds"
    if secrets_file.exists():
        with open(secrets_file, "r") as f:
            for line in f:
                if line.startswith("MAIL_APP_KEY="):
                    return line.split("=", 1)[1].strip()
    # 如果 secrets 文件不存在，使用环境变量
    auth_code = os.environ.get("MAIL_APP_KEY", "")
    if not auth_code:
        raise RuntimeError("未找到邮件授权码，请检查 ~/.openclaw/secrets/mail_creds 或设置 MAIL_APP_KEY 环境变量")
    return auth_code

def send_email(subject: str, body: str) -> bool:
    """发送邮件"""
    try:
        auth_code = load_auth_code()
        # 简单的 Markdown → Plain Text 转换
        import re
        plain = body
        # 去掉表格的|和-，保留内容
        plain = re.sub(r'\|\s*', '  ', plain)  # | 换成空格
        plain = re.sub(r'\s*\|', '  ', plain)
        plain = re.sub(r'^\|.*\|$', '', plain, flags=re.MULTILINE)  # 删除表格分隔行
        plain = re.sub(r'^\s*\|', '', plain, flags=re.MULTILINE)  # 去掉行首的|
        plain = re.sub(r'\|\s*$', '', plain, flags=re.MULTILINE)  # 去掉行尾的|
        # 去掉 Markdown 标题标记
        plain = re.sub(r'^#{1,6}\s+', '', plain, flags=re.MULTILINE)
        # **加粗** → 加粗（保留文字）
        plain = re.sub(r'\*\*(.+?)\*\*', r'\1', plain)
        # *斜体* → 斜体（保留文字）
        plain = re.sub(r'\*(.+?)\*', r'\1', plain)
        # `行内代码` → 保留内容
        plain = re.sub(r'`(.+?)`', r'\1', plain)
        # ```代码块``` → 去掉
        plain = re.sub(r'```.*?```', '', plain, flags=re.DOTALL)
        # --- 分隔线 → 换行
        plain = re.sub(r'^---+$', '', plain, flags=re.MULTILINE)
        # 合并多个空行为单个换行
        plain = re.sub(r'\n{3,}', '\n\n', plain)
        # 保留标题行（已去掉#）

        msg = f"From: {EMAIL_FROM}\r\n"
        msg += f"To: {EMAIL_TO}\r\n"
        msg += f"Subject: {subject}\r\n"
        msg += "Content-Type: text/plain; charset=utf-8\r\n"
        msg += "\r\n"
        msg += plain

        if SMTP_PORT == 465:
            server = smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=ssl.create_default_context(), timeout=30)
        else:
            server = smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=30)
            if server.has_extn('STARTTLS'):
                server.starttls()
        server.login(EMAIL_FROM, auth_code)
        server.sendmail(EMAIL_FROM, [EMAIL_TO], msg.encode("utf-8"))
        server.quit()
        print(f"邮件发送成功: {subject}")
        return True
    except Exception as e:
        print(f"邮件发送失败: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("用法: send_email.py <subject> <body>")
        sys.exit(1)
    subject = sys.argv[1]
    body = sys.argv[2]
    # body如果是文件路径，读取文件内容
    if os.path.isfile(body):
        with open(body, "r", encoding="utf-8") as f:
            body = f.read()
    success = send_email(subject, body)
    sys.exit(0 if success else 1)
