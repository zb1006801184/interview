# Flutter 面试题 - 异步编程

## 目录
1. [异步编程基础](#异步编程基础)
2. [Future 详解](#future-详解)
3. [async/await](#asyncawait)
4. [Stream 详解](#stream-详解)
5. [Isolate 多线程](#isolate-多线程)
6. [异步编程最佳实践](#异步编程最佳实践)
7. [常见面试题](#常见面试题)

---

## 异步编程基础

### 1. 什么是异步编程？

异步编程是一种编程范式，允许程序在等待某些操作（如网络请求、文件读写）完成时继续执行其他任务，而不是阻塞等待。

#### 1.1 为什么需要异步编程？

**在 Flutter 中的应用场景：**
- **网络请求**：API 调用通常需要几秒时间
- **文件操作**：读写文件可能耗时
- **数据库操作**：查询和写入操作
- **图像处理**：解码和压缩图片
- **定时任务**：延迟执行某些操作

**同步 vs 异步：**

```dart
// 同步操作 - 会阻塞 UI 线程
void syncOperation() {
  // 假设这是一个耗时 3 秒的操作
  for (int i = 0; i < 1000000000; i++) {
    // 计算操作
  }
  print('完成');
  // UI 会在这 3 秒内冻结
}

// 异步操作 - 不会阻塞 UI 线程
Future<void> asyncOperation() async {
  await Future.delayed(Duration(seconds: 3));
  print('完成');
  // UI 在这 3 秒内仍然可以响应用户操作
}
```

#### 1.2 Dart 的异步模型

Dart 使用**事件循环（Event Loop）**来处理异步操作：

```
┌─────────────────────────────────┐
│      Event Loop (事件循环)       │
├─────────────────────────────────┤
│  1. Microtask Queue (微任务队列) │
│  2. Event Queue (事件队列)       │
└─────────────────────────────────┘
```

**执行顺序：**
1. 先执行所有微任务（Microtask）
2. 再执行事件队列中的任务
3. 循环往复

```dart
void main() {
  print('1');
  
  // 添加到事件队列
  Future(() => print('2'));
  
  // 添加到微任务队列
  scheduleMicrotask(() => print('3'));
  
  print('4');
  
  // 输出顺序：1, 4, 3, 2
}
```

---

## Future 详解

### 2. Future 是什么？

`Future` 是 Dart 中表示异步操作结果的类，它代表一个可能在未来某个时刻完成（或失败）的计算。

#### 2.1 Future 的基本使用

```dart
// 创建一个立即完成的 Future
Future<String> future1 = Future.value('Hello');

// 创建一个延迟完成的 Future
Future<String> future2 = Future.delayed(
  Duration(seconds: 2),
  () => 'World',
);

// 创建一个异步函数返回的 Future
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 1));
  return 'Data';
}
```

#### 2.2 Future 的状态

Future 有三种状态：

1. **未完成（Uncompleted）**：操作还在进行中
2. **已完成（Completed with value）**：操作成功完成，有返回值
3. **已完成（Completed with error）**：操作失败，有错误信息

```dart
Future<String> future = fetchData();

// 检查状态
future.then((value) {
  print('成功: $value'); // 已完成状态
}).catchError((error) {
  print('失败: $error'); // 错误状态
});
```

#### 2.3 Future 的链式调用

```dart
Future<String> fetchUser() {
  return Future.delayed(Duration(seconds: 1), () => 'User123');
}

Future<String> fetchProfile(String userId) {
  return Future.delayed(Duration(seconds: 1), () => 'Profile of $userId');
}

// 链式调用
fetchUser()
  .then((userId) {
    print('获取到用户: $userId');
    return fetchProfile(userId);
  })
  .then((profile) {
    print('获取到资料: $profile');
  })
  .catchError((error) {
    print('错误: $error');
  });
```

#### 2.4 Future 的常用方法

**1. then() - 处理成功结果**

```dart
Future<int> getNumber() {
  return Future.value(42);
}

getNumber().then((value) {
  print('数字是: $value');
});
```

**2. catchError() - 处理错误**

```dart
Future<int> getNumber() {
  return Future.error('出错了');
}

getNumber()
  .then((value) => print(value))
  .catchError((error) => print('错误: $error'));
```

**3. whenComplete() - 无论成功失败都执行**

```dart
Future<int> getNumber() {
  return Future.value(42);
}

getNumber()
  .then((value) => print(value))
  .catchError((error) => print(error))
  .whenComplete(() => print('完成'));
```

**4. timeout() - 设置超时**

```dart
Future<String> fetchData() {
  return Future.delayed(Duration(seconds: 5), () => 'Data');
}

fetchData()
  .timeout(Duration(seconds: 3))
  .then((value) => print(value))
  .catchError((error) {
    if (error is TimeoutException) {
      print('请求超时');
    }
  });
```

**5. Future.wait() - 等待多个 Future**

```dart
Future<String> fetchUser() {
  return Future.delayed(Duration(seconds: 1), () => 'User');
}

Future<String> fetchPosts() {
  return Future.delayed(Duration(seconds: 2), () => 'Posts');
}

Future<String> fetchComments() {
  return Future.delayed(Duration(seconds: 1), () => 'Comments');
}

// 等待所有 Future 完成
Future.wait([
  fetchUser(),
  fetchPosts(),
  fetchComments(),
]).then((results) {
  print('所有数据: $results'); // ['User', 'Posts', 'Comments']
});
```

**6. Future.any() - 等待任意一个 Future 完成**

```dart
Future<String> fastRequest() {
  return Future.delayed(Duration(seconds: 1), () => 'Fast');
}

Future<String> slowRequest() {
  return Future.delayed(Duration(seconds: 3), () => 'Slow');
}

Future.any([fastRequest(), slowRequest()])
  .then((result) => print('最快的结果: $result')); // 'Fast'
```

**7. Future.forEach() - 顺序执行多个 Future**

```dart
List<String> urls = ['url1', 'url2', 'url3'];

Future.forEach(urls, (url) async {
  await Future.delayed(Duration(seconds: 1));
  print('处理: $url');
});
// 顺序执行，每个间隔 1 秒
```

---

## async/await

### 3. async/await 语法

`async/await` 是 Dart 提供的语法糖，让异步代码看起来像同步代码一样。

#### 3.1 基本语法

```dart
// 使用 async 标记异步函数
Future<String> fetchData() async {
  // 使用 await 等待异步操作完成
  String data = await Future.delayed(
    Duration(seconds: 1),
    () => 'Data',
  );
  return data;
}

// 调用异步函数
void main() async {
  String result = await fetchData();
  print(result); // 'Data'
}
```

#### 3.2 async/await vs then()

```dart
// 使用 then() 的方式
Future<String> fetchUser() {
  return Future.delayed(Duration(seconds: 1), () => 'User123');
}

fetchUser()
  .then((userId) {
    return fetchProfile(userId);
  })
  .then((profile) {
    print(profile);
  })
  .catchError((error) {
    print(error);
  });

// 使用 async/await 的方式（更清晰）
Future<void> loadData() async {
  try {
    String userId = await fetchUser();
    String profile = await fetchProfile(userId);
    print(profile);
  } catch (error) {
    print(error);
  }
}
```

#### 3.3 错误处理

```dart
// 使用 try-catch
Future<void> fetchData() async {
  try {
    String data = await Future.delayed(
      Duration(seconds: 1),
      () => throw Exception('网络错误'),
    );
    print(data);
  } catch (e) {
    print('错误: $e');
  }
}

// 使用 catchError
Future<void> fetchData() async {
  await Future.delayed(
    Duration(seconds: 1),
    () => throw Exception('网络错误'),
  ).catchError((error) {
    print('错误: $error');
  });
}
```

#### 3.4 并发执行

```dart
// 顺序执行（慢）
Future<void> sequential() async {
  String user = await fetchUser();      // 等待 1 秒
  String posts = await fetchPosts();    // 等待 2 秒
  String comments = await fetchComments(); // 等待 1 秒
  // 总共 4 秒
}

// 并发执行（快）
Future<void> concurrent() async {
  final results = await Future.wait([
    fetchUser(),      // 同时开始
    fetchPosts(),     // 同时开始
    fetchComments(),  // 同时开始
  ]);
  // 总共 2 秒（最长的那个）
}
```

#### 3.5 async 函数的返回值

```dart
// async 函数总是返回 Future
Future<String> asyncFunction() async {
  return 'Hello'; // 自动包装成 Future<String>
}

// 等价于
Future<String> asyncFunction() {
  return Future.value('Hello');
}

// 如果返回 Future，不会双重包装
Future<String> asyncFunction() async {
  return Future.value('Hello'); // 仍然是 Future<String>
}
```

---

## Stream 详解

### 4. Stream 是什么？

`Stream` 是 Dart 中表示异步数据序列的类，它可以产生多个值，而不是像 Future 那样只产生一个值。

#### 4.1 Stream 的基本使用

```dart
// 创建一个 Stream
Stream<int> countStream() async* {
  for (int i = 1; i <= 5; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i; // 产生一个值
  }
}

// 监听 Stream
void main() async {
  await for (int value in countStream()) {
    print(value); // 1, 2, 3, 4, 5
  }
}
```

#### 4.2 Stream 的创建方式

**1. 使用 async* 生成器**

```dart
Stream<int> numbers() async* {
  for (int i = 0; i < 5; i++) {
    yield i;
    await Future.delayed(Duration(milliseconds: 500));
  }
}
```

**2. 使用 StreamController**

```dart
StreamController<String> controller = StreamController<String>();

// 获取 Stream
Stream<String> stream = controller.stream;

// 添加数据
controller.add('Hello');
controller.add('World');

// 关闭 Stream
controller.close();

// 监听
stream.listen((data) {
  print(data);
});
```

**3. 使用 Stream.fromIterable()**

```dart
Stream<int> stream = Stream.fromIterable([1, 2, 3, 4, 5]);

stream.listen((value) {
  print(value);
});
```

**4. 使用 Stream.periodic()**

```dart
// 每秒产生一个值
Stream<int> stream = Stream.periodic(
  Duration(seconds: 1),
  (count) => count,
).take(5); // 只取前 5 个

stream.listen((value) {
  print(value); // 0, 1, 2, 3, 4
});
```

#### 4.3 Stream 的监听

**1. listen() 方法**

```dart
Stream<int> stream = countStream();

stream.listen(
  (value) => print('数据: $value'),      // onData
  onError: (error) => print('错误: $error'), // onError
  onDone: () => print('完成'),           // onDone
  cancelOnError: false,                  // 错误时不取消订阅
);
```

**2. await for 循环**

```dart
Stream<int> stream = countStream();

await for (int value in stream) {
  print(value);
}
// 循环结束后自动取消订阅
```

**3. forEach() 方法**

```dart
Stream<int> stream = countStream();

await stream.forEach((value) {
  print(value);
});
```

#### 4.4 Stream 的常用操作符

**1. map() - 转换数据**

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3]);

numbers
  .map((n) => n * 2)
  .listen((value) => print(value)); // 2, 4, 6
```

**2. where() - 过滤数据**

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3, 4, 5]);

numbers
  .where((n) => n % 2 == 0)
  .listen((value) => print(value)); // 2, 4
```

**3. take() - 取前 n 个**

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3, 4, 5]);

numbers
  .take(3)
  .listen((value) => print(value)); // 1, 2, 3
```

**4. skip() - 跳过前 n 个**

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3, 4, 5]);

numbers
  .skip(2)
  .listen((value) => print(value)); // 3, 4, 5
```

**5. expand() - 展开数据**

```dart
Stream<List<int>> lists = Stream.fromIterable([
  [1, 2],
  [3, 4],
]);

lists
  .expand((list) => list)
  .listen((value) => print(value)); // 1, 2, 3, 4
```

**6. reduce() - 累积计算**

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3, 4, 5]);

int sum = await numbers.reduce((a, b) => a + b);
print(sum); // 15
```

**7. fold() - 带初始值的累积**

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3]);

int sum = await numbers.fold(10, (a, b) => a + b);
print(sum); // 16 (10 + 1 + 2 + 3)
```

**8. asyncMap() - 异步转换**

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3]);

