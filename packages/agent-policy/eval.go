package main

import "strings"

type Verdict struct {
	Action  string `json:"action"`
	Command string `json:"command,omitempty"`
	Message string `json:"message,omitempty"`
	Rule    string `json:"rule,omitempty"`
}

const wrapMarker = "__agent_policy_rc"

func evaluate(pol *Policy, classes Classes, src, cwd string) Verdict {
	// A command carrying the wrap marker is one of our own rewrites being
	// re-issued; wrapping it again would nest budgets.
	if strings.Contains(src, wrapMarker) {
		return Verdict{Action: "allow"}
	}
	a := analyze(src, cwd)
	if a.parseErr {
		return Verdict{Action: "allow"}
	}
	var travs []*traversal
	for _, cmd := range a.commands {
		if t := traversalOf(cmd, classes); t != nil {
			travs = append(travs, t)
		}
	}
	for _, r := range pol.Rules {
		switch r.Kind {
		case "command":
			for _, cmd := range a.commands {
				if matchesAnyPrefix(cmd, r.Prefixes) {
					return Verdict{Action: "deny", Message: r.Message, Rule: r.Name}
				}
			}
		case "loop":
			for _, loopCmds := range a.loops {
				if loopMatches(loopCmds, r.All) {
					return Verdict{Action: "deny", Message: r.Message, Rule: r.Name}
				}
			}
		case "traversal":
			for _, t := range travs {
				if len(r.Commands) > 0 && !containsString(r.Commands, t.name) {
					continue
				}
				for _, root := range t.roots {
					if !root.known || root.class == "" ||
						!containsString(r.Classes, root.class) {
						continue
					}
					if r.Require == nil || !requireMet(r.Require, t, root) {
						return Verdict{Action: "deny", Message: r.Message, Rule: r.Name}
					}
				}
			}
		}
	}
	if len(travs) > 0 {
		return Verdict{Action: "budget"}
	}
	return Verdict{Action: "allow"}
}

func requireMet(req *Require, t *traversal, root rootInfo) bool {
	if req.MaxDepth > 0 && (!t.hasDepth || t.maxDepth > req.MaxDepth) {
		return false
	}
	if req.MinRootDepth > 0 && root.depth < req.MinRootDepth {
		return false
	}
	if req.Pruned && !t.pruned {
		return false
	}
	return true
}

func matchesAnyPrefix(cmd command, prefixes [][]string) bool {
	for _, p := range prefixes {
		if hasArgvPrefix(cmd, p) {
			return true
		}
	}
	return false
}

func hasArgvPrefix(cmd command, prefix []string) bool {
	if len(prefix) == 0 || len(cmd.argv) < len(prefix) {
		return false
	}
	for i, want := range prefix {
		if !cmd.argv[i].literal || cmd.argv[i].text != want {
			return false
		}
	}
	return true
}

func loopMatches(cmds []command, groups [][][]string) bool {
	if len(groups) == 0 {
		return false
	}
	for _, alts := range groups {
		found := false
		for _, cmd := range cmds {
			if matchesAnyPrefix(cmd, alts) {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}

func containsString(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}
