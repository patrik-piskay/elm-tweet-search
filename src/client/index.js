import Elm from './Main.elm';
import { search } from './js';

const app = Elm.App.fullscreen();

app.ports.filterTweets.subscribe(([tweets, searchTerm]) => {
    const filteredTweets = search(tweets, searchTerm);

    app.ports.filteredTweets.send(filteredTweets);
});
