package opendns

import (
	"context"
	"log"
	"net"
	"strings"
	"fmt"

	"github.com/osquery/osquery-go/plugin/logger"
	"github.com/osquery/osquery-go/plugin/table"
)

const (
	_PLUGIN_NAME   = "opendns"
	_DEBUG_OPENDNS = "debug.opendns.com"
	_ACTIVE        = "active"
	_SERVER        = "server"
	_ORIGINID      = "originid"
	_SOURCE        = "source"
	_ACTYPE        = "actype"
	_ORGID         = "orgid"
	_BUNDLE        = "bundle"
	_DEVICE        = "device"
	_USER          = "user"
	_DNSCRYPT      = "dnscrypt"
)

type OpenDNS struct{}

func New() (odns *OpenDNS, err error) {
	return
}

func (odns *OpenDNS) Columns() []table.ColumnDefinition {
	return []table.ColumnDefinition{
		table.BigIntColumn(_ACTIVE),
		table.TextColumn(_SERVER),
		table.TextColumn(_SOURCE),
		table.TextColumn(_DNSCRYPT),
		table.TextColumn(_USER),
		table.TextColumn(_DEVICE),
		table.BigIntColumn(_ORIGINID),
		table.BigIntColumn(_ACTYPE),
		table.BigIntColumn(_ORGID),
		table.BigIntColumn(_BUNDLE),
	}
}

func (odns *OpenDNS) Register() (string, []table.ColumnDefinition, table.GenerateFunc) {
	return _PLUGIN_NAME, odns.Columns(), odns.Generate
}

func (odns *OpenDNS) Generate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	txtrecords, err := getTXTRecords(ctx, _DEBUG_OPENDNS)
	if err != nil {
		return nil, err
	}

	return []map[string]string{
		prepareResults(txtrecords),
	}, nil
}

func (odns *OpenDNS) Logger() (string, logger.LogFunc) {
	return _PLUGIN_NAME, odns.Log
}

func (odns *OpenDNS) Log(ctx context.Context, typ logger.LogType, logText string) (err error) {
	log.Printf("%s: %s\n", typ, logText)
	return
}

func prepareResults(in []string) (ret map[string]string) {

	ret = map[string]string{
		_ACTIVE: fmt.Sprintf("%v", len(in)),
	}

	for _, txt := range in {
		out := strings.Split(txt, " ")

		// Remove last element in dnscrypt
		// since we want dnscrypt status
		if out[0] == "dnscrypt" {
			out = out[:len(out)-1]
		}

		ret[out[0]] = out[len(out)-1]
	}

	return
}

func getTXTRecords(ctx context.Context, query string) ([]string, error) {
	r := net.Resolver{}
	return r.LookupTXT(ctx, query)
	//return net.LookupTXT(query)
}
