# 📖 阅读 - iOS 电子书阅读器

> 支持自定义书源的电子书阅读器 | SwiftUI + SwiftData

![Platform](https://img.shields.io/badge/platform-iOS_16%2B-blue)
![Language](https://img.shields.io/badge/language-Sift_5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ 功能特性

### 核心功能
- 📚 **自定义书源** — 添加任意小说网站作为书源
- 🔍 **智能搜索** — 按书源搜索书籍
- 📖 **沉浸式阅读** — 5种背景主题、字号/行距调节
- 🎤 **语音朗读** — 系统级 TTS，语速可调（新增！）
- 📑 **目录导航** — 底部弹出式章节列表
- 💾 **进度自动保存** — 记住阅读位置
- ⭐ **书架管理** — 收藏、搜索、排序

### 阅读器特色
| 功能 | 说明 |
|------|------|
| 背景主题 | 护眼黄 / 羊皮纸 / 绿茵 / 深色 / 夜间 |
| 字号范围 | 12sp ~ 32sp |
| 行距调节 | 1.2x ~ 2.5x |
| 语音朗读 | AVSpeechSynthesizer 中文 TTS |
| 语速控制 | 很慢 → 快（9档） |
| 夜间模式 | 一键切换暗色主题 |

---

## 🚀 快速开始

### 方法一：获取安装包（无需编译环境）

详见 [IOS_SIGNING_GUIDE.md](./IOS_SIGNING_GUIDE.md)

**最简步骤：**
1. 从 GitHub Actions 下载 `.ipa` 文件
2. 安装 [AltStore](https://altstore.io/) 或 [Sideloadly](https://sideloadly.io/)
3. 用你的 Apple ID 免费签名安装到 iPhone

### 方法二：Xcode 编译

```bash
1. 克隆仓库
   git clone <repo-url>
   cd BookReader-iOS

2. 打开 Xcode
   open BookReader.xcodeproj

3. 解析依赖
   # Xcode 会自动解析 SwiftSoup
   
4. 选择设备并运行
   Cmd + R
```

### 方法三：GitHub Actions 自动构建

推送代码后自动构建：

```bash
git push origin main
# 或打 tag 触发发布构建
git tag v1.0.0 && git push --tags
```

产物在 **Actions → Artifacts** 中下载。

---

## 📦 项目结构

```
BookReader-iOS/
├── .github/workflows/
│   └── build-ios.yml          # GitHub Actions 自动构建
├── BookReader/
│   ├── BookReaderApp.swift    # App 入口 (SwiftData)
│   ├── Models/                # 数据模型 (@Model)
│   │   ├── BookSource.swift   # 书源
│   │   ├── Book.swift         # 书籍
│   │   ├── Chapter.swift      # 章节
│   │   └── ReadingProgress.swift  # 进度
│   ├── Services/
│   │   ├── NetworkService.swift     # URLSession 网络
│   │   ├── SourceParser.swift       # SwiftSoup HTML 解析
│   │   ├── TTSService.swift        # 语音朗读服务
│   │   └── DataManager.swift        # SwiftData CRUD
│   ├── ViewModels/            # @Observable ViewModel
│   ├── Views/                 # SwiftUI 页面
│   │   ├── Reader/ReaderView.swift  # 阅读器(含TTS)
│   │   ├── Home/BookshelfView.swift
│   │   ├── Discover/DiscoverView.swift
│   │   ├── Sources/SourcesView.swift
│   │   ├── Detail/BookDetailView.swift
│   │   └── Settings/SettingsView.swift
│   └── Theme/AppTheme.swift   # 配色 & 字体
├── BOOK_SOURCE_FORMAT.md      # 书源格式说明
└── IOS_SIGNING_GUIDE.md       # 签名安装教程
```

---

## 📝 书源格式

详见 [BOOK_SOURCE_FORMAT.md](./BOOK_SOURCE_FORMAT.md)

**简述：** 只需填写 5 个 URL 即添加一个书源：

| 字段 | 说明 |
|------|------|
| name | 书源名称 |
| baseUrl | 网站 URL |
| searchUrl | 搜索接口 (`{keyword}` = 关键词) |
| detailUrl | 详情接口 (`{bookUrl}` = 书籍ID) |
| chapterListUrl | 目录接口 |
| contentUrl | 正文接口 |

内置多套 CSS 选择器自动适配大多数小说网站。

---

## 🔧 技术栈

| 组件 | 技术 |
|------|------|
| UI | SwiftUI (iOS 16+) |
| 架构 | MVVM + @Observable |
| 数据库 | SwiftData (@Model) |
| 网络 | URLSession + async/await |
| HTML 解析 | SwiftSoup |
| 语音合成 | AVSpeechSynthesizer |
| 图片加载 | AsyncImage |
| 导航 | NavigationStack + path |

---

## 📱 最低要求

- **iOS 16.0+**
- **iPhone 5s 及以上**
- **Xcode 15+** （如需编译）

---

## 📄 License

MIT License
