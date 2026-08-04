package main

import (
	"strconv"
	"strings"
)

type rootInfo struct {
	path  string
	class string
	depth int // path components below the class root
	known bool
}

type traversal struct {
	name     string
	rawRoots []arg
	roots    []rootInfo
	hasDepth bool
	maxDepth int
	pruned   bool
}

var traversalNames = map[string]bool{
	"du": true, "fd": true, "fdfind": true, "find": true, "grep": true,
	"ls": true, "rg": true, "tree": true,
}

func traversalOf(cmd command, classes Classes) *traversal {
	if len(cmd.argv) == 0 || !cmd.argv[0].literal {
		return nil
	}
	name := cmd.argv[0].text
	if !traversalNames[name] {
		return nil
	}
	var t *traversal
	switch name {
	case "find":
		t = findTraversal(cmd.argv)
	case "grep":
		t = grepTraversal(cmd.argv)
	case "rg":
		t = rgTraversal(cmd.argv)
	case "fd", "fdfind":
		t = fdTraversal(cmd.argv)
		name = "fd"
	case "du":
		t = duTraversal(cmd.argv)
	case "tree":
		t = treeTraversal(cmd.argv)
	case "ls":
		t = lsTraversal(cmd.argv)
	}
	if t == nil {
		return nil
	}
	t.name = name
	resolveRoots(t, cmd.cwd, classes)
	return t
}

func findTraversal(argv []arg) *traversal {
	t := &traversal{}
	i := 1
	for ; i < len(argv); i++ {
		a := argv[i]
		if a.literal {
			if a.text == "(" || a.text == "!" {
				break
			}
			if strings.HasPrefix(a.text, "-") {
				if a.text == "-H" || a.text == "-L" || a.text == "-P" ||
					strings.HasPrefix(a.text, "-O") {
					continue
				}
				break
			}
		}
		t.rawRoots = append(t.rawRoots, a)
	}
	hasNot, hasPath := false, false
	for ; i < len(argv); i++ {
		a := argv[i]
		if !a.literal {
			continue
		}
		switch a.text {
		case "-maxdepth":
			if i+1 < len(argv) && argv[i+1].literal {
				if n, err := strconv.Atoi(argv[i+1].text); err == nil {
					t.hasDepth = true
					t.maxDepth = n
				}
			}
		case "-prune":
			t.pruned = true
		case "!", "-not":
			hasNot = true
		case "-ipath", "-path", "-wholename":
			hasPath = true
		}
	}
	if t.hasDepth || (hasNot && hasPath) {
		t.pruned = true
	}
	return t
}

var grepValueFlags = map[string]bool{
	"--exclude": true, "--exclude-dir": true, "--exclude-from": true,
	"--file": true, "--include": true, "--regexp": true,
	"-A": true, "-B": true, "-C": true, "-D": true, "-d": true, "-e": true,
	"-f": true, "-m": true,
}

func grepTraversal(argv []arg) *traversal {
	recursive := false
	hasPatternFlag := false
	var positionals []arg
	for i := 1; i < len(argv); i++ {
		a := argv[i]
		if a.literal && a.text != "-" && strings.HasPrefix(a.text, "-") {
			name, _ := splitFlag(a.text)
			if name == "--dereference-recursive" || name == "--recursive" {
				recursive = true
			}
			if !strings.HasPrefix(name, "--") && strings.ContainsAny(name[1:], "Rr") {
				recursive = true
			}
			if name == "--file" || name == "--regexp" || name == "-e" || name == "-f" {
				hasPatternFlag = true
			}
			if grepValueFlags[name] && name == a.text && i+1 < len(argv) {
				i++
			}
			continue
		}
		positionals = append(positionals, a)
	}
	if !recursive {
		return nil
	}
	if !hasPatternFlag && len(positionals) > 0 {
		positionals = positionals[1:]
	}
	return &traversal{rawRoots: positionals}
}

