package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/BurntSushi/toml"
	"github.com/buildpacks/libcnb/v2"
)

// BuildpackToml represents the structure of a buildpack.toml file
type BuildpackToml struct {
	API       string                  `toml:"api"`
	Buildpack libcnb.BuildpackInfo    `toml:"buildpack"`
	Metadata  map[string]any          `toml:"metadata"`
	Order     []libcnb.BuildpackOrder `toml:"order"`
}

type BuildpackInfo struct {
	Name        string
	Path        string
	TOML        BuildpackToml
	LastUpdated time.Time
}

func main() {
	// Get the project root (two levels up from scripts/generate-buildpack-docs)
	projectRoot, err := filepath.Abs("../..")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting project root: %v\n", err)
		os.Exit(1)
	}

	// Parse all buildpacks
	buildpacks, err := parseAllBuildpacks(projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing buildpacks: %v\n", err)
		os.Exit(1)
	}

	// Sort buildpacks by name for consistent output
	sort.Slice(buildpacks, func(i, j int) bool {
		return buildpacks[i].Name < buildpacks[j].Name
	})

	// Create bp-docs directory structure
	docsDir := filepath.Join(projectRoot, "bp-docs")
	buildpacksDir := filepath.Join(docsDir, "buildpacks")
	if err := os.MkdirAll(buildpacksDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Error creating directories: %v\n", err)
		os.Exit(1)
	}

	// Generate index page
	if err := generateIndexPage(docsDir, buildpacks); err != nil {
		fmt.Fprintf(os.Stderr, "Error generating index page: %v\n", err)
		os.Exit(1)
	}

	// Generate individual buildpack pages
	for _, bp := range buildpacks {
		if err := generateBuildpackPage(buildpacksDir, bp); err != nil {
			fmt.Fprintf(os.Stderr, "Error generating page for %s: %v\n", bp.Name, err)
			os.Exit(1)
		}
	}

	fmt.Printf("Successfully generated documentation for %d buildpacks in %s\n", len(buildpacks), docsDir)
}

func parseAllBuildpacks(projectRoot string) ([]BuildpackInfo, error) {
	metaDir := filepath.Join(projectRoot, "meta")
	entries, err := os.ReadDir(metaDir)
	if err != nil {
		return nil, fmt.Errorf("reading meta directory: %w", err)
	}

	var buildpacks []BuildpackInfo
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		buildpackPath := filepath.Join(metaDir, entry.Name(), "buildpack.toml")
		if _, err := os.Stat(buildpackPath); os.IsNotExist(err) {
			continue
		}

		var bp BuildpackToml
		if _, err := toml.DecodeFile(buildpackPath, &bp); err != nil {
			return nil, fmt.Errorf("parsing %s: %w", buildpackPath, err)
		}

		lastUpdated, err := getLastUpdate(projectRoot, filepath.Join("meta", entry.Name(), "buildpack.toml"))
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: could not get last update for %s: %v\n", entry.Name(), err)
			lastUpdated = time.Now()
		}

		buildpacks = append(buildpacks, BuildpackInfo{
			Name:        entry.Name(),
			Path:        buildpackPath,
			TOML:        bp,
			LastUpdated: lastUpdated,
		})
	}

	return buildpacks, nil
}

func getLastUpdate(projectRoot, relativePath string) (time.Time, error) {
	cmd := exec.Command("git", "log", "-1", "--format=%ai", "--", relativePath)
	cmd.Dir = projectRoot
	output, err := cmd.Output()
	if err != nil {
		return time.Time{}, err
	}

	dateStr := strings.TrimSpace(string(output))
	if dateStr == "" {
		return time.Now(), nil
	}

	// Parse git date format: "2025-12-19 06:11:59 +0000"
	t, err := time.Parse("2006-01-02 15:04:05 -0700", dateStr)
	if err != nil {
		return time.Time{}, fmt.Errorf("parsing date %s: %w", dateStr, err)
	}

	return t, nil
}

// buildpackDocURLs maps buildpack directory names to their documentation URLs
var buildpackDocURLs = map[string]string{
	"dotnet-core":       "/docs/recipes/deploy-dotnet/",
	"go":                "/docs/recipes/deploy-go/",
	"java":              "/docs/recipes/deploy-java/",
	"java-native-image": "/docs/recipes/deploy-java/",
	"nodejs":            "/docs/recipes/deploy-nodejs/",
	"php":               "/docs/recipes/deploy-php/",
	"python":            "/docs/recipes/deploy-python/",
	"ruby":              "/docs/recipes/deploy-ruby/",
	"runway":            "/docs/recipes/static/",
}

