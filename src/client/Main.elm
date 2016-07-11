module App exposing (..)

import Html.App as Html
--import UserSearch exposing (init, update, view)
import TweetSearch exposing (init, update, view)


main : Program Never
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
