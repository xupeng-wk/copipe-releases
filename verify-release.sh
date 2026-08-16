#!/usr/bin/env bash
# CoPipe — 发布包验签脚本（客户侧）
# 用法: bash verify-release.sh <发布包.tar.gz>（缺省取当前目录最新包）
# 校验链: 公钥指纹 → 清单签名 → 包哈希
set -euo pipefail

# 厂商发布公钥指纹（SHA-256, DER）。防渠道被攻破后的换钥攻击。
EXPECTED_FINGERPRINT="ee750cad79fd52e901c4fa5851b1e3e11166d1146f8d5ea355821387619ff4bf"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PUB_KEY="${PUB_KEY:-$SCRIPT_DIR/keys/RELEASE.pub}"

command -v openssl >/dev/null 2>&1 || { echo "✗ 需要 openssl（apt install openssl）"; exit 1; }

PKG="${1:-}"
if [ -z "$PKG" ]; then
  PKG="$(ls -t copipe-release-*.tar.gz 2>/dev/null | head -1 || true)"
fi
if [ -z "$PKG" ] || [ ! -f "$PKG" ]; then
  echo "用法: bash verify-release.sh <发布包.tar.gz>（缺省取当前目录最新包）"
  exit 1
fi

# 1. 公钥指纹校验
[ -f "$PUB_KEY" ] || { echo "✗ 未找到公钥: $PUB_KEY（请从发布仓 keys/RELEASE.pub 获取）"; exit 1; }
FINGERPRINT=$(openssl pkey -pubin -in "$PUB_KEY" -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1)
if [ "$FINGERPRINT" != "$EXPECTED_FINGERPRINT" ]; then
  echo "✗ 公钥指纹不符！请勿继续安装，并联系供应商。"
  echo "  实际: $FINGERPRINT"
  echo "  预期: $EXPECTED_FINGERPRINT"
  exit 1
fi
echo "✓ 公钥指纹一致"

# 2. 清单签名验证
SHA_FILE="${PKG}.sha256"
SIG_FILE="${PKG}.sig"
[ -f "$SHA_FILE" ] || { echo "✗ 缺少清单: $SHA_FILE"; exit 1; }
[ -f "$SIG_FILE" ] || { echo "✗ 缺少签名: $SIG_FILE"; exit 1; }
if ! openssl dgst -sha256 -verify "$PUB_KEY" -signature "$SIG_FILE" "$SHA_FILE" >/dev/null 2>&1; then
  echo "✗ 签名验证失败！包或清单可能被篡改，请勿继续安装。"
  exit 1
fi
echo "✓ 签名验证通过（清单出自厂商私钥）"

# 3. 包哈希校验
PKG_DIR="$(cd "$(dirname "$PKG")" && pwd)"
if ! ( cd "$PKG_DIR" && sha256sum -c "$(basename "$SHA_FILE")" ); then
  echo "✗ 包哈希校验失败！下载不完整或文件被篡改，请重新下载。"
  exit 1
fi
echo "✓ 包哈希校验通过"

echo ""
echo "✅ 验证通过: $(basename "$PKG")"
echo "   解包部署: tar xzf $PKG && cd ${PKG%.tar.gz} && bash deploy.sh"
