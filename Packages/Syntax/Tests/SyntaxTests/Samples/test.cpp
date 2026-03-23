// C++ highlight sample for tree-sitter-cpp

#include <iostream>
#include <string>
#include <vector>
#include <memory>

namespace demo {

enum class Color { Red, Green, Blue };

template <typename T>
concept Printable = requires(T t) {
    { std::cout << t } -> std::same_as<std::ostream&>;
};

class Base {
public:
    virtual ~Base() = default;
    virtual std::string name() const = 0;
};

class Widget : public Base {
public:
    explicit Widget(std::string label, int id)
        : label_(std::move(label)), id_(id) {}

    std::string name() const override {
        return label_ + "#" + std::to_string(id_);
    }

    int id() const noexcept { return id_; }

    static std::unique_ptr<Widget> create(const std::string& label) {
        static int counter = 0;
        return std::make_unique<Widget>(label, ++counter);
    }

private:
    std::string label_;
    int id_;
};

struct Point {
    double x;
    double y;

    Point operator+(const Point& other) const {
        return {x + other.x, y + other.y};
    }
};

template <typename T>
T clamp(T value, T low, T high) {
    if (value < low) return low;
    if (value > high) return high;
    return value;
}

}  // namespace demo

int main() {
    auto widget = demo::Widget::create("button");
    std::cout << widget->name() << std::endl;

    std::vector<int> numbers = {1, 2, 3, 4, 5};
    for (const auto& n : numbers) {
        std::cout << n << ' ';
    }

    demo::Point p1{1.0, 2.0};
    demo::Point p2{3.0, 4.0};
    auto p3 = p1 + p2;

    // single-line comment
    /* block
       comment */
    int hex = 0xFF;
    double pi = 3.14159;
    char ch = 'A';
    const char* raw = R"(raw string)";
    bool flag = true;
    void* ptr = nullptr;

    return 0;
}
