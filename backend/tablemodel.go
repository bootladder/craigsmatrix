package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

// TableModel wtf
type TableModel struct {
	Name         string            `json:"name"`
	ID           int               `json:"id"`
	TopHeadings  []string          `json:"topHeadings"`
	SideHeadings []string          `json:"sideHeadings"`
	Rows         [][]CellViewModel `json:"rows"`
}

//CellViewModel wtf
type CellViewModel struct {
	FeedURL string `json:"feedUrl"`
	PageURL string `json:"pageUrl"`
	Hits    int    `json:"hits"`
}

func editTableModelField(tableID, fieldIndex int, fieldValue, fieldType string) {
	fileReader, err := os.Open("../data/table1.json")
	fatal(err)
	var tableModel TableModel
	err = json.NewDecoder(fileReader).Decode(&tableModel)

	if fieldType == "top" {
		fmt.Print("The field in question is " + tableModel.TopHeadings[fieldIndex])
		fmt.Print("Changing it to " + fieldValue)
		tableModel.TopHeadings[fieldIndex] = fieldValue
	} else if fieldType == "side" {
		fmt.Print("The field in question is " + tableModel.SideHeadings[fieldIndex])
		fmt.Print("Changing it to " + fieldValue)
		tableModel.SideHeadings[fieldIndex] = fieldValue
	} else {
		fmt.Print("NO FIELD TYTPE SUPPLIED")
	}

	fmt.Print("REGENERATE URLS")
	tableModel.Rows = make([][]CellViewModel, len(tableModel.SideHeadings))
	for i := range tableModel.Rows {
		tableModel.Rows[i] = make([]CellViewModel, len(tableModel.TopHeadings))

		for j := range tableModel.Rows[i] {
			tableModel.Rows[i][j].FeedURL = makeCraigslistFeedURL(tableModel.SideHeadings[i], tableModel.TopHeadings[j])
			tableModel.Rows[i][j].PageURL = makeCraigslistPageURL(tableModel.SideHeadings[i], tableModel.TopHeadings[j])
			tableModel.Rows[i][j].Hits = 7
		}
	}

	jsonBytes, _ := json.MarshalIndent(tableModel, "", "  ")
	ioutil.WriteFile("../data/table1.json", jsonBytes, 666)
}

func makeCraigslistFeedURL(side, top string) string {
	return "https://" + top + ".craigslist.org/search/jjj?format=rss&query=" + side
}

func makeCraigslistPageURL(side, top string) string {
	return "https://" + top + ".craigslist.org/search/jjj?query=" + side
}

func (t *TableModel) toJSONBytes(tableID int) []byte {
	var contents []byte
	if 1 == tableID {
		fmt.Print("\n\nWTF 1")
		contents, err = ioutil.ReadFile("../data/table1.json")
		fatal(err)
	} else if 2 == tableID {
		fmt.Print("\n\nWTF 2")
		contents, err = ioutil.ReadFile("../data/table2.json")
		fatal(err)
	} else {
		contents = []byte("Invalid table ID, brah")
	}
	return contents
}