func generateIndexPage(docsDir string, buildpacks []BuildpackInfo) error {
	var sb strings.Builder

	// Hugo front matter
	sb.WriteString("---\n")
	sb.WriteString("title: \"Runway Buildpack Stack\"\n")
	sb.WriteString("type: docs\n")
	sb.WriteString("weight: 1\n")
	sb.WriteString("---\n\n")

	// Title and introduction
	sb.WriteString("This documentation catalogs all composite buildpacks available on Runway.\n\n")

	// Table header
	sb.WriteString("| Buildpack | Version | Last Updated |\n")
	sb.WriteString("|-----------|---------|--------------|\n")

	// Table rows
	for _, bp := range buildpacks {
		name := bp.TOML.Buildpack.Name
		if name == "" {
			name = bp.Name
		}
		version := bp.TOML.Buildpack.Version
		lastUpdate := bp.LastUpdated.Format("2006-01-02")

		sb.WriteString(fmt.Sprintf("| [`%s`](buildpacks/%s) | `%s` | %s |\n",
			name, bp.Name, version, lastUpdate))
	}

	// Write to file
	indexPath := filepath.Join(docsDir, "_index.md")
	return os.WriteFile(indexPath, []byte(sb.String()), 0644)
}

func generateBuildpackPage(buildpacksDir string, bp BuildpackInfo) error {
	var sb strings.Builder

	// Look up the documentation URL for this buildpack
	docURL, exists := buildpackDocURLs[bp.Name]
	if !exists {
		return fmt.Errorf("no documentation URL mapping found for buildpack: %s", bp.Name)
	}

	// Hugo front matter
	sb.WriteString("---\n")
	sb.WriteString(fmt.Sprintf("title: 'Runway Docs: %s'\n", bp.TOML.Buildpack.ID))
	sb.WriteString("meta:\n")
	sb.WriteString(fmt.Sprintf("  description: 'use %s to deploy on Runway'", bp.TOML.Buildpack.ID) + "\n")
	if len(bp.TOML.Buildpack.Keywords) > 0 {
		sb.WriteString("  keywords: runway,buildpack,")
		sb.WriteString(strings.Join(bp.TOML.Buildpack.Keywords, ",") + "\n")
	}
	sb.WriteString("---\n")

	// Hint box with deployment guide link
	sb.WriteString(fmt.Sprintf("{{<hint>}}[Learn how to use this buildpack](%s) to deploy an application on Runway.{{</hint>}}\n\n", docURL))

	// Title and metadata
	sb.WriteString(fmt.Sprintf("**ID:** `%s`\n", bp.TOML.Buildpack.ID))
	sb.WriteString(fmt.Sprintf("**Version:** `%s`\n", bp.TOML.Buildpack.Version))
	// if bp.TOML.Buildpack.Homepage != "" {
	// 	sb.WriteString(fmt.Sprintf("**Homepage:** %s  \n", bp.TOML.Buildpack.Homepage))
	// }
	sb.WriteString("\n")

	// Order Groups
	if len(bp.TOML.Order) > 0 {
		if len(bp.TOML.Order) == 1 {
			sb.WriteString("## Dependencies\n\n")
		} else {
			sb.WriteString("## Build Order Groups\n\n")
			sb.WriteString(fmt.Sprintf("This buildpack provides %d different build configurations.\n\n", len(bp.TOML.Order)))
		}

		for idx, order := range bp.TOML.Order {
			if len(bp.TOML.Order) > 1 {
				sb.WriteString(fmt.Sprintf("### Order %d\n\n", idx+1))
			}

			// Sort dependencies: required first, then optional, alphabetically within each group
			groups := order.Groups
			sort.Slice(groups, func(i, j int) bool {
				if groups[i].Optional != groups[j].Optional {
					return !groups[i].Optional
				}
				return groups[i].ID < groups[j].ID
			})

			sb.WriteString("| Dependency | Version | Required |\n")
			sb.WriteString("|------------|---------|----------|\n")

			for _, group := range groups {
				required := "Yes"
				if group.Optional {
					required = "Optional"
				}
				sb.WriteString(fmt.Sprintf("| `%s` | `%s` | %s |\n", group.ID, group.Version, required))
			}

			sb.WriteString("\n")
		}
	}

	// Last updated
	sb.WriteString(fmt.Sprintf("**Last Updated:** %s\n", bp.LastUpdated.Format("2006-01-02")))

	// Write to file
	pagePath := filepath.Join(buildpacksDir, bp.Name+".md")
	return os.WriteFile(pagePath, []byte(sb.String()), 0644)
}
