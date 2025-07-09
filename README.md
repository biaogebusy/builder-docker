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

## 4. web builder 目录下创建 Dockerfile

把 web-builder 里面的文件复制到项目的 web-builder 目录下，打开配置文件：`/src/environments/environment.prod.ts`，并配置你的 api 地址（你的前台访问地址），例如：

```ts
export const environment: IEnvironment = {
  apiUrl: 'https://base.builder.design',
  production: true,
  port: 4200,
  cache: true,
  multiLang: true,
  langs: [
    {
      label: '中文',
      langCode: 'zh-hans',
      prefix: '/',
      default: true,
    },
    {
      label: 'EN',
      langCode: 'en',
      prefix: '/en',
    },
  ],
};
```

```base
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

EXPOSE 4200

CMD ["node", "dist/server/server.mjs"]

```

## 5. 构建并启动容器

```bash
docker-compose up --build
```

## 测试容器网络连通性

在 docker-compose.yml 文件所在目录下：

```bash
docker-compose exec nginx ping php
docker-compose exec php ping nginx
```

## 验证步骤

测试 PHP 路由：

```bash
curl -I http://docker.builder.design/api/v3/landingPage
# 检查响应头中的 X-FastCGI-Cache 状态
```

检查缓存文件：

```bash
docker-compose exec nginx ls /var/cache/nginx/fastcgi_cache_panel
```

监控性能：

```bash
docker stats
docker-compose exec nginx nginx -T | grep cache
```
