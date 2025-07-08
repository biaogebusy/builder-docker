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
git clone git@github.com:biaogebusy/web-builder.git
```

## 4. web builder目录下创建 Dockerfile

``` base 
# 阶段 1：构建应用
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# 阶段 2：运行应用
FROM node:22-alpine

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

RUN npm install --only=production

EXPOSE 4200

CMD ["node", "dist/server/server.mjs"]

```

## 2. 构建并启动容器

```bash
docker-compose up --build
```
