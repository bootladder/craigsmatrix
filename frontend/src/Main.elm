module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Http
import Json.Decode exposing (..)
import Json.Encode 


-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { urlSetId : Int
    , debugBreadcrumb : String
    , currentUrl : String
    , tableModel : TableModel
    , craigslistPageHtmlString : String
    }


type alias CellViewModel =
    { color : String
    , label : String
    , url : String
    , hits : Int
    }

type alias TableModel =
    { name : String
    , topHeadings : List (String)
    , sideHeadings : List (String)
    , rows : List (List (CellViewModel))
    }



initialTableModel : TableModel
initialTableModel = 
        TableModel "dummy uninitted" [] [] [[]] 

-- INIT

initialUrl = "https://portland.craigslist.org/search/jjj?query=firmware"

init : () -> ( Model, Cmd Msg )
init _ =
    -- The initial model comes from a Request, now it is hard coded
    ( Model
        0
        "dummy debug"
        initialUrl
        initialTableModel
        "hello???"
    , (httpRequestTableModel)
    )



-- UPDATE


type Msg
    = ReceivedCraigslistPage (Result Http.Error String)
    | ReceivedTableModel  (Result Http.Error TableModel)
    | CellClicked CellViewModel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CellClicked cellViewModel -> 
            ( {model 
                | currentUrl = cellViewModel.url
                }
            , httpRequestCraigslistSearchPage cellViewModel.url
            )

        ReceivedCraigslistPage result ->
            case result of
                Ok fullText ->
                    ( {model 
                        | craigslistPageHtmlString = fullText}
                    , Cmd.none
                    )

                Err e ->
                    ( {model 
                        | craigslistPageHtmlString = "FAIL"}
                    , Cmd.none
                    )

        ReceivedTableModel result ->
            case result of
                Ok resultTableModel ->
                    ( {model 
                        | tableModel = resultTableModel}
                    , Cmd.none
                    )

                Err e ->
                    ( {model 
                        | craigslistPageHtmlString = "FAIL"}
                    , Cmd.none
                    )




-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [id "container"] 
    [ div [id "nothing"] [ text "nothing"]
    , tableNameLabel model.tableModel.name
    , topLabel
    , sideLabel
    , constantsLabel
    , div [id "myTable"] [renderTable model.tableModel]
    , div [id "urlView"] [text model.currentUrl]
    , craigslistSearchPage  model.craigslistPageHtmlString
    ]

renderTable : TableModel -> Html Msg
renderTable tableModel =
    let
        pairs = List.map2 Tuple.pair tableModel.sideHeadings tableModel.rows

        renderedRows = List.map 
                        (\(heading, cells) -> renderRow heading cells)
                        pairs
    in
    table [] (
        [renderTableHeadersRow tableModel.topHeadings]
        ++
        renderedRows
    )

renderTableHeadersRow : List (String) -> Html Msg
renderTableHeadersRow headings  =
    tr [] (
            [ th [] [text  "///"] ]
            ++
            List.map (\s -> th [] [text s]) headings
    )

renderRow : String -> List (CellViewModel) ->  Html Msg
renderRow heading cellViewModels =
        tr [id "myRow"] ( 
                th [] [text heading]
                ::
                  List.map renderCellViewModel cellViewModels
            )

renderCellViewModel : CellViewModel -> Html Msg
renderCellViewModel cellViewModel =
    td [class cellViewModel.color, onClick (CellClicked cellViewModel)] [text cellViewModel.label]


tableNameLabel : String -> Html msg
tableNameLabel name =
        div [id "tableNameLabel"]
            [ text "table name label"
            , div [] [text name]
            ]

constantsLabel : Html msg
constantsLabel = 
        div [id "constantsLabel"] 
            [ text "constants label" 
            , div [] [text "jobs"]
            ]

sideLabel : Html msg
sideLabel = 
        div [id "sideLabel"] 
        [ text "side label" 
        , div [] [text "search query"]
        ]


topLabel : Html msg
topLabel = 
        div [id "topLabel"] 
        [ text "top label" 
        , div [] [text "cities"]
        ]

craigslistSearchPage : String -> Html msg
craigslistSearchPage html =
    Html.node "rendered-html"
        [ Html.Attributes.property "content" (Json.Encode.string html) ]
        []

-- HTTP

httpRequestCraigslistSearchPage : String -> Cmd Msg
httpRequestCraigslistSearchPage url =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "searchURL", Json.Encode.string url )
                    ]
        , url = "http://localhost:8080/api/"
        , expect = Http.expectJson (\jsonResult -> ReceivedCraigslistPage jsonResult) craigslistPageDecoder
        }

httpRequestTableModel : Cmd Msg
httpRequestTableModel =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int 0 )
                    ]
        , url = "http://localhost:8080/api/table"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


-- DECODER

craigslistPageDecoder : Decoder String
craigslistPageDecoder =
    field "response" Json.Decode.string

tableModelDecoder : Decoder TableModel
tableModelDecoder = 
    Json.Decode.map4 TableModel
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "topHeadings" (Json.Decode.list string))
        (Json.Decode.field "sideHeadings" (Json.Decode.list string))
        rowsDecoder 
  

rowsDecoder : Decoder (List (List (CellViewModel)))
rowsDecoder =
  Json.Decode.field "rows" (Json.Decode.list ((Json.Decode.list cellViewModelDecoder)))

cellViewModelDecoder : Decoder CellViewModel
cellViewModelDecoder =
    Json.Decode.map4 CellViewModel
        (Json.Decode.field "color" Json.Decode.string)
        (Json.Decode.field "label" Json.Decode.string)
        (Json.Decode.field "url" Json.Decode.string)
        (Json.Decode.field "hits" Json.Decode.int)