numbers
  .asyncMap((n) async {
    await Future.delayed(Duration(seconds: 1));
    return n * 2;
  })
  .listen((value) => print(value));
```

**9. debounceTime() - 防抖**

```dart
// 需要导入 rxdart 包
import 'package:rxdart/rxdart.dart';

Stream<String> searchStream = Stream.periodic(
  Duration(milliseconds: 100),
  (i) => 'search $i',
);

searchStream
  .debounceTime(Duration(milliseconds: 500))
  .listen((value) => print(value));
```

**10. distinct() - 去重**

```dart
Stream<int> numbers = Stream.fromIterable([1, 1, 2, 2, 3, 3]);

numbers
  .distinct()
  .listen((value) => print(value)); // 1, 2, 3
```

#### 4.5 StreamController 的使用

```dart
class DataService {
  final _controller = StreamController<String>.broadcast();
  
  // 对外暴露 Stream
  Stream<String> get stream => _controller.stream;
  
  // 添加数据
  void addData(String data) {
    _controller.add(data);
  }
  
  // 添加错误
  void addError(Object error) {
    _controller.addError(error);
  }
  
  // 关闭 Stream
  void close() {
    _controller.close();
  }
}

// 使用
void main() {
  final service = DataService();
  
  // 多个监听者
  service.stream.listen((data) => print('监听者1: $data'));
  service.stream.listen((data) => print('监听者2: $data'));
  
  service.addData('Hello');
  service.addData('World');
  
  service.close();
}
```

**单订阅 vs 广播 Stream：**

```dart
// 单订阅 Stream（默认）
StreamController<String> singleController = StreamController<String>();
// 只能有一个监听者

