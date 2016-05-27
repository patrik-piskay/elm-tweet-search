module UserSearch exposing (..)

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

init : (Model, Cmd Action)
init =
    ( model
    , Cmd.none
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
    | UserSearchResult (List UserModel)
    | NoUserFound Http.Error

update : Action -> Model -> (Model, Cmd Action)
update action model =
    case action of
        NoOp -> (model, Cmd.none)
        UpdateUserSearch value ->
            let
                newModel = { model | userSearchInput = value }
            in
                (newModel, Cmd.none)
        SearchUser ->
            (model, getUser model.userSearchInput)
        UserSearchResult result ->
            let
                newModel = { model | users = Just result, noUserFound = False }
            in (newModel, Cmd.none)
        NoUserFound _ ->
            let
                newModel = { model | users = Nothing, noUserFound = True }
            in (newModel, Cmd.none)

-- VIEW

view : Model -> Html Action
view model =
    div []
        [ input
            [ type' "text"
            , placeholder "Twitter username"
            , value model.userSearchInput
            , class "user-search-input"
            , onInput UpdateUserSearch
            , on "keypress" (Json.map (always SearchUser) (Json.customDecoder keyCode isEnter))
            ]
            []
        , ul
            [ class "user-results" ]
            ( case model.users of
                Nothing ->
                    if model.noUserFound
                        then [ div [ class "no-user-found" ] [ text "No user found" ]]
                        else []
                Just users ->
                    List.map
                        (\user -> li [] [ renderUserRecord user ])
                        (Maybe.withDefault [] model.users)
            )
        ]

renderUserRecord : UserModel -> Html Action
renderUserRecord user =
    div []
        [ img [src user.profile_img] []
        , span [] [ text user.name ]
        ]

-- EFFECTS

getUser : String -> Cmd Action
getUser username =
    let
        request = Http.get getUserDetails ("http://localhost:3000/api/users/lookup.json?screen_name=" ++ username)
    in
        Task.perform NoUserFound UserSearchResult request

getUserDetails : Json.Decoder (List UserModel)
getUserDetails =
    Json.object2 UserModel
        ("name" := Json.string)
        ("profile_image_url" := Json.string)
    |> Json.list

isEnter : Int -> Result String ()
isEnter code =
    if code == 13 then Ok () else Err "Not enter pressed"