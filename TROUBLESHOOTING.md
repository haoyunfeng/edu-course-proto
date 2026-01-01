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

### 5. 模块路径更改后如何迁移

如果之前使用了其他模块路径（如 `edu-course/proto`），需要：

1. 更新 `proto/course.proto` 中的 `go_package`
2. 清理并重新生成代码
3. 更新调用方的导入路径
4. 更新调用方的 `go.mod` 中的模块路径

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