// 广播 Stream
StreamController<String> broadcastController = StreamController<String>.broadcast();
// 可以有多个监听者
```

---

## Isolate 多线程

### 5. Isolate 是什么？

`Isolate` 是 Dart 中的并发模型，每个 Isolate 都有自己独立的内存空间，不共享状态，通过消息传递进行通信。

#### 5.1 为什么需要 Isolate？

Dart 是单线程模型，所有代码都在主 Isolate（UI 线程）中执行。如果执行耗时操作，会阻塞 UI。

**使用场景：**
- 大量计算（图像处理、数据解析）
- 文件 I/O 操作
- 网络请求（虽然通常用 async/await，但大量并发时可用 Isolate）

#### 5.2 创建 Isolate

**1. 使用 Isolate.spawn()**

```dart
import 'dart:isolate';

// 在 Isolate 中执行的函数
void isolateFunction(SendPort sendPort) {
  // 执行耗时操作
  int result = 0;
  for (int i = 0; i < 1000000000; i++) {
    result += i;
  }
  
  // 发送结果
  sendPort.send(result);
}

// 创建 Isolate
void main() async {
  ReceivePort receivePort = ReceivePort();
  
  Isolate isolate = await Isolate.spawn(
    isolateFunction,
    receivePort.sendPort,
  );
  
  // 接收消息
  receivePort.listen((message) {
    print('结果: $message');
    receivePort.close();
    isolate.kill();
  });
}
```

**2. 使用 compute() 函数（推荐）**

```dart
import 'package:flutter/foundation.dart';

