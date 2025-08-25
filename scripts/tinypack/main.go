// go run . | tee Dockerfile
// docker build -t builder .
// (MAYBE docker-squash builder -t builder-squashed)
// make test-vue
// make test-php
package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

type Builder struct {
	Stack struct {
		BuildImage string `toml:"build-image"`
		Id         string `toml:"id"`
		RunImage   string `toml:"run-image"`
	}
	Buildpacks []struct {
		URI     string `toml:"uri"`
		Version string `toml:"version"`
	}
}

func main() {
	data, err := os.ReadFile("../../builder.toml")
	if err != nil {
		panic(err)
	}

	cfg := Builder{}
	err = toml.Unmarshal(data, &cfg)
	if err != nil {
		panic(err)
	}

	for i, b := range cfg.Buildpacks {
		img := strings.Replace(b.URI, "docker://", "", 1)
		fmt.Printf("FROM %s AS pack%d\n", img, i)
	}

	fmt.Printf("FROM paketobuildpacks/builder-jammy-buildpackless-full:latest as lifecycle\n") /// XXX hack, see below

	fmt.Printf("FROM %s AS base\n", cfg.Stack.BuildImage)

	/// XXX hack - find out: where does pack get these executables from?
	fmt.Printf("COPY --from=lifecycle /cnb /\n")
	fmt.Printf("COPY --from=lifecycle /lifecycle /cnb/lifecycle\n")

	for i, _ := range cfg.Buildpacks {
		fmt.Printf("COPY --from=pack%d /cnb /cnb\n", i)
	}
	metadata := `{
		"stack": {
			"runImage": {
				"image": "r.planetary-quantum.com/runway-public/runway-runimage:jammy-full",
				"mirrors": null
			}
		},
		"lifecycle": {
			"version": "0.20.13",
			"api": {
				"buildpack": "0.7",
				"platform": "0.7"
			},
			"apis":{
				"buildpack": {
					"deprecated": [],
					"supported": ["0.7","0.8","0.9","0.10","0.11"]
				},
				"platform":{
					"deprecated": [],
					"supported": ["0.7","0.8","0.9","0.10","0.11","0.12","0.13","0.14"]
				}
			}
		}
	}`
	metadata = strings.ReplaceAll(metadata, "\n", "")
	metadata = strings.ReplaceAll(metadata, "\t", "")
	fmt.Printf("LABEL \"io.buildpacks.builder.metadata\"=%q\n", metadata)
	fmt.Printf("ENV CNB_USER_ID=1001\n")
	fmt.Printf("ENV CNB_GROUP_ID=1000\n")
	fmt.Printf("ENV CNB_STACK_ID=io.buildpacks.stacks.jammy\n")

	/// XXX TODO: generate
	fmt.Printf("COPY order.toml /cnb/order.toml\n")
	fmt.Printf("COPY stack.toml /cnb/stack.toml\n")
	fmt.Printf("COPY run.toml /cnb/run.toml\n")

	fmt.Printf("USER 1001:1000\n")
}
