package main

import (
	"encoding/json"
	"flag"
	"os"
)

type hookInput struct {
	ToolName  string          `json:"tool_name"`
	Cwd       string          `json:"cwd"`
	ToolInput json.RawMessage `json:"tool_input"`
}

// runClaudeHook implements a Claude Code PreToolUse hook: it reads the hook
// JSON on stdin and emits a permission decision on stdout. Denial reasons and
// budget rewrites both feed back into the model's context.
func runClaudeHook(args []string) error {
	fs := flag.NewFlagSet("claude-hook", flag.ContinueOnError)
	policyPath := fs.String("policy", "policy.json", "path to policy.json")
	classesPath := fs.String("classes", "testdata/classes.json", "path to classes.json")
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
	v := evaluate(pol, classes, bash.Command, in.Cwd)
	enc := json.NewEncoder(os.Stdout)
	switch v.Action {
	case "deny":
		return enc.Encode(map[string]any{
			"hookSpecificOutput": map[string]any{
				"hookEventName":            "PreToolUse",
				"permissionDecision":       "deny",
				"permissionDecisionReason": v.Message,
			},
		})
	case "budget":
		wrapped, err := wrapBudget(bash.Command, pol.Budget)
		if err != nil {
			return nil
		}
		return enc.Encode(map[string]any{
			"hookSpecificOutput": map[string]any{
				"hookEventName":      "PreToolUse",
				"permissionDecision": "allow",
				"updatedInput": map[string]any{
					"command": wrapped,
				},
			},
		})
	}
	return nil
}
