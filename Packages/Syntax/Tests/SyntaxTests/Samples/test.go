// Go highlight sample for tree-sitter-go

package main

import (
	"context"
	"errors"
	"fmt"
	"math"
	"regexp"
	"strings"
	"time"
)

const (
	_ = iota
	FlagRead
	FlagWrite
	FlagExec
)

const appName string = "go-syntax-demo"

var (
	helloRaw = `line1
line2\t(raw string)`
	helloEscaped = "hello\nworld\t\"quoted\""
	pattern      = regexp.MustCompile(`^(?P<name>[a-z_]\w*)=(?P<value>.+)$`)
)

type Number interface {
	~int | ~int64 | ~float64
}

type Pair[K comparable, V any] struct {
	Key   K
	Value V
}

type Worker interface {
	Run(ctx context.Context) error
	Name() string
}

type JobState int

const (
	StateQueued JobState = iota
	StateRunning
	StateDone
	StateFailed
)

type Job struct {
	id        int64
	name      string
	state     JobState
	createdAt time.Time
	data      map[string]any
}

func NewJob(id int64, name string, data map[string]any) *Job {
	return &Job{
		id:        id,
		name:      name,
		state:     StateQueued,
		createdAt: time.Now(),
		data:      data,
	}
}

func (j *Job) Name() string { return j.name }

func (j *Job) Run(ctx context.Context) error {
	j.state = StateRunning
	defer func() {
		if r := recover(); r != nil {
			j.state = StateFailed
		}
	}()

	select {
	case <-ctx.Done():
		j.state = StateFailed
		return ctx.Err()
	case <-time.After(20 * time.Millisecond):
	}

	if _, ok := j.data["force_error"]; ok {
		j.state = StateFailed
		return errors.New("forced error")
	}

	j.state = StateDone
	return nil
}

func Sum[T Number](items []T) T {
	var total T
	for _, v := range items {
		total += v
	}
	return total
}

func ParseLine(line string) (Pair[string, string], error) {
	m := pattern.FindStringSubmatch(line)
	if m == nil {
		return Pair[string, string]{}, fmt.Errorf("invalid line: %q", line)
	}
	return Pair[string, string]{
		Key:   strings.TrimSpace(m[1]),
		Value: strings.TrimSpace(m[2]),
	}, nil
}

func classify(v any) string {
	switch x := v.(type) {
	case nil:
		return "nil"
	case int, int32, int64:
		return "integer"
	case float32, float64:
		return fmt.Sprintf("float(%.2f)", math.Abs(reflectFloat64(x)))
	case string:
		return fmt.Sprintf("string(%d)", len(x))
	default:
		return fmt.Sprintf("unknown(%T)", v)
	}
}

func reflectFloat64(v any) float64 {
	switch n := v.(type) {
	case float32:
		return float64(n)
	case float64:
		return n
	default:
		return 0
	}
}

func runAll(ctx context.Context, workers ...Worker) []error {
	errCh := make(chan error, len(workers))
	for _, w := range workers {
		go func(w Worker) {
			errCh <- w.Run(ctx)
		}(w)
	}

	errs := make([]error, 0, len(workers))
	for i := 0; i < cap(errCh); i++ {
		if err := <-errCh; err != nil {
			errs = append(errs, err)
		}
	}
	close(errCh)
	return errs
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 150*time.Millisecond)
	defer cancel()

	items := []int{1, 2, 3, 4, 5}
	total := Sum(items)

	jobA := NewJob(1, "alpha", map[string]any{"k": "v"})
	jobB := NewJob(2, "beta", map[string]any{"force_error": true})

	line := "name = gopher"
	p, err := ParseLine(line)
	if err != nil {
		fmt.Println("parse error:", err)
		return
	}

	errs := runAll(ctx, jobA, jobB)
	for i, e := range errs {
		fmt.Printf("#%d: %v\n", i, e)
	}

	r := 'g'
	flags := FlagRead | FlagWrite
	fmt.Println(appName, total, p.Key, p.Value, r, flags, helloRaw, helloEscaped)
	fmt.Println(classify(nil), classify(42), classify(3.14), classify("go"))
}
