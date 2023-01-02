port module Ports exposing (copyToClipboard, toggleModal)

-- PORTS


port copyToClipboard : String -> Cmd msg


port toggleModal : () -> Cmd msg
