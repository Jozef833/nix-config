package main

import (
	"encoding/json"
	"flag"
	"os"
)

type hookInput struct {
	ToolName  string          `json:"tool_name"`
	ToolInput json.RawMessage `json:"tool_input"`
}

// runClaudeHook implements a Claude Code PreToolUse hook: it reads the hook
// JSON on stdin and, on a deny, emits a permission decision whose reason is
// fed back to the model. Anything else produces no output (no decision).
func runClaudeHook(args []string) error {
	fs := flag.NewFlagSet("claude-hook", flag.ContinueOnError)
	policyPath := fs.String("policy", "policy.json", "path to policy.json")
	if err := fs.Parse(args); err != nil {
		return err
	}
	pol, err := loadPolicy(*policyPath)
	if err != nil {
		return err
	}
	var in hookInput
	if err := json.NewDecoder(os.Stdin).Decode(&in); err != nil {
		return err
	}
	if in.ToolName != "Bash" || len(in.ToolInput) == 0 {
		return nil
	}
	var bash struct {
		Command string `json:"command"`
	}
	if err := json.Unmarshal(in.ToolInput, &bash); err != nil || bash.Command == "" {
		return nil
	}
	v := evaluate(pol, bash.Command)
	if v.Action != "deny" {
		return nil
	}
	return json.NewEncoder(os.Stdout).Encode(map[string]any{
		"hookSpecificOutput": map[string]any{
			"hookEventName":            "PreToolUse",
			"permissionDecision":       "deny",
			"permissionDecisionReason": v.Message,
		},
	})
}
