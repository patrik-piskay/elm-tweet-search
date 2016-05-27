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
    , tweetsResult : Maybe (List TweetModel)
    , noTweetFound : Bool
    }

model : Model
model =
    { user = UserModel 1 "Patrik Piskay" "Patrik Piskay" "http://pbs.twimg.com/profile_images/662217947281268736/AA5_5qq1_normal.png"
    , tweetSearchInput = ""
    , tweetsResult = Nothing
    , noTweetFound = False
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

type Action =
    NoOp
    | UpdateTweetSearchValue String
    | SearchTweets
    | TweetSearchResult (List TweetModel)
    | NoTweetsFound Http.Error

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
            (model, getTweets model.tweetSearchInput)
        TweetSearchResult result ->
            let
                h = Debug.log "success" result
                newModel = { model | tweetsResult = Just result, noTweetFound = False }
            in (newModel, Cmd.none)
        NoTweetsFound er ->
            let
                h = Debug.log "err" er
                newModel = { model | tweetsResult = Nothing, noTweetFound = True }
            in (newModel, Cmd.none)

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
            [ class "user-results" ]
            ( case model.tweetsResult of
                Nothing ->
                    if model.noTweetFound
                        then [ div [ class "no-user-found" ] [ text "No tweets found" ]]
                        else []
                Just tweets ->
                    let t = Debug.log "tweets" tweets in
                    List.map
                        (\tweet -> li [] [ renderTweet tweet ])
                        (Maybe.withDefault [] model.tweetsResult)
            )
        ]

renderTweet : TweetModel -> Html Action
renderTweet tweet =
    div []
        [ span [] [ text tweet.text ]
        ]

-- EFFECTS

getTweets : String -> Cmd Action
getTweets searchValue =
    let
        request = Http.get decodeTweets ("http://localhost:3000/api/statuses/user_timeline.json?screen_name=" ++ searchValue)
    in
        Task.perform NoTweetsFound TweetSearchResult request

decodeTweets : Json.Decoder (List TweetModel)
decodeTweets =
    tweetDetails |> Json.list

retweetStatusDecoder : Json.Decoder TweetModel
retweetStatusDecoder =
    Json.object7 TweetModel
        ("id" := Json.float)
        ("text" := Json.string)
        ("user" := tweetUserDetails)
        (Json.maybe ("in_reply_to_status_id" := Json.float))
        (Json.maybe ("in_reply_to_user_id" := Json.float))
        (Json.maybe ("in_reply_to_screen_name" := Json.string))
        (Json.succeed Nothing)

tweetDetails : Json.Decoder TweetModel
tweetDetails =
    Json.object7 TweetModel
        ("id" := Json.float)
        ("text" := Json.string)
        ("user" := tweetUserDetails)
        (Json.maybe ("in_reply_to_status_id" := Json.float))
        (Json.maybe ("in_reply_to_user_id" := Json.float))
        (Json.maybe ("in_reply_to_screen_name" := Json.string))
        (Json.maybe ("retweeted_status" := retweetStatusDecoder |> Json.map RetweetedStatus))

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