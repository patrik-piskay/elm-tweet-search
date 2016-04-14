module App where

import StartApp
import Html
import Task
import Effects exposing (Never)
import TwitterSearch exposing (init, update, view)

app : StartApp.App TwitterSearch.Model
app =
    StartApp.start
        { init = init
        , update = update
        , view = view
        , inputs = []
        }

main : Signal Html.Html
main =
    app.html

port tasks : Signal (Task.Task Never ())
port tasks =
    app.tasks