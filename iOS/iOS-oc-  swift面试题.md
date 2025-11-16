# iOS 面试题 - Swift 面试题

本文档整理了 Swift 开发中最常见的面试题，涵盖了语言特性、内存管理、并发编程、高级特性等多个方面。

---

## 一、语言基础

### 1. Swift 和 Objective-C 的主要区别是什么？

**答案：**

| 特性 | Objective-C | Swift |
|------|-------------|-------|
| 语言类型 | 动态语言 | 静态语言 |
| 类型安全 | 弱类型，运行时检查 | 强类型，编译时检查 |
| 空值处理 | nil（可能崩溃） | Optional（类型安全） |
| 语法风格 | 消息传递 `[obj method]` | 函数调用 `obj.method()` |
| 内存管理 | MRC/ARC | ARC（自动管理） |
| 性能 | 运行时开销较大 | 编译时优化，性能更好 |
| 协议 | 可选方法 | 协议扩展，默认实现 |
| 泛型 | 支持有限 | 强大的泛型系统 |

**代码示例：**

```swift
// Swift - 类型安全
let name: String = "iOS"
let age: Int = 25
// let result = name + age  // 编译错误，类型不匹配

// Swift - Optional 安全处理
var optionalString: String? = "Hello"
if let value = optionalString {
    print(value)  // 安全解包
}
```

### 2. Swift 中的 Optional 是什么？如何使用？

**答案：**

- Optional 是 Swift 的类型安全特性，表示一个值可能存在也可能不存在
- 使用 `?` 声明可选类型，使用 `!` 强制解包（不推荐）
- 推荐使用 `if let`、`guard let`、`??` 等安全解包方式

**代码示例：**

```swift
// 声明可选类型
var name: String? = "Swift"
var age: Int? = nil

// 安全解包方式 1: if let
if let unwrappedName = name {
    print("Name is \(unwrappedName)")
}

// 安全解包方式 2: guard let
func processName(_ name: String?) {
    guard let name = name else {
        return
    }
    print("Processing \(name)")
}

// 安全解包方式 3: nil 合并运算符
let displayName = name ?? "Unknown"

// 可选链
let count = name?.count  // 如果 name 为 nil，count 也为 nil

// 强制解包（不推荐，可能导致崩溃）
let forcedName = name!  // 如果 name 为 nil，会崩溃
```

### 3. `let` 和 `var` 的区别是什么？

**答案：**

- `let` 声明**常量**，值不可变（immutable）
- `var` 声明**变量**，值可变（mutable）
- 推荐优先使用 `let`，只有在需要修改时才使用 `var`

**代码示例：**

```swift
// 常量 - 不可变
let name = "Swift"
// name = "Objective-C"  // 编译错误

// 变量 - 可变
var age = 25
age = 26  // 可以修改

// 引用类型中的 let
let array = [1, 2, 3]
// array = [4, 5, 6]  // 编译错误，不能重新赋值
array.append(4)  // 但可以修改内容（因为数组是引用类型）
```

### 4. Swift 中的值类型和引用类型有哪些？

**答案：**

**值类型（Value Types）：**
- 基本类型：`Int`、`Double`、`Bool`、`String`、`Character`
- 集合类型：`Array`、`Dictionary`、`Set`
- 结构体：`Struct`、`Tuple`、`Enum`
- 赋值时进行**拷贝**

**引用类型（Reference Types）：**
- 类：`Class`
- 闭包：`Closure`
- 函数：`Function`
- 赋值时传递**引用**

**代码示例：**

```swift
// 值类型 - 拷贝
var a = 10
var b = a
b = 20
print(a)  // 10，a 不受影响

// 引用类型 - 引用
class Person {
    var name: String
    init(name: String) {
        self.name = name
    }
}

let person1 = Person(name: "Alice")
let person2 = person1
person2.name = "Bob"
print(person1.name)  // "Bob"，person1 也受影响
```

### 5. `struct` 和 `class` 的区别是什么？

**答案：**

