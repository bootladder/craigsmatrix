package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"
)

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
