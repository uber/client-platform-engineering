package crowdstrikefalconagent

import (
	"testing"
)

func TestWindowsNew(t *testing.T) {
	if _, err := New(); err == nil {
		t.Fatal("This OS is not supported at the moment.  Should return error here.")
	}
}

func TestWindowsRegister(t *testing.T) {
	tmp, _ := New()

	name, table, generate := tmp.Register()
	if name != _PLUGIN_NAME {
		t.Fatalf("did not register correct plugin name, expecting %s, got %s", _PLUGIN_NAME, name)
	}

	if table == nil {
		t.Fatal("should return with table definition, got nil")
	}

	if generate == nil {
		t.Fatal("should return with generate function, got nil")
	}
}

func TestWindowsColumns(t *testing.T) {
	tmp, _ := New()
	col := tmp.Columns()

	if col == nil {
		t.Fatal("should return with columns, got nil")
	}
}
