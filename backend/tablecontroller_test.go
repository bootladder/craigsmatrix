package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"
)


type MockModelDiskWriter struct { isCalled bool}
func  (m * MockModelDiskWriter) isWriteCalled() bool {
	return m.isCalled
}
func (m*  MockModelDiskWriter)  writeModelToDisk() {
	m.isCalled = true
}

var mockModelDiskWriter MockModelDiskWriter

func clearModel_andSetMockModelDiskWriter() {
	setModel(Model{})

	mockModelDiskWriter = MockModelDiskWriter{}
	setModelDiskWriter(&mockModelDiskWriter)
}



func Test_makeNewModel_does_not_have_null_json(t *testing.T) {
	model := makeNewModel()
	jsonBytes, _ := json.MarshalIndent(model, "", "  ")
	jsonStr := string(jsonBytes)
	if strings.Contains(jsonStr, "null") {
		fmt.Printf("%v", string(jsonBytes))
		t.Fatalf("JSON of new model should NOT contain null")
	}
}

func Test_makeNewModel_has_initial_tablemodel(t *testing.T) {
	model := makeNewModel()
	if len(model.TableModels) == 0 {
		t.Fatalf("There must be an initial Table Model for the user to start with")
	}
}

func Test_modelToJSONBytes_on_makeNewTableModel(t *testing.T) {
	model := makeNewModel()
	setModel(model)

	modelToJSONBytes(0)
}

func printModel(model Model) {
	jsonBytes, _ := json.MarshalIndent(model, "", "  ")
	jsonStr := string(jsonBytes)
	fmt.Printf("%v", jsonStr)
}


func Test_initialmodel_printModel(t *testing.T){
	setModel(Model{})  // cleanup state

	//printModel(model)
}


func Test_addTable_5times_allhavedifferentids(t *testing.T) {
	clearModel_andSetMockModelDiskWriter()

	addTable()
	addTable()
	addTable()
	addTable()
	addTable()

	id1 := model.TableModels[0].ID
	id2 := model.TableModels[1].ID
	id3 := model.TableModels[2].ID
	id4 := model.TableModels[3].ID
	id5 := model.TableModels[4].ID

	ids := []int{id1,id2,id3,id4,id5}

	if occurrencesOf(id1, ids) > 1 {
		t.Fatalf("Duplicate ID 1")
	}

	if occurrencesOf(id2, ids) > 1 {
		t.Fatalf("Duplicate ID 2")
	}

	if occurrencesOf(id3, ids) > 1 {
		t.Fatalf("Duplicate ID 3")
	}

	if occurrencesOf(id4, ids) > 1 {
		t.Fatalf("Duplicate ID 4")
	}

	if occurrencesOf(id5, ids) > 1 {
		t.Fatalf("Duplicate ID 5")
	}

}

func occurrencesOf(id int, ids []int) int {
	count := 0
	for _, v := range ids {
		if id == v {
			count = count + 1
		}
	}

	return count
}


func Test_addTable_writesModelToDisk(t * testing.T) {
	clearModel_andSetMockModelDiskWriter()

	addTable()

	if mockModelDiskWriter.isCalled == false {
		t.Fatalf("addTable() did not write to disk")
	}
}


func Test_addTable_then_getActiveTableID_modelToJSONBytes_isCorrectModel(t * testing.T) {
	clearModel_andSetMockModelDiskWriter()

	//fmt.Printf("The whole model is %v", model)
	addTable()
	id := getActiveTableID()

	//fmt.Printf("the id is %d \n", id)

	//fmt.Printf("The whole model is %v", model)


	_ = modelToJSONBytes(id)

	//s := string(contents)

	//fmt.Printf("The model is  %s\n", s)
}



func Test_writeTable_idsoutoforder_stillworks(t * testing.T){
	clearModel_andSetMockModelDiskWriter()

	tableModel := TableModel{}

	addTable()
	addTable()

	// mess up  the ids
	model.TableModels[0].ID = 5


	writeTable(tableModel, 5)

}


func Test_modelToJSONBytes_takesId(t * testing.T){
	clearModel_andSetMockModelDiskWriter()

	addTable()
	addTable()
	addTable()

	bytes := modelToJSONBytes(2)
	s := string(bytes)
	//fmt.Printf("%v", model)

	if false == strings.Contains(s, "2"){
		t.Fatalf("The model should have 2, ie. id 2")
	}

}

func Test_brandNewTableModel_has_tableModel_with_ActiveTableID(t * testing.T){
	// so that at first the initial state has some ID to look up

	clearModel_andSetMockModelDiskWriter()
	model = makeNewModel()
	setModel(model)

	id := getActiveTableID()
	table := model.getTableModelByID(id)

	if table.ID != id {
		t.Fatalf("ID not there")
	}

}


func Test_deleteTable_activeTableIsStillValid(t * testing.T){
	clearModel_andSetMockModelDiskWriter()
	model = makeNewModel()
	setModel(model)


	addTable()
	deleteTable()
	id := getActiveTableID()
	_ = model.getTableModelByID(id)
}

func Test_deleteTopField_works(t * testing.T){
	clearModel_andSetMockModelDiskWriter()
	model = makeNewModel()
	setModel(model)


	addTable()
	id := model.getActiveTableModel().ID
	addTopField(id)
	addTopField(id)
	addTopField(id)
	deleteTopField(id)
}