| 特性 | Struct | Class |
|------|--------|-------|
| 类型 | 值类型 | 引用类型 |
| 继承 | 不支持 | 支持单继承 |
| 内存 | 栈分配 | 堆分配 |
| 性能 | 更快 | 相对较慢 |
| 线程安全 | 更安全 | 需要同步 |
| 初始化器 | 自动生成 | 需要手动实现 |
| 可变性 | 需要 `mutating` | 直接修改 |

**代码示例：**

```swift
// Struct - 值类型
struct Point {
    var x: Int
    var y: Int
    
    mutating func move(dx: Int, dy: Int) {
        x += dx
        y += dy
    }
}

// Class - 引用类型
class Person {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func changeName(_ newName: String) {
        name = newName  // 不需要 mutating
    }
}

// 继承
class Student: Person {
    var grade: Int
    
    init(name: String, grade: Int) {
        self.grade = grade
        super.init(name: name)
    }
}
```

---

## 二、内存管理

### 1. Swift 中的内存管理机制是什么？

**答案：**

- Swift 使用 **ARC（Automatic Reference Counting）** 自动引用计数
- 当对象的引用计数为 0 时，自动释放内存
- 通过 `strong`、`weak`、`unowned` 控制引用关系

**代码示例：**

```swift
class Person {
    let name: String
    var apartment: Apartment?
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("\(name) is being deinitialized")
    }
}

class Apartment {
    let unit: String
    weak var tenant: Person?  // 弱引用，避免循环引用
    
    init(unit: String) {
        self.unit = unit
    }
    
    deinit {
        print("Apartment \(unit) is being deinitialized")
    }
}
```

### 2. `strong`、`weak`、`unowned` 的区别是什么？

**答案：**

| 修饰符 | 引用计数 | 对象释放后 | 使用场景 |
|--------|----------|------------|----------|
| `strong` | +1 | 保持引用 | 默认，普通属性 |
| `weak` | 不变 | 自动置为 nil | 避免循环引用，delegate |
| `unowned` | 不变 | 悬空指针（不安全） | 生命周期更长的对象 |

**代码示例：**

```swift
class Parent {
    var child: Child?
}

class Child {
    weak var parent: Parent?  // 弱引用，避免循环引用
}

// unowned 使用场景
class Customer {
    let name: String
    var card: CreditCard?
    
    init(name: String) {
        self.name = name
    }
}

class CreditCard {
    let number: UInt64
    unowned let customer: Customer  // unowned，customer 生命周期更长
    
    init(number: UInt64, customer: Customer) {
        self.number = number
        self.customer = customer
    }
}
```

### 3. 什么是循环引用？如何避免？

**答案：**

- 循环引用是指两个或多个对象相互强引用，导致无法释放
- 解决方法：使用 `weak` 或 `unowned` 打破循环

**代码示例：**

```swift
// 循环引用示例
class Person {
    var apartment: Apartment?
}

class Apartment {
    var tenant: Person?  // 强引用，造成循环引用
}

// 解决方案：使用 weak
class Apartment {
    weak var tenant: Person?  // 弱引用，打破循环
}

// 闭包中的循环引用
class HTMLElement {
    let name: String
    let text: String?
    
    lazy var asHTML: () -> String = { [unowned self] in
        if let text = self.text {
            return "<\(self.name)>\(text)</\(self.name)>"
        } else {
            return "<\(self.name) />"
        }
    }
    
    init(name: String, text: String? = nil) {
        self.name = name
        self.text = text
    }
}
```

---

## 三、高级特性

### 1. Swift 中的泛型是什么？如何使用？

**答案：**

- 泛型允许编写灵活、可重用的代码，避免类型重复
- 使用 `<T>` 声明泛型类型参数
- 可以添加类型约束

**代码示例：**

```swift
// 泛型函数
func swapTwoValues<T>(_ a: inout T, _ b: inout T) {
    let temporaryA = a
    a = b
    b = temporaryA
}

// 泛型类型
struct Stack<Element> {
    var items: [Element] = []
    
    mutating func push(_ item: Element) {
        items.append(item)
    }
    
    mutating func pop() -> Element {
        return items.removeLast()
    }
}

// 类型约束
func findIndex<T: Equatable>(of valueToFind: T, in array: [T]) -> Int? {
    for (index, value) in array.enumerated() {
        if value == valueToFind {
            return index
        }
    }
    return nil
}
```

