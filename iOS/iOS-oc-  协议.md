# iOS 面试题 - 协议

## 1. 什么是协议（Protocol）？

协议（Protocol）是 Objective-C 和 Swift 中定义方法、属性和其他需求的蓝图。它类似于其他语言中的接口（Interface），用于声明一组方法，但不提供实现。

### 1.1 协议的特点

- 定义方法、属性和其他需求的规范
- 不提供具体实现（Swift 中可以有默认实现）
- 类、结构体、枚举都可以遵循协议
- 支持多协议遵循
- 可以实现面向协议编程（Protocol-Oriented Programming）

### 1.2 Objective-C 协议定义

```objc
// 协议定义
@protocol MyProtocol <NSObject>
@required  // 必须实现的方法
- (void)requiredMethod;

@optional  // 可选实现的方法
- (void)optionalMethod;
@end

// 类遵循协议
@interface MyClass : NSObject <MyProtocol>
@end
```

### 1.3 Swift 协议定义

```swift
// 协议定义
protocol MyProtocol {
    // 必须实现的方法
    func requiredMethod()
    
    // 可选方法（需要 @objc 标记）
    @objc optional func optionalMethod()
    
    // 属性要求
    var name: String { get set }
    var age: Int { get }
}

// 类遵循协议
class MyClass: MyProtocol {
    var name: String = ""
    var age: Int = 0
    
    func requiredMethod() {
        print("实现必须方法")
    }
}
```

## 2. 协议中的 @required 和 @optional 有什么区别？

### 2.1 @required（必须实现）

- 遵循协议的类必须实现这些方法
- 如果不实现，编译器会发出警告
- 默认情况下，协议中的方法都是 @required

```objc
@protocol DataSource <NSObject>
@required
- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
@end
```

### 2.2 @optional（可选实现）

- 遵循协议的类可以选择性实现这些方法
- 调用前需要检查方法是否存在
- 使用 `respondsToSelector:` 方法检查

```objc
@protocol DataSource <NSObject>
@optional
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

// 调用前检查
if ([self.dataSource respondsToSelector:@selector(didSelectRowAtIndexPath:)]) {
    [self.dataSource didSelectRowAtIndexPath:indexPath];
}
```

## 3. 协议中的属性如何定义？

### 3.1 Objective-C 协议属性

```objc
@protocol PersonProtocol <NSObject>
// 只读属性
@property (nonatomic, readonly) NSString *name;

// 读写属性
@property (nonatomic, readwrite) NSInteger age;
@end
```

### 3.2 Swift 协议属性

```swift
protocol PersonProtocol {
    // 只读属性
    var name: String { get }
    
    // 读写属性
    var age: Int { get set }
    
    // 类型属性
    static var species: String { get }
}
```

## 4. 协议继承是什么？

协议可以继承其他协议，遵循子协议的类必须实现父协议和子协议中的所有方法。

### 4.1 Objective-C 协议继承

```objc
@protocol BaseProtocol <NSObject>
- (void)baseMethod;
@end

@protocol DerivedProtocol <BaseProtocol>
- (void)derivedMethod;
@end

// 遵循 DerivedProtocol 的类必须实现 baseMethod 和 derivedMethod
@interface MyClass : NSObject <DerivedProtocol>
@end
```

### 4.2 Swift 协议继承

```swift
protocol BaseProtocol {
    func baseMethod()
}

protocol DerivedProtocol: BaseProtocol {
    func derivedMethod()
}

class MyClass: DerivedProtocol {
    func baseMethod() {
        print("基础方法")
    }
    
    func derivedMethod() {
        print("派生方法")
    }
}
```

## 5. 什么是协议扩展（Protocol Extension）？

协议扩展是 Swift 的特性，允许为协议提供默认实现，实现面向协议编程。

### 5.1 协议扩展的基本用法

```swift
protocol Drawable {
    func draw()
}

// 为协议提供默认实现
extension Drawable {
    func draw() {
        print("默认绘制")
    }
    
    // 可以添加新方法
    func drawWithColor(_ color: String) {
        print("使用 \(color) 颜色绘制")
    }
}

// 遵循协议的类可以直接使用默认实现
class Circle: Drawable {
    // 可以不实现 draw()，使用默认实现
}

let circle = Circle()
circle.draw()  // 输出：默认绘制
circle.drawWithColor("红色")  // 输出：使用 红色 颜色绘制
```

### 5.2 协议扩展的条件约束

```swift
extension Collection where Element: Equatable {
    func allEqual() -> Bool {
        guard let first = first else { return true }
        return allSatisfy { $0 == first }
    }
}

let numbers = [1, 1, 1, 1]
print(numbers.allEqual())  // true
```

## 6. 协议作为类型使用

协议可以作为类型使用，实现多态。

### 6.1 作为变量类型

