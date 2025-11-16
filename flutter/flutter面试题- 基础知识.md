# Flutter 面试题 - 基础知识

## 1. Flutter 是什么？

Flutter 是 Google 开发的跨平台 UI 框架，使用 Dart 语言编写，可以同时为 iOS、Android、Web、桌面等平台构建应用。

### 1.1 核心特性

- **跨平台**：一套代码，多端运行
- **高性能**：使用 Skia 引擎直接渲染，接近原生性能
- **热重载**：快速开发，实时预览
- **丰富的 Widget**：提供大量预构建的 UI 组件
- **响应式编程**：基于声明式 UI 框架

### 1.2 Flutter 架构

```
┌─────────────────────────────────────┐
│         Framework (Dart)            │
│  ┌──────────┐  ┌──────────────┐    │
│  │ Widgets  │  │ Material/Cupertino│
│  └──────────┘  └──────────────┘    │
├─────────────────────────────────────┤
│         Engine (C++)                │
│  ┌──────────┐  ┌──────────────┐    │
│  │ Skia     │  │ Dart VM      │    │
│  └──────────┘  └──────────────┘    │
├─────────────────────────────────────┤
│         Platform                    │
│  ┌──────────┐  ┌──────────────┐    │
│  │ iOS      │  │ Android      │    │
│  └──────────┘  └──────────────┘    │
└─────────────────────────────────────┘
```

## 2. Dart 语言基础

### 2.1 Dart 语言特性

#### 2.1.1 变量声明

```dart
// var - 类型推断
var name = 'Flutter';
var age = 25;

// 明确类型
String name = 'Flutter';
int age = 25;

// final - 运行时常量
final String name = 'Flutter';
final name = 'Flutter'; // 类型推断

// const - 编译时常量
const String name = 'Flutter';
const name = 'Flutter'; // 类型推断

// late - 延迟初始化
late String name;
void init() {
  name = 'Flutter';
}
```

#### 2.1.2 数据类型

```dart
// 基本类型
int age = 25;
double price = 99.99;
String name = 'Flutter';
bool isActive = true;

// 集合类型
List<String> list = ['a', 'b', 'c'];
Map<String, int> map = {'a': 1, 'b': 2};
Set<String> set = {'a', 'b', 'c'};

// 动态类型
dynamic value = 'Hello';
value = 123; // 可以改变类型

// Object 类型
Object obj = 'Hello';
obj = 123; // 也可以改变类型
```

#### 2.1.3 函数

```dart
// 普通函数
String greet(String name) {
  return 'Hello, $name';
}

// 箭头函数
String greet(String name) => 'Hello, $name';

// 可选参数
void printInfo(String name, [int? age]) {
  print('Name: $name, Age: ${age ?? 'unknown'}');
}

// 命名参数
void printInfo({required String name, int? age}) {
  print('Name: $name, Age: ${age ?? 'unknown'}');
}

// 默认参数
void printInfo({String name = 'Unknown', int age = 0}) {
  print('Name: $name, Age: $age');
}
```

#### 2.1.4 类和对象

```dart
// 类定义
class Person {
  String name;
  int age;
  
  // 构造函数
  Person(this.name, this.age);
  
  // 命名构造函数
  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        age = json['age'];
  
  // 方法
  void introduce() {
    print('I am $name, $age years old');
  }
}

// 继承
class Student extends Person {
  String school;
  
  Student(String name, int age, this.school) : super(name, age);
  
  @override
  void introduce() {
    super.introduce();
    print('I study at $school');
  }
}
```

#### 2.1.5 异步编程

```dart
// Future
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 1));
  return 'Data loaded';
}

// 使用 Future
fetchData().then((data) {
  print(data);
}).catchError((error) {
  print('Error: $error');
});

// async/await
void loadData() async {
  try {
    String data = await fetchData();
    print(data);
  } catch (error) {
    print('Error: $error');
  }
}

// Stream
Stream<int> countStream() async* {
  for (int i = 1; i <= 5; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

// 使用 Stream
countStream().listen((value) {
  print(value);
});
```

