package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Policy struct {
	Budget Budget `json:"budget"`
	Rules  []Rule `json:"rules"`
}

type Budget struct {
	Reflection     string `json:"reflection"`
	TimeoutSeconds int    `json:"timeoutSeconds"`
}

// Rule kinds:
//   - "command": deny when any simple command's argv starts with one of Prefixes
//   - "loop": deny when a single loop body contains, for every group in All,
//     a command matching one of that group's alternative argv prefixes
//   - "traversal": applies to filesystem-walking commands whose search root
//     falls in one of Classes; denies outright when Require is absent,
//     otherwise denies when the requirements are unmet
type Rule struct {
	All      [][][]string `json:"all,omitempty"`
	Classes  []string     `json:"classes,omitempty"`
	Commands []string     `json:"commands,omitempty"`
	Kind     string       `json:"kind"`
	Message  string       `json:"message"`
	Name     string       `json:"name"`
	Prefixes [][]string   `json:"prefixes,omitempty"`
	Require  *Require     `json:"require,omitempty"`
}

type Require struct {
	// MaxDepth: the command must state a depth bound of at most this value.
	MaxDepth int `json:"maxDepth,omitempty"`
	// MinRootDepth: the search root must sit at least this many path
	// components below the class root.
	MinRootDepth int `json:"minRootDepth,omitempty"`
	// Pruned: find must bound its walk (-prune, -not -path, or -maxdepth).
	Pruned bool `json:"pruned,omitempty"`
}

// Classes maps a class name to the filesystem roots it covers.
type Classes map[string][]string

func loadPolicy(path string) (*Policy, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("load policy: %w", err)
	}
	var pol Policy
	if err := json.Unmarshal(data, &pol); err != nil {
		return nil, fmt.Errorf("parse policy %s: %w", path, err)
	}
	return &pol, nil
}

func loadClasses(path string) (Classes, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("load classes: %w", err)
	}
	var classes Classes
	if err := json.Unmarshal(data, &classes); err != nil {
		return nil, fmt.Errorf("parse classes %s: %w", path, err)
	}
	return classes, nil
}
