package main

import (
	"flag"
	"log"
	"os"
	"time"

	"github.com/osquery/osquery-go"
	"github.com/osquery/osquery-go/plugin/logger"
	"github.com/osquery/osquery-go/plugin/table"
	"github.com/uber/client-platform-engineering/osq-exts/tables/crowdstrikefalconagent"
)

const (
	_EXT_MANAGER = "osq-exts"
	_ERR_FMT     = "err %v\n"
	_ERR_SOCKET  = "socket undefined."
)

var (
	socket   = flag.String("socket", "", "Path to the extensions UNIX domain socket")
	timeout  = flag.Int("timeout", 3, "Seconds to wait for autoloaded extensions")
	interval = flag.Int("interval", 3, "Seconds delay between connectivity checks")
	verbose  = flag.Bool("verbose", false, "enable verbose messaging")
)

func listOfPlugins() (plugins []osquery.OsqueryPlugin) {
	if csfa, err := crowdstrikefalconagent.New(); err == nil {
		plugins = append(plugins, table.NewPlugin(csfa.Register()))
		plugins = append(plugins, logger.NewPlugin(csfa.Logger()))
	}

	return
}

func checkError(err error) {
	if err != nil {
		log.Fatalf(_ERR_FMT, err)
	}
}

func main() {
	flag.Parse()

	if *socket == "" {
		flag.PrintDefaults()
		log.Fatal(_ERR_SOCKET)
	}

	_, err := os.Stat(*socket)
	checkError(err)

	serverTimeout := osquery.ServerTimeout(
		time.Second * time.Duration(*timeout),
	)

	serverPingInterval := osquery.ServerPingInterval(
		time.Second * time.Duration(*interval),
	)

	server, err := osquery.NewExtensionManagerServer(
		_EXT_MANAGER,
		*socket,
		serverTimeout,
		serverPingInterval,
	)
	checkError(err)

	for _, v := range listOfPlugins() {
		server.RegisterPlugin(v)
	}

	err = server.Run()
	checkError(err)
}
