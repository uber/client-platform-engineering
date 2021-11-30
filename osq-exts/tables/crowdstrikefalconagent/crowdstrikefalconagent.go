package crowdstrikefalconagent

import (
	"context"
	"github.com/osquery/osquery-go/plugin/logger"
	"github.com/osquery/osquery-go/plugin/table"
	"log"
)

const (
	_PLUGIN_NAME           = "crowdstrikefalconagent"
	_PLUGIN_NOT_COMPATIBLE = "Not compatible with current OS."
)

type CrowdStrikeFalconAgent struct{}

func New() (csfa *CrowdStrikeFalconAgent, err error) {
	err = csfa.osCompat()
	return
}

func (csfa *CrowdStrikeFalconAgent) Columns() []table.ColumnDefinition {
	return csfa.osColumns()
}

func (csfa *CrowdStrikeFalconAgent) Register() (string, []table.ColumnDefinition, table.GenerateFunc) {
	return _PLUGIN_NAME, csfa.Columns(), csfa.Generate
}

func (csfa *CrowdStrikeFalconAgent) Generate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	return csfa.osGenerate(ctx, queryContext)
}

func (csfa *CrowdStrikeFalconAgent) Logger() (string, logger.LogFunc) {
	return _PLUGIN_NAME, csfa.Log
}

func (csfa *CrowdStrikeFalconAgent) Log(ctx context.Context, typ logger.LogType, logText string) (err error) {
	//TODO:  Figure out a better way to handle logging.
	log.Printf("%s: %s\n", typ, logText)
	return
}
