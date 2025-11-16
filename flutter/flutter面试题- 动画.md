# Flutter 面试题 - 动画

本文档整理了 Flutter 开发中动画相关的面试题，涵盖了隐式动画、显式动画、动画控制器、补间动画、物理动画、Hero 动画等多个方面。

---

## 一、动画基础

### 1. Flutter 中的动画类型有哪些？

**答案：**

Flutter 中的动画主要分为两大类：

#### 1.1 隐式动画（Implicit Animations）

隐式动画是 Flutter 提供的简化动画 API，当属性值改变时自动产生动画效果。

**特点：**
- 使用简单，无需手动管理动画控制器
- 自动处理动画的开始、停止和反转
- 适合简单的属性变化动画

**常用隐式动画 Widget：**
- `AnimatedContainer`：容器属性动画
- `AnimatedOpacity`：透明度动画
- `AnimatedPadding`：内边距动画
- `AnimatedPositioned`：位置动画
- `AnimatedSize`：尺寸动画
- `AnimatedSwitcher`：切换动画
- `AnimatedCrossFade`：交叉淡入淡出
- `AnimatedRotation`：旋转动画
- `AnimatedScale`：缩放动画

#### 1.2 显式动画（Explicit Animations）

显式动画需要手动创建和管理 `AnimationController`，提供更精细的控制。

**特点：**
- 完全控制动画的生命周期
- 可以自定义动画曲线、时长、重复次数等
- 适合复杂的动画场景

**常用显式动画 Widget：**
- `AnimationController`：动画控制器
- `Tween`：补间动画
- `CurvedAnimation`：曲线动画
- `FadeTransition`：淡入淡出过渡
- `ScaleTransition`：缩放过渡
- `RotationTransition`：旋转过渡
- `SlideTransition`：滑动过渡

---

### 2. 隐式动画和显式动画的区别是什么？各自的使用场景？

**答案：**

#### 2.1 区别对比

| 特性 | 隐式动画 | 显式动画 |
|------|---------|---------|
| **复杂度** | 简单，API 友好 | 复杂，需要手动管理 |
| **控制度** | 有限，自动管理 | 完全控制 |
| **性能** | 优化良好 | 需要手动优化 |
| **适用场景** | 简单属性变化 | 复杂动画序列 |
| **代码量** | 少 | 多 |

#### 2.2 使用场景

**隐式动画适用于：**
- 简单的属性变化（颜色、大小、位置等）
- 状态切换动画
- 快速原型开发
- 不需要精确控制的场景

**示例：**

```dart
class ImplicitAnimationExample extends StatefulWidget {
  @override
  _ImplicitAnimationExampleState createState() => _ImplicitAnimationExampleState();
}

class _ImplicitAnimationExampleState extends State<ImplicitAnimationExample> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: AnimatedContainer(
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
        width: _expanded ? 200 : 100,
        height: _expanded ? 200 : 100,
        color: _expanded ? Colors.blue : Colors.red,
        child: Center(
          child: Text(_expanded ? '展开' : '收起'),
        ),
      ),
    );
  }
}
```

**显式动画适用于：**
- 复杂的动画序列
- 需要精确控制动画进度
- 多个动画协调
- 自定义动画曲线
- 需要监听动画状态

**示例：**

```dart
class ExplicitAnimationExample extends StatefulWidget {
  @override
  _ExplicitAnimationExampleState createState() => _ExplicitAnimationExampleState();
}

class _ExplicitAnimationExampleState extends State<ExplicitAnimationExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_controller.isAnimating) {
            _controller.stop();
          } else {
            _controller.repeat(reverse: true);
          }
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
```

---

## 二、AnimationController

### 3. AnimationController 是什么？如何使用？

**答案：**

#### 3.1 基本概念

`AnimationController` 是 Flutter 动画系统的核心，用于控制动画的播放、暂停、停止和反转。

**关键特性：**
- 生成 0.0 到 1.0 之间的值（或自定义范围）
- 控制动画的播放速度
- 管理动画的生命周期
- 提供动画状态监听

#### 3.2 基本使用

```dart
class AnimationControllerExample extends StatefulWidget {
  @override
  _AnimationControllerExampleState createState() => _AnimationControllerExampleState();
}

class _AnimationControllerExampleState extends State<AnimationControllerExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 创建动画控制器
    _controller = AnimationController(
      duration: Duration(seconds: 2), // 动画时长
      vsync: this, // 需要 TickerProvider
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // 必须释放资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            if (_controller.isAnimating) {
              _controller.stop();
            } else {
              _controller.forward();
            }
          },
          child: Text('播放动画'),
        ),
      ),
    );
  }
}
```

