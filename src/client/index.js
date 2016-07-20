import Elm from './Main.elm';
import { search } from './js';

const TweetSearchApp = Elm.App.fullscreen();

TweetSearchApp.ports.filterTweets.subscribe(([tweets, searchTerm]) => {
    const filteredTweets = search(tweets, searchTerm);

    TweetSearchApp.ports.filteredTweets.send(filteredTweets);
});
