import { fileURLToPath } from 'url'
import { dirname, resolve } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

export default {
  title: 'Iconmap for Rails',
  description: 'Vendor SVG icons from npm packages and serve them via Rails',
  base: '/iconmap-rails/',
  head: [['meta', { name: 'theme-color', content: '#1e88ff' }]],
  themeConfig: {
    siteTitle: 'Iconmap for Rails',
    logo: '/logo.svg',
    nav: [
      { text: 'Guide', link: '/' },
      { text: 'CLI', link: '/cli' },
      { text: 'API', link: '/api' }
    ],
    sidebar: {
      '/': [
        { text: 'Guide', items: [ { text: 'Introduction', link: '/' }, { text: 'Installation', link: '/installation' }, { text: 'How it works', link: '/how-it-works' }, { text: 'Configuration', link: '/configuration' } ] },
        { text: 'Reference', items: [ { text: 'CLI', link: '/cli' }, { text: 'API', link: '/api' } ] }
      ]
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/tagliala/iconmap-rails' }
    ]
  }
}
