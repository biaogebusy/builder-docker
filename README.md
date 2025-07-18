# 安装部署步骤

## 0. 准备环境

根据实际需求修改`.env`中的变量，根据变量创建：

- 前端暴露端口
- 后端暴露端口
- 数据库用户名和密码
- drupal root超级管理员密码

```bash
### PROJECT SETTINGS
PROJECT_NAME=builder
NODE_PORT=4200
PROJECT_PORT=5080

### PHP
PHP_TAG=8.1

### nginx
NGINX_TAG=1.29
### Mariadb
MARIADB_TAG=11.4
DB_NAME=drupal
DB_USER=drupal
DB_PASSWORD=9QoLiAh1RiVqHv26
DB_ROOT_PASSWORD=R826fXdLZXmovIhi
DB_HOST=mariadb
DB_PORT=3306
DB_DRIVER=mysql

### site
SITE_PASSWORD=8DvyifP9vUSv9%7L
```

## 1. 克隆或者下载 builder docker 项目

```bash
git clone git@github.com:biaogebusy/builder-docker.git
```

## 2. 克隆 Builder cms 仓库

在项目根目录下克隆最新的 builder cms 为 drupal

```bash
git clone git@github.com:biaogebusy/builder-cms.git drupal
```

修改`./init.d/services.yml`中`allowedOrigins`为你的前台域名。

```yml
  cors.config:
    enabled: true
    # Specify allowed headers, like 'x-allowed-header'.
    allowedHeaders: ['x-csrf-token','authorization','content-type','accept','origin','x-requested-with']
    # Specify allowed request methods, specify ['*'] to allow all possible ones.
    allowedMethods: ['*']
    # Configure requests allowed from specific origins.
    allowedOrigins: ['https://base.builder.design']
    # Sets the Access-Control-Expose-Headers header.
    exposedHeaders: true
    # Sets the Access-Control-Max-Age header.
    maxAge: 1000
    # Sets the Access-Control-Allow-Credentials header.
    supportsCredentials: true
```

## 3. 克隆 web builder

```base
git clone git@github.com:biaogebusy/web-builder.git
```

## 4. 绑定前台域名

打开web builder目录下：`/src/environments/environment.prod.ts`，修改环境变量apiUrl为你的前台域名，例如：

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

> 默认开启多语言

## 5. 持续构建脚本

以上前后台搭建完成之后，在项目根目录下执行构建脚本，脚本执行以下流程：

### 第一阶段

- 检查并拉取`wodby/drupal-php`对应版本镜像
- 检查并拉取`wodby/nginx`对应版本镜像
- 检查并拉取`wodby/mariadb`对应版本镜像
- web builder 下载依赖并构建打包

### 第二阶段

- 创建数据库，并导入`./init.d/durpal.sql`初始化的安装包
- 初始化Drupal站点`drupal/docroot/sites/default`相关文件及文件夹创建
- 创建 `files`文件夹并设置`777`权限
- 复制 `./init.d/services.yml` 到 `drupal/docroot/sites/default`目录下
- 复制 `drupal/docroot/sites/default/default.settings.php`为`settings.php`
- 配置`hash_salt`和反向代理`reverse_proxy`
- 配置数据库
- 重置密码为环境变量中的自定义密码

```bash
./install.sh
```