### 2.2 Dart 语言特性总结

| 特性 | 说明 |
|------|------|
| 类型安全 | 支持静态类型检查和类型推断 |
| 空安全 | 支持 null safety，避免空指针异常 |
| 异步支持 | 内置 Future 和 Stream，支持 async/await |
| Mixin | 支持混入，实现多继承 |
| 扩展方法 | 可以为现有类添加方法 |
| 泛型 | 支持泛型编程 |

## 3. Widget 基础

### 3.1 Widget 是什么？

Widget 是 Flutter 应用的基础构建块，所有 UI 元素都是 Widget。

#### 3.1.1 Widget 的特点

- **不可变**：Widget 是不可变的，一旦创建就不能修改
- **声明式**：通过描述 UI 应该是什么样子来构建界面
- **组合**：通过组合多个 Widget 来构建复杂 UI
- **轻量级**：Widget 对象本身很轻量，可以频繁创建

#### 3.1.2 Widget 树

```dart
MaterialApp(
  home: Scaffold(
    appBar: AppBar(
      title: Text('Flutter Demo'),
    ),
    body: Center(
      child: Column(
        children: [
          Text('Hello'),
          Text('World'),
        ],
      ),
    ),
  ),
)
```

### 3.2 StatelessWidget vs StatefulWidget

#### 3.2.1 StatelessWidget

无状态 Widget，创建后状态不会改变。

```dart
class MyWidget extends StatelessWidget {
  final String title;
  
  const MyWidget({Key? key, required this.title}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
```

**特点：**
- 不可变
- 性能更好（不需要重建状态）
- 适合静态 UI

#### 3.2.2 StatefulWidget

有状态 Widget，可以维护可变状态。

```dart
class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;
  
  void _increment() {
    setState(() {
      _count++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

**特点：**
- 可以维护可变状态
- 通过 `setState()` 触发重建
- 适合动态 UI

### 3.3 Widget 生命周期

#### 3.3.1 StatelessWidget 生命周期

```
创建 → build() → 销毁
```

#### 3.3.2 StatefulWidget 生命周期

```
1. createState() - 创建 State 对象
2. initState() - 初始化状态（只调用一次）
3. didChangeDependencies() - 依赖变化时调用
4. build() - 构建 Widget 树
5. didUpdateWidget() - Widget 配置更新时调用
6. setState() - 触发重建
7. deactivate() - State 对象从树中移除时调用
8. dispose() - State 对象被永久移除时调用
```

**代码示例：**

```dart
class LifecycleWidget extends StatefulWidget {
  @override
  _LifecycleWidgetState createState() => _LifecycleWidgetState();
}

class _LifecycleWidgetState extends State<LifecycleWidget> {
  @override
  void initState() {
    super.initState();
    print('initState: 初始化');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies: 依赖变化');
  }
  
  @override
  Widget build(BuildContext context) {
    print('build: 构建 Widget');
    return Container();
  }
  
  @override
  void didUpdateWidget(LifecycleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget: Widget 更新');
  }
  
  @override
  void deactivate() {
    super.deactivate();
    print('deactivate: 从树中移除');
  }
  
  @override
  void dispose() {
    super.dispose();
    print('dispose: 永久移除');
  }
}
```

## 4. 常用 Widget

### 4.1 布局 Widget

#### 4.1.1 Container

容器 Widget，可以设置宽高、内边距、装饰等。

```dart
Container(
  width: 100,
  height: 100,
  padding: EdgeInsets.all(10),
  margin: EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Text('Container'),
)
```

#### 4.1.2 Row 和 Column

用于水平（Row）和垂直（Column）布局。

```dart
// Row - 水平布局
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('A'),
    Text('B'),
    Text('C'),
  ],
)