var rgValueFlags = map[string]bool{
	"--after-context": true, "--before-context": true, "--color": true,
	"--colors": true, "--context": true, "--encoding": true, "--engine": true,
	"--file": true, "--glob": true, "--iglob": true, "--max-columns": true,
	"--max-count": true, "--max-depth": true, "--max-filesize": true,
	"--path-separator": true, "--pre": true, "--regexp": true,
	"--replace": true, "--sort": true, "--sortr": true, "--threads": true,
	"--type": true, "--type-not": true,
	"-A": true, "-B": true, "-C": true, "-E": true, "-M": true, "-T": true,
	"-e": true, "-f": true, "-g": true, "-j": true, "-m": true, "-r": true,
	"-t": true,
}

func rgTraversal(argv []arg) *traversal {
	t := &traversal{}
	hasPatternFlag := false
	filesMode := false
	var positionals []arg
	for i := 1; i < len(argv); i++ {
		a := argv[i]
		if a.literal && a.text != "-" && strings.HasPrefix(a.text, "-") {
			name, value := splitFlag(a.text)
			switch name {
			case "--files":
				filesMode = true
			case "--file", "--regexp", "-e", "-f":
				hasPatternFlag = true
			case "--max-depth":
				if value == "" && i+1 < len(argv) && argv[i+1].literal {
					value = argv[i+1].text
				}
				if n, err := strconv.Atoi(value); err == nil {
					t.hasDepth = true
					t.maxDepth = n
				}
			}
			if rgValueFlags[name] && name == a.text && i+1 < len(argv) {
				i++
			}
			continue
		}
		positionals = append(positionals, a)
	}
	if !hasPatternFlag && !filesMode && len(positionals) > 0 {
		positionals = positionals[1:]
	}
	t.rawRoots = positionals
	return t
}

var fdValueFlags = map[string]bool{
	"--and": true, "--base-directory": true, "--exclude": true,
	"--extension": true, "--format": true, "--max-depth": true,
	"--max-results": true, "--maxdepth": true, "--min-depth": true,
	"--newer": true, "--older": true, "--owner": true, "--search-path": true,
	"--size": true, "--threads": true, "--type": true,
	"-E": true, "-d": true, "-e": true, "-j": true, "-t": true,
}

func fdTraversal(argv []arg) *traversal {
	t := &traversal{}
	var positionals []arg
	for i := 1; i < len(argv); i++ {
		a := argv[i]
		if a.literal &&
			(a.text == "--exec" || a.text == "--exec-batch" || a.text == "-X" || a.text == "-x") {
			break
		}
		if a.literal && a.text != "-" && strings.HasPrefix(a.text, "-") {
			name, value := splitFlag(a.text)
			isDepth := name == "--max-depth" || name == "--maxdepth" || name == "-d"
			if (isDepth || name == "--search-path") && value == "" &&
				i+1 < len(argv) && argv[i+1].literal {
				value = argv[i+1].text
			}
			if isDepth {
				if n, err := strconv.Atoi(value); err == nil {
					t.hasDepth = true
					t.maxDepth = n
				}
			}
			if name == "--search-path" {
				if value != "" {
					t.rawRoots = append(t.rawRoots, arg{text: value, literal: true})
				} else if i+1 < len(argv) {
					t.rawRoots = append(t.rawRoots, argv[i+1])
				}
			}
			if fdValueFlags[name] && name == a.text && i+1 < len(argv) {
				i++
			}
			continue
		}
		positionals = append(positionals, a)
	}
	if len(positionals) > 0 {
		positionals = positionals[1:] // first positional is the pattern
	}
	t.rawRoots = append(t.rawRoots, positionals...)
	return t
}

var duValueFlags = map[string]bool{
	"--block-size": true, "--exclude": true, "--exclude-from": true,
	"--max-depth": true, "--threshold": true,
	"-B": true, "-X": true, "-d": true, "-t": true,
}

