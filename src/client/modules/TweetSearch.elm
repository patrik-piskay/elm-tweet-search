module TweetSearch exposing (..)

import Models exposing (..)
import Ports exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing ((:=))
import Http
import Task


-- MODEL


type alias Model =
    { user : UserModel
    , tweetSearchInput : String
    , tweets : RemoteData (List TweetModel)
    , filteredTweets : Maybe (List TweetModel)
    }


type RemoteData a
    = NotAsked
    | Loading
    | Failure Http.Error
    | Success a


model : Model
model =
    { user = UserModel 1 "Patrik Piskay" "ppiskay" "http://pbs.twimg.com/profile_images/662217947281268736/AA5_5qq1_normal.png"
    , tweetSearchInput = ""
    , tweets = Loading
    , filteredTweets = Nothing
    }


init : ( Model, Cmd Action )
init =
    ( model
    , getTweets model.user
    )



-- UPDATE


type Action
    = NoOp
    | UpdateTweetSearchValue String
    | TweetSearch
    | TweetSearchResult (List TweetModel)
    | HttpError Http.Error
    | FilteredTweets (List TweetModel)


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        NoOp ->
            ( model, Cmd.none )

        UpdateTweetSearchValue value ->
            let
                newModel =
                    { model | tweetSearchInput = value }
            in
                ( newModel, Cmd.none )

        TweetSearch ->
            case model.tweets of
                Success tweets ->
                    ( model, filterTweets tweets )

                _ ->
                    ( model, Cmd.none )

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
                _ =
                    Debug.log "filtered" tweets
            in
                ( model, Cmd.none )



-- VIEW


view : Model -> Html Action
view model =
    div []
        [ input
            [ type' "text"
            , placeholder "Tweet search"
            , value model.tweetSearchInput
            , class "user-search-input"
            , onInput UpdateTweetSearchValue
            , on "keypress" (Json.map (always TweetSearch) (Json.customDecoder keyCode isEnter))
            ]
            []
        , ul
            [ class "tweet-results" ]
            (case model.tweets of
                NotAsked ->
                    []

                Loading ->
                    [ div [ class "loading" ] [ text "Loading..." ] ]

                Failure err ->
                    [ div [ class "error" ] [ text "Could not load data" ] ]

                Success tweets ->
                    if not (List.isEmpty tweets) then
                        List.map
                            (\tweet -> li [] [ renderTweet tweet ])
                            tweets
                    else
                        [ div [ class "no-tweets-found" ] [ text "No tweets found" ] ]
            )
        ]


renderTweet : TweetModel -> Html Action
renderTweet tweet =
    let
        userName =
            case tweet.retweetedUserName of
                Nothing ->
                    tweet.user.screenName

                Just name ->
                    name

        url =
            "https://twitter.com/" ++ userName ++ "/status/" ++ tweet.id
    in
        a
            [ href url
            , target "blank"
            , class "tweet"
            ]
            [ span [] [ text tweet.text ]
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
            Http.get decodeTweets ("http://localhost:3000/api/statuses/user_timeline.json?screen_name=" ++ user.screenName ++ "&count=200")
    in
        Task.perform HttpError TweetSearchResult request


decodeTweets : Json.Decoder (List TweetModel)
decodeTweets =
    Json.oneOf
        [ Json.list tweetDetails
        , Json.succeed []
        ]


tweetDetails : Json.Decoder TweetModel
tweetDetails =
    Json.object7 TweetModel
        ("id_str" := Json.string)
        ("text" := Json.string)
        ("user" := tweetUserDetails)
        (Json.maybe ("in_reply_to_status_id" := Json.float))
        (Json.maybe ("in_reply_to_user_id" := Json.float))
        (Json.maybe ("in_reply_to_screen_name" := Json.string))
        (Json.maybe (Json.at [ "retweeted_status", "user", "screen_name" ] Json.string))


tweetUserDetails : Json.Decoder UserModel
tweetUserDetails =
    Json.object4 UserModel
        ("id" := Json.float)
        ("name" := Json.string)
        ("screen_name" := Json.string)
        ("profile_image_url" := Json.string)


isEnter : Int -> Result String ()
isEnter code =
    if code == 13 then
        Ok ()
    else
        Err "Not enter pressed"
