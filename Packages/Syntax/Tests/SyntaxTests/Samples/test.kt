// Kotlin highlight sample for tree-sitter-kotlin

package demo.syntax

import kotlin.math.max
import kotlin.random.Random

@Target(AnnotationTarget.CLASS)
annotation class Validated

enum class State {
    READY,
    RUNNING,
    DONE
}

interface Formatter {
    fun format(input: String): String
}

@Validated
data class Config(
    val name: String,
    val maxRetry: Int = 3,
    val tags: List<String> = emptyList()
)

sealed class Result<out T> {
    data class Success<T>(val value: T) : Result<T>()
    data class Failure(val error: Throwable) : Result<Nothing>()
}

class Service(private val config: Config) : Formatter {

    companion object {
        const val VERSION = "1.0.0"
        private val DEFAULT_CONFIG = Config("default")

        fun create(): Service = Service(DEFAULT_CONFIG)
    }

    private var state: State = State.READY
    private val logs = mutableListOf<String>()

    override fun format(input: String): String {
        return input.trim().lowercase()
    }

    fun process(items: List<Int>, flag: Boolean = false): Result<String> {
        state = State.RUNNING

        val filtered = items.filter { it > 0 }
            .map { it * 2 }
            .sorted()

        val message = buildString {
            append("Processed ${filtered.size} items")
            if (flag) append(" (flagged)")
        }

        logs.add(message)
        state = State.DONE

        return Result.Success(message)
    }

    fun findMax(a: Int, b: Int): Int = max(a, b)

    suspend fun fetchData(url: String): String {
        val random = Random.nextInt(100)
        return "data-$random"
    }
}

object Singleton {
    fun getInstance(): Singleton = this
}

fun topLevel(x: Int, y: Int): Int {
    return when {
        x > y -> x
        else -> y
    }
}

fun main() {
    val service = Service.create()
    val result = service.process(listOf(1, -2, 3, 0, 5), flag = true)

    when (result) {
        is Result.Success -> println("OK: ${result.value}")
        is Result.Failure -> println("Error: ${result.error.message}")
    }

    // single-line comment
    /* block
       comment */
    val hex = 0xFF
    val long = 42L
    val pi = 3.14
    val char = 'A'
    val escaped = "line1\nline2"
}
