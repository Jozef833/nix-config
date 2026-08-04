package main

import (
	"os"
	"path/filepath"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

type arg struct {
	text    string
	literal bool
}

type command struct {
	argv []arg
	cwd  string // empty means unknown
}

type analysis struct {
	commands []command
	loops    [][]command
	parseErr bool
}

type walkCtx struct {
	cwd string
}

type walker struct {
	res       *analysis
	loopStack []*[]command
	depth     int
}

const maxRecursionDepth = 20

func analyze(src, cwd string) *analysis {
	res := &analysis{}
	f, err := parseScript(src)
	if err != nil {
		res.parseErr = true
		return res
	}
	w := &walker{res: res}
	ctx := walkCtx{cwd: cwd}
	w.stmts(f.Stmts, &ctx)
	return res
}

func parseScript(src string) (*syntax.File, error) {
	parser := syntax.NewParser(syntax.Variant(syntax.LangBash))
	return parser.Parse(strings.NewReader(src), "")
}

func (w *walker) stmts(list []*syntax.Stmt, ctx *walkCtx) {
	for _, s := range list {
		w.stmt(s, ctx)
	}
}

func (w *walker) stmt(s *syntax.Stmt, ctx *walkCtx) {
	if s == nil || w.depth > maxRecursionDepth {
		return
	}
	for _, r := range s.Redirs {
		if r.Word != nil {
			w.wordParts(r.Word.Parts, ctx)
		}
	}
	w.command(s.Cmd, ctx)
}

func (w *walker) command(cmd syntax.Command, ctx *walkCtx) {
	switch x := cmd.(type) {
	case nil:
	case *syntax.CallExpr:
		w.call(x, ctx)
	case *syntax.BinaryCmd:
		w.stmt(x.X, ctx)
		w.stmt(x.Y, ctx)
	case *syntax.Subshell:
		sub := *ctx
		w.stmts(x.Stmts, &sub)
	case *syntax.Block:
		w.stmts(x.Stmts, ctx)
	case *syntax.IfClause:
		for ic := x; ic != nil; ic = ic.Else {
			w.stmts(ic.Cond, ctx)
			w.stmts(ic.Then, ctx)
		}
	case *syntax.WhileClause:
		w.loop(func() {
			w.stmts(x.Cond, ctx)
			w.stmts(x.Do, ctx)
		})
	case *syntax.ForClause:
		w.loop(func() {
			w.stmts(x.Do, ctx)
		})
	case *syntax.CaseClause:
		if x.Word != nil {
			w.wordParts(x.Word.Parts, ctx)
		}
		for _, item := range x.Items {
			w.stmts(item.Stmts, ctx)
		}
	case *syntax.FuncDecl:
		w.stmt(x.Body, ctx)
	case *syntax.TimeClause:
		w.stmt(x.Stmt, ctx)
	case *syntax.CoprocClause:
		w.stmt(x.Stmt, ctx)
	case *syntax.DeclClause:
		for _, as := range x.Args {
			if as.Value != nil {
				w.wordParts(as.Value.Parts, ctx)
			}
		}
	}
}

func (w *walker) loop(body func()) {
	acc := []command{}
	w.loopStack = append(w.loopStack, &acc)
	body()
	w.loopStack = w.loopStack[:len(w.loopStack)-1]
	w.res.loops = append(w.res.loops, acc)
}

func (w *walker) call(x *syntax.CallExpr, ctx *walkCtx) {
	for _, as := range x.Assigns {
		if as.Value != nil {
			w.wordParts(as.Value.Parts, ctx)
		}
	}
	var argv []arg
	for _, word := range x.Args {
		w.wordParts(word.Parts, ctx)
		argv = append(argv, wordToArg(word))
	}
	if len(argv) == 0 {
		return
	}
	w.emit(argv, ctx)
}

// wordParts walks nested command substitutions so commands inside $(...),
// <(...), and "..." are analyzed too.
func (w *walker) wordParts(parts []syntax.WordPart, ctx *walkCtx) {
	for _, p := range parts {
		switch y := p.(type) {
		case *syntax.CmdSubst:
			sub := *ctx
			w.stmts(y.Stmts, &sub)
		case *syntax.ProcSubst:
			sub := *ctx
			w.stmts(y.Stmts, &sub)
		case *syntax.DblQuoted:
			w.wordParts(y.Parts, ctx)
		}
	}
}

func (w *walker) emit(argv []arg, ctx *walkCtx) {
	argv = unwrap(argv)
	if len(argv) == 0 {
		return
	}
	name := ""
	if argv[0].literal {
		name = argv[0].text
	}

	switch name {
	case "cd", "pushd":
		w.trackCd(argv, ctx)
	case "bash", "dash", "sh", "zsh":
		if script, ok := dashC(argv); ok && w.depth < maxRecursionDepth {
			w.depth++
			if f, err := parseScript(script); err == nil {
				sub := *ctx
				w.stmts(f.Stmts, &sub)
			}
			w.depth--
		}
	}

	cmd := command{argv: argv, cwd: ctx.cwd}
	w.res.commands = append(w.res.commands, cmd)
	for _, acc := range w.loopStack {
		*acc = append(*acc, cmd)
	}
}

func (w *walker) trackCd(argv []arg, ctx *walkCtx) {
	var target *arg
	for i := 1; i < len(argv); i++ {
		if argv[i].literal && argv[i].text != "-" && strings.HasPrefix(argv[i].text, "-") {
			continue
		}
		target = &argv[i]
		break
	}
	if target == nil {
		if home, err := os.UserHomeDir(); err == nil {
			ctx.cwd = home
		} else {
			ctx.cwd = ""
		}
		return
	}
	if !target.literal || target.text == "-" {
		ctx.cwd = ""
		return
	}
	if p, ok := resolvePath(target.text, ctx.cwd); ok {
		ctx.cwd = p
	} else {
		ctx.cwd = ""
	}
}

func dashC(argv []arg) (string, bool) {
	for i := 1; i < len(argv); i++ {
		if !argv[i].literal {
			continue
		}
		if argv[i].text == "-c" && i+1 < len(argv) && argv[i+1].literal {
			return argv[i+1].text, true
		}
	}
	return "", false
}

// unwrap strips common launcher prefixes so the wrapped command is what gets
// evaluated: sudo find ... and xargs find ... are still find.
func unwrap(argv []arg) []arg {
	for len(argv) > 0 && argv[0].literal {
		switch argv[0].text {
		case "builtin", "command", "exec", "nice", "nohup":
			argv = argv[1:]
		case "doas", "sudo":
			argv = skipFlags(argv[1:], map[string]bool{"-g": true, "-u": true})
		case "timeout":
			rest := skipFlags(argv[1:], map[string]bool{
				"--kill-after": true, "--signal": true, "-k": true, "-s": true,
			})
			if len(rest) > 0 {
				rest = rest[1:] // the duration
			}
			argv = rest
		case "env":
			rest := argv[1:]
			for len(rest) > 0 && rest[0].literal &&
				(strings.Contains(rest[0].text, "=") || rest[0].text == "-i") {
				rest = rest[1:]
			}
			argv = rest
		case "xargs":
			argv = skipFlags(argv[1:], map[string]bool{
				"--arg-file": true, "--delimiter": true, "--max-args": true,
				"--max-lines": true, "--max-procs": true, "--replace": true,
				"-E": true, "-I": true, "-L": true, "-P": true, "-a": true,
				"-d": true, "-e": true, "-i": true, "-l": true, "-n": true,
				"-s": true,
			})
		case "devenv":
			sep := -1
			for i, a := range argv {
				if a.literal && a.text == "--" {
					sep = i
					break
				}
			}
			if sep < 0 || sep+1 >= len(argv) {
				return argv
			}
			argv = argv[sep+1:]
		default:
			return argv
		}
	}
	return argv
}

func skipFlags(argv []arg, withValue map[string]bool) []arg {
	for len(argv) > 0 && argv[0].literal && strings.HasPrefix(argv[0].text, "-") {
		name := argv[0].text
		if strings.ContainsRune(name, '=') {
			argv = argv[1:]
			continue
		}
		if withValue[name] && len(argv) > 1 {
			argv = argv[2:]
			continue
		}
		argv = argv[1:]
	}
	return argv
}

func wordToArg(word *syntax.Word) arg {
	var sb strings.Builder
	literal := literalParts(word.Parts, &sb)
	return arg{text: sb.String(), literal: literal}
}

func literalParts(parts []syntax.WordPart, sb *strings.Builder) bool {
	literal := true
	for _, p := range parts {
		switch y := p.(type) {
		case *syntax.Lit:
			sb.WriteString(unescape(y.Value))
		case *syntax.SglQuoted:
			sb.WriteString(y.Value)
		case *syntax.DblQuoted:
			if !literalParts(y.Parts, sb) {
				literal = false
			}
		default:
			literal = false
		}
	}
	return literal
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

func resolvePath(text, cwd string) (string, bool) {
	if text == "" {
		text = "."
	}
	if text == "~" || strings.HasPrefix(text, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", false
		}
		if text == "~" {
			text = home
		} else {
			text = filepath.Join(home, text[2:])
		}
	} else if strings.HasPrefix(text, "~") {
		// ~otheruser expansion is unsupported
		return "", false
	}
	if !filepath.IsAbs(text) {
		if cwd == "" {
			return "", false
		}
		text = filepath.Join(cwd, text)
	}
	return filepath.Clean(text), true
}