#### 3.3 常用方法

```dart
// 正向播放
_controller.forward();

// 反向播放
_controller.reverse();

// 停止动画
_controller.stop();

// 重置到开始
_controller.reset();

// 重复播放
_controller.repeat();

// 重复播放（往返）
_controller.repeat(reverse: true);

// 监听动画值
_controller.addListener(() {
  print('当前值: ${_controller.value}');
});

// 监听动画状态
_controller.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    print('动画完成');
  } else if (status == AnimationStatus.dismissed) {
    print('动画重置');
  }
});
```

#### 3.4 动画状态

`AnimationController` 有以下状态：

- `AnimationStatus.dismissed`：动画在开始位置（值为 0.0）
- `AnimationStatus.forward`：动画正在正向播放
- `AnimationStatus.reverse`：动画正在反向播放
- `AnimationStatus.completed`：动画在结束位置（值为 1.0）

---

### 4. 为什么 AnimationController 需要 TickerProvider？SingleTickerProviderStateMixin 和 TickerProviderStateMixin 的区别？

**答案：**

#### 4.1 TickerProvider 的作用

`TickerProvider` 提供 `Ticker` 对象，用于在每一帧刷新时通知 `AnimationController` 更新动画值。

**为什么需要：**
- Flutter 使用 `Ticker` 来同步动画与屏幕刷新率（通常 60fps）
- `Ticker` 确保动画在应用不可见时暂停，节省资源
- 提供帧同步机制，保证动画流畅

#### 4.2 SingleTickerProviderStateMixin vs TickerProviderStateMixin

**SingleTickerProviderStateMixin：**
- 只提供一个 `Ticker`
- 适用于只有一个 `AnimationController` 的场景
- 性能稍好（资源占用更少）

```dart
class SingleTickerExample extends StatefulWidget {
  @override
  _SingleTickerExampleState createState() => _SingleTickerExampleState();
}

class _SingleTickerExampleState extends State<SingleTickerExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this, // 使用 SingleTickerProviderStateMixin
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**TickerProviderStateMixin：**
- 可以提供多个 `Ticker`
- 适用于有多个 `AnimationController` 的场景
- 资源占用稍多

```dart
class MultipleTickerExample extends StatefulWidget {
  @override
  _MultipleTickerExampleState createState() => _MultipleTickerExampleState();
}

class _MultipleTickerExampleState extends State<MultipleTickerExample>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this, // 可以创建多个控制器
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }
}
```

---

## 三、Tween 和补间动画

### 5. Tween 是什么？如何使用 Tween 创建补间动画？

**答案：**

#### 5.1 Tween 基本概念

`Tween`（补间）用于定义动画的起始值和结束值，将 `AnimationController` 的 0.0-1.0 范围映射到实际的值范围。

#### 5.2 基本使用

```dart
class TweenExample extends StatefulWidget {
  @override
  _TweenExampleState createState() => _TweenExampleState();
}

