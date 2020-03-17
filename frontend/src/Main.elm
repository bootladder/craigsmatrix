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
    , allTableNames : List(String)
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
      pageUrl : String
    , feedUrl : String
    , hits : Int
    }

type alias TableModel =
    { name : String
    , id : Int
    , topHeadings : List (String)
    , sideHeadings : List (String)
    , rows : List (List (CellViewModel))
    }



-- INIT


initialTableModel : TableModel
initialTableModel = 
        TableModel "dummy uninitted" 1 [] [] [[]] 

initialUrl = "https://nothingrequestedyet"

init : () -> ( Model, Cmd Msg )
init _ =
    -- The initial model comes from a Request, now it is hard coded
    ( Model
        "dummy debug"
        initialUrl
        initialTableModel
        []
        "no craigslist page requested yet"
        ""
        0
        TopField
    , Cmd.batch [(httpRequestTableModel 1), httpRequestAllTableNames]
    )



-- UPDATE


type Msg
    = ReceivedCraigslistPage (Result Http.Error String)
    | ReceivedTableModel  (Result Http.Error TableModel)
    | ReceivedAllTableNames  (Result Http.Error (List (String)))
    | CellClicked CellViewModel
    | SelectTableClicked Int
    | AddTableClicked
    | DeleteTableClicked
    | FieldEditorChanged String
    | FieldEditorSubmit
    | TableTopFieldClicked String Int
    | TableSideFieldClicked String Int
    | TableTopFieldAddClicked
    | TableTopFieldDeleteClicked
    | TableSideFieldAddClicked
    | TableSideFieldDeleteClicked
    | UpdateTableData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CellClicked cellViewModel -> 
            ( {model 
                | currentUrl = cellViewModel.pageUrl
                }
            , httpRequestCraigslistSearchPage cellViewModel.pageUrl
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

        ReceivedAllTableNames  result ->
            case result of
                Ok names ->
                    ( {model | allTableNames = names}, Cmd.none)

                Err _ -> ({model
                        | craigslistPageHtmlString = "SOME OTHER HTTP ERROR"}
                        , Cmd.none)

        SelectTableClicked tableId -> 
            ( model 
            , httpRequestTableModel tableId
            )

        AddTableClicked -> (model, httpAddTable)
        DeleteTableClicked -> (model, Cmd.none)

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


        TableTopFieldAddClicked  ->
            (model,
            httpAddTopField model.tableModel.id)

        TableTopFieldDeleteClicked  ->
            (model,
            httpDeleteTopField model.tableModel.id)

        TableSideFieldAddClicked  ->
            (model,
            httpAddSideField model.tableModel.id)

        TableSideFieldDeleteClicked  ->
            (model,
            httpDeleteSideField model.tableModel.id)


        UpdateTableData ->
            ( model, httpUpdateTableData model.tableModel.id)




-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [id "container"] 
    [ pageHeader
    , tableSelectionWidget model
    , constantsLabel
    , fieldEditor model.editingFieldInputValue
    , div [id "myTable"] [renderTable model.tableModel]
    , div [id "urlView"] [text model.currentUrl]
    , craigslistSearchPage  model.craigslistPageHtmlString
    ]

pageHeader : Html Msg
pageHeader =
    div [id "pageHeader"] [ 
        h1 [] [text "CraigslistMatrix."]
        , h2 [] [text "Take your search to the next dimension.  The second dimension."]
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
        [tr [id "myRow"] [button [onClick TableSideFieldAddClicked] [text "add"]]]
        ++
        [tr [id "myRow"] [button [onClick TableSideFieldDeleteClicked] [text "del"]]]
    )

renderTableHeadersRow : List (String) -> Html Msg
renderTableHeadersRow headings  =
    tr [] (
            [ th [] [button [onClick UpdateTableData] [text "UPDATE"]] ]
            ++
            List.indexedMap (\i heading -> th [ onClick (TableTopFieldClicked heading i)] [text heading]) headings
            ++
            [ th [] [button [onClick TableTopFieldAddClicked] [text "add"]]]
            ++
            [ th [] [button [onClick TableTopFieldDeleteClicked] [text "del"]]]
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


tableSelectionWidget : Model -> Html Msg
tableSelectionWidget model =
        div [id "tableNameLabel"]
            [ text "table name label"
            , div [] [text "DURRRR"]
            , tableSelect model
            , button [ onClick AddTableClicked ] [ text "Add New Table"]
            , button [ onClick DeleteTableClicked ] [ text "Delete This Table"]
            , input [ ] []
            , button [] [ text "Update Table Name"]
            ]

tableSelect : Model -> Html Msg
tableSelect model =
        select [] 
            (List.indexedMap (\i name -> option [ onClick <| SelectTableClicked i ] [text name]) model.allTableNames)

constantsLabel : Html msg
constantsLabel = 
        div [id "constantsLabel"] 
            [ text "constants label" 
            , select [] [
                  option [] [text "community"]
                , option [] [text "events"]
                , option [] [text "for sale"]
                , option [] [text "gigs"]
                , option [] [text "housing"]
                , option [] [text "jobs"]
                , option [] [text "resumes"]
                , option [] [text "services"]
                ]
            ]


fieldEditor : String -> Html Msg
fieldEditor editorValue =
        div [id "fieldEditor"] 
        [ text "Field Editor" 
        , input [ onInput FieldEditorChanged
                , Html.Attributes.value editorValue 
                , placeholder "Click a row or column header"
                ] []
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

httpRequestAllTableNames : Cmd Msg
httpRequestAllTableNames =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "nothing here", Json.Encode.int 99 )
                    ]
        , url = "http://localhost:8080/api/alltablenames"
        , expect = Http.expectJson (\jsonResult -> ReceivedAllTableNames jsonResult) allTableNamesDecoder
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


httpAddTopField : Int -> Cmd Msg
httpAddTopField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/addtopfield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }

httpAddSideField : Int -> Cmd Msg
httpAddSideField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/addsidefield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


httpDeleteTopField : Int -> Cmd Msg
httpDeleteTopField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/deletetopfield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }

httpDeleteSideField : Int -> Cmd Msg
httpDeleteSideField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/deletesidefield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


 
httpAddTable : Cmd Msg
httpAddTable =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "nothing", Json.Encode.int 99 )
                    ]
        , url = "http://localhost:8080/api/addtable"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }



httpUpdateTableData : Int -> Cmd Msg
httpUpdateTableData tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/updatetabledata"
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
    Json.Decode.map3 CellViewModel
        (Json.Decode.field "pageUrl" Json.Decode.string)
        (Json.Decode.field "feedUrl" Json.Decode.string)


        (Json.Decode.field "hits" Json.Decode.int)

allTableNamesDecoder : Decoder (List (String))
allTableNamesDecoder =
    (Json.Decode.list string)