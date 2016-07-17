module UserSearch exposing (..)

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


type RemoteData a
    = NotAsked
    | Loading
    | Failure
    | Success a


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


type alias UserModel =
    { name : String
    , screen_name : String
    , profile_img : String
    }



-- UPDATE


type Action
    = UpdateUserSearch String
    | SearchUser
    | UserSearchResult (List UserModel)
    | NoUserFound Http.Error


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
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

        NoUserFound _ ->
            let
                newModel =
                    { model | user = Failure }
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

                Failure ->
                    [ div [ class "no-user-found" ] [ text "No user found" ] ]

                Success user ->
                    [ li [] [ renderUserRecord user ] ]
            )
        ]


renderUserRecord : UserModel -> Html Action
renderUserRecord user =
    div []
        [ img [ src user.profile_img ] []
        , span [] [ text user.name ]
        ]



-- EFFECTS


getUser : String -> Cmd Action
getUser username =
    let
        request =
            Http.get getUserDetails ("http://localhost:3000/api/users/lookup.json?screen_name=" ++ username)
    in
        Task.perform NoUserFound UserSearchResult request


getUserDetails : Json.Decoder (List UserModel)
getUserDetails =
    Json.object3 UserModel
        ("name" := Json.string)
        ("screen_name" := Json.string)
        ("profile_image_url" := Json.string)
        |> Json.list


isEnter : Int -> Result String ()
isEnter code =
    if code == 13 then
        Ok ()
    else
        Err "Not enter pressed"