class _TweenExampleState extends State<TweenExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // 数值补间
    _sizeAnimation = Tween<double>(begin: 50.0, end: 200.0).animate(_controller);

    // 颜色补间
    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.blue,
    ).animate(_controller);

    // 位置补间
    _positionAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(1, 1),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Transform.translate(
              offset: Offset(
                _positionAnimation.value.dx * 100,
                _positionAnimation.value.dy * 100,
              ),
              child: Container(
                width: _sizeAnimation.value,
                height: _sizeAnimation.value,
                color: _colorAnimation.value,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.forward();
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
```

#### 5.3 常用 Tween 类型

```dart
// 数值 Tween
Animation<double> sizeAnimation = Tween<double>(begin: 0, end: 100).animate(controller);

// 整数 Tween
Animation<int> intAnimation = IntTween(begin: 0, end: 100).animate(controller);

// 颜色 Tween
Animation<Color?> colorAnimation = ColorTween(
  begin: Colors.red,
  end: Colors.blue,
).animate(controller);

// 位置 Tween
Animation<Offset> offsetAnimation = Tween<Offset>(
  begin: Offset(0, 0),
  end: Offset(1, 1),
).animate(controller);

// 矩形 Tween
Animation<Rect?> rectAnimation = RectTween(
  begin: Rect.fromLTWH(0, 0, 50, 50),
  end: Rect.fromLTWH(100, 100, 200, 200),
).animate(controller);

// 大小 Tween
Animation<Size?> sizeAnimation = SizeTween(
  begin: Size(50, 50),
  end: Size(200, 200),
).animate(controller);

// 自定义类型 Tween
Animation<Alignment> alignmentAnimation = Tween<Alignment>(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
).animate(controller);
```

#### 5.4 Tween 链式调用

```dart
// 使用 chain 连接多个动画曲线
Animation<double> animation = Tween<double>(begin: 0, end: 1)
    .chain(CurveTween(curve: Curves.easeIn))
    .chain(CurveTween(curve: Curves.easeOut))
    .animate(controller);
```

---

### 6. 如何自定义 Tween？如何实现非线性动画？

**答案：**

#### 6.1 自定义 Tween

```dart
// 自定义 Point Tween
class PointTween extends Tween<Point> {
  PointTween({required Point begin, required Point end})
      : super(begin: begin, end: end);

  @override
  Point lerp(double t) {
    return Point(
      begin!.x + (end!.x - begin!.x) * t,
      begin!.y + (end!.y - begin!.y) * t,
    );
  }
}

class Point {
  final double x;
  final double y;
  Point(this.x, this.y);
}

// 使用自定义 Tween
Animation<Point> pointAnimation = PointTween(
  begin: Point(0, 0),
  end: Point(100, 100),
).animate(controller);
```

#### 6.2 非线性动画

使用 `CurvedAnimation` 或 `CurveTween` 实现非线性动画：

```dart
class CurvedAnimationExample extends StatefulWidget {
  @override
  _CurvedAnimationExampleState createState() => _CurvedAnimationExampleState();
}

class _CurvedAnimationExampleState extends State<CurvedAnimationExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _linearAnimation;
  late Animation<double> _easeInAnimation;
  late Animation<double> _easeOutAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // 线性动画
    _linearAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // 缓入动画
    _easeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // 缓出动画
    _easeOutAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // 弹跳动画
    _bounceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _linearAnimation,
            builder: (context, child) {
              return Container(
                width: _linearAnimation.value * 200,
                height: 20,
                color: Colors.red,
              );
            },
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _easeInAnimation,
            builder: (context, child) {
              return Container(
                width: _easeInAnimation.value * 200,
                height: 20,
                color: Colors.green,
              );
            },
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _easeOutAnimation,
            builder: (context, child) {
              return Container(
                width: _easeOutAnimation.value * 200,
                height: 20,
                color: Colors.blue,
              );
            },
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Container(
                width: _bounceAnimation.value * 200,
                height: 20,
                color: Colors.orange,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.reset();
          _controller.forward();
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
```

#### 6.3 自定义曲线

```dart
// 自定义动画曲线
class CustomCurve extends Curve {
  @override
  double transform(double t) {
    // 自定义曲线函数
    // t 是 0.0 到 1.0 之间的值
    return t * t * (3.0 - 2.0 * t); // 平滑步进函数
  }
}

// 使用自定义曲线
Animation<double> customAnimation = CurvedAnimation(
  parent: controller,
  curve: CustomCurve(),
);
```

---

## 四、动画 Widget

### 7. AnimatedBuilder 的作用是什么？什么时候使用？

**答案：**

#### 7.1 AnimatedBuilder 的作用

`AnimatedBuilder` 是一个用于构建动画 Widget 的工具，它会在动画值改变时自动重建其子 Widget。

**优点：**
- 只重建需要动画的部分，而不是整个 Widget 树
- 性能优化，避免不必要的重建
- 代码结构清晰

#### 7.2 使用场景

```dart
class AnimatedBuilderExample extends StatefulWidget {
  @override
  _AnimatedBuilderExampleState createState() => _AnimatedBuilderExampleState();
}

class _AnimatedBuilderExampleState extends State<AnimatedBuilderExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 这部分不会重建
      appBar: AppBar(title: Text('AnimatedBuilder 示例')),
      body: Center(
        // 只有这部分会重建
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * 2 * 3.14159,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            );
          },
          // child 参数可以优化性能，这部分不会重建
          child: Text('静态内容'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.repeat();
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
```

#### 7.3 性能优化技巧

```dart
// ✅ 好的做法：使用 child 参数
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Transform.scale(
      scale: _animation.value,
      child: child, // 使用 child 参数，避免重复创建
    );
  },
  child: ExpensiveWidget(), // 只创建一次
)

// ❌ 不好的做法：在 builder 中创建复杂 Widget
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Transform.scale(
      scale: _animation.value,
      child: ExpensiveWidget(), // 每次动画都会重建
    );
  },
)
```

---

### 8. AnimatedSwitcher 和 AnimatedCrossFade 的区别？

**答案：**

#### 8.1 AnimatedSwitcher

`AnimatedSwitcher` 用于在两个不同的 Widget 之间切换时添加过渡动画。

**特点：**
- 自动检测子 Widget 的变化
- 默认使用淡入淡出效果
- 可以自定义过渡动画

```dart
class AnimatedSwitcherExample extends StatefulWidget {
  @override
  _AnimatedSwitcherExampleState createState() => _AnimatedSwitcherExampleState();
}

