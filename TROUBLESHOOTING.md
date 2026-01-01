# 故障排查指南

## 常见问题

### 1. go: warning: "github.com/haoyunfeng/edu-course-proto/pb/..." matched no packages

**问题原因**：
模块路径不一致。`go.mod` 中的模块名必须与 Git 仓库路径匹配。

**解决方案**：
1. 确保 `proto/course.proto` 中的 `go_package` 选项为：
   ```protobuf
   option go_package = "github.com/haoyunfeng/edu-course-proto/pb";
   ```

2. 确保 `go.mod` 中的模块路径为：
   ```go
   module github.com/haoyunfeng/edu-course-proto
   ```

3. 重新生成代码：
   ```bash
   make clean
   make generate-protoc
   ```

4. 验证模块路径：
   ```bash
   go list -m
   # 应该输出：github.com/haoyunfeng/edu-course-proto
   ```

### 2. cannot find package "github.com/haoyunfeng/edu-course-proto/pb"

**问题原因**：
- 模块还未发布到 GitHub
- 或者路径不正确

**解决方案**：

**方案A：使用 replace 指令（本地开发）**
在调用方的 `go.mod` 中添加：
```go
replace github.com/haoyunfeng/edu-course-proto => /path/to/edu-course-proto
```

**方案B：发布到 GitHub**
1. 提交生成的代码到 Git：
   ```bash
   git add pb/ go.mod go.sum
   git commit -m "feat: generate proto code"
   git push
   ```

2. 创建版本标签：
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

3. 调用方使用：
   ```bash
   go get github.com/haoyunfeng/edu-course-proto@v1.0.0
   ```

### 3. protoc-gen-go: program not found

**问题原因**：
缺少 protobuf Go 插件

**解决方案**：
```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# 确保在 PATH 中
export PATH="$PATH:$(go env GOPATH)/bin"
```

### 4. 生成的代码导入路径不正确

**问题原因**：
`proto/course.proto` 中的 `go_package` 选项与实际的模块路径不匹配

**解决方案**：
1. 检查 `go_package` 选项：
   ```protobuf
   option go_package = "github.com/haoyunfeng/edu-course-proto/pb";
   ```
   格式应该是：`<Git仓库路径>/pb`

2. 重新生成代码：
   ```bash
   make clean
   make generate-protoc
   ```

### 5. can't request version "v1.0.1" of the main module

**问题原因**：
- 在模块的根目录中尝试 `go get` 自己的模块（这是不允许的）
- 或者尝试获取一个不存在的版本标签
- 或者 `go.mod` 中有错误的 replace 指令指向自己

**解决方案**：

1. **不要在模块根目录中 go get 自己的模块**
   ```bash
   # 错误：在模块根目录中执行
   cd /path/to/edu-course-proto
   go get github.com/haoyunfeng/edu-course-proto@v1.0.1  # ❌ 错误
   ```
   
   正确做法：在调用方的项目中执行 `go get`

2. **检查 go.mod 中是否有错误的 replace 指令**
   ```bash
   grep "replace" go.mod
   ```
   
   如果发现有指向自己的 replace 指令（这是示例代码），需要删除：
   ```go
   // 错误示例（应该删除）
   replace github.com/haoyunfeng/edu-course-proto => /path/to/edu-course-proto
   ```
   
   删除方法：
   ```bash
   go mod edit -dropreplace github.com/haoyunfeng/edu-course-proto
   ```

3. **如果要创建新版本，应该：**
   ```bash
   # 1. 生成代码
   make generate-protoc
   
   # 2. 提交更改
   git add pb/ go.mod go.sum
   git commit -m "feat: update to v1.0.1"
   
   # 3. 创建新标签
   git tag -a v1.0.1 -m "Release v1.0.1"
   git push origin main
   git push origin v1.0.1
   ```

4. **调用方使用新版本：**
   ```bash
   # 在调用方的项目中（不是模块根目录）
   go get github.com/haoyunfeng/edu-course-proto@v1.0.1
   ```

### 6. replacement directory ./pb_stub does not exist

**问题原因**：
在调用方的 `go.mod` 文件中有一个错误的 replace 指令，指向了不存在的目录。

**解决方案**：

1. 检查调用方项目的 `go.mod` 文件，查找 replace 指令：
   ```bash
   grep -A 2 "replace" go.mod
   ```

2. 如果发现有类似这样的错误 replace：
   ```go
   replace github.com/haoyunfeng/edu-course-proto/pb => ./pb_stub
   ```
   
   这是错误的！正确的做法应该是：

   **方案A：删除错误的 replace（推荐）**
   如果模块已经发布到 GitHub，直接删除这个 replace 指令：
   ```bash
   go mod edit -dropreplace github.com/haoyunfeng/edu-course-proto/pb
   ```

   **方案B：使用正确的 replace**
   如果要使用本地路径，应该是：
   ```go
   replace github.com/haoyunfeng/edu-course-proto => /path/to/edu-course-proto
   ```
   注意：替换的是模块路径 `github.com/haoyunfeng/edu-course-proto`，而不是包路径 `github.com/haoyunfeng/edu-course-proto/pb`

3. 清理并重新下载依赖：
   ```bash
   go mod tidy
   ```

**重要提示**：
- 模块路径：`github.com/haoyunfeng/edu-course-proto`（用于 replace 和 go get）
- 包路径：`github.com/haoyunfeng/edu-course-proto/pb`（用于 import）
- replace 指令应该替换模块路径，而不是包路径

## 验证步骤

完成配置后，可以通过以下步骤验证：

```bash
# 1. 生成代码
make generate-protoc

# 2. 检查模块路径
go list -m
# 应该输出：github.com/haoyunfeng/edu-course-proto

# 3. 检查包路径
go list ./pb/...
# 应该输出：github.com/haoyunfeng/edu-course-proto/pb

# 4. 编译验证
go build ./pb/...
# 应该无错误输出
```

## 获取帮助

如果问题仍未解决，请检查：
1. Go 版本是否符合要求（go 1.21+）
2. protoc 和插件版本是否最新
3. Git 仓库路径是否正确
4. 网络连接是否正常（如需从 GitHub 下载）
