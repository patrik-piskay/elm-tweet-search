module TweetSearch exposing (..)

import Models exposing (..)
import UserSearch exposing (decodeUserDetails)
import Ports exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing ((:=))
import Json.Encode
import Http
import Task
import String


-- MODEL


type alias Model =
    { user : Maybe UserModel
    , tweetSearchInput : String
    , tweets : RemoteData (List TweetModel)
    , filteredTweets : List TweetModel
    }


model : Model
model =
    { user = Nothing
    , tweetSearchInput = ""
    , tweets = Loading
    , filteredTweets = []
    }


init : ( Model, Cmd Action )
init =
    ( model
    , Cmd.none
    )



-- UPDATE


type Action
    = Reset
    | SetUser UserModel
    | UpdateTweetSearchValue String
    | TweetSearchResult (List TweetModel)
    | HttpError Http.Error
    | FilteredTweets (List TweetModel)


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        Reset ->
            init

        SetUser user ->
            let
                newModel =
                    { model | user = Just user }
            in
                ( newModel, getTweets user )

        UpdateTweetSearchValue value ->
            let
                newModel =
                    { model | tweetSearchInput = value }
            in
                case model.tweets of
                    Success tweets ->
                        ( newModel, filterTweets ( tweets, value ) )

                    _ ->
                        ( newModel, Cmd.none )

        TweetSearchResult result ->
            let
                newModel =
                    { model | tweets = Success result }
            in
                ( newModel, Cmd.none )

        HttpError err ->
            let
                _ =
                    Debug.log "err" err

                newModel =
                    { model | tweets = Failure err }
            in
                ( newModel, Cmd.none )

        FilteredTweets tweets ->
            let
                newModel =
                    { model | filteredTweets = tweets }
            in
                ( newModel, Cmd.none )



-- VIEW


view : Model -> Html Action
view model =
    case model.user of
        Just user ->
            div []
                [ div []
                    [ div [ class "user" ]
                        [ span
                            [ onClick Reset
                            , class "reset"
                            , property "innerHTML" (Json.Encode.string "&laquo;")
                            ]
                            []
                        , img [ src user.profileImg ] []
                        , span [] [ text user.name ]
                        ]
                    , input
                        [ type' "text"
                        , placeholder "Search in tweets..."
                        , value model.tweetSearchInput
                        , class "tweet-search-input"
                        , onInput UpdateTweetSearchValue
                        ]
                        []
                    ]
                , ul
                    [ class "tweet-results" ]
                    (case model.tweets of
                        NotAsked ->
                            []

                        Loading ->
                            [ div [ class "loading" ] [ text "Loading tweets ..." ] ]

                        Failure err ->
                            [ div [ class "error" ] [ text "Could not load data" ] ]

                        Success allTweets ->
                            if not (List.isEmpty allTweets) then
                                let
                                    tweets' =
                                        if String.isEmpty model.tweetSearchInput then
                                            allTweets
                                        else
                                            model.filteredTweets
                                in
                                    List.map
                                        (\tweet -> li [] [ renderTweet tweet ])
                                        tweets'
                            else
                                [ div [ class "no-tweets-found" ] [ text "No tweets found" ] ]
                    )
                ]

        Nothing ->
            div [] []


renderTweet : TweetModel -> Html Action
renderTweet tweet =
    let
        userName =
            case tweet.retweetedUserName of
                Just name ->
                    name

                Nothing ->
                    tweet.user.screenName

        url =
            "https://twitter.com/" ++ userName ++ "/status/" ++ tweet.id
    in
        a
            [ href url
            , target "blank"
            , class "tweet"
            ]
            [ span
                [ property "innerHTML" (Json.Encode.string tweet.text)
                ]
                []
            ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Action
subscriptions model =
    filteredTweets FilteredTweets



-- TASKS


getTweets : UserModel -> Cmd Action
getTweets user =
    let
        request =
            Http.get decodeTweets ("/api/statuses/user_timeline.json?screen_name=" ++ user.screenName ++ "&count=200")
    in
        Task.perform HttpError TweetSearchResult request


decodeTweets : Json.Decoder (List TweetModel)
decodeTweets =
    Json.oneOf
        [ Json.list decodeTweetDetails
        , Json.succeed []
        ]


decodeTweetDetails : Json.Decoder TweetModel
decodeTweetDetails =
    Json.object7 TweetModel
        ("id_str" := Json.string)
        ("text" := Json.string)
        ("user" := decodeUserDetails)
        (Json.maybe ("in_reply_to_status_id" := Json.float))
        (Json.maybe ("in_reply_to_user_id" := Json.float))
        (Json.maybe ("in_reply_to_screen_name" := Json.string))
        (Json.maybe (Json.at [ "retweeted_status", "user", "screen_name" ] Json.string))