class _AnimatedSwitcherExampleState extends State<AnimatedSwitcherExample> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Text(
                '$_counter',
                key: ValueKey(_counter), // 必须提供 key
                style: TextStyle(fontSize: 48),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _counter++;
                });
              },
              child: Text('增加'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 8.2 AnimatedCrossFade

`AnimatedCrossFade` 用于在两个 Widget 之间交叉淡入淡出，两个 Widget 同时存在。

**特点：**
- 两个 Widget 同时存在
- 一个淡出，另一个淡入
- 适合在两个固定 Widget 之间切换

```dart
class AnimatedCrossFadeExample extends StatefulWidget {
  @override
  _AnimatedCrossFadeExampleState createState() => _AnimatedCrossFadeExampleState();
}

class _AnimatedCrossFadeExampleState extends State<AnimatedCrossFadeExample> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedCrossFade(
              duration: Duration(milliseconds: 500),
              firstChild: Container(
                width: 200,
                height: 200,
                color: Colors.red,
                child: Center(child: Text('第一个')),
              ),
              secondChild: Container(
                width: 200,
                height: 200,
                color: Colors.blue,
                child: Center(child: Text('第二个')),
              ),
              crossFadeState: _showFirst
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showFirst = !_showFirst;
                });
              },
              child: Text('切换'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 8.3 区别对比

| 特性 | AnimatedSwitcher | AnimatedCrossFade |
|------|-----------------|-------------------|
| **Widget 数量** | 一个 Widget | 两个 Widget |
| **切换方式** | 替换 | 交叉淡入淡出 |
| **使用场景** | 动态内容切换 | 固定内容切换 |
| **Key 要求** | 需要提供 key | 不需要 key |

---

## 五、物理动画

### 9. 什么是物理动画？如何使用 PhysicsSimulation？

**答案：**

#### 9.1 物理动画概念

物理动画模拟真实世界的物理效果，如重力、摩擦力、弹性等，使动画更加自然。

#### 9.2 常用物理模拟

```dart
import 'package:flutter/physics.dart';

class PhysicsAnimationExample extends StatefulWidget {
  @override
  _PhysicsAnimationExampleState createState() => _PhysicsAnimationExampleState();
}

class _PhysicsAnimationExampleState extends State<PhysicsAnimationExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);

    // 弹簧动画
    final spring = SpringDescription(
      mass: 1,
      stiffness: 100,
      damping: 10,
    );

    final simulation = SpringSimulation(
      spring,
      0.0, // 起始位置
      1.0, // 结束位置
      0.0, // 初始速度
    );

    _animation = _controller.drive(
      Tween<double>(begin: 0, end: 200),
    );

    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

#### 9.3 常用物理模拟类型

```dart
// 1. 弹簧模拟
final spring = SpringDescription(
  mass: 1,        // 质量
  stiffness: 100, // 刚度
  damping: 10,    // 阻尼
);

final simulation = SpringSimulation(
  spring,
  start: 0.0,
  end: 1.0,
  velocity: 0.0,
);

// 2. 重力模拟
final simulation = GravitySimulation(
  9.8,    // 重力加速度
  0.0,    // 起始位置
  100.0,  // 结束位置
  0.0,    // 初始速度
);

// 3. 摩擦力模拟
final simulation = FrictionSimulation(
  0.5,    // 摩擦系数
  0.0,    // 起始位置
  100.0,  // 初始速度
);

// 4. 弹跳模拟
final simulation = BouncingScrollSimulation(
  position: 0.0,
  velocity: 100.0,
  leadingExtent: 0.0,
  trailingExtent: 1000.0,
  spring: spring,
);
```

