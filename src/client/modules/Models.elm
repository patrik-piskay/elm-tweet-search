module Models exposing (..)

import Http


type RemoteData a
    = NotAsked
    | Loading
    | Failure Http.Error
    | Success a


type alias UserModel =
    { id : Float
    , name : String
    , screenName : String
    , profileImg : String
    }


type alias TweetModel =
    { id : String
    , text : String
    , user : UserModel
    , replyStatusId : Maybe Float
    , replyUserId : Maybe Float
    , replyUserName : Maybe String
    , retweetedUserName : Maybe String
    }
