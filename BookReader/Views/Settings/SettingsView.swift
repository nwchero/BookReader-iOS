import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultFontSize") private var defaultFontSize: Int = 18
    @AppStorage("isNightMode") private var isNightMode: Bool = false
    @AppStorage("autoBrightness") private var autoBrightness: Bool = true
    @AppStorage("backgroundType") private var backgroundTypeRaw: String = "light"

    var body: some View {
        NavigationStack {
            List {
                Section("阅读设置") {
                    fontSizeRow
                    nightModeRow
                    autoBrightnessRow
                }

                Section("存储") {
                    cacheSizeRow
                    clearCacheRow
                }

                Section("关于") {
                    versionRow
                    licenseRow
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Font Size Row

    private var fontSizeRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "textformat")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("默认字号")
                Text("\(defaultFontSize) sp")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Stepper("", value: $defaultFontSize, in: 12...32, step: 2)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Night Mode Row

    private var nightModeRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.fill")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("夜间模式")
                Text("护眼暗色主题")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isNightMode)
                .tint(AppTheme.primary)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Auto Brightness Row

    private var autoBrightnessRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "brightness")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("跟随系统")
                Text("自动切换日间/夜间模式")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $autoBrightness)
                .tint(AppTheme.primary)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Cache Size Row

    private var cacheSizeRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("缓存大小")
                Text("0 MB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Clear Cache Row

    private var clearCacheRow: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .frame(width: 22)

                Text("清除缓存")

                Spacer()

                Text("清除")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Version Row

    private var versionRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 22)

            Text("版本")

            Spacer()

            Text("1.0.0")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - License Row

    private var licenseRow: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 22)

                Text("开源许可")

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
