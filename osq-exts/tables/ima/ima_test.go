package ima

import (
	"testing"
	"runtime"
)

func TestCreateNewIMA(t *testing.T) {
	_, err := NewIMA()

	switch(runtime.GOOS) {
	case "linux":
		if err != nil {
			t.Fatal("Linux OS Is Supported. This should not fail.")
		}
	case "darwin":
		fallthrough
	case "windows":
		fallthrough
	default:
		if err == nil {
			t.Fatal("OS is unsupported.  This should fail.")
		}
	}
}
