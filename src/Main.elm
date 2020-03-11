module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)



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
    }


type alias CellViewModel =
    { color : String
    , label : String
    }

type alias TableModel =
    { name : String
    , rows : List (List (CellViewModel))
    , topHeadings : List (String)
    , sideHeadings : List (String)
    }

myTableRows : List (List (CellViewModel))
myTableRows = [
         (List.map (\s -> CellViewModel "blueCell" s)  ["1","2","3","4","5","6"])
        , (List.map (\s -> CellViewModel "blueCell" s) ["15","16","17","18","19","10"])
        
    ]

myTableTopHeadings : List (String)
myTableTopHeadings = ["sfbay", "boston", "newyork", "longisland", "austin", "seattle"]

myTableSideHeadings : List (String)
myTableSideHeadings = ["Carpentry", "Masonry"]

myTableModel : TableModel
myTableModel = TableModel "Table 1" myTableRows myTableTopHeadings myTableSideHeadings

-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    -- The initial model comes from a Request, now it is hard coded
    ( Model
        0
        "dummy debug"
    , Cmd.none
    )



-- UPDATE


type Msg
    = FormInput String
    | AddColumnButtonClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html msg
view model =
    div [id "container"] 
    [ div [id "nothing"] [ text "nothing"]
    , tableNameLabel myTableModel.name
    , topLabel
    , sideLabel
    , constantsLabel
    , div [id "myTable"] [renderTable myTableModel]
    ]

renderTable : TableModel -> Html msg
renderTable tableModel =
    let
        pairs = List.map2 Tuple.pair tableModel.sideHeadings tableModel.rows

        renderedRows = List.map 
                        (\(heading, cells) -> myRow heading cells)
                        pairs
    in
    table [] (
        [myTableHeadersRow tableModel.topHeadings]
        ++
        renderedRows
    )

myTableHeadersRow : List (String) -> Html msg
myTableHeadersRow headings  =
    tr [] (
            [ th [] [text  "///"] ]
            ++
            List.map (\s -> th [] [text s]) headings
    )

myRow : String -> List (CellViewModel) ->  Html msg
myRow heading cellViewModels =
        tr [id "myRow"] ( 
                th [] [text heading]
                ::
                  List.map renderCellViewModel cellViewModels
            )

renderCellViewModel : CellViewModel -> Html msg
renderCellViewModel cellViewModel =
    td [class cellViewModel.color] [text cellViewModel.label]


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