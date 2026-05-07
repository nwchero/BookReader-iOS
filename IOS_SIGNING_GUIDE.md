# 📱 iOS 签名安装完整教程（个人使用，免费）

> **目标：** 在没有 Apple 开发者账号（$99/年）的情况下，把 App 安装到自己的 iPhone 上。

---

## 方法一：免费签名安装（推荐 ⭐）

### 方案 A：使用 AltStore（最简单）

**原理：** 利用你的 **Apple ID 免费开发者权限**（每个 Apple ID 可以签名 3 个 App，有效期 7 天）

#### 步骤 1：安装 AltServer

1. **需要一台电脑**（Mac 或 Windows 都行）
2. 下载 [AltServer](https://altstore.io/)：
   - Mac: https://altstore.io/download/
   - Windows: https://altstore.io/download/#windows

#### 步骤 2：连接 iPhone

1. 用 USB 数据线把 iPhone 连接到电脑
2. iPhone 上弹出「信任此电脑？」→ **点击「信任」**
3. 输入 iPhone 解锁密码确认

#### 步骤 3：登录 Apple ID

在电脑上打开 AltServer：
- Mac: 菜单栏 → AltServer → Install AltStore → 选择你的 iPhone
- Windows: 系统托盘 → AltServer 图标 → Install AltStore → 选择你的 iPhone
- 输入你的 **Apple ID 和密码**（就是 App Store 登录的那个）
- 如果开启了**双重认证**，手机上会收到验证码，输入即可

#### 步骤 4：安装 .ipa 文件

1. 把构建好的 `BookReader-unsigned.ipa` 文件保存到电脑
2. 双击 `.ipa` 文件 → 自动用 AltStore 安装到手机
3. 或者：AltStore → My Device → 点击 **+** → 选择 .ipa 文件
4. 等待安装完成（约 30 秒~1 分钟）
5. iPhone 上出现「阅读」App 图标 ✅

#### ⚠️ 重要：续签（每 7 天一次）

免费签名的 App **7 天后过期**，需要续签：

- **Mac:** 菜单栏 AltServer → 勾选 "Resign running apps every 7 days"（自动续签）
- **Windows:** 保持 AltServer 运行 + 手机通过 WiFi 连接同一网络
- **手动续签:** AltStore → 手机图标 → Reinstall

> 💡 **技巧：** 把 AltServer 设置为开机自启，连着 WiFi 就能自动续签。

---

### 方案 B：使用 Sideloadly（Windows 用户友好）

**下载地址：** https://sideloadly.io/

#### 操作步骤：

1. **下载并安装 Sideloadly**（支持 Windows/Mac/Linux）
2. **准备文件：**
   - `BookReader-unsigned.ipa`（从 GitHub Actions 下载的未签名包）
   - 你的 **Apple ID**
   - **密码**（如果开启双重认证，需要**App专用密码**）
     > 获取方式：appleid.apple.com → 登录 → 安全 → App专用密码 → 生成
3. **打开 Sideloadly：**
   ```
   左侧选择你的 iPhone（USB 连接）
   Apple ID: 输入你的 Apple ID
   Password: 输入密码或 App专用密码
   IPA File: 点击选择 BookReader-unsigned.ipa
   ```
4. 点击 **Start** 按钮
5. 等待进度条完成 → 手机上出现 App ✅

#### 同样需要 7 天续签一次

---

### 方案 C：TrollStore（永久签名，需 iOS 14.0~15.4.1）

如果你的 iOS 版本在 **14.0 ~ 15.4.1** 之间，可以使用 TrollStore 实现永久免签：

**条件：** 需要利用一个系统漏洞安装（一次性操作）

**步骤简述：**

1. 访问 https://trollstore.app/
2. 下载对应你 iOS 版本的安装工具
3. 通过 Safari 安装 TrollStore
4. 安装后，用 TrollStore 打开 `BookReader-unsigned.ipa`
5. **永久有效！不需要续签！** 🎉

> 这是目前最好的方案，但只支持特定 iOS 版本范围。

---

### 方案 D：Apple Developer 正式签名（$99/年）

如果你愿意付费，这是最稳定的方式：

1. 访问 https://developer.apple.com/programs/
2. 注册 Apple Developer Program（个人 $99/年）
3. 在 Xcode 中配置证书和描述文件
4. GitHub Actions 中配置 Secrets 即可自动签名

---

## 方法二：GitHub Actions 自动构建+签名

我已经为你创建了 `.github/workflows/build-ios.yml` 工作流！

### 使用流程：

```
第1步：Fork 或上传代码到 GitHub
        ↓
第2步：配置 Secrets（如果需要自动签名）
        ↓
第3步：触发构建（push代码 或 手动触发）
        ↓
第4步：下载 .ipa 文件
        ↓
第5步：用上述方法 A/B/C/D 安装到手机
```

### 触发构建的三种方式：

| 方式 | 说明 |
|------|------|
| **Push 到 main 分支** | 推送代码自动构建 |
| **打 Tag** | `git tag v1.0.0 && git push --tags` |
| **手动触发** | GitHub 页面 → Actions → Build iOS IPA → Run workflow |

### 下载产物：

1. 进入 GitHub 仓库 → **Actions** 标签页
2. 点击最新的 **Build iOS IPA** workflow run
3. 滚动到底部 → **Artifacts** 区域
4. 点击 `BookReader-iOS-xxxxx` 下载 zip
5. 解压得到 `.ipa` 文件

---

## 🆘 常见问题

### Q: 安装后提示「无法验证」？
A: **设置 → 通用 → VPN与设备管理 → 你的 Apple ID → 信任**

### Q: 7天后过期了怎么办？
A: 重新用 AltStore/Sideloadly 安装一遍，或设置自动续签

### Q: Windows 电脑可以吗？
A: 可以！AltServer 有 Windows 版，Sideloadly 也支持 Windows

### Q: 没有 Apple ID 怎么办？
A: 免费注册一个就行：https://appleid.apple.com/account

### Q: Mac 电脑都没有怎么办？
A: 找朋友借一下，或者用云服务（如 MacinCloud）远程租一台 Mac

### Q: 安装后闪退？
A: 可能是架构问题（arm64），确保你的 iPhone 是 A7 芯片以上（iPhone 5s 及以后都行）

---

## 📋 快速检查清单

- [ ] 一台 iPhone（iOS 12+）
- [ ] 一台电脑（Mac/Windows均可）
- [ ] 一个 Apple ID（免费的就够）
- [ ] USB 数据线（或同一 WiFi）
- [ ] `BookReader-unsigned.ipa` 文件
- [ ] AltStore / Sideloadly 软件

---

## 推荐路线图（按难度排序）

```
新手入门:
  Sideloadly (最傻瓜式) → 5分钟搞定

日常使用:
  AltStore (自动续签) → 一次配置长期使用

最佳体验:
  TrollStore (永久签名) → 但需要特定 iOS 版本

专业开发:
  Apple Developer ($99/年) → 可上架 TestFlight/App Store
```
