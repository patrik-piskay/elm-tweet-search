module TwitterSearch where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing ((:=))
import Http
import Task

-- MODEL

type alias Model =
    { users : Maybe (List UserModel)
    , userSearchInput : String
    , noUserFound : Bool
    }

model : Model
model =
    { users = Nothing
    , userSearchInput = ""
    , noUserFound = False
    }

init : (Model, Effects Action)
init =
    ( model
    , Effects.none
    )

type alias UserModel =
    { name : String
    , profile_img : String
    }

userModel : Maybe UserModel
userModel = Nothing

-- UPDATE

type Action =
    NoOp
    | UpdateUserSearch String
    | SearchUser
    | UserSearchResult (Maybe (List UserModel))

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        NoOp -> (model, Effects.none)
        UpdateUserSearch value ->
            let
                newModel = { model | userSearchInput = value }
            in
                (newModel, Effects.none)
        SearchUser ->
            (model, getUser model.userSearchInput)
        UserSearchResult result ->
            case result of
                Just result ->
                    let
                        newModel = { model | users = Just result, noUserFound = False }
                    in (newModel, Effects.none)
                Nothing ->
                    let
                        newModel = { model | noUserFound = True }
                    in (newModel, Effects.none)

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div []
        [ input
            [ type' "text"
            , placeholder "Twitter username"
            , value model.userSearchInput
            , class "user-search-input"
            , on "input" targetValue (\value -> Signal.message address (UpdateUserSearch value))
            , on "keypress" (Json.customDecoder keyCode isEnter) (\_ -> Signal.message address SearchUser)
            ]
            []
        , ul
            [ class "user-results" ]
            ( case model.users of
                Nothing ->
                    if model.noUserFound
                        then [ text "No user found" ]
                        else []
                Just users ->
                    List.map
                        (\user -> li [] [ renderUserRecord user ])
                        (Maybe.withDefault [] model.users)
            )
        ]

renderUserRecord : UserModel -> Html
renderUserRecord user =
    div []
        [ img [src user.profile_img] []
        , span [] [ text user.name ]
        ]

-- EFFECTS

getUser : String -> Effects Action
getUser username =
    Http.get getUserDetails ("http://localhost:3000/api/users/lookup.json?screen_name=" ++ username)
        |> Task.toMaybe
        |> Task.map UserSearchResult
        |> Effects.task

getUserDetails : Json.Decoder (List UserModel)
getUserDetails =
    Json.object2 UserModel
        ("name" := Json.string)
        ("profile_image_url" := Json.string)
    |> Json.list

isEnter : Int -> Result String ()
isEnter code =
    if code == 13 then Ok () else Err "Not enter pressed"

-- WIRING

userQuery : Signal.Mailbox String
userQuery = Signal.mailbox ""