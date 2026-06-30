---
title: "Hugo 博客搭建笔记"
date: 2026-06-29
draft: false
tags: ["Hugo", "博客", "GitHub Pages"]
categories: ["技术"]
description: "记录使用 Hugo 搭建 GitHub Pages 个人博客的全过程"
---

## 前言

这是我使用 Hugo 搭建个人博客的第一篇文章。本博客使用 [Demius](https://github.com/demius782/demius) 主题，部署在 GitHub Pages 上。

## 为什么要用 Hugo

- ⚡ **构建速度极快** — Go 语言编写，毫秒级生成
- 🎨 **主题生态丰富** — 上百种精美主题可选
- 📝 **Markdown 原生支持** — 专注写作
- 🔧 **零依赖部署** — 生成的纯静态文件可直接托管

## 博客结构

```
dev/
├── content/         # 文章内容（Markdown）
├── themes/demius/   # 主题目录
├── static/          # 静态资源
├── hugo.toml        # 站点配置
└── .github/         # GitHub Actions 部署
```

## 写作流程

1. `hugo new posts/my-post.md` 创建新文章
2. 编辑 Markdown 内容
3. `git add . && git commit -m "post: 新文章"`
4. `git push` 推送到 GitHub，自动部署到 Pages

## 总结

Hugo 让写博客回归本质 — **专注于内容本身**。

> "Talk is cheap. Show me the code." — Linus Torvalds
