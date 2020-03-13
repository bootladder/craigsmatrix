module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Http
import Json.Decode exposing (..)
import Json.Encode 

import String


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
    { debugBreadcrumb : String
    , currentUrl : String
    , tableModel : TableModel
    , craigslistPageHtmlString : String
    , editingFieldInputValue : String
    , editingFieldIndex : Int
    , editingFieldType : FieldType
    }

type FieldType = TopField | SideField

fieldTypeToString : FieldType -> String
fieldTypeToString ft = case ft of
    TopField -> "top"
    SideField -> "side"


type alias CellViewModel =
    {
      url : String
    , hits : Int
    }

type alias TableModel =
    { name : String
    , id : Int
    , topHeadings : List (String)
    , sideHeadings : List (String)
    , rows : List (List (CellViewModel))
    }



initialTableModel : TableModel
initialTableModel = 
        TableModel "dummy uninitted" 1 [] [] [[]] 

-- INIT

initialUrl = "https://portland.craigslist.org/search/jjj?query=firmware"

init : () -> ( Model, Cmd Msg )
init _ =
    -- The initial model comes from a Request, now it is hard coded
    ( Model
        "dummy debug"
        initialUrl
        initialTableModel
        "hello???"
        "field input"
        0
        TopField
    , (httpRequestTableModel 1)
    )



-- UPDATE


type Msg
    = ReceivedCraigslistPage (Result Http.Error String)
    | ReceivedTableModel  (Result Http.Error TableModel)
    | CellClicked CellViewModel
    | SelectTableClicked Int
    | FieldEditorChanged String
    | FieldEditorSubmit
    | TableTopFieldClicked String Int
    | TableSideFieldClicked String Int


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

                Err (Http.BadBody s) ->
                    ( {model 
                        | craigslistPageHtmlString = s}
                    , Cmd.none
                    )
                Err _ ->
                    ( {model 
                        | craigslistPageHtmlString = "SOME OTHER HTTP ERROR"}
                    , Cmd.none
                    )

        SelectTableClicked tableId -> 
            ( model 
            , httpRequestTableModel tableId
            )

        FieldEditorChanged input ->
            ( {model| editingFieldInputValue = input}, Cmd.none)

        FieldEditorSubmit ->
            ( model, 
                httpSubmitFieldEdit model.editingFieldInputValue 
                                    model.editingFieldType
                                    model.tableModel.id 
                                    model.editingFieldIndex)

        TableTopFieldClicked fieldName fieldIndex ->
            ( {model | editingFieldInputValue = fieldName
                       ,editingFieldType = TopField
                       ,editingFieldIndex = fieldIndex
            }, Cmd.none)

        TableSideFieldClicked fieldName fieldIndex ->
            ( {model | editingFieldInputValue = fieldName
                       ,editingFieldType = SideField
                       ,editingFieldIndex = fieldIndex
            }, Cmd.none)




-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [id "container"] 
    [ div [id "pageHeader"] [ text "page header"]
    , tableNameLabel model.tableModel.name
    , topLabel
    , sideLabel
    , constantsLabel
    , fieldEditor model.editingFieldInputValue
    , div [id "myTable"] [renderTable model.tableModel]
    , div [id "urlView"] [text model.currentUrl]
    , craigslistSearchPage  model.craigslistPageHtmlString
    ]

renderTable : TableModel -> Html Msg
renderTable tableModel =
    let
        pairs = List.map2 Tuple.pair tableModel.sideHeadings tableModel.rows

        renderedRows = List.indexedMap 
                        (\i (heading, cells) -> renderRow i heading cells)
                        pairs
    in
    table [] (
        [renderTableHeadersRow tableModel.topHeadings]
        ++
        renderedRows
        ++
        [tr [id "myRow"] [button [] [text "add"]]]
        ++
        [tr [id "myRow"] [button [] [text "del"]]]
    )

renderTableHeadersRow : List (String) -> Html Msg
renderTableHeadersRow headings  =
    tr [] (
            [ th [] [text  "///"] ]
            ++
            List.indexedMap (\i heading -> th [ onClick (TableTopFieldClicked heading i)] [text heading]) headings
            ++
            [ th [] [button [] [text "add"]]]
            ++
            [ th [] [button [] [text "del"]]]
    )

renderRow : Int -> String -> List (CellViewModel) ->  Html Msg
renderRow index heading cellViewModels =
        tr [id "myRow"] ( 
                th [onClick (TableSideFieldClicked heading index)] [text heading]
                ::
                  List.map renderCellViewModel cellViewModels
            )

renderCellViewModel : CellViewModel -> Html Msg
renderCellViewModel cellViewModel =
    td [class "blueCell", onClick (CellClicked cellViewModel)] [text <| String.fromInt cellViewModel.hits]


tableNameLabel : String -> Html Msg
tableNameLabel name =
        div [id "tableNameLabel"]
            [ text "table name label"
            , div [] [text name]
            , button [ onClick <| SelectTableClicked 1 ] [ text "Table 1"]
            , button [ onClick <| SelectTableClicked 2 ] [ text "Table 2"]
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


topLabel : Html Msg
topLabel = 
        div [id "topLabel"] 
        [ text "top label" 
        , div [] [text "cities"]
        ]

fieldEditor : String -> Html Msg
fieldEditor editorValue =
        div [id "fieldEditor"] 
        [ text "Field Editor" 
        , input [ onInput FieldEditorChanged, Html.Attributes.value editorValue ] []
        , button [ onClick FieldEditorSubmit ] [text "Submit"]
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

httpRequestTableModel : Int -> Cmd Msg
httpRequestTableModel id =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int id )
                    ]
        , url = "http://localhost:8080/api/table"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


httpSubmitFieldEdit : String -> FieldType -> Int -> Int -> Cmd Msg
httpSubmitFieldEdit fieldValue fieldType tableId fieldIndex =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    , ( "fieldType", Json.Encode.string <| fieldTypeToString fieldType )
                    , ( "fieldIndex", Json.Encode.int fieldIndex)
                    , ( "fieldValue", Json.Encode.string fieldValue)
                    ]
        , url = "http://localhost:8080/api/fieldedit"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


-- DECODER

craigslistPageDecoder : Decoder String
craigslistPageDecoder =
    field "response" Json.Decode.string

tableModelDecoder : Decoder TableModel
tableModelDecoder = 
    Json.Decode.map5 TableModel
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "id" (Json.Decode.int))
        (Json.Decode.field "topHeadings" (Json.Decode.list string))
        (Json.Decode.field "sideHeadings" (Json.Decode.list string))
        rowsDecoder 
  

rowsDecoder : Decoder (List (List (CellViewModel)))
rowsDecoder =
  Json.Decode.field "rows" (Json.Decode.list ((Json.Decode.list cellViewModelDecoder)))

cellViewModelDecoder : Decoder CellViewModel
cellViewModelDecoder =
    Json.Decode.map2 CellViewModel
        (Json.Decode.field "url" Json.Decode.string)
        (Json.Decode.field "hits" Json.Decode.int)