### 2. 什么是协议（Protocol）？协议扩展是什么？

**答案：**

- 协议定义了方法、属性和其他需求的蓝图
- 协议扩展可以为协议提供默认实现
- Swift 的协议比 Objective-C 更强大，支持协议扩展

**代码示例：**

```swift
// 协议定义
protocol Drawable {
    func draw()
    var area: Double { get }
}

// 协议扩展 - 提供默认实现
extension Drawable {
    func draw() {
        print("Drawing...")
    }
}

// 遵循协议
struct Circle: Drawable {
    let radius: Double
    
    var area: Double {
        return Double.pi * radius * radius
    }
}

// 协议作为类型
func render(_ drawable: Drawable) {
    drawable.draw()
}
```

### 3. 什么是扩展（Extension）？如何使用？

**答案：**

- 扩展可以为现有的类、结构体、枚举或协议添加新功能
- 可以添加计算属性、方法、初始化器、下标等
- 不能添加存储属性

**代码示例：**

```swift
// 扩展 Int
extension Int {
    var squared: Int {
        return self * self
    }
    
    func times(_ closure: () -> Void) {
        for _ in 0..<self {
            closure()
        }
    }
}

let number = 5
print(number.squared)  // 25
3.times {
    print("Hello")
}

// 扩展协议
extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
```

### 4. 什么是属性观察器（Property Observers）？

**答案：**

- `willSet`：在值被设置之前调用
- `didSet`：在值被设置之后调用
- 可以用于监听属性值的变化

**代码示例：**

```swift
class StepCounter {
    var totalSteps: Int = 0 {
        willSet(newTotalSteps) {
            print("About to set totalSteps to \(newTotalSteps)")
        }
        didSet {
            if totalSteps > oldValue {
                print("Added \(totalSteps - oldValue) steps")
            }
        }
    }
}

let stepCounter = StepCounter()
stepCounter.totalSteps = 200
// 输出：
// About to set totalSteps to 200
// Added 200 steps
```

### 5. 什么是计算属性（Computed Properties）？

**答案：**

- 计算属性不存储值，而是提供一个 getter 和可选的 setter
- 通过其他属性计算得出值

**代码示例：**

```swift
struct Rectangle {
    var width: Double
    var height: Double
    
    // 只读计算属性
    var area: Double {
        return width * height
    }
    
    // 可读可写计算属性
    var center: (x: Double, y: Double) {
        get {
            return (width / 2, height / 2)
        }
        set(newCenter) {
            width = newCenter.x * 2
            height = newCenter.y * 2
        }
    }
}
```

---

## 四、函数式编程

### 1. Swift 中的高阶函数有哪些？

**答案：**

- `map`：转换每个元素
- `filter`：过滤元素
- `reduce`：归约操作
- `flatMap`/`compactMap`：展平并过滤 nil
- `forEach`：遍历执行

**代码示例：**

```swift
let numbers = [1, 2, 3, 4, 5]

// map - 转换
let doubled = numbers.map { $0 * 2 }  // [2, 4, 6, 8, 10]

// filter - 过滤
let evens = numbers.filter { $0 % 2 == 0 }  // [2, 4]

// reduce - 归约
let sum = numbers.reduce(0, +)  // 15

// compactMap - 过滤 nil
let strings = ["1", "2", "three", "4"]
let numbers2 = strings.compactMap { Int($0) }  // [1, 2, 4]

// flatMap - 展平
let nested = [[1, 2], [3, 4], [5]]
let flattened = nested.flatMap { $0 }  // [1, 2, 3, 4, 5]
```

### 2. 什么是闭包（Closure）？如何使用？

**答案：**

- 闭包是自包含的功能代码块，可以捕获和存储其上下文中的常量和变量
- 类似于其他语言中的匿名函数或 lambda 表达式
- 可以使用尾随闭包语法简化代码

**代码示例：**