// Column - 垂直布局
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('A'),
    Text('B'),
    Text('C'),
  ],
)
```

#### 4.1.3 Stack

层叠布局，用于重叠 Widget。

```dart
Stack(
  alignment: Alignment.center,
  children: [
    Container(
      width: 200,
      height: 200,
      color: Colors.blue,
    ),
    Text('Overlay'),
  ],
)
```

#### 4.1.4 Expanded 和 Flexible

用于在 Row/Column 中分配空间。

```dart
Row(
  children: [
    Expanded(
      flex: 2, // 占据 2/3 空间
      child: Container(color: Colors.red),
    ),
    Expanded(
      flex: 1, // 占据 1/3 空间
      child: Container(color: Colors.blue),
    ),
  ],
)
```

### 4.2 文本 Widget

#### 4.2.1 Text

显示文本。

```dart
Text(
  'Hello Flutter',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
)
```

#### 4.2.2 RichText

富文本，可以设置不同样式。

```dart
RichText(
  text: TextSpan(
    text: 'Hello ',
    style: TextStyle(color: Colors.black),
    children: [
      TextSpan(
        text: 'Flutter',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
)
```

### 4.3 按钮 Widget

```dart
// ElevatedButton - 凸起按钮
ElevatedButton(
  onPressed: () {
    print('Pressed');
  },
  child: Text('Click Me'),
)

// TextButton - 文本按钮
TextButton(
  onPressed: () {},
  child: Text('Text Button'),
)

// IconButton - 图标按钮
IconButton(
  onPressed: () {},
  icon: Icon(Icons.add),
)
```

### 4.4 输入 Widget

```dart
// TextField - 文本输入
TextField(
  decoration: InputDecoration(
    labelText: 'Name',
    hintText: 'Enter your name',
    border: OutlineInputBorder(),
  ),
  onChanged: (value) {
    print(value);
  },
)

// TextFormField - 表单输入（带验证）
TextFormField(
  decoration: InputDecoration(labelText: 'Email'),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    return null;
  },
)
```

### 4.5 列表 Widget

```dart
// ListView - 列表
ListView(
  children: [
    ListTile(title: Text('Item 1')),
    ListTile(title: Text('Item 2')),
    ListTile(title: Text('Item 3')),
  ],
)

// ListView.builder - 动态列表
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index]),
    );
  },
)
```

## 5. 导航和路由

### 5.1 基本导航

```dart
// 导航到新页面
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SecondPage(),
  ),
);

// 返回上一页
Navigator.pop(context);

// 返回并传递数据
Navigator.pop(context, 'Result Data');
```

### 5.2 命名路由

```dart
// 定义路由
MaterialApp(
  routes: {
    '/': (context) => HomePage(),
    '/second': (context) => SecondPage(),
  },
  initialRoute: '/',
)

// 使用命名路由
Navigator.pushNamed(context, '/second');

// 传递参数
Navigator.pushNamed(
  context,
  '/second',
  arguments: {'id': 123},
);

