# 打包和分发指南

本文档说明如何将生成的 proto 代码打包分发给调用方使用。

## 打包方式

### 方式一：Git 模块方式（推荐）

如果代码托管在 Git 仓库中（如 GitHub、GitLab），这是最推荐的方式。

#### 1. 生成代码并提交

```bash
# 生成代码
make generate-protoc

# 提交生成的代码（可选：如果希望将生成的代码也提交到仓库）
git add pb/ go.mod go.sum
git commit -m "feat: generate proto code"
```

#### 2. 打版本标签

```bash
# 创建版本标签
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

#### 3. 调用方使用

调用方可以通过以下方式引入：

```bash
# 直接引入模块
go get github.com/haoyunfeng/edu-course-proto@v1.0.0

# 方式2：使用 replace 指令（开发阶段）
# 在调用方的 go.mod 中添加：
replace github.com/haoyunfeng/edu-course-proto => ../edu-course-proto
```

在代码中使用：
```go
import (
    "github.com/haoyunfeng/edu-course-proto/pb"
    "google.golang.org/grpc"
)

// 使用生成的代码
client := pb.NewCourseServiceClient(conn)
```

### 方式二：打包成 tar.gz

适合需要离线分发或不想将生成的代码提交到 Git 的场景。

#### 1. 生成打包文件

```bash
# 生成代码并打包
make generate-protoc
make package

# 或者指定版本号打包
make package VERSION=v1.0.0

# 或使用 release 命令（推荐）
make release VERSION=v1.0.0
```

打包文件会生成在 `dist/` 目录下，例如：`dist/edu-course-proto-1.0.0.tar.gz`

#### 2. 分发给调用方

将打包文件发送给调用方，调用方需要：

```bash
# 解压包
tar -xzf edu-course-proto-1.0.0.tar.gz
cd edu-course-proto-1.0.0

# 在调用方的项目中，使用 replace 指令
# 在 go.mod 中添加：
replace github.com/haoyunfeng/edu-course-proto => /path/to/edu-course-proto-1.0.0
```

或者直接复制到项目中：
```bash
# 将解压后的内容复制到项目的 vendor 或 lib 目录
cp -r edu-course-proto-1.0.0 /path/to/your-project/vendor/edu-course-proto
```

### 方式三：发布到私有 Go 模块仓库

如果公司有私有的 Go 模块仓库（如 GoProxy、JFrog Artifactory 等）：

#### 1. 配置 Go 模块路径

修改 `proto/course.proto` 中的 `go_package` 选项为私有仓库路径：
```protobuf
option go_package = "github.com/yourcompany/edu-course-proto/pb";
```

修改 `go.mod` 中的模块路径：
```go
module github.com/yourcompany/edu-course-proto
```

#### 2. 发布到私有仓库

根据私有仓库的要求进行发布，通常是：
```bash
go mod tidy
# 根据私有仓库文档进行发布
```

#### 3. 调用方使用

```bash
# 配置 GOPRIVATE 环境变量
go env -w GOPRIVATE=github.com/yourcompany/*

# 引入模块
go get github.com/yourcompany/edu-course-proto@v1.0.0
```

## 最佳实践

1. **版本管理**：使用语义化版本（Semantic Versioning），如 v1.0.0, v1.1.0, v2.0.0
2. **生成代码管理**：
   - 选项A：将生成的代码提交到 Git（方便但不优雅）
   - 选项B：只提交 proto 文件，CI/CD 自动生成并发布（推荐）
3. **依赖管理**：确保生成的代码包含完整的 `go.mod` 和 `go.sum`
4. **文档**：在 README 中说明如何引入和使用

## 示例：CI/CD 自动发布

可以在 CI/CD 流程中自动化打包和发布：

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Generate proto code
        run: make generate-protoc
      - name: Package
        run: make package VERSION=${GITHUB_REF#refs/tags/}
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: proto-package
          path: dist/*.tar.gz
```

## 常见问题

**Q: 调用方如何知道使用哪个版本？**
A: 建议使用 Git 标签管理版本，调用方可以通过 `go get module@version` 指定版本。

**Q: 生成的代码需要提交到 Git 吗？**
A: 两种方式都可以：
- 提交：方便调用方直接使用，但会增加仓库大小
- 不提交：更优雅，但需要 CI/CD 自动生成并发布

**Q: 如何更新版本？**
A: 修改 proto 文件后，重新生成代码，创建新的 Git 标签并打包。
