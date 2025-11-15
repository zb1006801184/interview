# iOS 面试题 - KVC

## 1. 什么是 KVC？

KVC（Key-Value Coding）是键值编码，是一种通过字符串访问对象属性的机制。它允许通过字符串形式的键（key）来访问对象的属性，而不需要直接调用 getter/setter 方法。

### 1.1 KVC 的特点

- 通过字符串访问属性
- 支持键路径（Key Path）
- 自动类型转换
- 支持集合操作

## 2. KVC 的基本用法？

### 2.1 设置值

```objc
// 使用 setValue:forKey:
[person setValue:@"John" forKey:@"name"];

// 使用 setValue:forKeyPath:
[person setValue:@"Beijing" forKeyPath:@"address.city"];
```

### 2.2 获取值

```objc
// 使用 valueForKey:
NSString *name = [person valueForKey:@"name"];

// 使用 valueForKeyPath:
NSString *city = [person valueForKeyPath:@"address.city"];
```

### 2.3 基本示例

```objc
@interface Person : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, strong) Address *address;
@end

// 使用 KVC
Person *person = [[Person alloc] init];
[person setValue:@"John" forKey:@"name"];
[person setValue:@25 forKey:@"age"];
NSString *name = [person valueForKey:@"name"];
NSNumber *age = [person valueForKey:@"age"];
```

## 3. KVC 的查找顺序？

### 3.1 setValue:forKey: 的查找顺序

1. 查找 `set<Key>:` 方法
2. 查找 `_set<Key>:` 方法
3. 查找 `setIs<Key>:` 方法
4. 如果找不到 setter，且 `accessInstanceVariablesDirectly` 返回 YES，则访问实例变量：
   - `_<key>`
   - `_is<Key>`
   - `<key>`
   - `is<Key>`
5. 如果都找不到，调用 `setValue:forUndefinedKey:`，默认抛出异常

### 3.2 valueForKey: 的查找顺序

1. 查找 `get<Key>` 方法
2. 查找 `<key>` 方法
3. 查找 `is<Key>` 方法
4. 查找 `_<key>` 方法
5. 如果找不到 getter，且 `accessInstanceVariablesDirectly` 返回 YES，则访问实例变量：
   - `_<key>`
   - `_is<Key>`
   - `<key>`
   - `is<Key>`
6. 如果都找不到，调用 `valueForUndefinedKey:`，默认抛出异常

### 3.3 代码示例

```objc
@interface Person : NSObject {
    NSString *_name;      // 优先级最高
    NSString *_isName;    // 优先级第二
    NSString *name;       // 优先级第三
    NSString *isName;     // 优先级最低
}
@end
```

## 4. 什么是键路径（Key Path）？

键路径允许通过点号（.）访问嵌套对象的属性。

### 4.1 基本用法

```objc
// 访问嵌套属性
NSString *city = [person valueForKeyPath:@"address.city"];

// 设置嵌套属性
[person setValue:@"Shanghai" forKeyPath:@"address.city"];
```

### 4.2 集合操作

```objc
// 获取数组中所有对象的某个属性
NSArray *names = [people valueForKeyPath:@"name"];

// 计算集合操作
NSNumber *avgAge = [people valueForKeyPath:@"@avg.age"];
NSNumber *maxAge = [people valueForKeyPath:@"@max.age"];
NSNumber *minAge = [people valueForKeyPath:@"@min.age"];
NSNumber *sumAge = [people valueForKeyPath:@"@sum.age"];
NSNumber *count = [people valueForKeyPath:@"@count"];
```

## 5. KVC 的集合操作符？

### 5.1 聚合操作符

- `@avg`：平均值
- `@count`：数量
- `@max`：最大值
- `@min`：最小值
- `@sum`：总和

### 5.2 数组操作符

- `@distinctUnionOfObjects`：去重
- `@unionOfObjects`：不去重
- `@distinctUnionOfArrays`：数组去重合并
- `@unionOfArrays`：数组合并
- `@distinctUnionOfSets`：集合去重合并

### 5.3 代码示例

```objc
NSArray *people = @[person1, person2, person3];

// 聚合操作
NSNumber *avgAge = [people valueForKeyPath:@"@avg.age"];
NSNumber *maxAge = [people valueForKeyPath:@"@max.age"];
NSNumber *minAge = [people valueForKeyPath:@"@min.age"];
NSNumber *sumAge = [people valueForKeyPath:@"@sum.age"];
NSNumber *count = [people valueForKeyPath:@"@count"];

// 数组操作
NSArray *names = [people valueForKeyPath:@"@distinctUnionOfObjects.name"];
NSArray *allNames = [people valueForKeyPath:@"@unionOfObjects.name"];
```

## 6. KVC 的类型转换？

### 6.1 自动类型转换

KVC 会自动进行类型转换：