```swift
// 闭包语法
let names = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]

// 完整语法
let sorted1 = names.sorted(by: { (s1: String, s2: String) -> Bool in
    return s1 > s2
})

// 类型推断
let sorted2 = names.sorted(by: { s1, s2 in return s1 > s2 })

// 单表达式隐式返回
let sorted3 = names.sorted(by: { s1, s2 in s1 > s2 })

// 参数名缩写
let sorted4 = names.sorted(by: { $0 > $1 })

// 尾随闭包
let sorted5 = names.sorted { $0 > $1 }

// 捕获值
func makeIncrementer(incrementAmount: Int) -> () -> Int {
    var total = 0
    let incrementer: () -> Int = {
        total += incrementAmount
        return total
    }
    return incrementer
}
```

---

## 五、错误处理

### 1. Swift 中的错误处理机制是什么？

**答案：**

- 使用 `Error` 协议定义错误类型
- 使用 `throw` 抛出错误
- 使用 `do-catch` 捕获错误
- 使用 `try?`、`try!` 简化错误处理

**代码示例：**

```swift
// 定义错误类型
enum VendingMachineError: Error {
    case invalidSelection
    case insufficientFunds(coinsNeeded: Int)
    case outOfStock
}

// 抛出错误
func vend(itemNamed name: String) throws {
    guard let item = inventory[name] else {
        throw VendingMachineError.invalidSelection
    }
    
    guard item.count > 0 else {
        throw VendingMachineError.outOfStock
    }
    
    guard item.price <= coinsDeposited else {
        throw VendingMachineError.insufficientFunds(coinsNeeded: item.price - coinsDeposited)
    }
}

// 捕获错误
do {
    try vend(itemNamed: "Candy Bar")
} catch VendingMachineError.invalidSelection {
    print("Invalid Selection.")
} catch VendingMachineError.insufficientFunds(let coinsNeeded) {
    print("Insufficient funds. Please insert an additional \(coinsNeeded) coins.")
} catch {
    print("Unexpected error: \(error).")
}

// 可选值处理
let result = try? someThrowingFunction()  // 返回可选值

// 强制解包（不推荐）
let result2 = try! someThrowingFunction()  // 如果抛出错误会崩溃
```

### 2. `defer` 关键字的作用是什么？

**答案：**

- `defer` 用于在函数返回前执行清理代码
- 无论函数如何返回（正常返回或抛出错误），`defer` 中的代码都会执行
- 多个 `defer` 按相反顺序执行（后进先出）

**代码示例：**

```swift
func processFile(filename: String) throws {
    let file = openFile(filename)
    defer {
        closeFile(file)  // 确保文件被关闭
    }
    
    // 处理文件
    try processData(file)
    // defer 代码在这里执行
}

// 多个 defer
func example() {
    defer { print("First defer") }
    defer { print("Second defer") }
    defer { print("Third defer") }
    print("Function body")
}
// 输出：
// Function body
// Third defer
// Second defer
// First defer
```

---

## 六、并发编程

### 1. Swift 中的并发编程方式有哪些？

**答案：**

- **GCD（Grand Central Dispatch）**：C 语言 API，底层并发框架
- **Operation Queue**：基于 GCD 的高级抽象
- **async/await**（Swift 5.5+）：现代异步编程方式
- **Actor**（Swift 5.5+）：数据竞争安全的并发模型

**代码示例：**

```swift
// GCD
DispatchQueue.global().async {
    // 后台任务
    let data = fetchData()
    
    DispatchQueue.main.async {
        // 更新 UI
        updateUI(with: data)
    }
}

// async/await
func fetchUserData() async throws -> User {
    let data = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// 使用 async/await
Task {
    do {
        let user = try await fetchUserData()
        print(user.name)
    } catch {
        print("Error: \(error)")
    }
}

// Actor - 数据竞争安全
actor BankAccount {
    private var balance: Double = 0
    
    func deposit(_ amount: Double) {
        balance += amount
    }
    
    func withdraw(_ amount: Double) -> Bool {
        if balance >= amount {
            balance -= amount
            return true
        }
        return false
    }
}
```

