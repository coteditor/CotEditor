// Java highlight sample for tree-sitter-java

package demo.syntax;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@FunctionalInterface
interface Formatter {
    String format(String input);
}

enum State {
    READY,
    RUNNING,
    DONE
}

public final class TestJava {

    private static final String APP_NAME = "java-syntax-demo";
    private static final int MAX_RETRY = 3;

    private final List<String> logs = new ArrayList<>();
    private State state = State.READY;

    public TestJava() {
        this.logs.add("created");
    }

    public static void main(String[] args) {
        TestJava app = new TestJava();
        app.run((value) -> "[" + value + "]");
    }

    public void run(Formatter formatter) {
        for (int i = 0; i < MAX_RETRY; i++) {
            this.state = State.RUNNING;
            String line = formatter.format("attempt=" + i + ", app=" + APP_NAME);
            this.logs.add(line);
        }

        Map<String, Object> info = Map.of(
            "state", this.state,
            "createdAt", Instant.now(),
            "ok", true,
            "ratio", 3.14,
            "grade", 'A',
            "none", null
        );

        this.finish(info);
    }

    private void finish(Map<String, Object> info) {
        this.state = State.DONE;
        String escaped = "line1\nline2\t\"quoted\"";

        if (info.get("ok") instanceof Boolean value && value) {
            this.logs.add(escaped);
        } else {
            this.logs.add("failed");
        }

        // Method references and typed scopes.
        this.logs.forEach(System.out::println);
    }
}
