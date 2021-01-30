package main

import (
	"fmt"
)


// Model is the model for everything
type Model struct {
	ActiveTableModelID int          `json:"activetablemodelid"`
	TableModels        []TableModel `json:"tablemodels"`
}

func makeNewModel() Model {
	model := Model{}
	model.TableModels = []TableModel{}
	model.TableModels = append(model.TableModels, makeNewtableModel(0))
	return model
}

// TableModel stores everything in a table
type TableModel struct {
	Name         string        `json:"name"`
	ID           int           `json:"id"`
	Category     string        `json:"category"`
	TopHeadings  []string      `json:"topHeadings"`
	SideHeadings []string      `json:"sideHeadings"`
	Rows         [][]CellModel `json:"rows"`
}

func makeNewtableModel(id int) TableModel {
	tm := TableModel{}
	tm.Name = fmt.Sprintf("New Table id %d ", id)
	tm.ID = id
	tm.TopHeadings = []string{"TopHeading"}
	tm.SideHeadings = []string{"SideHeading"}
	tm.Rows = [][]CellModel{}
	return tm
}

//CellModel models a RSS feed
type CellModel struct {
	FeedURL          string `json:"feedUrl"`
	PageURL          string `json:"pageUrl"`
	Hits             int    `json:"hits"`
	LinksAlreadySeen []string
}

// TableNameAndID  is used so the frontend can populate the dropdown
type TableNameAndID struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}
