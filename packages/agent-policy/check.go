package main

import (
	"encoding/json"
	"flag"
	"io"
	"os"
)

// runCheck evaluates a command read from stdin and prints the verdict as
// JSON: {"action":"allow"} or {"action":"deny","message":...}. The OpenCode
// plugin consumes this.
func runCheck(args []string) error {
	fs := flag.NewFlagSet("check", flag.ContinueOnError)
	policyPath := fs.String("policy", "policy.json", "path to policy.json")
	if err := fs.Parse(args); err != nil {
		return err
	}
	pol, err := loadPolicy(*policyPath)
	if err != nil {
		return err
	}
	src, err := io.ReadAll(os.Stdin)
	if err != nil {
		return err
	}
	return json.NewEncoder(os.Stdout).Encode(evaluate(pol, string(src)))
}
