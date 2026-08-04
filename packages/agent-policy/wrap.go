package main

import (
	"fmt"

	"mvdan.cc/sh/v3/syntax"
)

// wrapBudget reruns the original command verbatim under a timeout; on exit
// 124 the reflection message lands on stderr, where the agent reads it as
// part of the failed tool result.
func wrapBudget(src string, b Budget) (string, error) {
	timeout := b.TimeoutSeconds
	if timeout <= 0 {
		timeout = 60
	}
	quotedCmd, err := syntax.Quote(src, syntax.LangBash)
	if err != nil {
		return "", err
	}
	quotedMsg, err := syntax.Quote(b.Reflection, syntax.LangBash)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf(
		"timeout %d bash -c %s; %s=$?; if [ \"$%s\" -eq 124 ]; then printf '%%s\\n' %s >&2; fi; exit \"$%s\"",
		timeout, quotedCmd, wrapMarker, wrapMarker, quotedMsg, wrapMarker,
	), nil
}
