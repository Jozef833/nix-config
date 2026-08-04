package main

import (
	"path"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

// The engine models exactly one binary: bash itself. It parses the script,
// enumerates every simple command (including inside $(...), <(...), and
// inline `bash -c '...'` scripts wherever they appear in an argv), and tags
// loop membership. What any other binary's flags mean is the rules' business.

// subcmd is one simple command: its argv[0] and the remaining argv joined
// with spaces for regex matching. Words built purely from literals are
// unquoted/unescaped; expansions keep their source text ($VAR, $(cmd), ...)
// so rules match what the author wrote.
type subcmd struct {
	name    string
	nameLit bool
	args    string
}

type analysis struct {
	commands []subcmd
	loops    [][]subcmd
	parseErr bool
}

type walker struct {
	src       string
	res       *analysis
	loopStack []*[]subcmd
	depth     int
}

const maxRecursionDepth = 20

func analyze(src string) *analysis {
	res := &analysis{}
	f, err := parseScript(src)
	if err != nil {
		res.parseErr = true
		return res
	}
	w := &walker{src: src, res: res}
	w.stmts(f.Stmts)
	return res
}

func parseScript(src string) (*syntax.File, error) {
	parser := syntax.NewParser(syntax.Variant(syntax.LangBash))
	return parser.Parse(strings.NewReader(src), "")
}

func (w *walker) stmts(list []*syntax.Stmt) {
	for _, s := range list {
		w.stmt(s)
	}
}

func (w *walker) stmt(s *syntax.Stmt) {
	if s == nil || w.depth > maxRecursionDepth {
		return
	}
	for _, r := range s.Redirs {
		if r.Word != nil {
			w.wordParts(r.Word.Parts)
		}
	}
	w.command(s.Cmd)
}

func (w *walker) command(cmd syntax.Command) {
	switch x := cmd.(type) {
	case nil:
	case *syntax.CallExpr:
		w.call(x)
	case *syntax.BinaryCmd:
		w.stmt(x.X)
		w.stmt(x.Y)
	case *syntax.Subshell:
		w.stmts(x.Stmts)
	case *syntax.Block:
		w.stmts(x.Stmts)
	case *syntax.IfClause:
		for ic := x; ic != nil; ic = ic.Else {
			w.stmts(ic.Cond)
			w.stmts(ic.Then)
		}
	case *syntax.WhileClause:
		w.loop(func() {
			w.stmts(x.Cond)
			w.stmts(x.Do)
		})
	case *syntax.ForClause:
		w.loop(func() {
			w.stmts(x.Do)
		})
	case *syntax.CaseClause:
		if x.Word != nil {
			w.wordParts(x.Word.Parts)
		}
		for _, item := range x.Items {
			w.stmts(item.Stmts)
		}
	case *syntax.FuncDecl:
		w.stmt(x.Body)
	case *syntax.TimeClause:
		w.stmt(x.Stmt)
	case *syntax.CoprocClause:
		w.stmt(x.Stmt)
	case *syntax.DeclClause:
		for _, as := range x.Args {
			if as.Value != nil {
				w.wordParts(as.Value.Parts)
			}
		}
	}
}

func (w *walker) loop(body func()) {
	acc := []subcmd{}
	w.loopStack = append(w.loopStack, &acc)
	body()
	w.loopStack = w.loopStack[:len(w.loopStack)-1]
	w.res.loops = append(w.res.loops, acc)
}

func (w *walker) call(x *syntax.CallExpr) {
	for _, as := range x.Assigns {
		if as.Value != nil {
			w.wordParts(as.Value.Parts)
		}
	}
	var argv []arg
	for _, word := range x.Args {
		w.wordParts(word.Parts)
		argv = append(argv, w.wordToArg(word))
	}
	if len(argv) == 0 {
		return
	}
	w.emit(argv)
}

// wordParts walks nested command substitutions so commands inside $(...),
// <(...), and "..." are analyzed too.
func (w *walker) wordParts(parts []syntax.WordPart) {
	for _, p := range parts {
		switch y := p.(type) {
		case *syntax.CmdSubst:
			w.stmts(y.Stmts)
		case *syntax.ProcSubst:
			w.stmts(y.Stmts)
		case *syntax.DblQuoted:
			w.wordParts(y.Parts)
		}
	}
}

func (w *walker) emit(argv []arg) {
	if script, ok := inlineScript(argv); ok && w.depth < maxRecursionDepth {
		if f, err := parseScript(script); err == nil {
			sub := &walker{src: script, res: w.res, loopStack: w.loopStack, depth: w.depth + 1}
			sub.stmts(f.Stmts)
		}
	}
	cmd := subcmd{name: argv[0].text, nameLit: argv[0].literal, args: joinArgs(argv[1:])}
	w.res.commands = append(w.res.commands, cmd)
	for _, acc := range w.loopStack {
		*acc = append(*acc, cmd)
	}
}

var shellNames = map[string]bool{"bash": true, "dash": true, "sh": true, "zsh": true}

// inlineScript finds a literal `bash -c '<script>'` (or sh/dash/zsh) anywhere
// in an argv — so `sudo bash -c '...'` and `devenv shell -- bash -c '...'`
// are seen without modeling sudo or devenv.
func inlineScript(argv []arg) (string, bool) {
	for i := 0; i < len(argv); i++ {
		if !argv[i].literal || !shellNames[path.Base(argv[i].text)] {
			continue
		}
		for j := i + 1; j+1 < len(argv); j++ {
			if argv[j].literal && argv[j].text == "-c" && argv[j+1].literal {
				return argv[j+1].text, true
			}
		}
	}
	return "", false
}

type arg struct {
	text    string
	literal bool
}

func joinArgs(argv []arg) string {
	parts := make([]string, len(argv))
	for i, a := range argv {
		parts[i] = a.text
	}
	return strings.Join(parts, " ")
}

func (w *walker) wordToArg(word *syntax.Word) arg {
	var sb strings.Builder
	literal := w.textParts(word.Parts, &sb)
	return arg{text: sb.String(), literal: literal}
}

func (w *walker) textParts(parts []syntax.WordPart, sb *strings.Builder) bool {
	literal := true
	for _, p := range parts {
		switch y := p.(type) {
		case *syntax.Lit:
			sb.WriteString(unescape(y.Value))
		case *syntax.SglQuoted:
			sb.WriteString(y.Value)
		case *syntax.DblQuoted:
			if !w.textParts(y.Parts, sb) {
				literal = false
			}
		default:
			sb.WriteString(w.span(p.Pos(), p.End()))
			literal = false
		}
	}
	return literal
}

func (w *walker) span(from, to syntax.Pos) string {
	a, b := int(from.Offset()), int(to.Offset())
	if a < 0 || b > len(w.src) || a > b {
		return ""
	}
	return w.src[a:b]
}

func unescape(s string) string {
	if !strings.Contains(s, "\\") {
		return s
	}
	var sb strings.Builder
	escaped := false
	for _, r := range s {
		if escaped {
			sb.WriteRune(r)
			escaped = false
			continue
		}
		if r == '\\' {
			escaped = true
			continue
		}
		sb.WriteRune(r)
	}
	if escaped {
		sb.WriteRune('\\')
	}
	return sb.String()
}
