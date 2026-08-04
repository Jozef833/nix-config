package main

import (
	"encoding/json"
	"flag"
	"io"
	"os"
)

// runCheck evaluates a command read from stdin and prints a verdict as JSON:
// {"action":"allow"}, {"action":"deny","message":...}, or
// {"action":"rewrite","command":...}. The OpenCode plugin consumes this.
func runCheck(args []string) error {
	fs := flag.NewFlagSet("check", flag.ContinueOnError)
	policyPath := fs.String("policy", "policy.json", "path to policy.json")
	classesPath := fs.String("classes", "testdata/classes.json", "path to classes.json")
	cwd := fs.String("cwd", "", "working directory of the command")
	if err := fs.Parse(args); err != nil {
		return err
	}
	pol, err := loadPolicy(*policyPath)
	if err != nil {
		return err
	}
	classes, err := loadClasses(*classesPath)
	if err != nil {
		return err
	}
	src, err := io.ReadAll(os.Stdin)
	if err != nil {
		return err
	}
	v := evaluate(pol, classes, string(src), *cwd)
	if v.Action == "budget" {
		if wrapped, err := wrapBudget(string(src), pol.Budget); err == nil {
			v = Verdict{Action: "rewrite", Command: wrapped, Rule: v.Rule}
		} else {
			v = Verdict{Action: "allow"}
		}
	}
	return json.NewEncoder(os.Stdout).Encode(v)
}
