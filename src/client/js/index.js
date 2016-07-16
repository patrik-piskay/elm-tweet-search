import Fuse from 'fuse';

export const search = (tweets) => {
    const fuse = new Fuse(tweets, { keys: ['text'] });

    return fuse;
};
