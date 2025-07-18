#!/bin/bash

# 读取.env文件（假设.env文件与脚本在同一目录）
source .env

# 函数：检查镜像是否存在
check_image_exists() {
    docker image inspect "$FULL_IMAGE" > /dev/null 2>&1
    return $?
}

# 函数：拉取镜像
pull_image() {
    echo "正在拉取镜像 ${FULL_IMAGE}..."
    if docker pull "$FULL_IMAGE"; then
        echo "镜像拉取成功"
        return 0
    else
        echo "错误：镜像拉取失败" >&2
        return 1
    fi
}


# 检查php镜像
FULL_IMAGE="wodby/drupal-php:$PHP_TAG"
echo "开始检查镜像 $FULL_IMAGE"

if check_image_exists; then
    echo "镜像 ${FULL_IMAGE} 已存在"
else
    if ! pull_image; then
        echo "镜像 ${FULL_IMAGE}  拉取失败" >&2
        exit 1
    fi
fi

# 检查nginx镜像
FULL_IMAGE="wodby/nginx:$NGINX_TAG"
echo "开始检查镜像 $FULL_IMAGE"

if check_image_exists; then
    echo "镜像 ${FULL_IMAGE} 已存在"
else
    if ! pull_image; then
        echo "镜像 ${FULL_IMAGE}  拉取失败" >&2
        exit 1
    fi
fi


# 检查mariadb镜像
FULL_IMAGE="wodby/mariadb:$MARIADB_TAG"
echo "开始检查镜像 $FULL_IMAGE"

if check_image_exists; then
    echo "镜像 ${FULL_IMAGE} 已存在"
else
    if ! pull_image; then
        echo "镜像 ${FULL_IMAGE}  拉取失败" >&2
        exit 1
    fi
fi

# 构建环境
echo "构建环境"
docker-compose up -d
sleep 10
DB_CONTAINER_NAME="${PROJECT_NAME}_mariadb"
# 检查容器是否存在
if docker inspect --format='{{.State.Status}}' "$DB_CONTAINER_NAME" >/dev/null 2>&1; then
    echo "容器 $DB_CONTAINER_NAME 创建成功"
    
    # 检查容器是否正在运行
    container_status=$(docker inspect -f '{{.State.Status}}' "$DB_CONTAINER_NAME")
    if [ "$container_status" = "running" ]; then
        echo "容器正在运行"
        # 导入数据库
        docker exec -i $DB_CONTAINER_NAME mariadb --user=root --password=$DB_ROOT_PASSWORD --database=$DB_NAME < ./init.d/drupal.sql
        echo "成功导入数据库"
    else
        echo "容器创建成功但未运行 (状态: $container_status)"
        exit 1
    fi
else
    echo "错误：容器 $DB_CONTAINER_NAME 不存在" >&2
    exit 1
fi


# 初始化drupal配置
DRUUPAL_DIR="drupal/docroot/sites/default"
 # 获取脚本绝对路径（更可靠的方式）
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# 组合完整路径
DRUUPAL_FILES="$SCRIPT_DIR/$DRUUPAL_DIR/files"

# 创建目录
if ! mkdir -p "$DRUUPAL_FILES"; then
    echo "错误: 无法创建目录 $DRUUPAL_FILES" >&2
    exit 1
fi
echo "成功创建/确认目录: $DRUUPAL_FILES"
chmod -R 777 $DRUUPAL_FILES

# 创建配置文件
SETTING_FILE="$SCRIPT_DIR/$DRUUPAL_DIR/settings.php"
rm "$SETTING_FILE"
cp "$SCRIPT_DIR/init.d/services.yml" "$SCRIPT_DIR/$DRUUPAL_DIR"
cp "$SCRIPT_DIR/$DRUUPAL_DIR/default.settings.php" $SETTING_FILE
echo "成功创建配置文件: $SETTING_FILE"

HASH_SALT=$(head -c 64 /dev/urandom | base64 | tr -dc 'a-zA-Z' | head -c 64)

# 配置drupal
read -d '' content << EOF
\$settings['hash_salt'] = '$HASH_SALT';
\$settings['reverse_proxy'] = TRUE;
\$settings['reverse_proxy_addresses'] = array(\$_SERVER['REMOTE_ADDR']);
\$settings['reverse_proxy_trusted_headers'] = \\\Symfony\\\Component\\\HttpFoundation\\\Request::HEADER_X_FORWARDED_FOR | \\\Symfony\\\Component\\\HttpFoundation\\\Request::HEADER_X_FORWARDED_HOST | \\\Symfony\\\Component\\\HttpFoundation\\\Request::HEADER_X_FORWARDED_PROTO ;

if (file_exists(\$app_root . '/' . \$site_path . '/settings.local.php')) {
   include \$app_root . '/' . \$site_path . '/settings.local.php';
}
\$databases['default']['default'] = array (
  'database' => '$DB_NAME',
  'username' => '$DB_USER',
  'password' => '$DB_PASSWORD',
  'prefix' => '',
  'host' => '$DB_HOST',
  'port' => '$DB_PORT',
  'namespace' => 'Drupal\\\\\\\Core\\\\\\\Database\\\\\\\Driver\\\\\\\mysql',
  'driver' => 'mysql',
);
EOF


printf "\n%s\n" "$content" >> "$SETTING_FILE"
echo "成功配置文件: $SETTING_FILE"

docker exec -it "${PROJECT_NAME}_php" drush upwd root "$SITE_PASSWORD"
echo "登录密码: $SITE_PASSWORD"
echo "安装完成"