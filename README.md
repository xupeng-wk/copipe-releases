# CoPipe Releases

CoPipe 离线发布包仓库。每个 release 对应一个 `copipe-release-YYYYMMDD-HHMM.tar.gz`
发布包，tag 与包名时间戳一致（如 `v20260816-1529`）。

## 下载、验证与部署

```bash
# 1. 下载发布包及签名文件（版本号换成目标 release 的 tag）
V=v20260816-1529
PKG=copipe-release-20260816-1529.tar.gz
curl -LO https://github.com/xupeng-wk/copipe-releases/releases/download/$V/$PKG
curl -LO https://github.com/xupeng-wk/copipe-releases/releases/download/$V/$PKG.sha256
curl -LO https://github.com/xupeng-wk/copipe-releases/releases/download/$V/$PKG.sig

# 2. 验签（脚本内置公钥指纹校验，公钥可先 git clone 本仓或单独下载 keys/RELEASE.pub）
bash verify-release.sh $PKG

# 3. 解包并部署
tar xzf $PKG && cd copipe-release-* && bash deploy.sh
```

查最新版本号：

```bash
curl -s https://api.github.com/repos/xupeng-wk/copipe-releases/releases/latest | grep '"tag_name"'
```

## 验签说明

- `keys/RELEASE.pub` — 发布公钥，本仓库一次性提交，从稳定 URL 获取
- `<包>.sha256` — 发布包哈希清单
- `<包>.sig` — 厂商私钥对清单的签名
- `verify-release.sh` 依次校验：公钥指纹 → 清单签名 → 包哈希，任一环节失败即中止

**公钥指纹（SHA-256, DER）**：

```
ee750cad79fd52e901c4fa5851b1e3e11166d1146f8d5ea355821387619ff4bf
```

如指纹与上述不符，说明公钥或获取渠道被篡改，请勿继续安装，并联系供应商。
