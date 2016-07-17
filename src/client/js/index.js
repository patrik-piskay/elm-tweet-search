import textFilter from 'text-filter';

export const search = (tweets, searchTerm) => {
    const result = tweets.filter(textFilter({
        query: searchTerm,
        fields: ['text'],
    }));

    return result;
};
