package opendns

import (
	"context"
	"log"
	"net"
	"strings"
	"time"

	"github.com/osquery/osquery-go/plugin/logger"
	"github.com/osquery/osquery-go/plugin/table"
)

const (
	_PLUGIN_NAME   = "opendns"
	_DEBUG_OPENDNS = "debug.opendns.com"
	_KEY           = "key"
	_VALUE         = "value"
)

type OpenDNS struct{}

func New() (odns *OpenDNS, err error) {
	return
}

func (odns *OpenDNS) Columns() []table.ColumnDefinition {
	return []table.ColumnDefinition{
		table.TextColumn(_KEY),
		table.TextColumn(_VALUE),
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

	return prepareResults(txtrecords), nil
}

func (odns *OpenDNS) Logger() (string, logger.LogFunc) {
	return _PLUGIN_NAME, odns.Log
}

func (odns *OpenDNS) Log(ctx context.Context, typ logger.LogType, logText string) (err error) {
	log.Printf("%s: %s\n", typ, logText)
	return
}

func prepareResults(in []string) (ret []map[string]string) {

	for _, txt := range in {

		if txt == "" {
			continue
		}

		split := strings.Split(txt, " ")
		out := make(map[string]string)
		out[_KEY] = split[0]

		if len(split[1:]) > 0 {
			out[_VALUE] = strings.Join(split[1:], " ")
		}

		ret = append(ret, out)
	}

	return
}

func getTXTRecords(ctx context.Context, query string) ([]string, error) {
	r := net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			d := net.Dialer{
				Timeout: 3 * time.Second,
			}
			// forcing TCP as a workaround to this bug
			// https://github.com/golang/go/issues/21160
			// review again in golang 1.19
			return d.DialContext(ctx, "tcp", address)
		},
	}

	return r.LookupTXT(ctx, query)
}
