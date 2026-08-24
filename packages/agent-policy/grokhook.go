package main

import (
	"encoding/json"
	"flag"
	"os"
)

type grokHookInput struct {
	ToolName  string          `json:"toolName"`
	ToolInput json.RawMessage `json:"toolInput"`
}

// runGrokHook implements a Grok PreToolUse hook: the same policy engine as
// runClaudeHook, adapted to Grok's camelCase envelope and its own canonical
// bash tool name ("Bash" is accepted too, so a hooks file shared with Claude
// still matches). Grok's PreToolUse deny shape is flat ({"decision":"deny"}),
// unlike Claude's nested hookSpecificOutput.
func runGrokHook(args []string) error {
	fs := flag.NewFlagSet("grok-hook", flag.ContinueOnError)
	policyPath := fs.String("policy", "policy.json", "path to policy.json")
	if err := fs.Parse(args); err != nil {
		return err
	}
	pol, err := loadPolicy(*policyPath)
	if err != nil {
		return err
	}
	var in grokHookInput
	if err := json.NewDecoder(os.Stdin).Decode(&in); err != nil {
		return err
	}
	if (in.ToolName != "run_terminal_command" && in.ToolName != "Bash") || len(in.ToolInput) == 0 {
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
		"decision": "deny",
		"reason":   v.Message,
	})
}
