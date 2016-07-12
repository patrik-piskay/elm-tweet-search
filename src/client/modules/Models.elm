module Models exposing (..)


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
