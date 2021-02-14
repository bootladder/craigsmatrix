package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	//"github.com/mmcdole/gofeed"
)

var defaultmodelpath = "./data/themodel.json"
var model Model // = loadModelDataFile()

var modelDiskWriter ModelDiskWriter

func setModel(m Model) {
	model = m
}

func setModelDiskWriter(m ModelDiskWriter) {
	modelDiskWriter = m
}


func loadModelDataFile() Model {

	filename := fmt.Sprintf(defaultmodelpath)
	fileReader, err := os.Open(filename)

	if err != nil {
		//create new model, set the model and write to disk
		fmt.Printf("Not found. Creating a  new one " + defaultmodelpath)
		fileReader, err = os.Create(defaultmodelpath)
		model = makeNewModel()
		modelDiskWriter.writeModelToDisk()
	}
	b, err := ioutil.ReadAll(fileReader)
	fatal(err)

	var themodel Model
	json.Unmarshal(b, &themodel)

	fmt.Printf("The model is: %v", themodel)
	return themodel
}

func editTableModelField(tableID, fieldIndex int, fieldValue, fieldType string) {
	tableModel := model.getTableModelByID(tableID)

	if fieldType == "top" {
		tableModel.TopHeadings[fieldIndex] = fieldValue
	} else if fieldType == "side" {
		tableModel.SideHeadings[fieldIndex] = fieldValue
	} else {
		fmt.Print("NO FIELD TYPE SUPPLIED. DOING NOTHING")
	}

	tableModel.Rows = make([][]CellModel, len(tableModel.SideHeadings))
	for i := range tableModel.Rows {
		tableModel.Rows[i] = make([]CellModel, len(tableModel.TopHeadings))

		for j := range tableModel.Rows[i] {
			tableModel.Rows[i][j].PageURL =
				makeCraigslistPageURL(tableModel.SideHeadings[i], tableModel.TopHeadings[j], tableModel.Category)
			tableModel.Rows[i][j].Hits = -1
		}
	}

	writeTable(tableModel, tableID)
}

var categoryCodes = map[string]string{
	"for sale": "sss",
	"jobs":     "jjj",
}

func makeCraigslistPageURL(side, top, category string) string {
	return "https://" + top + ".craigslist.org/search/" + categoryCodes[category] + "?query=" + side
}

func updateTableData(tableID int) {

	tableModel := model.getTableModelByID(tableID)

	for i := range tableModel.Rows {
		for j := range tableModel.Rows[i] {

			searchUrl := tableModel.Rows[i][j].PageURL

			results := getResultsFromCraigslistUrl(searchUrl)
			fmt.Printf("There are %d search results\n", len(results))

			var numberOfUnseenLinks = 0
			for _, item := range results {
				fmt.Print(item.Title)
				if false == sliceContains(tableModel.Rows[i][j].LinksAlreadySeen, item.Url) {
					numberOfUnseenLinks++
				}
			}
			fmt.Printf("There are %d UNSEEN items\n", numberOfUnseenLinks)

			tableModel.Rows[i][j].Hits = numberOfUnseenLinks

			tableModel.Rows[i][j].LinksAlreadySeen = make([]string, len(results))
			for z, item := range results {
				tableModel.Rows[i][j].LinksAlreadySeen[z] = item.Url
			}

		}
	}

	writeTable(tableModel, tableID)
}

func sliceContains(slice []string, elem string) bool {
	for i := range slice {
		if slice[i] == elem {
			return true
		}
	}
	return false
}

func addTopField(tableID int) {

	// TODO: populate table model rows
	tableModel := model.getTableModelByID(tableID)
	tableModel.TopHeadings = append(tableModel.TopHeadings, "new field")
	writeTable(tableModel, tableID)
}

func addSideField(tableID int) {
	tableModel := model.getTableModelByID(tableID)
	tableModel.SideHeadings = append(tableModel.SideHeadings, "new field")
	tableModel.Rows =
		append(tableModel.Rows, make([]CellModel, len(tableModel.TopHeadings)))

	writeTable(tableModel, tableID)
}

func deleteTopField(tableID int) {
	tableModel := model.getTableModelByID(tableID)
	tableModel.TopHeadings = tableModel.TopHeadings[:len(tableModel.TopHeadings)-1]

	//keep the rows in sync by slicing to length of top headers
	for i := range tableModel.Rows {
		tableModel.Rows[i] = tableModel.Rows[i][:len(tableModel.TopHeadings)]
	}

	writeTable(tableModel, tableID)
}

func deleteSideField(tableID int) {
	tableModel := model.getTableModelByID(tableID)

	// keep the rows and the side headings in sync
	tableModel.SideHeadings = tableModel.SideHeadings[:len(tableModel.SideHeadings)-1]
	tableModel.Rows = tableModel.Rows[:len(tableModel.SideHeadings)]

	writeTable(tableModel, tableID)
}

func addTable() int {
	numTables := len(model.TableModels)
	//pick a unique ID
	newTableID := numTables + 1
	newTableModel := makeNewtableModel(newTableID)

	model.TableModels = append(model.TableModels, newTableModel)
	model.ActiveTableModelID = newTableID

	modelDiskWriter.writeModelToDisk()
	return numTables
}

func deleteTable() {

	var newTableModels []TableModel
	for i := range model.TableModels {
		if model.TableModels[i].ID != model.ActiveTableModelID {
			newTableModels = append(newTableModels, model.TableModels[i])
		}

	}
	model.ActiveTableModelID = 1

	model.TableModels = newTableModels
	modelDiskWriter.writeModelToDisk()
}

func updateTableName(newname string) {

	tableModel := model.getActiveTableModel()
	tableModel.Name = newname
	writeTable(tableModel, model.ActiveTableModelID)
}

func updateTableCategory(category string) {

	tableModel := model.getActiveTableModel()
	tableModel.Category = category
	writeTable(tableModel, model.ActiveTableModelID)
}

func listOfTableNamesAndIDsAsJSONBytes() []byte {

	var namesandids []TableNameAndID
	for i := range model.TableModels {
		nextEntry := TableNameAndID{model.TableModels[i].ID, model.TableModels[i].Name}
		namesandids = append(namesandids, nextEntry)
	}

	b, _ := json.MarshalIndent(&namesandids, "", "  ")
	return b
}

func getActiveTableID() int {
	return model.ActiveTableModelID
}
func setActiveTableModelID(id int) {
	model.ActiveTableModelID = id

	modelDiskWriter.writeModelToDisk()
}

func writeTable(tableModel TableModel, tableID int) {
	for id,tm := range(model.TableModels) {
		if tm.ID == tableID {
			model.TableModels[id] = tableModel
		}
	}

	modelDiskWriter.writeModelToDisk()
}


func modelToJSONBytes(tableID int) []byte {
	tableModel := model.getTableModelByID(tableID)
	contents, _ := json.MarshalIndent(tableModel, "", "  ")
	return contents
}