// 计算函数（必须是顶级函数或静态方法）
int heavyComputation(int n) {
  int result = 0;
  for (int i = 0; i < n; i++) {
    result += i;
  }
  return result;
}

// 使用 compute
void main() async {
  int result = await compute(heavyComputation, 1000000000);
  print('结果: $result');
}
```

#### 5.3 Isolate 之间的通信

**双向通信：**

```dart
import 'dart:isolate';

// Isolate 函数
void isolateFunction(SendPort mainSendPort) async {
  ReceivePort isolateReceivePort = ReceivePort();
  
  // 发送自己的 ReceivePort 给主 Isolate
  mainSendPort.send(isolateReceivePort.sendPort);
  
  // 接收主 Isolate 的消息
  await for (var message in isolateReceivePort) {
    if (message is SendPort) {
      // 收到主 Isolate 的 SendPort
      message.send('Hello from Isolate');
    } else {
      // 处理其他消息
      print('Isolate 收到: $message');
      mainSendPort.send('Echo: $message');
    }
  }
}

void main() async {
  ReceivePort mainReceivePort = ReceivePort();
  
  Isolate isolate = await Isolate.spawn(
    isolateFunction,
    mainReceivePort.sendPort,
  );
  
  // 接收 Isolate 的 SendPort
  SendPort? isolateSendPort;
  await for (var message in mainReceivePort) {
    if (message is SendPort) {
      isolateSendPort = message;
      // 发送消息给 Isolate
      isolateSendPort.send('Hello from main');
    } else {
      print('主 Isolate 收到: $message');
      isolate.kill();
      break;
    }
  }
}
```

#### 5.4 Isolate 的限制

**不能传递的数据类型：**
- 函数（除了顶级函数和静态方法）
- 闭包
- 某些对象（需要可序列化）

**解决方案：**
- 使用 `Isolate.spawnUri()` 加载独立的 Dart 文件
- 只传递可序列化的数据（基本类型、List、Map 等）

---

## 异步编程最佳实践

### 6. 最佳实践

#### 6.1 避免阻塞 UI 线程

```dart
// ❌ 错误：阻塞 UI
void badExample() {
  for (int i = 0; i < 1000000000; i++) {
    // 耗时计算
  }
}

