# 使用示例

本文档展示调用方如何使用打包好的 proto 代码。

## 方式一：通过 Git 模块引入（推荐）

### 1. 在调用方项目中引入

```bash
# 引入模块（使用特定版本）
go get github.com/haoyunfeng/edu-course-proto@v1.0.0

# 或者在 go.mod 中手动添加
go mod edit -require github.com/haoyunfeng/edu-course-proto@v1.0.0
go mod download
```

### 2. 在代码中使用

```go
package main

import (
    "context"
    "log"
    
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    
    pb "github.com/haoyunfeng/edu-course-proto/pb"
)

func main() {
    // 建立 gRPC 连接
    conn, err := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()
    
    // 创建客户端
    client := pb.NewCourseServiceClient(conn)
    
    // 调用服务
    ctx := context.Background()
    
    // 示例：创建课程
    req := &pb.CreateCourseRequest{
        Title:       "Go 编程入门",
        Content:     "这是一门 Go 编程入门课程",
        Description: "学习 Go 语言的基础知识",
        Price:       99.99,
        TypeId:      1,
        TypeCode:    "programming",
        CreatedBy:   "admin",
        UpdatedBy:   "admin",
        Status:      1,
    }
    
    resp, err := client.CreateCourse(ctx, req)
    if err != nil {
        log.Fatalf("Failed to create course: %v", err)
    }
    
    log.Printf("Course created: %+v", resp.Course)
}
```

### 3. 调用方的 go.mod 示例

```go
module your-project

go 1.21

require (
    github.com/haoyunfeng/edu-course-proto v1.0.0
    google.golang.org/grpc v1.60.0
    google.golang.org/protobuf v1.31.0
)
```

**注意**：如果模块还未发布到 GitHub，可以使用 replace 指令进行本地开发：
```go
replace github.com/haoyunfeng/edu-course-proto => ../edu-course-proto
```

## 方式二：使用本地打包文件

### 1. 解压打包文件

```bash
# 解压打包文件
tar -xzf edu-course-proto-1.0.0.tar.gz
mv edu-course-proto-1.0.0 /path/to/your-project/vendor/edu-course-proto
```

### 2. 在调用方的 go.mod 中使用 replace

```go
module your-project

go 1.21

require (
    github.com/haoyunfeng/edu-course-proto v0.0.0-00010101000000-000000000000
    google.golang.org/grpc v1.60.0
    google.golang.org/protobuf v1.31.0
)

replace github.com/haoyunfeng/edu-course-proto => ./vendor/edu-course-proto
```

### 3. 在代码中使用

```go
package main

import (
    "context"
    "log"
    
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    
    pb "github.com/haoyunfeng/edu-course-proto/pb"
)

func main() {
    // ... 使用方式同上
}
```

## 方式三：使用私有 Go 模块仓库

如果使用私有模块仓库，需要先配置：

```bash
# 设置私有仓库
go env -w GOPRIVATE=github.com/yourcompany/*
go env -w GOPROXY=https://goproxy.io,direct
```

然后正常使用 `go get` 引入。

## 服务端实现示例

作为服务提供方，你也可以参考如何实现服务端：

```go
package main

import (
    "context"
    "log"
    "net"
    "time"
    
    "google.golang.org/grpc"
    pb "github.com/haoyunfeng/edu-course-proto/pb"
)

type server struct {
    pb.UnimplementedCourseServiceServer
}

func (s *server) CreateCourse(ctx context.Context, req *pb.CreateCourseRequest) (*pb.CreateCourseResponse, error) {
    // 实现创建课程的逻辑
    course := &pb.Course{
        Id:          1,
        Title:       req.Title,
        Content:     req.Content,
        Description: req.Description,
        Price:       req.Price,
        TypeId:      req.TypeId,
        TypeCode:    req.TypeCode,
        CreatedBy:   req.CreatedBy,
        UpdatedBy:   req.UpdatedBy,
        Status:      req.Status,
        CreatedAt:   time.Now().Unix(),
        UpdatedAt:   time.Now().Unix(),
    }
    
    return &pb.CreateCourseResponse{
        Course: course,
    }, nil
}

func (s *server) GetCourse(ctx context.Context, req *pb.GetCourseRequest) (*pb.GetCourseResponse, error) {
    // 实现获取课程的逻辑
    // ...
}

func main() {
    lis, err := net.Listen("tcp", ":50051")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }
    
    s := grpc.NewServer()
    pb.RegisterCourseServiceServer(s, &server{})
    
    log.Println("Server listening on :50051")
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

## 注意事项

1. **版本管理**：建议使用语义化版本，如 v1.0.0, v1.1.0, v2.0.0
2. **依赖更新**：当 proto 定义更新时，调用方需要更新依赖版本
3. **兼容性**：重大变更应该升级主版本号（如 v1.x.x -> v2.x.x）
4. **错误处理**：gRPC 错误需要通过 `status.FromError()` 处理