```objc
// 字符串转数字
[person setValue:@"25" forKey:@"age"]; // NSString -> NSInteger

// 数字转字符串
NSString *ageStr = [person valueForKey:@"age"]; // NSInteger -> NSString

// NSNumber 转换
[person setValue:@25 forKey:@"age"]; // NSNumber -> NSInteger
NSNumber *ageNum = [person valueForKey:@"age"]; // NSInteger -> NSNumber
```

### 6.2 支持的类型转换

- 数值类型之间的转换
- 字符串和数值之间的转换
- NSValue 和基础类型的转换

## 7. KVC 的异常处理？

### 7.1 未定义的键

```objc
// 重写方法处理未定义的键
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"未定义的键：%@", key);
    // 不抛出异常，静默处理
}

- (id)valueForUndefinedKey:(NSString *)key {
    NSLog(@"未定义的键：%@", key);
    return nil;
}
```

### 7.2 nil 值处理

```objc
// 重写方法处理 nil 值
- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"age"]) {
        [self setValue:@0 forKey:key];
    } else {
        [super setNilValueForKey:key];
    }
}
```

## 8. KVC 的验证？

### 8.1 验证方法

```objc
// 验证值是否有效
NSError *error = nil;
BOOL isValid = [person validateValue:&value forKey:@"age" error:&error];
if (!isValid) {
    NSLog(@"验证失败：%@", error);
}
```

### 8.2 实现验证方法

```objc
- (BOOL)validateValue:(inout id *)ioValue forKey:(NSString *)inKey error:(out NSError **)outError {
    if ([inKey isEqualToString:@"age"]) {
        NSInteger age = [*ioValue integerValue];
        if (age < 0 || age > 150) {
            if (outError) {
                *outError = [NSError errorWithDomain:@"PersonErrorDomain" 
                                                code:1001 
                                            userInfo:@{NSLocalizedDescriptionKey: @"年龄必须在 0-150 之间"}];
            }
            return NO;
        }
    }
    return YES;
}

// 或者实现 validate<Key>:error: 方法
- (BOOL)validateAge:(id *)ioValue error:(NSError **)outError {
    NSInteger age = [*ioValue integerValue];
    if (age < 0 || age > 150) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"PersonErrorDomain" 
                                            code:1001 
                                        userInfo:@{NSLocalizedDescriptionKey: @"年龄必须在 0-150 之间"}];
        }
        return NO;
    }
    return YES;
}
```

## 9. KVC 与集合？

### 9.1 可变集合代理

```objc
// 获取可变数组代理
NSMutableArray *items = [person mutableArrayValueForKey:@"items"];
[items addObject:@"新项"]; // 会触发 KVO

// 获取可变集合代理
NSMutableSet *tags = [person mutableSetValueForKey:@"tags"];
[tags addObject:@"新标签"]; // 会触发 KVO
```

### 9.2 集合访问方法

```objc
// 实现集合访问方法
- (NSUInteger)countOfItems {
    return self.items.count;
}

- (id)objectInItemsAtIndex:(NSUInteger)index {
    return self.items[index];
}

- (void)insertObject:(id)object inItemsAtIndex:(NSUInteger)index {
    [self.items insertObject:object atIndex:index];
}

- (void)removeObjectFromItemsAtIndex:(NSUInteger)index {
    [self.items removeObjectAtIndex:index];
}
```

## 10. KVC 的性能影响？

### 10.1 性能开销

- 字符串查找和比较
- 方法查找和调用
- 类型转换

### 10.2 优化建议

- 避免频繁使用 KVC
- 缓存 key 字符串
- 直接调用 getter/setter 方法

## 11. KVC 的应用场景？

### 11.1 动态属性访问

```objc
// 根据配置动态设置属性
NSDictionary *config = @{@"name": @"John", @"age": @25};
for (NSString *key in config) {
    [person setValue:config[key] forKey:key];
}
```

### 11.2 数据绑定

```objc
// 将字典数据绑定到对象
NSDictionary *data = @{@"name": @"John", @"age": @25};
[person setValuesForKeysWithDictionary:data];
```

### 11.3 JSON 解析

```objc
// 使用 KVC 解析 JSON
NSDictionary *json = @{@"name": @"John", @"age": @25};
Person *person = [[Person alloc] init];
[person setValuesForKeysWithDictionary:json];
```

## 12. KVC 与 KVO 的关系？

### 12.1 KVC 触发 KVO

使用 KVC 设置值会触发 KVO：

```objc
[person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
[person setValue:@"New Name" forKey:@"name"]; // 会触发 KVO
```

### 12.2 KVO 依赖 KVC

KVO 的实现依赖于 KVC 的查找机制。

## 13. KVC 的注意事项？

### 13.1 键名必须正确

```objc
// 错误：键名拼写错误
[person setValue:@"John" forKey:@"nmae"]; // 会抛出异常

// 正确：键名正确
[person setValue:@"John" forKey:@"name"];
```

### 13.2 类型必须兼容

```objc
// 错误：类型不兼容
[person setValue:@"abc" forKey:@"age"]; // 可能出错

// 正确：类型兼容
[person setValue:@25 forKey:@"age"];
```

