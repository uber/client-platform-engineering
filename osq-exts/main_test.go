package main

import (
	"github.com/osquery/osquery-go/plugin/logger"
	"github.com/osquery/osquery-go/plugin/table"
	"reflect"
	"testing"
)

func TestEmptyFlag(t *testing.T) {
	if *socket != "" {
		t.Fatal("*socket not empty")
	}
}

func TestListOfPlugins(t *testing.T) {
	out := listOfPlugins()
	for _, v := range out {
		switch v.(type) {
		case *table.Plugin:
			continue
		case *logger.Plugin:
			continue
		default:
			t.Fatalf("unknown type %v", reflect.TypeOf(v))
		}
	}
}