func duTraversal(argv []arg) *traversal {
	t := &traversal{}
	for i := 1; i < len(argv); i++ {
		a := argv[i]
		if a.literal && a.text != "-" && strings.HasPrefix(a.text, "-") {
			name, value := splitFlag(a.text)
			// du's depth flags bound output, not the walk, so they don't set
			// hasDepth; the budget timeout is what bounds du's cost.
			if duValueFlags[name] && name == a.text && i+1 < len(argv) {
				i++
			}
			_ = value
			continue
		}
		t.rawRoots = append(t.rawRoots, a)
	}
	return t
}

var treeValueFlags = map[string]bool{
	"--filelimit": true,
	"-I":          true, "-L": true, "-P": true, "-o": true,
}

func treeTraversal(argv []arg) *traversal {
	t := &traversal{}
	for i := 1; i < len(argv); i++ {
		a := argv[i]
		if a.literal && a.text != "-" && strings.HasPrefix(a.text, "-") {
			name, value := splitFlag(a.text)
			if name == "-L" {
				if value == "" && i+1 < len(argv) && argv[i+1].literal {
					value = argv[i+1].text
				}
				if n, err := strconv.Atoi(value); err == nil {
					t.hasDepth = true
					t.maxDepth = n
				}
			}
			if treeValueFlags[name] && name == a.text && i+1 < len(argv) {
				i++
			}
			continue
		}
		t.rawRoots = append(t.rawRoots, a)
	}
	return t
}

func lsTraversal(argv []arg) *traversal {
	recursive := false
	t := &traversal{}
	for i := 1; i < len(argv); i++ {
		a := argv[i]
		if a.literal && a.text != "-" && strings.HasPrefix(a.text, "-") {
			name, _ := splitFlag(a.text)
			if name == "--recursive" ||
				(!strings.HasPrefix(name, "--") && strings.ContainsRune(name[1:], 'R')) {
				recursive = true
			}
			continue
		}
		t.rawRoots = append(t.rawRoots, a)
	}
	if !recursive {
		return nil
	}
	return t
}

func splitFlag(text string) (name, value string) {
	if i := strings.IndexByte(text, '='); i >= 0 {
		return text[:i], text[i+1:]
	}
	return text, ""
}

func resolveRoots(t *traversal, cwd string, classes Classes) {
	raw := t.rawRoots
	if len(raw) == 0 {
		raw = []arg{{text: ".", literal: true}}
	}
	for _, a := range raw {
		if !a.literal {
			t.roots = append(t.roots, rootInfo{})
			continue
		}
		text := a.text
		if i := strings.IndexAny(text, "*?["); i >= 0 {
			prefix := text[:i]
			if j := strings.LastIndexByte(prefix, '/'); j >= 0 {
				text = prefix[:j+1]
			} else {
				text = "."
			}
		}
		p, ok := resolvePath(text, cwd)
		if !ok {
			t.roots = append(t.roots, rootInfo{})
			continue
		}
		class, depth := classify(classes, p)
		t.roots = append(t.roots, rootInfo{path: p, class: class, depth: depth, known: true})
	}
}

// classify returns the longest-prefix class containing path and how many
// components below that class root the path sits. The "/" class root matches
// only "/" itself.
func classify(classes Classes, path string) (string, int) {
	bestClass, bestRoot := "", ""
	matched := false
	for name, roots := range classes {
		for _, root := range roots {
			if root == "/" {
				if path == "/" && !matched {
					bestClass, bestRoot, matched = name, "/", true
				}
				continue
			}
			clean := strings.TrimSuffix(root, "/")
			if path == clean || strings.HasPrefix(path, clean+"/") {
				if !matched || len(clean) > len(bestRoot) {
					bestClass, bestRoot, matched = name, clean, true
				}
			}
		}
	}
	if !matched {
		return "", 0
	}
	rel := strings.Trim(strings.TrimPrefix(path, bestRoot), "/")
	if rel == "" {
		return bestClass, 0
	}
	return bestClass, len(strings.Split(rel, "/"))
}