### 2. 什么是 `async/await`？如何使用？

**答案：**

- `async/await` 是 Swift 5.5 引入的现代异步编程方式
- `async` 标记异步函数，`await` 等待异步操作完成
- 比回调函数和 completion handler 更清晰易读

**代码示例：**

```swift
// 定义异步函数
func fetchImage(from url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
        throw ImageError.invalidData
    }
    return image
}

// 调用异步函数
Task {
    do {
        let image = try await fetchImage(from: imageURL)
        imageView.image = image
    } catch {
        print("Failed to load image: \(error)")
    }
}

// 并发执行多个异步任务
async let firstImage = fetchImage(from: url1)
async let secondImage = fetchImage(from: url2)
let images = try await [firstImage, secondImage]
```

---

## 七、枚举（Enum）

### 1. Swift 中的枚举有什么特性？

**答案：**

- 枚举是一等类型，功能强大
- 可以有关联值（Associated Values）
- 可以有原始值（Raw Values）
- 可以有方法、计算属性、初始化器
- 可以遵循协议

**代码示例：**

```swift
// 基本枚举
enum CompassPoint {
    case north
    case south
    case east
    case west
}

// 关联值
enum Barcode {
    case upc(Int, Int, Int, Int)
    case qrCode(String)
}

let productBarcode = Barcode.upc(8, 85909, 51226, 3)
let qrBarcode = Barcode.qrCode("ABCDEFGHIJKLMNOP")

// 原始值
enum Planet: Int {
    case mercury = 1, venus, earth, mars, jupiter, saturn, uranus, neptune
}

let earthsOrder = Planet.earth.rawValue  // 3

// 枚举方法
enum TrafficLight {
    case red, yellow, green
    
    func description() -> String {
        switch self {
        case .red:
            return "Stop"
        case .yellow:
            return "Caution"
        case .green:
            return "Go"
        }
    }
}
```

### 2. `indirect` 关键字在枚举中的作用是什么？

**答案：**

- `indirect` 用于创建递归枚举
- 允许枚举的关联值引用自身

**代码示例：**

```swift
// 递归枚举
indirect enum ArithmeticExpression {
    case number(Int)
    case addition(ArithmeticExpression, ArithmeticExpression)
    case multiplication(ArithmeticExpression, ArithmeticExpression)
}

// 使用
let five = ArithmeticExpression.number(5)
let four = ArithmeticExpression.number(4)
let sum = ArithmeticExpression.addition(five, four)
let product = ArithmeticExpression.multiplication(sum, ArithmeticExpression.number(2))

// 计算表达式
func evaluate(_ expression: ArithmeticExpression) -> Int {
    switch expression {
    case let .number(value):
        return value
    case let .addition(left, right):
        return evaluate(left) + evaluate(right)
    case let .multiplication(left, right):
        return evaluate(left) * evaluate(right)
    }
}
```

---

## 八、访问控制

### 1. Swift 中的访问控制级别有哪些？

**答案：**

| 访问级别 | 说明 | 使用场景 |
|---------|------|----------|
| `open` | 最高级别，可被任何模块访问和继承 | 框架的公开 API |
| `public` | 可被任何模块访问，但不可被其他模块继承 | 框架的公开接口 |
| `internal` | 默认级别，同一模块内可访问 | 模块内部使用 |
| `fileprivate` | 同一文件内可访问 | 文件内部使用 |
| `private` | 最严格，同一作用域内可访问 | 类内部使用 |

**代码示例：**

```swift
// 公开类
open class PublicClass {
    open func publicMethod() {}
    public func anotherPublicMethod() {}
    internal func internalMethod() {}
    fileprivate func fileprivateMethod() {}
    private func privateMethod() {}
}

// 内部类（默认）
class InternalClass {
    func method() {}
}

// 私有类
private class PrivateClass {
    func method() {}
}
```

---

## 九、其他重要特性

### 1. 什么是 `guard` 语句？与 `if` 的区别是什么？

**答案：**

- `guard` 用于提前退出，要求条件为真才能继续执行
- `guard` 必须包含 `else` 分支，且必须退出当前作用域
- 使用 `guard` 可以减少嵌套，提高代码可读性

