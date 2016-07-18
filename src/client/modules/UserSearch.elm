module UserSearch exposing (..)

import Models exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing ((:=))
import Http
import Task


-- MODEL


type alias Model =
    { user : RemoteData UserModel
    , userSearchInput : String
    }


model : Model
model =
    { user = NotAsked
    , userSearchInput = ""
    }


init : ( Model, Cmd Action )
init =
    ( model
    , Cmd.none
    )



-- UPDATE


type Action
    = Reset
    | UpdateUserSearch String
    | SearchUser
    | UserSearchResult (List UserModel)
    | NoUserFound Http.Error


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        Reset ->
            init

        UpdateUserSearch value ->
            let
                newModel =
                    { model | userSearchInput = value }
            in
                ( newModel, Cmd.none )

        SearchUser ->
            let
                newModel =
                    { model | user = Loading }
            in
                ( newModel, getUser model.userSearchInput )

        UserSearchResult result ->
            case result of
                [] ->
                    ( model, Cmd.none )

                user :: _ ->
                    let
                        newModel =
                            { model | user = Success user }
                    in
                        ( newModel, Cmd.none )

        NoUserFound err ->
            let
                newModel =
                    { model | user = Failure err }
            in
                ( newModel, Cmd.none )



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
            (case model.user of
                NotAsked ->
                    []

                Loading ->
                    [ div [ class "loading" ] [ text "Loading..." ] ]

                Failure _ ->
                    [ div [ class "no-user-found" ] [ text "No user found" ] ]

                Success user ->
                    [ li [] [ renderUserRecord user ] ]
            )
        ]


renderUserRecord : UserModel -> Html Action
renderUserRecord user =
    div []
        [ img [ src user.profileImg ] []
        , span [] [ text user.name ]
        ]



-- TASKS


getUser : String -> Cmd Action
getUser username =
    let
        request =
            Http.get getUserDetails ("http://localhost:3000/api/users/lookup.json?screen_name=" ++ username)
    in
        Task.perform NoUserFound UserSearchResult request


getUserDetails : Json.Decoder (List UserModel)
getUserDetails =
    decodeUserDetails |> Json.list


decodeUserDetails : Json.Decoder UserModel
decodeUserDetails =
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
