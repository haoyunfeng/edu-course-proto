# edu-course-proto

课程服务的 Protocol Buffers 定义文件。

## 项目结构

```
.
├── proto/
│   └── course.proto      # 课程服务的 proto 定义
├── buf.yaml              # Buf 配置文件
├── buf.gen.yaml          # Buf 代码生成配置
├── Makefile              # 构建脚本
└── README.md
```

## 依赖

### 方式一：使用 Buf（推荐）

- [Buf](https://buf.build/) - 用于 protobuf 管理和代码生成

安装 Buf:
```bash
brew install bufbuild/buf/buf
# 或者
curl -sSL "https://github.com/bufbuild/buf/releases/latest/download/buf-$(uname -s)-$(uname -m)" -o "/usr/local/bin/buf"
chmod +x "/usr/local/bin/buf"
```

### 方式二：使用 protoc（传统方式）

需要安装以下工具：

1. Protocol Buffers Compiler (`protoc`)
   ```bash
   brew install protobuf
   ```

2. Go 插件
   ```bash
   go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
   go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
   ```

   确保 Go bin 目录在 PATH 中：
   ```bash
   export PATH="$PATH:$(go env GOPATH)/bin"
   ```

## 使用方法

### 生成 Go 代码

**使用 Buf（推荐）：**
```bash
make generate
```

**使用 protoc（替代方案）：**
```bash
make generate-protoc
```

两种方式都会从 proto 文件生成 Go 代码到 `gen/go` 目录。

### 代码检查

```bash
make lint      # 检查 proto 文件格式
make format    # 格式化 proto 文件
make breaking  # 检查破坏性变更
```

### 清理生成的文件

```bash
make clean
```

### 打包和分发

#### 方式一：Git 模块方式（推荐）

1. 生成代码并打标签：
```bash
make generate-protoc
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

2. 调用方使用：
```bash
go get github.com/haoyunfeng/edu-course-proto/gen/go@v1.0.0
```

#### 方式二：打包成 tar.gz

```bash
# 生成并打包
make release VERSION=v1.0.0

# 打包文件位于: dist/edu-course-proto-1.0.0.tar.gz
```

详细说明请参考 [PACKAGING.md](./PACKAGING.md)

## Service 定义

`CourseService` 提供以下 RPC 方法：

- `CreateCourse` - 创建课程
- `GetCourse` - 获取单个课程
- `GetAllCourses` - 获取所有课程
- `UpdateCourse` - 更新课程
- `DeleteCourse` - 删除课程

## 许可证

MIT