**代码示例：**

```swift
// 使用 if（嵌套较深）
func processUser(_ user: User?) {
    if let user = user {
        if let name = user.name {
            if !name.isEmpty {
                print("Processing \(name)")
                // 处理逻辑
            }
        }
    }
}

// 使用 guard（更清晰）
func processUser(_ user: User?) {
    guard let user = user else { return }
    guard let name = user.name, !name.isEmpty else { return }
    
    print("Processing \(name)")
    // 处理逻辑
}
```

### 2. 什么是 `lazy` 属性？

**答案：**

- `lazy` 属性是延迟加载的属性
- 只有在第一次访问时才会计算
- 必须是 `var`，不能是 `let`
- 线程不安全

**代码示例：**

```swift
class DataImporter {
    var filename = "data.txt"
    // 数据导入逻辑
}

class DataManager {
    lazy var importer = DataImporter()
    var data: [String] = []
}

let manager = DataManager()
manager.data.append("Some data")
// importer 还没有被创建

print(manager.importer.filename)
// importer 现在被创建了
```

### 3. 什么是 `inout` 参数？

**答案：**

- `inout` 允许函数修改参数的值
- 传递时需要在参数前加 `&`
- 类似于 C 语言的指针传递

**代码示例：**

```swift
func swapTwoInts(_ a: inout Int, _ b: inout Int) {
    let temporaryA = a
    a = b
    b = temporaryA
}

var someInt = 3
var anotherInt = 107
swapTwoInts(&someInt, &anotherInt)
print("someInt is now \(someInt), and anotherInt is now \(anotherInt)")
// 输出: someInt is now 107, and anotherInt is now 3
```

### 4. 什么是 `@escaping` 闭包？

**答案：**

- `@escaping` 表示闭包可能在函数返回后才执行
- 非 `@escaping` 闭包必须在函数返回前执行
- 异步操作、存储闭包等场景需要使用 `@escaping`

**代码示例：**

```swift
var completionHandlers: [() -> Void] = []

// 非 escaping 闭包（默认）
func someFunctionWithNonescapingClosure(closure: () -> Void) {
    closure()  // 在函数返回前执行
}

// escaping 闭包
func someFunctionWithEscapingClosure(closure: @escaping () -> Void) {
    completionHandlers.append(closure)  // 闭包被存储，稍后执行
}

// 使用示例
class SomeClass {
    var x = 10
    
    func doSomething() {
        someFunctionWithEscapingClosure { [self] in
            x = 100  // 需要捕获 self
        }
    }
}
```

### 5. 什么是 `@autoclosure`？

**答案：**

- `@autoclosure` 自动将表达式包装成闭包
- 延迟表达式的求值
- 常用于短路求值场景

**代码示例：**

```swift
// 没有 @autoclosure
func logIfTrue(_ predicate: () -> Bool) {
    if predicate() {
        print("True")
    }
}
logIfTrue { 2 > 1 }  // 需要闭包语法

// 使用 @autoclosure
func logIfTrue(_ predicate: @autoclosure () -> Bool) {
    if predicate() {
        print("True")
    }
}
logIfTrue(2 > 1)  // 可以直接传表达式

// 实际应用：短路求值
func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}
```

---

## 十、Swift 5.x 新特性

### 1. Swift 5.5 引入了哪些重要特性？

**答案：**

- **async/await**：现代异步编程
- **Actor**：数据竞争安全的并发模型
- **Structured Concurrency**：结构化并发
- **AsyncSequence**：异步序列
- **MainActor**：主线程隔离

**代码示例：**

```swift
// Actor
actor Counter {
    private var value = 0
    
    func increment() {
        value += 1
    }
    
    func getValue() -> Int {
        return value
    }
}

// 使用 Actor
let counter = Counter()
Task {
    await counter.increment()
    let value = await counter.getValue()
    print(value)
}

// MainActor
@MainActor
class ViewController: UIViewController {
    func updateUI() {
        // 自动在主线程执行
        label.text = "Updated"
    }
}
```