```swift
protocol Animal {
    func makeSound()
}

class Dog: Animal {
    func makeSound() {
        print("汪汪")
    }
}

class Cat: Animal {
    func makeSound() {
        print("喵喵")
    }
}

// 协议作为类型
var animal: Animal = Dog()
animal.makeSound()  // 汪汪

animal = Cat()
animal.makeSound()  // 喵喵
```

### 6.2 作为集合元素类型

```swift
let animals: [Animal] = [Dog(), Cat()]
animals.forEach { $0.makeSound() }
```

## 7. 协议中的关联类型（Associated Types）

关联类型是 Swift 协议中的占位符类型，让协议更加灵活。

### 7.1 关联类型定义

```swift
protocol Container {
    associatedtype Item
    mutating func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}

// 实现协议时指定关联类型
struct IntStack: Container {
    typealias Item = Int
    var items: [Int] = []
    
    mutating func append(_ item: Int) {
        items.append(item)
    }
    
    var count: Int {
        return items.count
    }
    
    subscript(i: Int) -> Int {
        return items[i]
    }
}
```

### 7.2 关联类型的类型约束

```swift
protocol Container {
    associatedtype Item: Equatable
    mutating func append(_ item: Item)
}

// Item 必须是 Equatable 类型
```

## 8. 协议组合（Protocol Composition）

可以组合多个协议，要求类型同时遵循多个协议。

### 8.1 Swift 协议组合

```swift
protocol Named {
    var name: String { get }
}

protocol Aged {
    var age: Int { get }
}

// 协议组合
func wishHappyBirthday(to celebrator: Named & Aged) {
    print("生日快乐，\(celebrator.name)，\(celebrator.age) 岁！")
}

struct Person: Named, Aged {
    var name: String
    var age: Int
}

let person = Person(name: "张三", age: 25)
wishHappyBirthday(to: person)
```

### 8.2 Objective-C 协议组合

```objc
// 遵循多个协议
@interface MyClass : NSObject <Protocol1, Protocol2>
@end

// 检查是否遵循协议
if ([object conformsToProtocol:@protocol(MyProtocol)]) {
    // 对象遵循协议
}
```

## 9. 协议和代理模式（Delegate Pattern）

代理模式是 iOS 开发中最常用的设计模式之一，通过协议实现。

### 9.1 代理模式实现

```objc
// 定义协议
@protocol UITableViewDelegate <NSObject>
@optional
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

// 使用代理
@interface ViewController : UIViewController <UITableViewDelegate>
@property (nonatomic, weak) id<UITableViewDelegate> delegate;
@end

@implementation ViewController
- (void)someMethod {
    if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [self.delegate tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}
@end
```

### 9.2 为什么代理属性使用 weak？

```objc
@property (nonatomic, weak) id<MyDelegate> delegate;
```

- 避免循环引用：对象 A 持有对象 B，对象 B 的 delegate 指向对象 A
- 如果使用 strong，会导致循环引用，内存无法释放
- weak 引用不会增加引用计数，避免循环引用

## 10. 协议和面向协议编程（POP）

面向协议编程是 Swift 的核心特性，强调使用协议而非类继承。

### 10.1 POP vs OOP

```swift
// 面向对象编程（OOP）- 使用继承
class Animal {
    func makeSound() {
        fatalError("子类必须实现")
    }
}

class Dog: Animal {
    override func makeSound() {
        print("汪汪")
    }
}

// 面向协议编程（POP）- 使用协议
protocol Animal {
    func makeSound()
}

struct Dog: Animal {
    func makeSound() {
        print("汪汪")
    }
}
```

### 10.2 POP 的优势

- **灵活性**：值类型（结构体、枚举）也可以遵循协议
- **组合优于继承**：可以遵循多个协议
- **默认实现**：协议扩展提供默认实现
- **测试友好**：更容易进行单元测试

## 11. 协议中的方法冲突处理

当类遵循多个协议，且这些协议有相同的方法签名时，需要明确实现。

### 11.1 方法冲突解决

```swift
protocol ProtocolA {
    func method()
}

protocol ProtocolB {
    func method()
}

class MyClass: ProtocolA, ProtocolB {
    // 一个实现同时满足两个协议
    func method() {
        print("实现方法")
    }
}
```

### 11.2 使用协议扩展区分实现

```swift
protocol ProtocolA {
    func method()
}

protocol ProtocolB {
    func method()
}

extension ProtocolA {
    func method() {
        print("ProtocolA 的实现")
    }
}

extension ProtocolB {
    func method() {
        print("ProtocolB 的实现")
    }
}

class MyClass: ProtocolA, ProtocolB {
    // 必须明确实现，否则会有歧义
    func method() {
        print("MyClass 的实现")
    }
}
```

## 12. 协议中的 Self 和 Self 类型

### 12.1 Self 关键字

