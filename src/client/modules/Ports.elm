port module Ports exposing (..)

import Models exposing (TweetModel)


port filterTweets : (List TweetModel, String) -> Cmd msg


port filteredTweets : (List TweetModel -> msg) -> Sub msg
