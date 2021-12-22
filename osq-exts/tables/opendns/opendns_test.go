package opendns

import (
	"context"
	"testing"
)

var (
	_FAKE_TXT_RECORDS = []string{
		"server m1234.home",
		"originid 1234567890",
		"source 127.0.0.1:1337",
		"actype 0",
		"orgid 123456",
		"bundle 7890",
		"device a1b2c3d4e5",
		"user id 5e4d3c2b1a",
		"dnscrypt enabled (1234)",
	}
)

func TestTXTRecords(t *testing.T) {
	ctx := context.Background()

	_, err := getTXTRecords(ctx, _DEBUG_OPENDNS)
	if err != nil {
		t.Fatalf("err %v", err)
	}
}

func TestPrepareWithResults(t *testing.T) {
	results := prepareResults(_FAKE_TXT_RECORDS)
	if len(results) != len(_FAKE_TXT_RECORDS) {
		t.Fatal("len not equal")
	}
}

func TestPrepareWithoutResults(t *testing.T) {
	norecords := make([]string, 0)
	results := prepareResults(norecords)
	if len(results) != 0 {
		t.Fatalf("results do not match")
	}
}