// ✅ 正确：使用 Isolate
void goodExample() async {
  int result = await compute(heavyComputation, 1000000000);
}
```

#### 6.2 合理使用 async/await

```dart
// ❌ 错误：不必要的 async
Future<String> badExample() async {
  return Future.value('Hello');
}

// ✅ 正确：直接返回 Future
Future<String> goodExample() {
  return Future.value('Hello');
}

// ✅ 正确：需要 await 时使用 async
Future<String> goodExample2() async {
  String data = await fetchData();
  return data;
}
```

#### 6.3 错误处理

```dart
// ✅ 使用 try-catch
Future<void> fetchData() async {
  try {
    String data = await api.getData();
    // 处理数据
  } catch (e) {
    // 处理错误
    print('错误: $e');
  }
}

// ✅ 使用 catchError
Future<void> fetchData() async {
  await api.getData()
    .then((data) {
      // 处理数据
    })
    .catchError((error) {
      // 处理错误
      print('错误: $error');
    });
}
```

#### 6.4 并发控制

```dart
// ✅ 使用 Future.wait 并发执行
Future<void> loadAllData() async {
  final results = await Future.wait([
    fetchUser(),
    fetchPosts(),
    fetchComments(),
  ]);
}

// ✅ 限制并发数量
Future<void> loadWithLimit() async {
  const maxConcurrent = 3;
  final futures = <Future>[];
  
  for (var url in urls) {
    if (futures.length >= maxConcurrent) {
      await Future.any(futures);
      futures.removeWhere((f) => f.isCompleted);
    }
    futures.add(fetchUrl(url));
  }
  
  await Future.wait(futures);
}
```

#### 6.5 Stream 资源管理

```dart
// ✅ 记得取消订阅
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {
      // 处理数据
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel(); // 取消订阅
    super.dispose();
  }
}
```

#### 6.6 使用 StreamBuilder

```dart
StreamBuilder<String>(
  stream: dataStream,
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text('错误: ${snapshot.error}');
    }
    
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (!snapshot.hasData) {
      return Text('没有数据');
    }
    
    return Text('数据: ${snapshot.data}');
  },
)
```

---

## 常见面试题

### 7.1 Future 和 Stream 的区别？

**Future：**
- 表示一个异步操作，只会产生一个值
- 完成后就结束了
- 适用于一次性操作（如网络请求）

**Stream：**
- 表示一个异步数据序列，可以产生多个值
- 可以持续产生数据
- 适用于持续的数据流（如用户输入、WebSocket）

```dart
// Future - 一个值
Future<String> fetchUser() async {
  return 'User';
}

