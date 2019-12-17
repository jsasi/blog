module.exports = {
    base: '/blog/',
  title: 'Asi的博客',
  description: '学无止境',
  dest: './dist',
  head: [
      ['link', {rel: 'icon', href: '/favicon.ico'}]
  ],
  markdown: {
      lineNumbers: true
  },
  themeConfig: {
      sidebarDepth: 2,
      lastUpdated: 'Last Updated',
      nav:require('./nav'),
    sidebar:[
        ['/', '首页'],
        ['/android/an.md', '我的第一篇博客']
      ],
          //   sidebar: require('./sidebar'),

  }
}

