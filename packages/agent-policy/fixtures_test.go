package main

import "testing"

func TestFixtures(t *testing.T) {
	results, err := runFixtures("policy.json", "testdata/fixtures.json")
	if err != nil {
		t.Fatal(err)
	}
	for _, r := range results {
		if !r.ok {
			t.Errorf("%s: %q: got %s (%s), want %s",
				r.fixture.Name, r.fixture.Command,
				r.got.Action, r.got.Message, r.fixture.Expect)
		}
	}
}
