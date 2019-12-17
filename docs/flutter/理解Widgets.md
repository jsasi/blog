# 理解Widgets

Flutter Widget采用现代响应式框架构建，这和React/Vue相似，他们的核心思想都是用 widget 来构建你的 UI 界面。 当widget的状态发生变化时，widget会重新构建UI，Flutter会对比前后变化的不同， 以确定底层渲染树从一个状态转换到下一个状态所需的最小更改，这也类似于React/Vue中虚拟DOM的diff算法。

但是Flutter中的Widget的概念更广泛，它不仅可以表示UI元素，也可以表示一些功能性的组件如：用于手势检测的 `GestureDetector` widget、用于APP主题数据传递的`Theme`等等，也可以认为是Flutter把万事万物都封装在Widget里，万事万物都是组件。

## Widget和Element

Widget并非真正渲染到屏幕的ui元素，屏幕上显示的是Element，Widget包含了ui元素的配置，类似于包含dom元素和css、js的综合体。

Element是由Widget生成的，一个Widget可以对应多个Element。

## Widget类

```
abstract class Widget extends DiagnosticableTree {
  /// Initializes [key] for subclasses.
  const Widget({ this.key });

  final Key key;

  @protected
  Element createElement();

  /// A short, textual description of this widget.
  @override
  String toStringShort() {
    return key == null ? '$runtimeType' : '$runtimeType-$key';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.dense;
  }

  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType
        && oldWidget.key == newWidget.key;
  }
}
```

- `Widget`类继承自`DiagnosticableTree`，`DiagnosticableTree`即“诊断树”，主要作用是提供调试信息。

- `Key`: 这个`key`属性类似于React/Vue中的`key`，主要的作用是决定是否在下一次`build`时复用旧的widget，决定的条件在`canUpdate()`方法中。

- `createElement()`：正如前文所述“一个Widget可以对应多个`Element`”；Flutter Framework在构建UI树时，会先调用此方法生成对应节点的`Element`对象。此方法是Flutter Framework隐式调用的，在我们开发过程中基本不会调用到。

- `debugFillProperties(...)` 复写父类的方法，主要是设置诊断树的一些特性。

- `canUpdate(...)`是一个静态方法，它主要用于在Widget树重新`build`时复用旧的widget，其实具体来说，应该是：是否用新的Widget对象去更新旧UI树上所对应的`Element`对象的配置；通过其源码我们可以看到，只要`newWidget`与`oldWidget`的`runtimeType`和`key`同时相等时就会用`newWidget`去更新`Element`对象的配置，否则就会创建新的`Element`。

   

  ## StatelessWidget

  一般的我们实现新组件，并不直接继承Widget，而是继承StatelessWidget或者StatefulWidget，StatelessWidget是无状态的静态组件，Flutter会递归调用所有的Widget。一般地，在写Widget的时候，我们会先写`key`参数，`child`和`children`是最后写的。

  既然是递归调用，我们在子组件里，可以通过`context.ancestorWidgetOfExactType()`获取子组件的最近父级组件。

  ## StatefulWidget

  如果需要变更状态，比如点击变色、单选框、进度条等，需要继承StatefulWidget，重写`createState（）`,返回一个State。

  ### State

  一个StatefulWidget类会对应一个State类，State表示与其对应的StatefulWidget要维护的状态。当State被改变时，可以手动调用其`setState()`方法通知Flutter framework状态发生改变，Flutter framework在收到消息后，会重新调用其`build`方法重新构建widget树，从而达到更新UI的目的。

  State的`build(BuildContext context)`方法返回WIdget,为什么不放在StatefulWidget里呢：

  - 状态访问不便 。

    State包含组件的状态，而组件会根据状态改变，所以分开的话获取状态不方便。

  - 继承StatefulWidget不便。
  
    有的组件本身有build方法。
  
    

#### State生命周期

