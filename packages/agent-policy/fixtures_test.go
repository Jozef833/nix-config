package main

import "testing"

func TestFixtures(t *testing.T) {
	results, err := runFixtures("policy.json", "testdata/classes.json", "testdata/fixtures.json")
	if err != nil {
		t.Fatal(err)
	}
	for _, r := range results {
		if !r.ok {
			t.Errorf("%s: %q: got %s (rule %q), want %s (rule %q)",
				r.fixture.Name, r.fixture.Command,
				r.got.Action, r.got.Rule,
				r.fixture.Expect, r.fixture.Rule)
		}
	}
}

func TestWrapIdempotent(t *testing.T) {
	pol := &Policy{Budget: Budget{Reflection: "over budget", TimeoutSeconds: 60}}
	classes := Classes{"home": {"/home/nixos"}}
	first := evaluate(pol, classes, "find . -name x", "/home/nixos/somewhere")
	if first.Action != "budget" {
		t.Fatalf("first pass: got %s, want budget", first.Action)
	}
	wrapped, err := wrapBudget("find . -name x", pol.Budget)
	if err != nil {
		t.Fatal(err)
	}
	second := evaluate(pol, classes, wrapped, "/home/nixos/somewhere")
	if second.Action != "allow" {
		t.Fatalf("second pass: got %s, want allow (no double wrap)", second.Action)
	}
}
