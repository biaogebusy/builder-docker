# CMS 基线转储

- 文件：`drupal-base.gz`，gzip 压缩的 MariaDB SQL 转储。
- 来源：builder-cms base 环境的 `builder_cms_d11` 数据库。
- 导出日期：2026-10-28。
- 导出时的代码：builder-cms 分支 `11.x`，commit `af55bfe1b`。

builder-cms 发布改变 CMS 基线时，重新导出转储，并更新本文件的记录。
导入脚本在导入后执行 `drush updb -y` 和 `drush cr`，保证数据库结构不落后于代码。