![声明周期](https://cdn.jsdelivr.net/gh/flutterchina/flutter-in-action/docs/imgs/3-2.jpg)

- `initState`：当Widget第一次插入到Widget树时会被调用，对于每一个State对象，Flutter framework只会调用一次该回调，所以，通常在该回调中做一些一次性的操作，如状态初始化、订阅子树的事件通知等。不能在该回调中调用`BuildContext.inheritFromWidgetOfExactType`（该方法用于在Widget树上获取离当前widget最近的一个父级`InheritFromWidget`，关于`InheritedWidget`我们将在后面章节介绍），原因是在初始化完成后，Widget树中的`InheritFromWidget`也可能会发生变化，所以正确的做法应该在在`build（）`方法或`didChangeDependencies()`中调用它。
- `didChangeDependencies()`：当State对象的依赖发生变化时会被调用；例如：在之前`build()` 中包含了一个`InheritedWidget`，然后在之后的`build()` 中`InheritedWidget`发生了变化，那么此时`InheritedWidget`的子widget的`didChangeDependencies()`回调都会被调用。典型的场景是当系统语言Locale或应用主题改变时，Flutter framework会通知widget调用此回调。
- `build()`：此回调读者现在应该已经相当熟悉了，它主要是用于构建Widget子树的，会在如下场景被调用：
  1. 在调用`initState()`之后。
  2. 在调用`didUpdateWidget()`之后。
  3. 在调用`setState()`之后。
  4. 在调用`didChangeDependencies()`之后。
  5. 在State对象从树中一个位置移除后（会调用deactivate）又重新插入到树的其它位置之后。
- `reassemble()`：此回调是专门为了开发调试而提供的，在热重载(hot reload)时会被调用，此回调在Release模式下永远不会被调用。
- `didUpdateWidget()`：在widget重新构建时，Flutter framework会调用`Widget.canUpdate`来检测Widget树中同一位置的新旧节点，然后决定是否需要更新，如果`Widget.canUpdate`返回`true`则会调用此回调。正如之前所述，`Widget.canUpdate`会在新旧widget的key和runtimeType同时相等时会返回true，也就是说在在新旧widget的key和runtimeType同时相等时`didUpdateWidget()`就会被调用。
- `deactivate()`：当State对象从树中被移除时，会调用此回调。在一些场景下，Flutter framework会将State对象重新插到树中，如包含此State对象的子树在树的一个位置移动到另一个位置时（可以通过GlobalKey来实现）。如果移除后没有重新插入到树中则紧接着会调用`dispose()`方法。
- `dispose()`：当State对象从树中被永久移除时调用；通常在此回调中释放资源。



##  布局类组件

Flutter拥有丰富的布局widget，但这里有一些最常用的布局widget。其目的是尽可能快地让您构建应用并运行，而不是让您淹没在整个完整的widget列表中。 有关其他可用widget的信息，请参阅[widget概述](https://flutter.io/widgets/)，或使用[API 参考 docs](https://docs.flutter.io/)文档中的搜索框。 此外，API文档中的widget页面经常会推荐一些可能更适合您需求的类似widget。

以下widget分为两类：[widgets library](https://docs.flutter.io/flutter/widgets/widgets-library.html)中的标准widget和[Material Components library](https://docs.flutter.io/flutter/material/material-library.html)中的专用widget 。 任何应用程序都可以使用widgets library中的widget，但只有Material应用程序可以使用Material Components库。

### 标准 widgets

- [Container](https://flutterchina.club/tutorials/layout/#container)

    添加 padding, margins, borders, background color, 或将其他装饰添加到widget.

- [GridView](https://flutterchina.club/tutorials/layout/#gridview)

    将 widgets 排列为可滚动的网格.

- [ListView](https://flutterchina.club/tutorials/layout/#listview)

    将widget排列为可滚动列表

- [Stack](https://flutterchina.club/tutorials/layout/#stack)

    将widget重叠在另一个widget之上.

### Material Components

- [Card](https://flutterchina.club/tutorials/layout/#card)

    将相关内容放到带圆角和投影的盒子中。

- [ListTile](https://flutterchina.club/tutorials/layout/#listtile)

    将最多3行文字，以及可选的行前和和行尾的图标排成一行

**配置文件 Widget 生成了 Element，而后创建 RenderObject 关联到 Element 的内部 `renderObject` 对象上，最后Flutter 通过 RenderObject 数据来布局和绘制。** 理论上你也可以认为 RenderObject 是最终给 Flutter 的渲染数据，它保存了大小和位置等信息，Flutter 通过它去绘制出画面。RenderObject 涉及到布局、计算、绘制等流程，要是每次都全部重新创建开销就比较大了。所以Widget 做了对应的判断以便于复用，比如：在 `newWidget` 与`oldWidget` 的 *runtimeType* 和 *key* 相等时会选择使用 `newWidget` 去更新已经存在的 Element 对象，不然就选择重新创建新的 Element。

```
 static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType
        && oldWidget.key == newWidget.key;
  }
```

**Widget 重新创建，Element 树和 RenderObject 树并不会完全重新创建。**

