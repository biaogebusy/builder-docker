# 部署步骤

## 1. 克隆 builder docker 项目到服务器

```bash
git clone git@github.com:biaogebusy/builder-docker.git
```

## 2. 克隆 Builder cms 仓库

在项目根目录下克隆最新的 builder cms

```bash
git clone git@github.com:biaogebusy/builder-cms.git drupal
```

## 3. 克隆 web builder

```base
cd web-builder
git clone git@github.com:biaogebusy/web-builder.git
```

## 2. 构建并启动容器

```bash
docker-compose up --build
```