---

## 六、Hero 动画

### 10. Hero 动画是什么？如何实现页面间的 Hero 动画？

**答案：**

#### 10.1 Hero 动画概念

`Hero` 动画用于在不同页面之间共享一个 Widget，创建平滑的过渡效果，常用于列表项到详情页的过渡。

#### 10.2 基本实现

```dart
// 第一个页面
class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('第一页')),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecondPage()),
            );
          },
          child: Hero(
            tag: 'hero-image', // 必须唯一
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 第二个页面
class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('第二页')),
      body: Center(
        child: Hero(
          tag: 'hero-image', // 必须与第一个页面相同
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(150),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 10.3 自定义 Hero 动画

```dart
class CustomHeroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('自定义 Hero')),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => SecondPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return Hero(
                    tag: 'hero-image',
                    child: child,
                    flightShuttleBuilder: (
                      BuildContext flightContext,
                      Animation<double> animation,
                      HeroFlightDirection flightDirection,
                      BuildContext fromHeroContext,
                      BuildContext toHeroContext,
                    ) {
                      final Hero toHero = toHeroContext.widget as Hero;
                      return RotationTransition(
                        turns: animation,
                        child: toHero.child,
                      );
                    },
                  );
                },
              ),
            );
          },
          child: Hero(
            tag: 'hero-image',
            child: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 10.4 注意事项

1. **tag 必须唯一**：同一页面中不能有相同的 tag
2. **Widget 类型可以不同**：但建议保持相似的结构
3. **性能考虑**：Hero 动画会创建新的 Widget，注意性能影响
4. **嵌套 Hero**：可以嵌套使用，但要注意 tag 的唯一性

---

## 七、动画性能优化

### 11. 如何优化 Flutter 动画性能？

**答案：**

#### 11.1 使用 RepaintBoundary

```dart
// 将动画 Widget 包裹在 RepaintBoundary 中
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return Transform.rotate(
        angle: _animation.value * 2 * 3.14159,
        child: child,
      );
    },
    child: ExpensiveWidget(),
  ),
)
```

#### 11.2 使用 const 构造函数

```dart
// ✅ 好的做法
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Transform.scale(
      scale: _animation.value,
      child: const Text('静态文本'), // 使用 const
    );
  },
)

// ❌ 不好的做法
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Transform.scale(
      scale: _animation.value,
      child: Text('静态文本'), // 每次重建
    );
  },
)
```

#### 11.3 使用 child 参数

```dart
// ✅ 好的做法：使用 child 参数
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Transform.translate(
      offset: Offset(_animation.value, 0),
      child: child, // 使用 child，避免重复创建
    );
  },
  child: ExpensiveWidget(), // 只创建一次
)

// ❌ 不好的做法
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Transform.translate(
      offset: Offset(_animation.value, 0),
      child: ExpensiveWidget(), // 每次动画都重建
    );
  },
)
```

#### 11.4 避免在动画中执行耗时操作

```dart
// ❌ 不好的做法
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    // 不要在动画回调中执行耗时操作
    final data = expensiveCalculation(); // 避免这样做
    return Container(
      width: _animation.value * 100,
      child: Text(data),
    );
  },
)

// ✅ 好的做法
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Container(
      width: _animation.value * 100,
      child: child, // 使用预计算的数据
    );
  },
  child: Text(_precomputedData), // 预先计算
)
```

#### 11.5 使用 AnimationController.unbounded

对于不需要限制范围的动画，使用 `unbounded` 控制器：

```dart
// 对于物理动画，使用 unbounded
_controller = AnimationController.unbounded(vsync: this);
```

#### 11.6 及时释放资源

```dart
@override
void dispose() {
  _controller.dispose(); // 必须释放
  super.dispose();
}
```

---

## 八、动画实践

### 12. 如何实现一个加载动画？

**答案：**

```dart
class LoadingAnimation extends StatefulWidget {
  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
```

### 13. 如何实现一个下拉刷新动画？

**答案：**

```dart
class PullToRefreshAnimation extends StatefulWidget {
  @override
  _PullToRefreshAnimationState createState() => _PullToRefreshAnimationState();
}

class _PullToRefreshAnimationState extends State<PullToRefreshAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    _controller.forward();

    // 模拟网络请求
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView.builder(
          itemCount: 20,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Item $index'),
            );
          },
        ),
      ),
    );
  }
}
```

### 14. 如何实现一个页面转场动画？

**答案：**

```dart
class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 淡入淡出
            return FadeTransition(
              opacity: animation,
              child: child,
            );

            // 缩放
            // return ScaleTransition(
            //   scale: animation,
            //   child: child,
            // );

            // 滑动
            // return SlideTransition(
            //   position: Tween<Offset>(
            //     begin: Offset(1.0, 0.0),
            //     end: Offset.zero,
            //   ).animate(animation),
            //   child: child,
            // );

            // 组合动画
            // return SlideTransition(
            //   position: Tween<Offset>(
            //     begin: Offset(1.0, 0.0),
            //     end: Offset.zero,
            //   ).animate(CurvedAnimation(
            //     parent: animation,
            //     curve: Curves.easeOut,
            //   )),
            //   child: FadeTransition(
            //     opacity: animation,
            //     child: child,
            //   ),
            // );
          },
          transitionDuration: Duration(milliseconds: 300),
        );
}

// 使用
Navigator.push(
  context,
  CustomPageRoute(child: SecondPage()),
);
```

---

## 九、常见问题

### 15. 动画不流畅怎么办？

**答案：**

#### 15.1 检查帧率

使用 Flutter DevTools 检查帧率，确保达到 60fps。

#### 15.2 优化重建范围

```dart
// ✅ 只重建需要的部分
AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
    return Transform.rotate(
      angle: _animation.value,
      child: child, // 使用 child 参数
    );
  },
  child: ExpensiveWidget(), // 不重建
)

// ❌ 重建整个 Widget 树
setState(() {
  _angle = _animation.value; // 导致整个页面重建
});
```

#### 15.3 使用 RepaintBoundary

```dart
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return CustomPaint(
        painter: MyPainter(_animation.value),
      );
    },
  ),
)
```

#### 15.4 减少动画数量

同时运行的动画数量过多会影响性能，考虑合并或简化动画。

---

### 16. 如何暂停和恢复动画？

**答案：**

```dart
class PauseResumeAnimation extends StatefulWidget {
  @override
  _PauseResumeAnimationState createState() => _PauseResumeAnimationState();
}

class _PauseResumeAnimationState extends State<PauseResumeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAnimation() {
    setState(() {
      if (_controller.isAnimating) {
        _controller.stop();
        _isPaused = true;
      } else {
        if (_isPaused) {
          _controller.forward();
        } else {
          _controller.repeat();
        }
        _isPaused = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * 2 * 3.14159,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAnimation,
        child: Icon(_controller.isAnimating ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
```

---

### 17. 如何实现动画的链式调用（一个接一个）？

**答案：**

```dart
class ChainedAnimationExample extends StatefulWidget {
  @override
  _ChainedAnimationExampleState createState() => _ChainedAnimationExampleState();
}

class _ChainedAnimationExampleState extends State<ChainedAnimationExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    // 淡入动画（0-1秒）
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.33, curve: Curves.easeIn),
      ),
    );

    // 缩放动画（1-2秒）
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.33, 0.66, curve: Curves.easeOut),
      ),
    );

    // 旋转动画（2-3秒）
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value * 2 * 3.14159,
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.reset();
          _controller.forward();
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
```

---

## 十、总结

### 关键要点

1. **隐式动画**：适合简单的属性变化，使用方便
2. **显式动画**：适合复杂动画，完全控制
3. **AnimationController**：动画的核心控制器，必须正确释放
4. **Tween**：定义动画的值范围
5. **性能优化**：使用 `AnimatedBuilder`、`RepaintBoundary`、`const` 等
6. **Hero 动画**：实现页面间的平滑过渡
7. **物理动画**：模拟真实世界的物理效果

### 最佳实践

1. 及时释放 `AnimationController`
2. 使用 `AnimatedBuilder` 优化性能
3. 合理使用 `const` 构造函数
4. 避免在动画回调中执行耗时操作
5. 使用 `RepaintBoundary` 隔离重绘区域
6. 选择合适的动画曲线
7. 测试不同设备的性能表现

---

*本文档持续更新中，如有问题或建议，欢迎反馈。*