### 2. Swift 5.9 引入了哪些重要特性？

**答案：**

- **Macros（宏）**：代码生成工具
- **Parameter Packs**：参数包
- **Noncopyable Types**：不可复制类型
- **Consuming/borrowing**：所有权修饰符

**代码示例：**

```swift
// 宏示例（简化版）
@Observable
class User {
    var name: String = ""
    var age: Int = 0
}

// 不可复制类型
struct FileHandle: ~Copyable {
    let fd: Int32
    
    consuming func close() {
        // 关闭文件
    }
}
```

---

## 十一、常见面试问题

### 1. Swift 中如何实现单例模式？

**答案：**

使用 `static let` 实现线程安全的单例。

**代码示例：**

```swift
class Singleton {
    static let shared = Singleton()
    
    private init() {
        // 私有初始化器，防止外部创建实例
    }
    
    func doSomething() {
        print("Doing something...")
    }
}

// 使用
Singleton.shared.doSomething()
```

### 2. Swift 中如何实现观察者模式？

**答案：**

使用 `PropertyWrapper` 或 `Combine` 框架。

**代码示例：**

```swift
// 使用 PropertyWrapper
@propertyWrapper
struct Observable<Value> {
    private var value: Value
    private var observers: [(Value) -> Void] = []
    
    var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            observers.forEach { $0(newValue) }
        }
    }
    
    mutating func observe(_ observer: @escaping (Value) -> Void) {
        observers.append(observer)
    }
}

// 使用 Combine
import Combine

class ViewModel: ObservableObject {
    @Published var name: String = ""
}
```

### 3. Swift 中如何实现依赖注入？

**答案：**

通过构造函数或属性注入依赖。

**代码示例：**

```swift
// 协议定义
protocol NetworkService {
    func fetchData() -> String
}

// 实现
class APINetworkService: NetworkService {
    func fetchData() -> String {
        return "Data from API"
    }
}

// 依赖注入
class ViewModel {
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func loadData() {
        let data = networkService.fetchData()
        print(data)
    }
}

// 使用
let viewModel = ViewModel(networkService: APINetworkService())
```

### 4. Swift 中如何处理 JSON 解析？

**答案：**

使用 `Codable` 协议进行 JSON 编解码。

**代码示例：**

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// 编码
let user = User(id: 1, name: "John", email: "john@example.com")
let encoder = JSONEncoder()
if let jsonData = try? encoder.encode(user) {
    let jsonString = String(data: jsonData, encoding: .utf8)
    print(jsonString ?? "")
}

// 解码
let jsonString = """
{"id":1,"name":"John","email":"john@example.com"}
"""
let decoder = JSONDecoder()
if let jsonData = jsonString.data(using: .utf8),
   let user = try? decoder.decode(User.self, from: jsonData) {
    print(user.name)
}
```

---

## 十二、性能优化

### 1. Swift 中如何优化性能？

**答案：**

- 使用值类型（Struct）代替引用类型（Class）减少堆分配
- 使用 `lazy` 延迟加载
- 避免不必要的 `copy` 操作
- 使用 `inout` 减少值拷贝
- 合理使用 `final` 关键字
- 使用 `@inline` 内联函数

**代码示例：**

```swift
// 使用 final 优化
final class OptimizedClass {
    func method() {
        // 编译器可以优化，因为不会被继承
    }
}

// 使用值类型
struct Point {
    var x: Double
    var y: Double
}  // 更高效，栈分配

// 避免不必要的拷贝
func processLargeArray(_ array: inout [Int]) {
    // 使用 inout 避免拷贝
}
```

---

## 总结

Swift 作为一门现代编程语言，具有以下特点：

1. **类型安全**：强类型系统，编译时检查
2. **内存安全**：ARC 自动内存管理，Optional 避免空指针
3. **性能优秀**：编译时优化，接近 C 语言性能
4. **语法简洁**：现代语法，代码可读性强
5. **功能强大**：泛型、协议、扩展等高级特性
6. **并发支持**：async/await、Actor 等现代并发模型

掌握这些知识点，能够帮助你在 Swift 开发面试中脱颖而出。

