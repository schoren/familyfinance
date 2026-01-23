import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "Keda Documentation",
  description: "User guide for Keda Family Finance",
  base: '/docs/',

  themeConfig: {
    logo: '/assets/logo.png',

    socialLinks: [
      { icon: 'github', link: 'https://github.com/schoren/keda' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2026-present'
    }
  },

  locales: {
    root: {
      label: 'English',
      lang: 'en',
      themeConfig: {
        nav: [
          { text: 'Home', link: '/' },
          { text: 'Guide', link: '/expenses' },
        ],
        sidebar: [
          {
            text: 'Getting Started',
            items: [
              { text: 'Introduction', link: '/' },
              { text: 'Authentication', link: '/auth' }
            ]
          },
          {
            text: 'Features',
            items: [
              { text: 'Expenses', link: '/expenses' },
              { text: 'Categories', link: '/categories' },
              { text: 'Accounts', link: '/accounts' },
              { text: 'Household', link: '/household' }
            ]
          }
        ]
      }
    },
    es: {
      label: 'Español',
      lang: 'es',
      link: '/es/',
      themeConfig: {
        nav: [
          { text: 'Inicio', link: '/es/' },
          { text: 'Guía', link: '/es/expenses' },
        ],
        sidebar: [
          {
            text: 'Primeros Pasos',
            items: [
              { text: 'Introducción', link: '/es/' },
              { text: 'Autenticación', link: '/es/auth' }
            ]
          },
          {
            text: 'Funcionalidades',
            items: [
              { text: 'Gastos', link: '/es/expenses' },
              { text: 'Categorías', link: '/es/categories' },
              { text: 'Cuentas', link: '/es/accounts' },
              { text: 'Hogar', link: '/es/household' }
            ]
          }
        ]
      }
    }
  }
})
