# Android Helium Browser 编译说明

当前源码基于 Chromium `150.0.7871.124`，版本号由 `vanadium/args.gn` 自动读取。

## 1. 环境要求

- Ubuntu 24.04（其他较新的 Debian/Ubuntu 版本通常也可用）
- 建议至少 16 核 CPU、32 GB 内存
- 建议预留 150 GB 以上磁盘空间
- 可访问 Chromium、GitHub、Google Storage 等源码和依赖站点
- 当前用户需要具有 `sudo` 权限，首次构建会自动安装系统依赖

仓库必须连同子模块一起获取：

```bash
git clone --recursive https://github.com/dandelions/android-helium-browser.git
cd android-helium-browser
git submodule update --init --recursive
```

如果已经克隆仓库，在切换版本或拉取更新后执行：

```bash
git submodule sync --recursive
git submodule update --init --recursive
```

## 2. 首次编译

默认仅编译 arm64 APK，使用 14 个本地并行任务：

```bash
NINJA_JOBS=14 ./build.sh
```

脚本会依次完成：

1. 从 `vanadium/args.gn` 读取 Chromium 版本。
2. 安装编译依赖并准备 `depot_tools`。
3. 获取对应 Chromium 标签并执行 `gclient sync`。
4. 应用 Vanadium 主补丁和 V8 子项目补丁。
5. 下载过滤列表并应用 Helium Android 补丁。
6. 生成 GN 输出目录并调用 Ninja 编译。
7. 自动生成本地测试签名（未提供正式签名时）并签署 APK/AAB。

产物位于：

```text
chromium/src/out/release/150.0.7871.124-arm64-v8a.apk
```

## 3. 可选构建参数

同时构建 32 位 ARM、64 位 ARM 和 AAB：

```bash
BUILD_ARM=1 BUILD_ARM64=1 BUILD_AAB=1 NINJA_JOBS=14 ./build.sh
```

常用环境变量：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `BUILD_ARM` | `0` | 构建 armeabi-v7a APK |
| `BUILD_ARM64` | `1` | 构建 arm64-v8a APK |
| `BUILD_AAB` | `0` | 构建 arm64 Android App Bundle |
| `NINJA_JOBS` | `14` | Ninja/Siso 本地并行任务数 |
| `CCACHE_MAX_SIZE` | `30G` | ccache 最大容量 |
| `BUILD_PROXY` | 自动读取代理变量 | 构建下载所使用的 HTTP/HTTPS 代理 |
| `BUILD_VERSION_INCREMENT` | 按 UTC 分钟生成 | Chromium Android `versionCode` 增量 |

例如使用代理：

```bash
BUILD_PROXY=http://127.0.0.1:7890 NINJA_JOBS=14 ./build.sh
```

## 4. 增量编译

首次完整构建成功后，可以复用现有 `depot_tools`、Chromium 源码和输出目录：

```bash
FAST_LOCAL_BUILD=1 NINJA_JOBS=14 ./build.sh
```

`FAST_LOCAL_BUILD=1` 会跳过源码准备、系统依赖安装和 `patch.sh`。如果修改了补丁脚本，应先对现有源码执行：

```bash
./hotfix_existing_src.sh chromium/src
FAST_LOCAL_BUILD=1 NINJA_JOBS=14 ./build.sh
```

升级 Chromium/Vanadium 版本时不要使用快速模式，应重新执行完整构建流程。

## 5. 正式签名

默认会在 `keys/` 中生成仅供本地测试的签名。正式发布时准备：

```text
keys/test.jks
keys/local.properties
```

`keys/local.properties` 示例：

```properties
keyAlias=your-key-alias
keyPassword=your-key-password
storePassword=your-store-password
```

也可以通过 CI 环境变量传入 Base64 内容：

- `LOCAL_TEST_JKS`：`local.properties` 的 Base64
- `STORE_TEST_JKS`：JKS 文件的 Base64

## 6. 基础验证

不下载完整 Chromium 源码时，可以先验证脚本和合并状态：

```bash
bash -n build.sh
bash -n patch.sh
bash -n hotfix_existing_src.sh
bash -n common.sh
git submodule status
grep android_default_version_name vanadium/args.gn
```

版本行应显示：

```text
android_default_version_name = "150.0.7871.124"
```
