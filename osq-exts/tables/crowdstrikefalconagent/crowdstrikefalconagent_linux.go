package crowdstrikefalconagent

import (
	"context"
	"errors"

	"github.com/osquery/osquery-go/plugin/table"
)

func (c *CrowdStrikeFalconAgent) osCompat() error {
	return errors.New(_PLUGIN_NOT_COMPATIBLE)
}

func (c *CrowdStrikeFalconAgent) osColumns() []table.ColumnDefinition {
	return []table.ColumnDefinition{}
}

func (c *CrowdStrikeFalconAgent) osGenerate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	return []map[string]string{{}}, errors.New(_PLUGIN_NOT_COMPATIBLE)
}
