package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"
)

func Test_makeNewModel(t *testing.T) {
	model := makeNewModel()
	jsonBytes, _ := json.MarshalIndent(model, "", "  ")
	jsonStr := string(jsonBytes)
	if strings.Contains(jsonStr, "null") {
		fmt.Printf("%v", string(jsonBytes))
		t.Fatalf("JSON of new model should NOT contain null")
	}
}
