const path = require('path');
module.exports = {
  plugins: [
    require('postcss-import')({
      root: path.resolve(__dirname, 'themes/demius/assets/css'),
      path: [
        path.resolve(__dirname, 'themes/demius/assets/css'),
        path.resolve(__dirname, 'assets/css'),
        path.resolve(__dirname)
      ]
    })
  ]
}
