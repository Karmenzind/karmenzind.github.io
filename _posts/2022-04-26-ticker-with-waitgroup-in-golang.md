---
title: "Cron jobs with ticker&waitgroup in GoLang"
categories:
    - Blog
tags:
    - golang
---


I wrote an simple cron job and inserted it to agent module of Telegraf. Here is the code.


```go
package cron

import (
	"context"
	"runtime"
	"sync"
	"time"

	"github.com/influxdata/telegraf/testutil"
	"github.com/influxdata/telegraf/internal/config"
)


var wg sync.WaitGroup
var logger = testutil.Logger{Name: "cron"}

type JobFunc func(*config.Config) error

var intervalMap = map[string]int{
	"Job1": 600,
	"Job2": 60,
}

func StartCron(ctx context.Context, config *config.Config) {
	if config.Agent.EnvTag == "product" {
		logger.Infof("")
	}

	wg.Add(1)
	go RunJob("Job1", job1, ctx, config)

	if runtime.GOOS != "windows" {
		wg.Add(1)
		go RunJob("Job2", job2, ctx, config)
	}

	wg.Wait()
	logger.Info("All cron jobs stopped gracefully.")
}

func RunJob(name string, fn JobFunc, ctx context.Context, c *config.Config) {
	interval := intervalMap[name]
	logger.Infof("Initialized cron job: %s. Interval: %d.\n", name, interval)
	ticker := time.NewTicker(time.Duration(interval) * time.Second)

	defer func() {
		ticker.Stop()
		wg.Done()
		logger.Infof("Job `%s` ticker/wg stopped.\n", name)
	}()

	for {
		select {
		case <-ctx.Done():
			logger.Infof("Job `%s` recived `ctx.Done` signal.\n", name)
			return
		case <-ticker.C:
            err := fn(c)
            if err != nil {
                logger.Errorf("Job `%s` threw error: %s", name, err)
            }
		}
	}
}
```

And in `github.com/influxdata/telegraf/agent.go`:


```go

func (a *Agent) Run(ctx context.Context) error {
    // ...

    var wg sync.WaitGroup

    wg.Add(1)
    go func() {
        defer wg.Done()
        cron.StartCron(ctx, a.Config)
    }()

    // ...

    wg.wait()

    // ...
}
```

The outter layered `WaitGroup` is necessary that give `StartCron` goroutine time to wait its jobs. With these code, the jobs can be gracefully shutdown and restarted along with agent itself.
