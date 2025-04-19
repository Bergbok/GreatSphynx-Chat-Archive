import { browserslistToTargets } from 'lightningcss';
import { defineConfig } from 'vite';
import { globSync } from 'glob';
import { ViteMinifyPlugin } from 'vite-plugin-minify'
import browserslist from 'browserslist';
import path from 'path';

export default defineConfig({
    build: {
        cssMinify: 'lightningcss',
        rollupOptions: {
            input: Object.fromEntries(
                [
                    ['index', path.resolve(__dirname, 'index.html')],
                    ...globSync('src/html/**/*.html').map(file => {
                        return [
                            path.relative(path.resolve(__dirname, 'src/html'), file),
                            path.resolve(__dirname, file)
                        ]
                    })
                ]
            )
        }
    },
    css: {
        transformer: 'lightningcss',
        lightningcss: {
            cssModules: {
                pattern: '[local]'
            },
            drafts: {
                customMedia: false
            },
            nonStandard: {
                deepSelectorCombinator: false
            },
            targets: browserslistToTargets(browserslist('defaults'))
        }
    },
    esbuild: {
        legalComments: 'none'
    },
    plugins: [
        ViteMinifyPlugin({
            collapseBooleanAttributes: true,
            collapseWhitespace: true,
            keepClosingSlash: false,
            minifyCSS: false,
            minifyJS: false,
            minifyURLs: false,
            quoteCharacter: "'",
            removeAttributeQuotes: true,
            removeComments: false,
            removeEmptyAttributes: true
        })
    ],
    server: {
        open: true
    }
});
