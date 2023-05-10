#!/bin/bash

# 检查用户是否为 root
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 用户身份运行此脚本。"
  exit 1
fi

# 检查内核版本
KERNEL_VERSION=$(uname -r | cut -d. -f1-2)
REQUIRED_VERSION="4.9"

if (( $(echo "$KERNEL_VERSION < $REQUIRED_VERSION" | bc -l) )); then
  echo "你的内核版本为 $KERNEL_VERSION，需要更新到 4.9 以上的版本才能继续。"
  exit 1
fi

# 检查 BBR 是否已可用
BBR_AVAILABLE=$(sysctl net.ipv4.tcp_available_congestion_control | grep -c "bbr")

if [ "$BBR_AVAILABLE" -eq 0 ]; then
  echo "BBR 不可用，无法启用。"
  exit 1
fi

# 添加 BBR 参数到 sysctl 配置
sysctl -w net.core.default_qdisc=fq
sysctl -w net.ipv4.tcp_congestion_control=bbr

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

# 验证 BBR 启用成功
BBR_ENABLED=$(sysctl net.ipv4.tcp_congestion_control | grep -c "bbr")

if [ "$BBR_ENABLED" -eq 1 ]; then
  echo "BBR 已成功启用。"
else
  echo "无法启用 BBR，请检查系统配置。"
fi