```swift
protocol Copyable {
    func copy() -> Self
}

class MyClass: Copyable {
    func copy() -> Self {
        return type(of: self).init()
    }
    
    required init() {}
}
```

### 12.2 Self 类型约束

```swift
protocol Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool
}
```

## 13. 协议在 SwiftUI 中的应用

### 13.1 View 协议

```swift
protocol View {
    associatedtype Body: View
    var body: Self.Body { get }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

### 13.2 ObservableObject 协议

```swift
protocol ObservableObject: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

class ViewModel: ObservableObject {
    @Published var name: String = ""
}
```

## 14. 常见协议面试题

### 14.1 协议和类的区别？

| 特性 | 协议 | 类 |
|------|------|-----|
| 实例化 | 不能直接实例化 | 可以实例化 |
| 继承 | 支持协议继承 | 支持类继承 |
| 多继承 | 支持多协议遵循 | 不支持多继承 |
| 存储属性 | Swift 中不支持 | 支持 |
| 值类型 | 结构体、枚举可遵循 | 只能是引用类型 |

### 14.2 什么时候使用协议，什么时候使用类？

**使用协议的情况：**
- 需要定义接口规范
- 实现多态
- 值类型需要共享行为
- 实现代理模式
- 面向协议编程

**使用类的情况：**
- 需要存储属性
- 需要引用语义
- 需要继承已有类
- 需要类型标识（identity）

### 14.3 协议扩展和类扩展的区别？

```swift
// 协议扩展：为所有遵循协议的类型提供默认实现
extension MyProtocol {
    func defaultMethod() {
        print("默认实现")
    }
}

// 类扩展：为特定类添加功能
extension MyClass {
    func newMethod() {
        print("新方法")
    }
}
```

## 15. 协议的实际应用场景

### 15.1 数据源模式（DataSource Pattern）

```swift
protocol DataSource {
    func numberOfSections() -> Int
    func numberOfRows(in section: Int) -> Int
    func item(at indexPath: IndexPath) -> Any?
}

class TableViewController: DataSource {
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        return 10
    }
    
    func item(at indexPath: IndexPath) -> Any? {
        return nil
    }
}
```

### 15.2 策略模式（Strategy Pattern）

```swift
protocol PaymentStrategy {
    func pay(amount: Double)
}

class CreditCardPayment: PaymentStrategy {
    func pay(amount: Double) {
        print("使用信用卡支付 \(amount)")
    }
}

class AlipayPayment: PaymentStrategy {
    func pay(amount: Double) {
        print("使用支付宝支付 \(amount)")
    }
}

class PaymentProcessor {
    var strategy: PaymentStrategy
    
    init(strategy: PaymentStrategy) {
        self.strategy = strategy
    }
    
    func processPayment(amount: Double) {
        strategy.pay(amount: amount)
    }
}
```

### 15.3 工厂模式（Factory Pattern）

```swift
protocol Animal {
    func makeSound()
}

class Dog: Animal {
    func makeSound() {
        print("汪汪")
    }
}

class Cat: Animal {
    func makeSound() {
        print("喵喵")
    }
}

protocol AnimalFactory {
    func createAnimal() -> Animal
}

class DogFactory: AnimalFactory {
    func createAnimal() -> Animal {
        return Dog()
    }
}

class CatFactory: AnimalFactory {
    func createAnimal() -> Animal {
        return Cat()
    }
}
```

## 16. 协议的性能考虑

### 16.1 协议类型的内存布局

- 协议类型使用存在容器（Existential Container）存储
- 小值类型（<= 3 个指针大小）直接存储
- 大值类型使用间接存储，增加内存开销

### 16.2 协议类型擦除（Type Erasure）

```swift
// 使用 Any 进行类型擦除
let animals: [Any] = [Dog(), Cat()]

// 使用泛型避免类型擦除
func process<T: Animal>(_ animal: T) {
    animal.makeSound()
}
```

## 17. 协议测试

### 17.1 协议 Mock

```swift
protocol NetworkService {
    func fetchData(completion: @escaping (Data?) -> Void)
}

// 真实实现
class RealNetworkService: NetworkService {
    func fetchData(completion: @escaping (Data?) -> Void) {
        // 网络请求
    }
}

// Mock 实现用于测试
class MockNetworkService: NetworkService {
    var mockData: Data?
    
    func fetchData(completion: @escaping (Data?) -> Void) {
        completion(mockData)
    }
}
```

## 18. 总结

协议是 iOS 开发中非常重要的概念，它提供了：

1. **接口定义**：规范类的行为
2. **多态支持**：实现运行时多态
3. **代码解耦**：降低模块间耦合
4. **灵活设计**：支持面向协议编程
5. **测试友好**：便于 Mock 和测试

掌握协议的使用对于 iOS 开发至关重要，特别是在 Swift 中，协议是语言的核心特性之一。

