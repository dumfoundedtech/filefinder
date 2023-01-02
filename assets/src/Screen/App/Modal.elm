module Screen.App.Modal exposing (viewError)

import Html
import Html.Attributes
import Http



-- VIEW ERROR


viewError : Http.Error -> Html.Html msg
viewError err =
    let
        message =
            case err of
                Http.BadUrl url ->
                    url ++ " is invalid"

                Http.Timeout ->
                    "Hit network timeout"

                Http.NetworkError ->
                    "Hit network error"

                Http.BadStatus code ->
                    String.fromInt code ++ " status code"

                Http.BadBody message_ ->
                    message_
    in
    Html.div [ Html.Attributes.id "modal-content" ]
        [ Html.div [ Html.Attributes.id "modal-banner" ]
            [ Html.text "Error!" ]
        , Html.div [ Html.Attributes.id "modal-error" ]
            [ Html.pre [] [ Html.text message ] ]
        ]
