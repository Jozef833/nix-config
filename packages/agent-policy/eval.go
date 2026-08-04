package main

type Verdict struct {
	Action  string `json:"action"`
	Message string `json:"message,omitempty"`
}

// evaluate applies the rules in order; the first that fires denies with its
// message. Unparsable input is allowed (fail open): a policy engine that
// wedges the agent is worse than a missed match.
func evaluate(pol *Policy, src string) Verdict {
	a := analyze(src)
	if a.parseErr {
		return Verdict{Action: "allow"}
	}
	for i := range pol.Rules {
		if ruleFires(&pol.Rules[i], a) {
			return Verdict{Action: "deny", Message: pol.Rules[i].Message}
		}
	}
	return Verdict{Action: "allow"}
}

func ruleFires(r *Rule, a *analysis) bool {
	switch r.Scope {
	case "command":
		for i := range a.commands {
			c := &a.commands[i]
			if allSatisfiedBy(r.Match, c) && !anySatisfiedBy(r.Unless, c) {
				return true
			}
		}
	case "loop":
		for _, group := range a.loops {
			if covered(r.Match, group) && !anyInGroup(r.Unless, group) {
				return true
			}
		}
	case "script":
		if covered(r.Match, a.commands) && !anyInGroup(r.Unless, a.commands) {
			return true
		}
	}
	return false
}

func satisfied(m *Matcher, c *subcmd) bool {
	if len(m.Command) > 0 {
		if !c.nameLit || !containsString(m.Command, c.name) {
			return false
		}
	}
	for _, re := range m.argsRes {
		if !re.MatchString(c.args) {
			return false
		}
	}
	return true
}

func allSatisfiedBy(ms []Matcher, c *subcmd) bool {
	for i := range ms {
		if !satisfied(&ms[i], c) {
			return false
		}
	}
	return true
}

func anySatisfiedBy(ms []Matcher, c *subcmd) bool {
	for i := range ms {
		if satisfied(&ms[i], c) {
			return true
		}
	}
	return false
}

// covered reports whether every matcher is satisfied by some command in the
// group (different commands may satisfy different matchers).
func covered(ms []Matcher, group []subcmd) bool {
	for i := range ms {
		found := false
		for j := range group {
			if satisfied(&ms[i], &group[j]) {
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

func anyInGroup(ms []Matcher, group []subcmd) bool {
	for i := range ms {
		for j := range group {
			if satisfied(&ms[i], &group[j]) {
				return true
			}
		}
	}
	return false
}

func containsString(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}
