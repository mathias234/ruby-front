const path = require('path');
const esbuild = require('esbuild');
const plugin = require('node-stdlib-browser/helpers/esbuild/plugin');
const stdLibBrowser = require('node-stdlib-browser');

(async () => {
	await esbuild.build({
		entryPoints: ['index.js'],
		bundle: true,
		outfile: 'build.js',
		minify: false,
		sourcemap: true,
    format: "esm",
		inject: [require.resolve('node-stdlib-browser/helpers/esbuild/shim')],
		define: {
			Buffer: 'Buffer'
		},
		plugins: [plugin(stdLibBrowser)]
	});
})();
