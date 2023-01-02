module Screen.Error exposing (Model, fromDecoding, fromLoading, view)

import Html
import Html.Attributes
import Http
import Json.Decode



-- MODEL


type Model
    = Decoding Json.Decode.Error
    | Loading Http.Error


fromDecoding : Json.Decode.Error -> ( Model, Cmd msg )
fromDecoding err =
    ( Decoding err, Cmd.none )


fromLoading : Http.Error -> ( Model, Cmd msg )
fromLoading err =
    ( Loading err, Cmd.none )



-- VIEW


view : Model -> Html.Html msg
view _ =
    Html.section
        [ Html.Attributes.id "error" ]
        [ Html.div []
            [ Html.h1 [] [ Html.text "Bummer" ]
            , Html.p []
                [ Html.text """Something strange happened... refresh or reach
                out to us!""" ]
            ]
        ]