### 13.3 访问实例变量

```objc
// 控制是否允许访问实例变量
+ (BOOL)accessInstanceVariablesDirectly {
    return YES; // 允许访问实例变量（默认）
    // return NO; // 不允许访问实例变量
}
```

## 14. KVC 与字典的转换？

### 14.1 对象转字典

```objc
// 使用 KVC 获取所有属性值
NSArray *keys = @[@"name", @"age", @"address"];
NSDictionary *dict = [person dictionaryWithValuesForKeys:keys];
```

### 14.2 字典转对象

```objc
// 使用 KVC 设置所有属性值
NSDictionary *dict = @{@"name": @"John", @"age": @25};
[person setValuesForKeysWithDictionary:dict];
```

## 15. KVC 的常见问题？

### 15.1 键名错误导致崩溃

```objc
// 问题：键名不存在
[person setValue:@"John" forKey:@"wrongKey"]; // 抛出异常

// 解决：重写 setValue:forUndefinedKey:
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // 处理未定义的键
}
```

### 15.2 类型不兼容

```objc
// 问题：类型不兼容
[person setValue:@"abc" forKey:@"age"]; // 可能出错

// 解决：重写 setNilValueForKey: 或 validateValue:forKey:error:
```

### 15.3 性能问题

```objc
// 问题：频繁使用 KVC 影响性能
for (int i = 0; i < 10000; i++) {
    [person setValue:@(i) forKey:@"age"]; // 性能较差
}

// 解决：直接调用 setter
for (int i = 0; i < 10000; i++) {
    person.age = i; // 性能较好
}
```

## 16. KVC 的最佳实践？

### 16.1 合理使用 KVC

- 适合动态属性访问
- 适合数据绑定
- 不适合频繁调用的场景

### 16.2 处理异常

```objc
// 重写异常处理方法
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // 处理未定义的键
}

- (id)valueForUndefinedKey:(NSString *)key {
    // 返回默认值
    return nil;
}
```

### 16.3 验证数据

```objc
// 实现验证方法
- (BOOL)validateValue:(inout id *)ioValue forKey:(NSString *)inKey error:(out NSError **)outError {
    // 验证逻辑
    return YES;
}
```

## 17. KVC 与 Swift？

### 17.1 Swift 中的 KVC

Swift 中也可以使用 KVC，但需要：
- 类继承自 NSObject
- 属性使用 `@objc` 标记
- 使用 `#keyPath` 获取键路径

### 17.2 代码示例

```swift
class Person: NSObject {
    @objc var name: String = ""
    @objc var age: Int = 0
}

let person = Person()
person.setValue("John", forKey: "name")
let name = person.value(forKey: "name")

// 使用 #keyPath
let keyPath = #keyPath(Person.name)
person.setValue("John", forKeyPath: keyPath)
```

## 18. KVC 的常见面试题总结

1. **什么是 KVC？** - 键值编码，通过字符串访问属性
2. **KVC 的基本用法？** - setValue:forKey:、valueForKey:
3. **KVC 的查找顺序？** - setter/getter、实例变量
4. **什么是键路径？** - 通过点号访问嵌套属性
5. **KVC 的集合操作符？** - @avg、@max、@min、@sum、@count
6. **KVC 的类型转换？** - 自动类型转换
7. **KVC 的异常处理？** - setValue:forUndefinedKey:、valueForUndefinedKey:
8. **KVC 的验证？** - validateValue:forKey:error:
9. **KVC 与集合？** - mutableArrayValueForKey:、mutableSetValueForKey:
10. **KVC 的性能影响？** - 字符串查找、方法查找
11. **KVC 的应用场景？** - 动态属性访问、数据绑定
12. **KVC 与 KVO 的关系？** - KVC 触发 KVO
13. **KVC 的注意事项？** - 键名正确、类型兼容

## 19. KVC 的高级用法

### 19.1 自定义键路径

```objc
// 实现 valueForKeyPath: 的自定义逻辑
- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath isEqualToString:@"fullName"]) {
        return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    }
    return [super valueForKeyPath:keyPath];
}
```

### 19.2 集合过滤

```objc
// 使用键路径过滤集合
NSArray *adults = [people valueForKeyPath:@"@distinctUnionOfObjects.name"];
NSArray *filtered = [people filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"age >= 18"]];
```

### 19.3 动态属性访问

```objc
// 根据字符串动态访问属性
NSString *propertyName = @"name";
id value = [person valueForKey:propertyName];
[person setValue:@"New Name" forKey:propertyName];
```

## 20. KVC 的实现原理？

### 20.1 查找机制

KVC 通过 Runtime 的机制查找 setter/getter 方法和实例变量。

### 20.2 类型转换

KVC 使用 `NSNumber` 和 `NSValue` 进行类型转换。

### 20.3 集合代理

`mutableArrayValueForKey:` 等方法返回代理对象，操作代理对象会触发 KVO。

