# 确保脚本抛出遇到的错误
set -e

# 生成静态文件
npm run docs:build

# 进入生成的文件夹
cd docs/.vuepress/dist

git init
git add -A
git commit -m 'deploy'

#如果打算发布到 https://<USERNAME>.github.io/<REPO>/（也就是说你的仓库在 https://github.com/<USERNAME>/<REPO>），则将 base 设置为 /<REPO>/，此处我设置为 /study_blogs /
#git push -f git@github.com:<USERNAME>/<REPO>.git master:gh-pages(分支）
git push -f git@github.com:jsasi/blog.git master

cd -