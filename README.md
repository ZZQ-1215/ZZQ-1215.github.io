# 我的 Hugo 博客

使用 [Hugo](https://gohugo.io/) + [Demius](https://github.com/demius782/demius) 主题搭建的 GitHub Pages 个人博客。

## 本地开发

```bash
# 安装依赖
npm install

# 启动本地预览（带热重载）
hugo server -D

# 构建静态文件
hugo --minify
```

## 部署

推送到 `main` 分支即可自动部署到 GitHub Pages（通过 GitHub Actions）。

## 目录结构

- `content/` — 博客文章（Markdown）
- `themes/demius/` — 主题文件
- `static/` — 静态资源（图片、favicon 等）
- `hugo.toml` — 站点配置
- `.github/workflows/hugo.yml` — 部署工作流
