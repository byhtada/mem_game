const { merge } = require('webpack-merge');
const common = require('./webpack.common.js');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyPlugin = require('copy-webpack-plugin');
const path = require('path');

module.exports = merge(common, {
  mode: 'development',
  devtool: 'source-map',
  output: {
    path: path.resolve(__dirname, '../public'),
    clean: false,
    filename: './js/app.js',
  },
  watchOptions: {
    poll: 1000,
    aggregateTimeout: 300,
    ignored: /node_modules/,
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './index.html',
      cache: false,
      inject: 'body',
    }),
    new CopyPlugin({
      patterns: [
        { from: 'img', to: 'img' },
        { from: 'css', to: 'css' },
        { from: 'js/vendor', to: 'js/vendor' },
        { from: 'js/consumer.js', to: 'js/consumer.js' },
        { from: 'icon.svg', to: 'icon.svg' },
        { from: 'favicon.ico', to: 'favicon.ico' },
        { from: 'robots.txt', to: 'robots.txt' },
        { from: 'icon.png', to: 'icon.png' },
        { from: '404.html', to: '404.html' },
        { from: 'site.webmanifest', to: 'site.webmanifest' },
        { from: 'assets', to: 'assets' },
        { from: 'libs', to: 'libs' },
      ],
    }),
  ],
});