// Stream - 多个值
Stream<int> countStream() async* {
  for (int i = 1; i <= 10; i++) {
    yield i;
  }
}
```

### 7.2 async/await 的执行顺序？

```dart
void main() {
  print('1');
  
  Future(() => print('2'));
  
  scheduleMicrotask(() => print('3'));
  
  print('4');
  
  // 输出：1, 4, 3, 2
  // 原因：先执行同步代码，再执行微任务，最后执行事件队列
}
```

### 7.3 如何取消一个 Future？

```dart
// 使用 CancelToken（需要自己实现或使用第三方库）
class CancelToken {
  bool _cancelled = false;
  
  void cancel() {
    _cancelled = true;
  }
  
  bool get isCancelled => _cancelled;
}

Future<String> fetchData(CancelToken token) async {
  for (int i = 0; i < 10; i++) {
    if (token.isCancelled) {
      throw Exception('已取消');
    }
    await Future.delayed(Duration(seconds: 1));
  }
  return 'Data';
}
```

### 7.4 如何实现 Future 的超时重试？

```dart
Future<T> retryWithTimeout<T>(
  Future<T> Function() operation,
  int maxRetries,
  Duration timeout,
) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await operation().timeout(timeout);
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 1));
    }
  }
  throw Exception('重试失败');
}
```

### 7.5 Stream 的 listen 和 await for 的区别？

**listen()：**
- 返回 StreamSubscription，可以手动取消
- 可以设置多个回调（onData, onError, onDone）
- 不会等待 Stream 完成

**await for：**
- 会等待 Stream 完成
- 自动取消订阅
- 代码更简洁

```dart
// listen
StreamSubscription subscription = stream.listen(
  (data) => print(data),
  onError: (error) => print(error),
  onDone: () => print('完成'),
);
subscription.cancel(); // 手动取消

// await for
await for (var data in stream) {
  print(data);
}
// 自动取消
```

### 7.6 如何将多个 Stream 合并？

```dart
// 使用 StreamZip（需要 rxdart）
import 'package:rxdart/rxdart.dart';

Stream<int> stream1 = Stream.periodic(Duration(seconds: 1), (i) => i);
Stream<String> stream2 = Stream.periodic(Duration(seconds: 2), (i) => 'A$i');

StreamZip([stream1, stream2]).listen((values) {
  print(values); // [0, 'A0'], [1, 'A0'], [2, 'A1']...
});

// 使用 StreamController
StreamController<String> controller = StreamController<String>.broadcast();

stream1.listen((value) => controller.add('Stream1: $value'));
stream2.listen((value) => controller.add('Stream2: $value'));

