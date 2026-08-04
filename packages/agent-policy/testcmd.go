package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
)

type Fixture struct {
	Name    string `json:"name"`
	Command string `json:"command"`
	Cwd     string `json:"cwd"`
	Expect  string `json:"expect"`
	Rule    string `json:"rule,omitempty"`
}

type fixtureResult struct {
	fixture Fixture
	got     Verdict
	ok      bool
}

func runFixtures(policyPath, classesPath, fixturesPath string) ([]fixtureResult, error) {
	pol, err := loadPolicy(policyPath)
	if err != nil {
		return nil, err
	}
	classes, err := loadClasses(classesPath)
	if err != nil {
		return nil, err
	}
	data, err := os.ReadFile(fixturesPath)
	if err != nil {
		return nil, err
	}
	var fixtures []Fixture
	if err := json.Unmarshal(data, &fixtures); err != nil {
		return nil, fmt.Errorf("parse fixtures %s: %w", fixturesPath, err)
	}
	var results []fixtureResult
	for _, f := range fixtures {
		got := evaluate(pol, classes, f.Command, f.Cwd)
		ok := got.Action == f.Expect && (f.Rule == "" || got.Rule == f.Rule)
		results = append(results, fixtureResult{fixture: f, got: got, ok: ok})
	}
	return results, nil
}

// runTest proves the policy against the fixture corpus. Every policy change
// should come with a fixture demonstrating it.
func runTest(args []string) error {
	fs := flag.NewFlagSet("test", flag.ContinueOnError)
	policyPath := fs.String("policy", "policy.json", "path to policy.json")
	classesPath := fs.String("classes", "testdata/classes.json", "path to classes.json")
	fixturesPath := fs.String("fixtures", "testdata/fixtures.json", "path to fixtures.json")
	if err := fs.Parse(args); err != nil {
		return err
	}
	results, err := runFixtures(*policyPath, *classesPath, *fixturesPath)
	if err != nil {
		return err
	}
	failures := 0
	for _, r := range results {
		status := "PASS"
		if !r.ok {
			status = "FAIL"
			failures++
		}
		fmt.Printf("%s %s: got %s", status, r.fixture.Name, r.got.Action)
		if r.got.Rule != "" {
			fmt.Printf(" (%s)", r.got.Rule)
		}
		if !r.ok {
			fmt.Printf(", want %s", r.fixture.Expect)
			if r.fixture.Rule != "" {
				fmt.Printf(" (%s)", r.fixture.Rule)
			}
		}
		fmt.Println()
	}
	if failures > 0 {
		return fmt.Errorf("%d of %d fixtures failed", failures, len(results))
	}
	fmt.Printf("all %d fixtures passed\n", len(results))
	return nil
}
