# 📚 书源格式说明

## 书源格式：自定义规则引擎（非 JSON/XML）

本项目使用的书源格式是**自定义配置格式**，每个书源包含以下字段：

---

### 字段定义

| 字段 | 必填 | 说明 | 示例 |
|------|------|------|------|
| `name` | ✅ | 书源显示名称 | `"笔趣阁"` |
| `baseUrl` | ✅ | 网站基础地址 | `"https://www.biquge.com"` |
| `searchUrl` | ✅ | 搜索接口 URL 模板 | `"/search.php?q={keyword}"` |
| `detailUrl` | ❌ | 书籍详情接口模板 | `"/book/{bookUrl}"` |
| `chapterListUrl` | ❌ | 章节目录接口模板 | `"/chapters/{bookUrl}"` |
| `contentUrl` | ❌ | 章节正文接口模板 | `"/chapter/{chapterUrl}"` |
| `searchMethod` | ❌ | 请求方式 | `"GET"` 或 `"POST"` |

### 占位符说明

| 占位符 | 替换内容 |
|--------|----------|
| `{keyword}` | 用户输入的搜索关键词 |
| `{bookUrl}` | 书籍的唯一标识 URL |
| `{chapterUrl}` | 章节的唯一标识 URL |

---

## 工作原理

```
用户搜索 "斗破苍穹"
        ↓
1. searchUrl 中的 {keyword} 被替换为 "斗破苍穹"
2. 完整URL: baseUrl + searchUrl = https://xxx.com/search.php?q=斗破苍穹
3. 获取 HTML → 用 Jsoup/SwiftSoup 解析
4. 提取书籍列表（标题、作者、链接）
5. 用户点击某本书
6. 用 detailUrl 获取详情页 → 提取简介、封面等
7. 用 chapterListUrl 获取章节列表
8. 点击某章 → 用 contentUrl 获取正文
9. 清洗 HTML 标签 → 纯文本渲染
```

---

## 实际示例

### 示例 1：通用小说网站

```json
{
    "name": "示例小说网",
    "baseUrl": "https://example.com",
    "searchUrl": "/search?keyword={keyword}",
    "detailUrl": "/book/{bookUrl}",
    "chapterListUrl": "/chapters/{bookUrl}",
    "contentUrl": "/read/{chapterUrl}",
    "searchMethod": "GET"
}
```

**使用流程：**
1. 用户搜索「遮天」→ 访问 `https://example.com/search?keyword=遮天`
2. 解析搜索结果页，提取 `.result-list .book-item a` 元素
3. 点击《遮天》→ 访问详情页获取信息
4. 加载目录 → 解析 `#list dl dd a` 获取所有章节
5. 点击第1章 → 访问正文页，提取 `#content` 的文字

### 示例 2：POST 方式搜索的书源

```json
{
    "name": "某 POST 搜索站",
    "baseUrl": "https://post-example.com",
    "searchUrl": "/api/search",
    "detailUrl": "/novel/{bookUrl}",
    "chapterListUrl": "/novel/{bookUrl}/chapters",
    "contentUrl": "/novel/chapter/{chapterUrl}",
    "searchMethod": "POST"
}
```

---

## HTML 解析适配策略

阅读器的解析器内置了**多套 CSS 选择器**，自动尝试匹配：

### 搜索结果页选择器优先级：
```
.result-list .book-item      ← 最常用
.search-result .book-info
.novellist li                 ← 笔趣阁类站点
.result-item                  ← 通用兜底
a[href*='/book/']             ← 最终兜底
```

### 详情页选择器：
```
#info h1                      ← 标题
.book-info h1                 ← 备选
.author                       ← 作者
#intro                        ← 简介
#fmimg img                    ← 封面
```

### 目录页选择器：
```
#list dl dd a                 ← 最常见
.chapter-list a
.volume-list a
#contentlist a                ← 兜底
```

### 正文页选择器：
```
#content                      ← 最常见
#BookText
.chapter-content
.read-content
article                       ← 兜底
```

> **这意味着：大多数标准结构的小说网站无需修改代码即可直接使用！**

---

## 如何添加新书源？

### 方法一：App 内添加
1. 打开 App → 底部 **「书源」**
2. 点击右上角 **「+」**
3. 填写各字段 → 保存

### 方法二：分析网站后填写

以你想添加的网站为例：

1. **打开网站**，找到搜索框
2. **搜索一本书**，观察浏览器地址栏 URL
   - 如: `https://site.com/s?w=关键词`
   - 则 `baseUrl = "https://site.com"`, `searchUrl = "/s?w={keyword}"`
3. **点进一本书**，观察 URL 规则
4. **点进目录页**，确认章节列表结构
5. **点进某一章**，确认正文区域

如果网站结构比较标准，大概率直接就能用！

---

## 与其他阅读 App 的书源兼容性

| 格式 | 本项目支持 | 说明 |
|------|-----------|------|
| 阅读 App JSON 格式 | ⚠️ 需转换 | 字段名不同，需手动映射 |
| 阅读 App JS 规则 | ❌ 不支持 | 不支持 JavaScript 规则引擎 |
| 自定义格式（本格式） | ✅ 原生支持 | 上述字段格式 |
| 纯 URL 填写 | ✅ 支持 | 只需填写 5 个 URL 即可 |

如需从「阅读」App 的书源转换过来，主要对应关系：
- `bookSourceUrl` → `baseUrl`
- `ruleSearch.url` → `searchUrl`
- `ruleBookInfo.url` → `detailUrl`
- `ruleToc.url` → `chapterListUrl`
- `ruleContent.url` → `contentUrl`
