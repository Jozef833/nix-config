package main

import (
	"encoding/json"
	"fmt"
	"os"
	"regexp"
)

type Policy struct {
	Rules []Rule `json:"rules"`
}

// Rule: deny with Message when every Match matcher is satisfied within Scope
// and no Unless matcher is satisfied within that same scope.
//
// Scope controls how close together the matchers must co-occur:
//   - "command": one simple command satisfies everything (default for a
//     single matcher)
//   - "loop": the commands of one loop body satisfy everything (default for
//     multiple matchers: "script")
//   - "script": commands anywhere in the submitted script
//
// Rules are an unordered set. A rule has no name; its message is its
// documentation.
type Rule struct {
	Match   []Matcher `json:"match"`
	Message string    `json:"message"`
	Scope   string    `json:"scope,omitempty"`
	Unless  []Matcher `json:"unless,omitempty"`
}

// Matcher: Command matches argv[0] exactly (any of the listed names);
// Args regexes (RE2) must all match the remaining argv joined with spaces.
// Either field may be omitted, not both.
type Matcher struct {
	Args    StringList `json:"args,omitempty"`
	Command StringList `json:"command,omitempty"`

	argsRes []*regexp.Regexp
}

// StringList accepts a JSON string or array of strings.
type StringList []string

func (s *StringList) UnmarshalJSON(data []byte) error {
	var one string
	if err := json.Unmarshal(data, &one); err == nil {
		*s = []string{one}
		return nil
	}
	var many []string
	if err := json.Unmarshal(data, &many); err != nil {
		return err
	}
	*s = many
	return nil
}

func loadPolicy(path string) (*Policy, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("load policy: %w", err)
	}
	var pol Policy
	if err := json.Unmarshal(data, &pol); err != nil {
		return nil, fmt.Errorf("parse policy %s: %w", path, err)
	}
	if err := pol.validate(); err != nil {
		return nil, fmt.Errorf("invalid policy %s: %w", path, err)
	}
	return &pol, nil
}

func (p *Policy) validate() error {
	for i := range p.Rules {
		r := &p.Rules[i]
		if len(r.Match) == 0 {
			return fmt.Errorf("rule %d: needs at least one match matcher", i+1)
		}
		if r.Message == "" {
			return fmt.Errorf("rule %d: needs a message", i+1)
		}
		switch r.Scope {
		case "":
			if len(r.Match) == 1 {
				r.Scope = "command"
			} else {
				r.Scope = "script"
			}
		case "command", "loop", "script":
		default:
			return fmt.Errorf("rule %d: unknown scope %q", i+1, r.Scope)
		}
		for _, set := range [][]Matcher{r.Match, r.Unless} {
			for j := range set {
				m := &set[j]
				if len(m.Command) == 0 && len(m.Args) == 0 {
					return fmt.Errorf("rule %d: matcher needs command or args", i+1)
				}
				for _, expr := range m.Args {
					re, err := regexp.Compile(expr)
					if err != nil {
						return fmt.Errorf("rule %d: args regex %q: %w", i+1, expr, err)
					}
					m.argsRes = append(m.argsRes, re)
				}
			}
		}
	}
	return nil
}
