module App exposing (..)

import Html exposing (..)
import Html.App as Html
import UserSearch exposing (..)
import TweetSearch exposing (..)


type alias Model =
    { userSearch : UserSearch.Model
    , tweetSearch : TweetSearch.Model
    }


model : Model
model =
    { userSearch = fst UserSearch.init
    , tweetSearch = fst TweetSearch.init
    }


init : ( Model, Cmd Action )
init =
    ( model, Cmd.none )


type Action
    = User UserSearch.Action
    | Tweets TweetSearch.Action


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        User (UserSearchResult result) ->
            let
                ( newUserModel, newUserCmd ) =
                    UserSearch.update (UserSearchResult result) model.userSearch

                ( newTweetModel, newTweetCmd ) =
                    case newUserModel.user of
                        UserSearch.Success user ->
                            TweetSearch.update (TweetSearch.SetUser user) model.tweetSearch

                        _ ->
                            ( model.tweetSearch, Cmd.none )

                newModel =
                    { model | userSearch = newUserModel, tweetSearch = newTweetModel }
            in
                ( newModel
                , Cmd.batch
                    [ Cmd.map User newUserCmd
                    , Cmd.map Tweets newTweetCmd
                    ]
                )

        User action' ->
            let
                ( newUserModel, newUserCmd ) =
                    UserSearch.update action' model.userSearch

                newModel =
                    { model | userSearch = newUserModel }
            in
                ( newModel, Cmd.map User newUserCmd )

        Tweets (TweetSearch.Reset) ->
            let
                ( newTweetModel, newTweetCmd ) =
                    TweetSearch.update TweetSearch.Reset model.tweetSearch

                ( newUserModel, newUserCmd ) =
                    UserSearch.update UserSearch.Reset model.userSearch

                newModel =
                    { model | tweetSearch = newTweetModel, userSearch = newUserModel }
            in
                ( newModel
                , Cmd.batch
                    [ Cmd.map Tweets newTweetCmd
                    , Cmd.map User newUserCmd
                    ]
                )

        Tweets action' ->
            let
                ( newTweetModel, newTweetCmd ) =
                    TweetSearch.update action' model.tweetSearch

                newModel =
                    { model | tweetSearch = newTweetModel }
            in
                ( newModel, Cmd.map Tweets newTweetCmd )


view : Model -> Html Action
view model =
    case model.userSearch.user of
        UserSearch.Success user ->
            Html.map Tweets <| TweetSearch.view model.tweetSearch

        _ ->
            Html.map User <| UserSearch.view model.userSearch


main : Program Never
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \model -> Sub.map Tweets (subscriptions model.tweetSearch)
        }
