# macOS 原生时间线小组件

状态：贡献实现方案已决定（2026-10-12）；签名、系统添加与真实刷新尚未验收。
用户选择 macOS 原生小组件，当前没有 Apple Developer 团队，先准备贡献代码。

## 范围与选择

采用 WidgetKit + SwiftUI 扩展，嵌入 Daygo.app/Contents/PlugIns；最低 macOS 14。
小 / 中 / 大尺寸分别显示最近 1 / 3 / 8 条当前逻辑日活动，最新在前。
不新增 Provider 调用、编辑、截图、网络请求或数据库连接。
桌面悬浮窗不能进入系统的小组件库，因此不采用。
扩展直接读取业务数据库会扩大授权与数据暴露面，因此不采用。

Go 拥有日期、卡片筛选和上限；仅数据库写入且捕获所有者发布快照。
原生适配器解析已签名应用的 DaygoWidgetAppGroup 元数据，将快照原子写入系统 App Group
容器并调用 WidgetCenter。扩展只读快照，不取得数据库、录制目录或钥匙串权限。
共享快照含用户活动标题，添加小组件表示用户选择在桌面展示这些内容；不包含摘要、
详细摘要、应用 / 站点、帧、路径、密钥或 LLM payload，标题最多 160 Unicode 字符。
无 App Group 配置的既有构建不启动发布循环，不修改现有应用身份与打包行为。

## 更新与边界

Go 每 30 秒查询存储与语言，只有可见数据改变才发布 / 请求刷新；启动立即发布。
系统实际刷新时间受 WidgetKit 预算约束，不能承诺 15 秒实时同步。
快照包括 Go 计算的逻辑日与下一个 4 点有效期；Swift 不重算逻辑日。
扩展在过期时显示空态，并预排有效期边界的空态条目，防止旧日卡片被误认为当前日。
主应用退出后保留最后快照及更新时间；到有效期即不再显示旧活动。
读取失败 / 不兼容 / 超限快照显示“打开 Daygo 同步”，不展示原始错误。

## 构建与身份

独立 build.sh 只构建开发用 appex，不自动进入 release 或修改既有打包入口。
embed.sh 针对显式指定的开发 app 拷贝扩展、写入两端同一个 App Group，并按内到外签名。
团队 ID 与签名身份由贡献者提供，不硬编码上游团队，不访问真实用户数据。
无团队时可以编译和运行匿名契约检查，不能声称系统添加 / 容器访问已通过。
开发应用的最终签名 / TCC 授权仍须单独验收；不要对已安装的录制实例试验。

## 依据与验收

- [Apple：创建 Widget 扩展](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [Apple：更新预算](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date/)
- [Apple：配置 App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [timeline 执行册](../modules/timeline.md)

门禁：G-core、Go / Swift 双侧匿名 JSON 契约与九语言资源；G-native 另需真实签名安装、
系统小组件库添加、关窗持续更新、编辑 / 删除刷新、4 点换日、主应用退出 / 重开、
损坏快照、浅深外观与九语言验证。旧的宿主验收不覆盖本增量。
回退：删除开发 app 的扩展与 DaygoWidgetAppGroup 配置，恢复该开发 app 原签名；
快照可删除，无数据库迁移。撤销本提交恢复源码。
