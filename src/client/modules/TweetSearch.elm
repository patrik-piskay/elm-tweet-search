module TweetSearch exposing (..)

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
    }

type RemoteData a
    = NotAsked
    | Loading
    | Failure Http.Error
    | Success a

model : Model
model =
    { user = UserModel 1 "Patrik Piskay" "Patrik Piskay" "http://pbs.twimg.com/profile_images/662217947281268736/AA5_5qq1_normal.png"
    , tweetSearchInput = ""
    , tweets = NotAsked
    }

init : (Model, Cmd Action)
init =
    ( model
    , Cmd.none
    )

type alias UserModel =
    { id : Float
    , name : String
    , screen_name : String
    , profile_img : String
    }

type alias TweetModel =
    { id : Float
    , text : String
    , user : UserModel
    , replyStatusId : Maybe Float
    , replyUserId : Maybe Float
    , replyUserName : Maybe String
    , retweetedStatus : Maybe RetweetedStatus
    }

type RetweetedStatus = RetweetedStatus TweetModel

-- UPDATE

type Action
    = NoOp
    | UpdateTweetSearchValue String
    | SearchTweets
    | TweetSearchResult (List TweetModel)
    -- | NoTweetsFound
    | HttpError Http.Error

update : Action -> Model -> (Model, Cmd Action)
update action model =
    case action of
        NoOp -> (model, Cmd.none)
        UpdateTweetSearchValue value ->
            let
                newModel = { model | tweetSearchInput = value }
            in
                (newModel, Cmd.none)
        SearchTweets ->
            let
                newModel = { model | tweets = Loading }
            in
                (newModel, getTweets model.tweetSearchInput)
        TweetSearchResult result ->
            let
                newModel = { model | tweets = Success result }
            in
                (newModel, Cmd.none)
        HttpError err ->
            let
                _ = Debug.log "err" err
                newModel = { model | tweets = Failure err }
            in
                (newModel, Cmd.none)

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
            , on "keypress" (Json.map (always SearchTweets) (Json.customDecoder keyCode isEnter))
            ]
            []
        , ul
            [ class "tweet-results" ]
            ( case model.tweets of
                NotAsked ->
                    []
                Loading ->
                    [ div [] [ text "Loading..." ] ]
                Failure err ->
                    [ div [ class "error" ] [ text "Could not load data" ]]
                Success tweets ->
                    if not (List.isEmpty tweets)
                        then List.map
                            (\tweet -> li [] [ renderTweet tweet ])
                            tweets
                        else
                            [ div [ class "no-tweets-found" ] [ text "No tweets found" ]]
            )
        ]

renderTweet : TweetModel -> Html Action
renderTweet tweet =
    div []
        [ span [] [ text tweet.text ]
        ]

-- TASKS

getTweets : String -> Cmd Action
getTweets searchValue =
    let
        request = Http.get decodeTweets ("http://localhost:3000/api/statuses/user_timeline.json?screen_name=" ++ searchValue)
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
        ("id" := Json.float)
        ("text" := Json.string)
        ("user" := tweetUserDetails)
        (Json.maybe ("in_reply_to_status_id" := Json.float))
        (Json.maybe ("in_reply_to_user_id" := Json.float))
        (Json.maybe ("in_reply_to_screen_name" := Json.string))
        (Json.maybe ("retweeted_status" := lazy (\_ -> tweetDetails) |> Json.map RetweetedStatus))

lazy : (() -> Json.Decoder a) -> Json.Decoder a
lazy thunk =
    Json.customDecoder Json.value
        (\value -> Json.decodeValue (thunk ()) value)

tweetUserDetails : Json.Decoder UserModel
tweetUserDetails =
    Json.object4 UserModel
        ("id" := Json.float)
        ("name" := Json.string)
        ("screen_name" := Json.string)
        ("profile_image_url" := Json.string)

isEnter : Int -> Result String ()
isEnter code =
    if code == 13 then Ok () else Err "Not enter pressed"