// 接收参数
final args = ModalRoute.of(context)!.settings.arguments as Map;
```

### 5.3 路由生成器

```dart
MaterialApp(
  onGenerateRoute: (settings) {
    if (settings.name == '/') {
      return MaterialPageRoute(builder: (_) => HomePage());
    } else if (settings.name == '/second') {
      final args = settings.arguments as Map;
      return MaterialPageRoute(
        builder: (_) => SecondPage(id: args['id']),
      );
    }
    return null;
  },
)
```

## 6. 状态管理基础

### 6.1 setState

最基础的状态管理方式。

```dart
class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;
  
  void _increment() {
    setState(() {
      _count++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### 6.2 InheritedWidget

用于在 Widget 树中向下传递数据。

```dart
class CounterInheritedWidget extends InheritedWidget {
  final int count;
  final VoidCallback increment;
  
  CounterInheritedWidget({
    required this.count,
    required this.increment,
    required Widget child,
  }) : super(child: child);
  
  static CounterInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CounterInheritedWidget>();
  }
  
  @override
  bool updateShouldNotify(CounterInheritedWidget oldWidget) {
    return count != oldWidget.count;
  }
}
```

## 7. 异步操作

### 7.1 Future

```dart
// 创建 Future
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));
  return 'Data loaded';
}

// 使用 FutureBuilder
FutureBuilder<String>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return Text('Data: ${snapshot.data}');
    }
  },
)
```

### 7.2 Stream

```dart
// 创建 Stream
Stream<int> countStream() async* {
  for (int i = 1; i <= 10; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

// 使用 StreamBuilder
StreamBuilder<int>(
  stream: countStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('Count: ${snapshot.data}');
    } else {
      return CircularProgressIndicator();
    }
  },
)
```

## 8. 网络请求

### 8.1 http 包

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// GET 请求
Future<Map<String, dynamic>> fetchData() async {
  final response = await http.get(
    Uri.parse('https://api.example.com/data'),
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load data');
  }
}

// POST 请求
Future<Map<String, dynamic>> postData(Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse('https://api.example.com/data'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(data),
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to post data');
  }
}
```

### 8.2 dio 包

```dart
import 'package:dio/dio.dart';

final dio = Dio();

// GET 请求
Future<Map<String, dynamic>> fetchData() async {
  final response = await dio.get('https://api.example.com/data');
  return response.data;
}

// POST 请求
Future<Map<String, dynamic>> postData(Map<String, dynamic> data) async {
  final response = await dio.post(
    'https://api.example.com/data',
    data: data,
  );
  return response.data;
}
```

## 9. 本地存储

### 9.1 SharedPreferences

```dart
import 'package:shared_preferences/shared_preferences.dart';

// 保存数据
Future<void> saveData(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

// 读取数据
Future<String?> loadData(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

// 删除数据
Future<void> deleteData(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
```

### 9.2 SQLite

```dart
import 'package:sqflite/sqflite.dart';

// 创建数据库
Future<Database> openDatabase() async {
  return await openDatabase(
    'my_database.db',
    version: 1,
    onCreate: (db, version) {
      db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY,
          name TEXT,
          age INTEGER
        )
      ''');
    },
  );
}

// 插入数据
Future<void> insertUser(Database db, String name, int age) async {
  await db.insert('users', {'name': name, 'age': age});
}

// 查询数据
Future<List<Map<String, dynamic>>> getUsers(Database db) async {
  return await db.query('users');
}
```

## 10. 主题和样式

### 10.1 Material 主题

```dart
MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      color: Colors.blue,
      textTheme: TextTheme(
        headline6: TextStyle(color: Colors.white),
      ),
    ),
  ),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
  ),
  themeMode: ThemeMode.system,
  home: MyHomePage(),
)
```

### 10.2 Cupertino 主题

```dart
CupertinoApp(
  theme: CupertinoThemeData(
    primaryColor: CupertinoColors.activeBlue,
    brightness: Brightness.light,
  ),
  home: MyHomePage(),
)
```

## 11. 性能优化

### 11.1 const 构造函数

使用 `const` 可以避免不必要的重建。

```dart
// 好的做法
const Text('Hello')

// 避免
Text('Hello') // 每次都会创建新对象
```

### 11.2 使用 const Widget

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Title'), // const Widget
        Text('Content'),
      ],
    );
  }
}
```

### 11.3 避免在 build 方法中创建对象

```dart
// 不好的做法
@override
Widget build(BuildContext context) {
  return Container(
    child: Text(DateTime.now().toString()), // 每次重建都创建新对象
  );
}

// 好的做法
class _MyWidgetState extends State<MyWidget> {
  late String _time;
  
  @override
  void initState() {
    super.initState();
    _time = DateTime.now().toString();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(_time),
    );
  }
}
```

### 11.4 使用 ListView.builder

对于长列表，使用 `ListView.builder` 而不是 `ListView`。

```dart
// 好的做法 - 只构建可见的 item
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)

// 避免 - 会构建所有 item
ListView(
  children: items.map((item) => ListTile(title: Text(item))).toList(),
)
```

## 12. 调试和测试

### 12.1 调试工具

```dart
// print 调试
print('Debug message');

// debugPrint（推荐，避免日志过多）
debugPrint('Debug message');

// 断点调试
// 在 IDE 中设置断点，使用调试模式运行
```

### 12.2 Widget 测试

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments', (WidgetTester tester) async {
    // 构建 Widget
    await tester.pumpWidget(MyApp());
    
    // 查找 Widget
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    
    // 触发操作
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    
    // 验证结果
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
```

## 13. 常见问题

### 13.1 什么是 Key？

Key 用于标识 Widget，帮助 Flutter 在重建时识别 Widget。

```dart
// ValueKey - 使用值作为 key
ValueKey('unique_id')

// ObjectKey - 使用对象作为 key
ObjectKey(user)

// UniqueKey - 唯一 key
UniqueKey()

// GlobalKey - 全局 key，可以访问 Widget 的状态
GlobalKey<_MyWidgetState>()
```

### 13.2 什么是 BuildContext？

BuildContext 是 Widget 在树中的位置，用于访问主题、媒体查询、导航等。

```dart
// 获取主题
Theme.of(context).primaryColor

// 获取媒体查询
MediaQuery.of(context).size

// 导航
Navigator.of(context).push(...)
```

### 13.3 什么是 MediaQuery？

MediaQuery 提供设备信息，如屏幕尺寸、方向等。

```dart
// 获取屏幕尺寸
final size = MediaQuery.of(context).size;
final width = size.width;
final height = size.height;

// 获取设备像素比
final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

// 检查方向
final orientation = MediaQuery.of(context).orientation;
final isPortrait = orientation == Orientation.portrait;
```

### 13.4 如何处理屏幕适配？

```dart
// 使用 MediaQuery
final screenWidth = MediaQuery.of(context).size.width;
final screenHeight = MediaQuery.of(context).size.height;

// 使用百分比
Container(
  width: screenWidth * 0.8, // 80% 宽度
  height: screenHeight * 0.5, // 50% 高度
)

// 使用 LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return WideLayout();
    } else {
      return NarrowLayout();
    }
  },
)
```

## 14. Flutter 基础知识总结

### 14.1 核心概念

1. **Widget**：Flutter 的基础构建块，所有 UI 都是 Widget
2. **State**：Widget 的状态，通过 `setState()` 更新
3. **BuildContext**：Widget 在树中的位置
4. **Key**：用于标识 Widget
5. **生命周期**：Widget 从创建到销毁的过程

### 14.2 常用 Widget

- **布局**：Container、Row、Column、Stack、Expanded、Flexible
- **文本**：Text、RichText
- **按钮**：ElevatedButton、TextButton、IconButton
- **输入**：TextField、TextFormField
- **列表**：ListView、ListView.builder

### 14.3 状态管理

- **setState**：基础状态管理
- **InheritedWidget**：向下传递数据
- **Provider**：推荐的状态管理方案
- **Bloc**：复杂应用的状态管理

### 14.4 性能优化

- 使用 `const` 构造函数
- 避免在 `build` 方法中创建对象
- 使用 `ListView.builder` 处理长列表
- 合理使用 `setState()`

### 14.5 常见面试题

1. **Flutter 是什么？** - Google 的跨平台 UI 框架
2. **Widget 和 Element 的区别？** - Widget 是配置，Element 是实例
3. **StatelessWidget 和 StatefulWidget 的区别？** - 是否有可变状态
4. **setState() 的作用？** - 标记 Widget 为脏，触发重建
5. **什么是 Key？** - 用于标识 Widget
6. **Flutter 如何实现热重载？** - 通过增量编译和状态保持
7. **如何优化 Flutter 性能？** - 使用 const、避免不必要的重建
8. **如何处理异步操作？** - 使用 Future、Stream、async/await
9. **如何进行导航？** - 使用 Navigator
10. **如何进行本地存储？** - SharedPreferences、SQLite

---

## 参考资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 语言文档](https://dart.dev/guides)
- [Flutter Widget 目录](https://flutter.dev/docs/development/ui/widgets)

