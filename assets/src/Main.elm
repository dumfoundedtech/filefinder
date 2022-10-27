module Main exposing (main)

import Browser
import Html
import Html.Attributes
import Json.Decode
import Screen.App
import Screen.Error
import Screen.Loading
import Session



-- MAIN


main : Program Json.Decode.Value Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Loading Screen.Loading.Model
    | App Screen.App.Model
    | Error Screen.Error.Model


init : Json.Decode.Value -> ( Model, Cmd Msg )
init flags =
    case Json.Decode.decodeValue Session.decoder flags of
        Ok session ->
            Tuple.mapBoth Loading (Cmd.map LoadingMsg) <|
                Screen.Loading.init session

        Err err ->
            Tuple.mapBoth Error (Cmd.map Basics.never) <|
                Screen.Error.fromDecoding err



-- UPDATE


type Msg
    = LoadingMsg Screen.Loading.Msg
    | AppMsg Screen.App.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadingMsg msg_ ->
            case model of
                Loading model_ ->
                    let
                        update_ =
                            Screen.Loading.update msg_ model_
                    in
                    case update_.nextScreen of
                        Session.CurrentScreen ->
                            ( Loading update_.model
                            , Cmd.map LoadingMsg update_.cmd
                            )

                        Session.AppScreen data ->
                            Tuple.mapBoth App (Cmd.map AppMsg) <|
                                Screen.App.init data update_.model.session

                        Session.ErrorScreen err ->
                            Tuple.mapBoth Error (Cmd.map never) <|
                                Screen.Error.fromLoading err

                _ ->
                    ( model, Cmd.none )

        AppMsg msg_ ->
            case model of
                App model_ ->
                    Tuple.mapBoth App (Cmd.map AppMsg) <|
                        Screen.App.update msg_ model_

                _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Loading model_ ->
            Sub.map LoadingMsg <| Screen.Loading.subscriptions model_

        _ ->
            Sub.none


view : Model -> Browser.Document Msg
view model =
    { title = "File Finder"
    , body =
        [ Html.div [ Html.Attributes.class "screen-wrap" ]
            [ viewBody model ]
        ]
    }


viewBody : Model -> Html.Html Msg
viewBody model =
    case model of
        Loading model_ ->
            Html.map LoadingMsg <| Screen.Loading.view model_

        App model_ ->
            Html.map AppMsg <| Screen.App.view model_

        Error model_ ->
            Screen.Error.view model_
