#!/usr/bin/env python3
"""发送邮件报告到老板邮箱"""
import smtplib
import sys
import os

# 邮件配置
SMTP_HOST = "smtp.sina.com"
SMTP_PORT = 587
EMAIL_FROM = "loongsoncloud@sina.com"
AUTH_CODE = "b2b1af13b41813b0"
EMAIL_TO = "loongsoncloud@sina.com"  # 发送给自己

def send_email(subject: str, body: str) -> bool:
    """发送邮件"""
    try:
        msg = f"From: {EMAIL_FROM}\r\n"
        msg += f"To: {EMAIL_TO}\r\n"
        msg += f"Subject: {subject}\r\n"
        msg += "Content-Type: text/plain; charset=utf-8\r\n"
        msg += "\r\n"
        msg += body

        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
        server.starttls()
        server.login(EMAIL_FROM, AUTH_CODE)
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
