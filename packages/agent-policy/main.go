// agent-policy evaluates agent-issued bash commands against a declarative
// policy, allowing or denying each with a teaching message.
package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: agent-policy <claude-hook|check|test> [flags]")
		os.Exit(2)
	}
	var err error
	switch os.Args[1] {
	case "claude-hook":
		err = runClaudeHook(os.Args[2:])
	case "check":
		err = runCheck(os.Args[2:])
	case "test":
		err = runTest(os.Args[2:])
	default:
		fmt.Fprintf(os.Stderr, "agent-policy: unknown subcommand %q\n", os.Args[1])
		os.Exit(2)
	}
	if err != nil {
		// Exit 1 is non-blocking for Claude Code hooks (only exit 2 blocks),
		// and the OpenCode plugin treats a non-zero exit as allow, so engine
		// failures fail open rather than wedging the agent.
		fmt.Fprintf(os.Stderr, "agent-policy: %v\n", err)
		os.Exit(1)
	}
}
