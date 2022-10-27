module Screen.Loading exposing
    ( Model
    , Msg
    , Update
    , init
    , subscriptions
    , update
    , view
    )

import Browser.Events
import Data.Dir
import Data.File
import Html
import Html.Attributes
import Http
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , state : State
    }


type State
    = Loading Int
    | LoadedDirs Data.Dir.Data Int
    | LoadedFiles Data.File.Data Int
    | Loaded ( Data.Dir.Data, Data.File.Data ) Int


init : Session.Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , state = Loading 0
      }
    , Cmd.batch
        [ Data.Dir.getRootShopDirs
            { token = session.token
            , tracker = Nothing
            , tagger = GotDirs
            }
        , Data.File.getRootShopFiles
            { token = session.token
            , tracker = Nothing
            , tagger = GotFiles
            }
        ]
    )



-- UPDATE


type alias Update =
    { model : Model
    , cmd : Cmd Msg
    , nextScreen : Session.NextScreen
    }


type Msg
    = GotDirs (Result Http.Error Data.Dir.Data)
    | GotFiles (Result Http.Error Data.File.Data)
    | Tick Int


update : Msg -> Model -> Update
update msg model =
    case msg of
        GotDirs result ->
            case result of
                Ok dirs ->
                    case model.state of
                        Loading time ->
                            updateModel
                                { model | state = LoadedDirs dirs time }

                        LoadedFiles files time ->
                            updateModel
                                { model | state = Loaded ( dirs, files ) time }

                        _ ->
                            updateModel model

                Err err ->
                    { model = model
                    , cmd = Cmd.none
                    , nextScreen = Session.ErrorScreen err
                    }

        GotFiles result ->
            case result of
                Ok files ->
                    case model.state of
                        Loading time ->
                            updateModel
                                { model | state = LoadedFiles files time }

                        LoadedDirs dirs time ->
                            updateModel
                                { model | state = Loaded ( dirs, files ) time }

                        _ ->
                            updateModel model

                Err err ->
                    { model = model
                    , cmd = Cmd.none
                    , nextScreen = Session.ErrorScreen err
                    }

        Tick delta ->
            case model.state of
                Loading time ->
                    updateModel { model | state = Loading <| time + delta }

                LoadedDirs data time ->
                    updateModel
                        { model | state = LoadedDirs data <| time + delta }

                LoadedFiles data time ->
                    updateModel
                        { model | state = LoadedFiles data <| time + delta }

                Loaded data time ->
                    if time > animateInDuration + animateOutDuration then
                        { model = model
                        , cmd = Cmd.none
                        , nextScreen = Session.AppScreen data
                        }

                    else
                        updateModel
                            { model | state = Loaded data <| time + delta }


updateModel : Model -> Update
updateModel model =
    { model = model
    , cmd = Cmd.none
    , nextScreen = Session.CurrentScreen
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onAnimationFrameDelta (Tick << Basics.round)



-- VIEW


view : Model -> Html.Html Msg
view model =
    let
        animateIn time =
            if time > animateInDuration then
                "pulsate"

            else
                "slide-in"

        class =
            case model.state of
                Loading time ->
                    animateIn time

                LoadedDirs _ time ->
                    animateIn time

                LoadedFiles _ time ->
                    animateIn time

                Loaded _ time ->
                    if time > animateInDuration then
                        "slide-out"

                    else
                        "slide-in"
    in
    Html.section
        [ Html.Attributes.id "loading" ]
        [ Html.div [ Html.Attributes.class class ]
            [ Html.h1 [] [ Html.text "File Finder" ] ]
        ]



-- HELPERS


animateInDuration : Int
animateInDuration =
    1000


animateOutDuration : Int
animateOutDuration =
    500
