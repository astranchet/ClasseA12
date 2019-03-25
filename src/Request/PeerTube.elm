module Request.PeerTube exposing (getAccount, getUserInfo, getVideo, getVideoList, login)

import Data.PeerTube
    exposing
        ( Account
        , UserInfo
        , UserToken
        , Video
        , accountDecoder
        , dataDecoder
        , userInfoDecoder
        , userTokenDecoder
        , videoDecoder
        )
import Http
import Json.Encode as Encode
import Url


type alias Request a =
    { method : String
    , headers : List Http.Header
    , url : String
    , body : Http.Body
    , expect : Http.Expect a
    , timeout : Maybe Float
    , withCredentials : Bool
    }


videoListRequest : Http.Request (List Video)
videoListRequest =
    Http.get "https://peertube.scopyleft.fr/api/v1/video-channels/vincent_channel/videos" dataDecoder


getVideoList : (Result Http.Error (List Video) -> msg) -> Cmd msg
getVideoList message =
    Http.send message videoListRequest


videoRequest : String -> Http.Request Video
videoRequest videoID =
    Http.get ("https://peertube.scopyleft.fr/api/v1/videos/" ++ videoID) videoDecoder


getVideo : String -> (Result Http.Error Video -> msg) -> Cmd msg
getVideo videoID message =
    Http.send message (videoRequest videoID)


accountRequest : String -> Http.Request Account
accountRequest accountName =
    Http.get ("https://peertube.scopyleft.fr/api/v1/accounts/" ++ accountName) accountDecoder


getAccount : String -> (Result Http.Error Account -> msg) -> Cmd msg
getAccount accountName message =
    Http.send message (accountRequest accountName)


loginRequest : String -> String -> String -> Http.Request UserToken
loginRequest username password serverURL =
    let
        url =
            serverURL ++ "/users/token"

        data =
            [ ( "username", username |> Url.percentEncode )
            , ( "password", password |> Url.percentEncode )
            , ( "client_id", "d2g8qdmcmc4gxiloss44murer3egmteo" )
            , ( "client_secret", "1IZJ6knBPJb7NJXhcH6jBDS15m6EXi4u" )
            , ( "grant_type", "password" )
            , ( "response_type", "code" )
            , ( "scope", "upload" )
            ]

        body =
            data
                |> List.map (\( key, val ) -> key ++ "=" ++ val)
                |> String.join "&"
                |> Http.stringBody "application/x-www-form-urlencoded"
    in
    Http.post url body userTokenDecoder


login : String -> String -> String -> (Result Http.Error UserToken -> msg) -> Cmd msg
login username password serverURL message =
    Http.send message (loginRequest username password serverURL)


getUserInfoRequest : String -> String -> Http.Request UserInfo
getUserInfoRequest accessToken serverURL =
    let
        url =
            serverURL ++ "/users/me"

        request : Request UserInfo
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson userInfoDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in
    request
        |> withHeader "Authorization" ("Bearer " ++ accessToken)
        |> Http.request


getUserInfo : String -> String -> (Result Http.Error UserInfo -> msg) -> Cmd msg
getUserInfo accessToken serverURL message =
    Http.send message (getUserInfoRequest accessToken serverURL)


withHeader : String -> String -> Request a -> Request a
withHeader headerName headerValue request =
    let
        header =
            Http.header headerName headerValue
    in
    { request | headers = header :: request.headers }