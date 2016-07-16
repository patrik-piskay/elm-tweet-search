module.exports = {
    entry: {
        elm: './src/client/Main.elm',
        js: './src/client/js/index.js',
    },
    output: {
        path: './build',
        filename: '[name].bundle.js',
        libraryTarget: 'umd',
    },
    module: {
        loaders: [{
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node-modules/],
            loader: 'elm-webpack',
        }, {
            test: /\.js$/,
            exclude: /node_modules/,
            loader: 'babel?presets[]=es2015',
        }],
    }
};