controller.stream.listen((value) => print(value));
```

### 7.7 Isolate 和 Thread 的区别？

**Isolate：**
- 独立的内存空间，不共享状态
- 通过消息传递通信
- 更安全，不会出现竞态条件
- Dart 的并发模型

**Thread：**
- 共享内存空间
- 可以直接访问共享变量
- 可能出现竞态条件，需要锁机制
- 传统多线程模型

### 7.8 什么时候使用 Isolate？

**需要使用 Isolate 的场景：**
- CPU 密集型任务（图像处理、大量计算）
- 解析大型 JSON 文件
- 加密/解密操作
- 压缩/解压操作

**不需要使用 Isolate 的场景：**
- 网络请求（使用 async/await 即可）
- 简单的异步操作
- UI 更新

### 7.9 如何避免内存泄漏？

```dart
// ✅ 正确：取消订阅
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {
      if (mounted) {
        setState(() {
          // 更新状态
        });
      }
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        // 更新 UI
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
```

### 7.10 如何实现防抖和节流？

```dart
// 防抖（debounce）- 延迟执行，只执行最后一次
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({required this.delay});
  
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

// 使用
final debouncer = Debouncer(delay: Duration(milliseconds: 500));

onTextChanged(String text) {
  debouncer.run(() {
    // 执行搜索
    search(text);
  });
}

// 节流（throttle）- 限制执行频率
class Throttler {
  final Duration delay;
  DateTime? _lastRun;
  
  Throttler({required this.delay});
  
  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || 
        now.difference(_lastRun!) >= delay) {
      action();
      _lastRun = now;
    }
  }
}

// 使用
final throttler = Throttler(delay: Duration(seconds: 1));

onScroll() {
  throttler.run(() {
    // 执行操作
    loadMore();
  });
}
```

### 7.11 如何处理异步操作的竞态条件？

```dart
// 使用 Completer 和标志位
class DataLoader {
  int _requestId = 0;
  
  Future<String> loadData() async {
    final currentId = ++_requestId;
    
    try {
      final data = await fetchData();
      
      // 检查是否是最新的请求
      if (currentId == _requestId) {
        return data;
      } else {
        throw Exception('请求已过期');
      }
    } catch (e) {
      if (currentId == _requestId) {
        rethrow;
      }
      throw Exception('请求已过期');
    }
  }
}
```

### 7.12 Future.microtask 和 Future 的区别？

```dart
void main() {
  print('1');
  
  // 添加到事件队列
  Future(() => print('2'));
  
  // 添加到微任务队列
  Future.microtask(() => print('3'));
  
  scheduleMicrotask(() => print('4'));
  
  print('5');
  
  // 输出：1, 5, 3, 4, 2
  // 微任务队列优先于事件队列执行
}
```

### 7.13 如何实现一个简单的 Future？

```dart
class SimpleFuture<T> {
  T? _value;
  Object? _error;
  bool _isCompleted = false;
  List<void Function(T)> _onData = [];
  List<void Function(Object)> _onError = [];
  
  SimpleFuture();
  
  // 完成 Future
  void complete(T value) {
    if (_isCompleted) return;
    _isCompleted = true;
    _value = value;
    for (var callback in _onData) {
      callback(value);
    }
    _onData.clear();
    _onError.clear();
  }
  
  // 完成 Future（错误）
  void completeError(Object error) {
    if (_isCompleted) return;
    _isCompleted = true;
    _error = error;
    for (var callback in _onError) {
      callback(error);
    }
    _onData.clear();
    _onError.clear();
  }
  
  // 监听完成
  SimpleFuture<T> then(void Function(T) onData) {
    if (_isCompleted && _error == null) {
      onData(_value as T);
    } else if (!_isCompleted) {
      _onData.add(onData);
    }
    return this;
  }
  
  SimpleFuture<T> catchError(void Function(Object) onError) {
    if (_isCompleted && _error != null) {
      onError(_error!);
    } else if (!_isCompleted) {
      _onError.add(onError);
    }
    return this;
  }
}
```

---

## 总结

Flutter 的异步编程是开发中非常重要的部分，掌握以下要点：

1. **Future**：处理一次性异步操作
2. **async/await**：让异步代码更易读
3. **Stream**：处理持续的数据流
4. **Isolate**：处理 CPU 密集型任务
5. **最佳实践**：避免阻塞 UI、合理使用并发、正确管理资源

理解这些概念和用法，能够帮助你编写出高效、健壮的 Flutter 应用。

