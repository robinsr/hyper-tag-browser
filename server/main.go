package main

//go:generate go run github.com/99designs/gqlgen generate

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/robinsr/taggedfilebrowser/server/config"
	serverdb "github.com/robinsr/taggedfilebrowser/server/db"
	"github.com/robinsr/taggedfilebrowser/server/graph"
	"github.com/robinsr/taggedfilebrowser/server/graph/resolvers"
)

func defaultConfigPath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, "Library", "Application Support", "com.hypertag.server", "server-config.json")
}

func main() {
	configPath := flag.String("config", defaultConfigPath(), "path to server config JSON")
	flag.Parse()

	if *configPath == "" {
		log.Fatal("--config path is required and no default could be determined")
	}

	for {
		restart := run(*configPath)
		if !restart {
			break
		}
		log.Println("restarting after config change...")
	}
}

// run starts the server and returns true if it should restart (config changed)
// or false if it should exit cleanly.
func run(configPath string) (restart bool) {
	cfg, err := config.Load(configPath)
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	if !cfg.Enabled {
		log.Println("server disabled in config, exiting")
		return false
	}

	db, err := serverdb.Open(cfg.DatabasePath)
	if err != nil {
		log.Fatalf("failed to open database %q: %v", cfg.DatabasePath, err)
	}
	defer db.Close()

	resolver := resolvers.NewResolver(db)
	gqlSrv := handler.NewDefaultServer(graph.NewExecutableSchema(graph.Config{Resolvers: resolver}))

	mux := http.NewServeMux()
	mux.Handle("/query", gqlSrv)
	mux.Handle("/", playground.Handler("HyperTagBrowser GraphQL", "/query"))

	httpSrv := &http.Server{
		Addr:    fmt.Sprintf("127.0.0.1:%d", cfg.Port),
		Handler: mux,
	}

	restartCh := make(chan struct{}, 1)
	stopWatch, watchErr := config.Watch(configPath, func(_ config.ServerConfig) {
		select {
		case restartCh <- struct{}{}:
		default:
		}
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		httpSrv.Shutdown(ctx) //nolint:errcheck
	})
	if watchErr != nil {
		log.Printf("warning: config watch unavailable: %v", watchErr)
	}
	if stopWatch != nil {
		defer stopWatch()
	}

	log.Printf("GraphQL server on http://127.0.0.1:%d/query (playground: http://127.0.0.1:%d/)", cfg.Port, cfg.Port)
	if serveErr := httpSrv.ListenAndServe(); serveErr != nil && serveErr != http.ErrServerClosed {
		log.Fatalf("server error: %v", serveErr)
	}

	select {
	case <-restartCh:
		return true
	default:
		return false
	}
}
