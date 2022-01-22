process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const { webpackConfig, merge } = require('shakapacker');
const customConfig = require('./custom');

// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.

module.exports = merge(webpackConfig, customConfig);
