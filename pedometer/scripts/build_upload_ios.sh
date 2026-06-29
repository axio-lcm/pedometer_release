#!/bin/bash
# 打包IPA，上传符号表到FirebaseCrashlytics，上传IPA到AppStore
# Author: 肖品
# Date: 2026-06-01
# 前提：一定要配置好Firebase Crashlytics，并配置好ios/Runner/GoogleService-Info.plist, 然后把ryh_upload_apple_id和ryh_upload_pwd添加到Keychain中，分别存储Apple ID和App专用密码（app-specific password）
# 1.存储位置: scripts/build_upload_ios.sh
# 2.授予权限：chmod +x scripts/build_upload_ios.sh
# 3.执行命令：./scripts/build_upload_ios.sh -v 2.2.0.87

#ryh_upload_apple_id和ryh_upload_pwd改成你开发者账号的存储名称
APPLE_ID_KEYCHAIN_ITEM="alh_upload_apple_id"
APP_PASSWORD_KEYCHAIN_ITEM="alh_upload_pwd"
APP_PASSWORD="@keychain:$APP_PASSWORD_KEYCHAIN_ITEM"

usage() {
  cat <<EOF
用法:
  ./scripts/build_upload_ios.sh -v <version>

参数:
  -v <version>  必填。版本号，同时作为 symbols 子目录名，例如 1.1.0.45
  -h            显示帮助

Keychain 准备:
  security add-generic-password -s $APPLE_ID_KEYCHAIN_ITEM -w "account@gmail.com" -U

  xcrun altool --store-password-in-keychain-item $APP_PASSWORD_KEYCHAIN_ITEM \\
    -u "account@gmail.com" \\
    -p "xxxx-xxxx-xxxx-xxxx"
EOF
}

# 定义清理函数
cleanup() {
  echo "⚠️ 收到中断信号,正在清理..."
  # 删除临时文件和中间产物
  rm -rf build/ios/ipa/* 2>/dev/null
  rm -rf "$SYMBOL_DIR" 2>/dev/null
  echo "✅ 清理完成,脚本已终止"
  exit 1
}

# 捕获中断信号
trap cleanup INT TERM

set -e

# 默认值
SYMBOLS_SUB_DIR=""
APPLE_ID=""

# 解析命令行参数
while getopts ":v:h" opt; do
  case $opt in
    v) SYMBOLS_SUB_DIR="$OPTARG";;
    h)
      usage
      exit 0
      ;;
    :)
      echo "❌ 选项 -$OPTARG 需要参数"
      usage
      exit 1
      ;;
    \?)
      echo "❌ 无效的选项 -$OPTARG"
      usage
      exit 1
      ;;
  esac
done

# 校验参数
if [[ -z "$SYMBOLS_SUB_DIR" ]]; then
  echo "❌ 未提供版本号"
  usage
  exit 1
fi

# 切换到脚本所在目录的上级（项目根目录）
cd "$(dirname "$0")/.."

SYMBOL_DIR="symbols/$SYMBOLS_SUB_DIR"
SYMBOL_FILE="$SYMBOL_DIR/app.ios-arm64.symbols"
SYMBOL_dSYM_FILE="$SYMBOL_DIR/Runner.app.dSYM"
SOURCE_dSYM_FILE="build/ios/archive/Runner.xcarchive/dSYMs/Runner.app.dSYM"

echo "正在从 Keychain 读取 Apple ID..."
if ! APPLE_ID=$(security find-generic-password -s "$APPLE_ID_KEYCHAIN_ITEM" -w 2>/dev/null); then
  echo "❌ 找不到 Apple ID Keychain item: $APPLE_ID_KEYCHAIN_ITEM"
  echo "请先执行："
  echo "security add-generic-password -s $APPLE_ID_KEYCHAIN_ITEM -w \"account@gmail.com\" -U"
  exit 1
fi

if [[ -z "$APPLE_ID" ]]; then
  echo "❌ Apple ID Keychain item 为空: $APPLE_ID_KEYCHAIN_ITEM"
  exit 1
fi

echo "🔥构建路径"
echo "符号表目录: $SYMBOL_DIR"
echo "Flutter符号表：$SYMBOL_FILE"
echo "dSYM符号表：$SYMBOL_dSYM_FILE"

echo "开始构建代码混淆的IPA..."
flutter build ipa --obfuscate --split-debug-info=$SYMBOL_DIR || { echo "❌ IPA构建失败"; cleanup; }
echo "IPA构建完成！"

# 检查源dSYM文件是否存在
if [[ ! -d "$SOURCE_dSYM_FILE" ]]; then
  echo "❌ 源dSYM文件未生成：$SOURCE_dSYM_FILE"
  cleanup
fi

# 复制dSYM文件到符号目录
echo "正在复制dSYM文件到符号目录..."
cp -R "$SOURCE_dSYM_FILE" "$SYMBOL_DIR" || { echo "❌ dSYM文件复制失败"; cleanup; }
echo "dSYM文件复制完成$SYMBOL_dSYM_FILE"

echo "准备上传符号表到FirebaseCrashlytics..."
echo "正在检测相关文件是否存在..."

# 检查符号文件是否存在
if [[ ! -f "$SYMBOL_FILE" ]]; then
  echo "❌ 符号文件未生成：$SYMBOL_FILE"
  cleanup
fi

# 检查 upload-symbols 脚本是否存在
if [[ ! -f "ios/Pods/FirebaseCrashlytics/upload-symbols" ]]; then
  echo "❌ 找不到 upload-symbols 脚本"
  cleanup
fi

# 检查 GoogleService-Info.plist 是否存在
if [[ ! -f "ios/Runner/GoogleService-Info.plist" ]]; then
  echo "❌ 找不到 GoogleService-Info.plist 文件"
  cleanup
fi

# 检查符号文件目录是否存在
if [[ ! -d "$SYMBOL_DIR" ]]; then
  echo "❌ 找不到符号文件目录: $SYMBOL_DIR"
  cleanup
fi

echo "正在上传符号文件到 Firebase Crashlytics..."
./ios/Pods/FirebaseCrashlytics/upload-symbols \
 -gsp ios/Runner/GoogleService-Info.plist \
 -p ios $SYMBOL_FILE || { echo "❌ Flutter符号表上传失败"; cleanup; }

echo "✅ $SYMBOL_FILE 符号表上传完成"

./ios/Pods/FirebaseCrashlytics/upload-symbols \
 -gsp ios/Runner/GoogleService-Info.plist \
 -p ios $SYMBOL_dSYM_FILE || { echo "❌ dSYM符号表上传失败"; cleanup; }

echo "✅ $SYMBOL_dSYM_FILE 符号表上传完成"

# 上传到 App Store
echo "准备上传到 App Store..."

# 检查 xcrun 命令是否可用
if ! command -v xcrun &> /dev/null; then
 echo "❌ 找不到 xcrun 命令"
 cleanup
fi

echo "正在上传 IPA 到 App Store..."
xcrun altool --upload-app -f build/ios/ipa/*.ipa \
 -t ios \
 -u "$APPLE_ID" \
 -p "$APP_PASSWORD" \
 || { echo "❌ IPA上传失败"; cleanup; }
#  --show-progress || { echo "❌ IPA上传失败"; cleanup; }

echo "✅ IPA 成功上传到AppStore！"

# 移除中断信号捕获
trap - INT TERM
echo "✅ 所有任务已完成"