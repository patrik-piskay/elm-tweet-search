module.exports = {
    entry: './src/client/index.js',
    output: {
        path: './build',
        filename: 'bundle.js',
    },
    module: {
        noParse: /\.elm$/,
        loaders: [{
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node-modules/],
            loader: 'elm-webpack',
        }, {
            test: /\.js$/,
            exclude: /node_modules/,
            loader: 'babel?presets[]=es2015&plugins[]=transform-object-rest-spread',
        }],
    }
};
