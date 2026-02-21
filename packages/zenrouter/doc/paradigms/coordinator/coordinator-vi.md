# Viết Coordinator đầu tiên của bạn

> **Tập trung hóa định tuyến, xử lý deep link, quản lý điều hướng lồng nhau**

Bạn đang bắt đầu hướng dẫn nhanh để tạo Coordinator đầu tiên của mình nhằm kích hoạt xử lý định tuyến trong ứng dụng. Trong khoảng 15 phút, bạn sẽ học được những điều cơ bản. Bây giờ hãy bắt đầu!

## Coordinator là gì?

Coordinator là một mẫu (pattern) cung cấp hệ thống định tuyến tập trung với deep linking, đồng bộ hóa URL và hỗ trợ các phân cấp điều hướng lồng nhau phức tạp. Đây là mô hình mạnh mẽ nhất trong ZenRouter, được xây dựng dựa trên nền tảng mệnh lệnh (imperative).

### Khi nào nên sử dụng Coordinator

- Bạn cần hỗ trợ deep linking hoặc URL web
- Xây dựng cho web với điều hướng trình duyệt
- Bạn muốn quản lý tuyến đường (route) tập trung
- Bạn có điều hướng lồng nhau phức tạp (các tab bên trong các tab, ngăn kéo + các tab)
- Bạn cần định tuyến và điều hướng dựa trên URL
- Bạn muốn trạng thái tuyến đường có thể gỡ lỗi
- Bạn đang xây dựng một ứng dụng lớn với nhiều tuyến đường

Hãy cùng tìm hiểu sâu hơn về các khái niệm cốt lõi của Coordinator.

## Ứng dụng ví dụ

Mã nguồn của ứng dụng ví dụ có thể được tìm thấy [tại đây](https://github.com/definev/zenrouter/tree/main/packages/zenrouter/doc/paradigms/coordinator/example). Bạn có thể vào thư mục `example` và chạy `flutter run` để xem kết quả cuối cùng hoặc làm theo hướng dẫn từng bước bên dưới.

### Tạo dự án

Hãy tạo dự án của bạn bằng lệnh `flutter create`.

```bash
flutter create --empty coordinator_example
cd coordinator_example
```

Sau đó mở dự án trong IDE yêu thích của bạn và thêm dependency `zenrouter` vào tệp `pubspec.yaml`.

```yaml
dependencies:
  zenrouter: ^0.2.1
```

Bây giờ việc thiết lập đã hoàn tất, hãy tạo cấu trúc thư mục cho ứng dụng của chúng ta.

```bash
lib
|- main.dart
|- routes
| |- coordinator.dart
| |- app_route.dart
```

### Thiết lập Coordinator

Một `Coordinator` là thành phần trung tâm của định tuyến URI.

Một `Coordinator` quản lý nhiều `StackPath` và cung cấp:
1. **Phân tích URI** - Chuyển đổi URL thành các route
2. **Giải quyết Route** - Tìm đường dẫn chính xác cho mỗi route
3. **Deep Linking** - Xử lý các deep link đến
4. **Điều hướng lồng nhau** - Quản lý nhiều ngăn xếp điều hướng (navigation stack)

Khi sử dụng Coordinator, bạn phải ghi đè (override) phương thức `parseRouteFromUri` để chuyển đổi **URI** thành **Route**.

Lớp AppRoute đại diện cho một route trong ứng dụng. Nó kế thừa lớp RouteTarget và thực thi mixin RouteUnique. Điều này đảm bảo rằng mỗi route có một định danh duy nhất. Xem thêm tại [Phần Mixin](#routeunique).

```dart
/// file: lib/routes/coordinator.dart

import 'app_route.dart';

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    ...
  }
}
```

Và thiết lập `AppRoute` cho `Coordinator`.

```dart
/// file: lib/routes/app_route.dart

abstract class AppRoute extends RouteTarget with RouteUnique {}
```

### Cách tạo một Route?

Bạn sẽ kế thừa lớp trừu tượng `AppRoute` ở trên để tạo một Route mới trong ứng dụng của mình.

Ví dụ, đây là route `Home` và `PostDetail`. `Home` không có tham số, trong khi `PostDetail` có tham số `id`.

> **Quan trọng**: Khi một route có tham số (như `id` trong `PostDetail`), bạn **phải** ghi đè `props` để bao gồm chúng. ZenRouter sử dụng điều này để kiểm tra tính bằng nhau nhằm ngăn chặn các route trùng lặp và xử lý cập nhật chính xác.

```dart
/// file: lib/routes/app_route.dart

class Home extends AppRoute {
  Uri toUri() => Uri.parse('/');
  
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => coordinator.push(PostDetail(id: 1)),
          child: const Text('Go to Post Detail'),
        ),
      ),
    );
  }
}

class PostDetail extends AppRoute {
  PostDetail({
    required this.id,
  });
  
  final String id;
  
  /// Nếu các tham số có tham gia vào hàm `toUri`, bạn phải thêm nó vào `props`
  List<Object?> get props => [id];
  
  Uri toUri() => Uri.parse('/post/$id');
  
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post $id Detail'),
      ),
      body: Center(
        child: Text('Post ID: $id'),
      ),
    );
  }
}
```

### Kết nối Coordinator

Vậy hãy quay lại `AppCoordinator` của bạn. Bạn sẽ cần triển khai ánh xạ từ `uri` sang `AppRoute` trong phương thức `parseRouteFromUri`.

```dart
/// file: lib/routes/coordinator.dart

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => Home(),
      ['post', String id] => PostDetail(id: id),
      /// Không tìm thấy route phù hợp
      _ => NotFoundRoute(uri: uri),
    };
  }
}

/// Không tìm thấy route phù hợp
class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});

  final Uri uri;
  
  @override
  Uri toUri() => uri;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Found'),
      ),
      body: Center(
        child: Text('Route not found: $uri'),
      ),
    );
  }
}
```

Vậy là xong! Bạn đã tạo một Coordinator có thể xử lý deep link và điều hướng lồng nhau.

Cuối cùng chỉ cần kết nối `Coordinator` của bạn bên trong `MaterialApp`.

```dart

void main() {
  runApp(const MainApp());
}

/// Điểm nhập (entrypoint) của ứng dụng
/// 
/// Nó kết nối `Coordinator` bên trong `MaterialApp` của bạn.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  final appCoordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeConfig: appCoordinator,
    );
  }
}
```

Hãy chạy ứng dụng của bạn trong trình duyệt với 
```
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```
Bây giờ khi bạn mở `http://localhost:8080/#/post/123`, nó sẽ đi trực tiếp đến bài viết 123.

### Sử dụng Nâng cao

Bây giờ bạn đã có hai route cơ bản trong ứng dụng của mình, hãy nâng cao hơn nữa!
Hãy tưởng tượng một màn hình chính với hai tab: `Feed` và `Profile`.
- Tab `Feed` chứa hai route con: `PostList` và `PostDetail`.
- Tab `Profile` chứa hai route con: `ProfileView` và `SettingsView`.

Luồng `Feed`: Bạn có một danh sách các bài viết, và khi bạn nhấp vào một bài viết, nó sẽ điều hướng đến route `PostDetail`.

```bash
 0---------------------0
 |                     |
 | Post 1              |
 |- - - - - - - - - - -|
 | Post 2              |
 |- - - - - - - - - - -|
 | Post 3              |
 |- - - - - - - - - - -|
 | Post 4              |
 |- - - - - - - - - - -|
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |    *     |          |
 0---------------------0
          |
          | Nhấn "Post 1"
          V
 0---------------------0
 |                     |
 |    Post 1 Detail    |
 |- - - - - - - - - - -|
 |                     |
 |                     |
 |      Post id: 1     |
 |         |           |
 |     Lorem ipsum     |
 |                     |
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |    *     |          |
 0---------------------0

```

Luồng `Profile`: Bạn có một màn hình hồ sơ và một màn hình cài đặt.

```bash
 0---------------------0
 |                     |
 | Hello, User         |
 |- - - - - - - - - - -|
 | Open "Settings"     |
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |          |    *     |
 0---------------------0
          |
          | Nhấn "Settings"
          V
 0---------------------0
 |                     |
 | <- Settings View    |
 |- - - - - - - - - - -|
 |                     |
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |          |    *     |
 0---------------------0
```

Đó đại diện cho toàn bộ luồng của ứng dụng mới của chúng ta. Để đạt được điều này, tôi cần giới thiệu cho bạn một khái niệm mới: `RouteLayout`. `RouteLayout` thực thi `RouteUnique` và sở hữu một `StackPath` (chứa một danh sách các mục `RouteUnique`).

Có hai loại `StackPath`:
- `NavigationPath`: Một đường dẫn ngăn xếp (stack path) nơi bạn có thể push, pop, hoặc xóa các route một cách linh hoạt; thường được sử dụng với `NavigationStack`.
- `IndexedStackPath`: Một đường dẫn ngăn xếp có số lượng route cố định. Bạn không thể sửa đổi nó sau khi khởi tạo và chỉ có thể chọn cái nào đang hoạt động; thường được sử dụng với `IndexedStack`.

Đối với bố cục ở trên, chúng ta có 3 `RouteLayout` cần tạo:
- `FeedLayout`: Một `NavigationPath` có thể có 2 tab: `PostList` và `PostDetail`.
- `ProfileLayout`: Một `NavigationPath` có thể có 2 tab: `ProfileView` và `SettingsView`.
- `HomeLayout`: Một `IndexedStackPath` chỉ chứa 2 tab: `FeedLayout` và `ProfileLayout`. (Lưu ý rằng `RouteLayout` vẫn là một `RouteUnique`, vì vậy nó có thể được sử dụng như một route).

Bạn phải định nghĩa `StackPath` trong `Coordinator`. Hãy tạo nó trong `lib/routes/coordinator.dart`.

```dart
/// file: lib/routes/coordinator.dart

class AppCoordinator extends Coordinator<AppRoute> {
  late final homeIndexed = IndexedStackPath<AppRoute>.createWith(
    [
      FeedLayout(),
      ProfileLayout(),
    ],
    coordinator: this,
    label: 'home',
  );
  late final feedNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'feed',
  );
  late final profileNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'profile',
  );
  
  /// QUAN TRỌNG: Bạn phải đăng ký tất cả các stack path của mình tại đây!
  /// ZenRouter sử dụng danh sách này để quản lý trạng thái điều hướng và các listener.
  /// Đừng quên bao gồm đường dẫn 'root' được cung cấp bởi Coordinator.
  @override
  List<StackPath<RouteTarget>> get paths => [
    root, 
    homeIndexed,
    feedNavigation,
    profileNavigation,
  ];

  ...
}
```

Và hãy kết nối nó trong tệp `lib/routes/app_route.dart`. `FeedLayout` và `ProfileLayout` nằm trong `HomeLayout` nên chúng ta ghi đè thuộc tính `layout` trong chúng thành `HomeLayout`.

```dart
/// file: lib/routes/app_route.dart

class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.homeIndexed;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: path.activeIndex,
        onTap: (index) {
          coordinator.push(path.stack[index]);

          /// Đảm bảo tab được chọn không trống
          switch (index) {
            case 0:
              if (coordinator.feedNavigation.stack.isEmpty) {
                coordinator.push(PostList());
              }
            case 1:
              if (coordinator.profileNavigation.stack.isEmpty) {
                coordinator.push(Profile());
              }
          }
        },
      ),
    );
  }
}

class FeedLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.feedNavigation;

  Type? get layout => HomeLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return buildPath(coordinator);
  }
}

class ProfileLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.profileNavigation;

  Type? get layout => HomeLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return buildPath(coordinator);
  }
}
```

Chúng ta đang thiết lập `RouteLayout` cho ứng dụng. Bây giờ hãy tạo `PostList` và `PostDetail`.

```dart
class PostList extends AppRoute {
  Uri toUri() => Uri.parse('/post');

  /// `PostList` sẽ được hiển thị bên trong `FeedLayout`
  Type? get layout => FeedLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Post 1'),
          onTap: () => coordinator.push(PostDetail(id: 1)),
        ),
        ListTile(
          title: const Text('Post 2'),
          onTap: () => coordinator.push(PostDetail(id: 2)),
        ),
      ],
    );
  }
}

class PostDetail extends AppRoute {
  ...

  /// `PostDetail` sẽ được hiển thị bên trong `FeedLayout`
  /// Thêm dòng này vào route `PostDetail` hiện có
  Type? get layout => FeedLayout;

  ...
}
```

Tiếp theo, chúng ta đến `ProfileLayout` và tạo `ProfileView` và `SettingsView`.

```dart

class Profile extends AppRoute {
  Uri toUri() => Uri.parse('/profile');

  /// `ProfileView` sẽ được hiển thị bên trong `ProfileLayout`
  Type? get layout => ProfileLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const ListTile(title: Text('Hello, User')),
          ListTile(
            title: const Text('Open Settings'),
            onTap: () => coordinator.push(Settings()),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class Settings extends AppRoute {
  Uri toUri() => Uri.parse('/settings');

  /// `SettingsView` sẽ được hiển thị bên trong `ProfileLayout`
  Type? get layout => ProfileLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(
      child: Text('Settings View'),
    );
  }
}
```

Tuyệt vời, mọi route đã được thiết lập. Bây giờ hãy kết nối nó trong tệp `lib/routes/coordinator.dart`. Mã boilerplate cuối cùng khi định nghĩa một layout là bạn phải định nghĩa một hàm factory trong phương thức `defineLayout`.
Hàm `defineLayout` nhận 2 tham số: `Type` của `RouteLayout` và một factory `Function` tạo ra `RouteLayout`.

```dart
/// file: lib/routes/coordinator.dart

class AppCoordinator extends Coordinator<AppRoute> {
  final homeIndexed = IndexedStackPath<AppRoute>(
    routes: [
      FeedLayout(),
      ProfileLayout(),
    ],
  )..bindLayout(HomeLayout.new);
  late final feedNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'feed',
  )..bindLayout(FeedLayout.new);
  late final profileNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'profile',
  )..bindLayout(ProfileLayout.new);

  @override
  List<StackPath<RouteTarget>> get paths => [
    root,
    homeIndexed,
    feedNavigation,
    profileNavigation,
  ];
  ...
}

```

Phương thức `parseRouteFromUri` cần được làm lại vì chúng ta đã thêm nhiều màn hình mới.

### Xử lý Root Path

Đôi khi bạn muốn chuyển hướng đường dẫn gốc `/` đến một route cụ thể, như `PostList`. Bạn có thể sử dụng mixin `RouteRedirect` để đạt được điều này.

```dart
class IndexRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<AppRoute?> redirect() {
    return PostList();
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

Bây giờ hãy cập nhật `parseRouteFromUri`:

```dart

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['post'] => PostList(),
      ['post', final id] => PostDetail(id: id),
      ['profile'] => Profile(),
      ['settings'] => Settings(),
      _ => NotFoundRoute(uri: uri),
    };
  }
}
```

Tất cả đã xong. Bây giờ bạn có thể chạy ứng dụng của mình và kiểm tra nó. Kết quả cuối cùng sẽ giống như thế này:

![Coordinator](https://raw.githubusercontent.com/definev/zenrouter/main/packages/zenrouter/doc/paradigms/coordinator/final.gif)

## Tài liệu tham khảo API

Để có tài liệu API đầy đủ bao gồm tất cả các phương thức, thuộc tính và cách sử dụng nâng cao, xem:

**[→ Tài liệu tham khảo API Coordinator](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md)**

Tham khảo nhanh cho `Coordinator`:

| Phương thức | Mô tả |
|--------|-------------|
| `parseRouteFromUri(Uri)` | Phương thức trừu tượng để phân tích URL thành các route |
| `push(T)` | Đẩy (push) route vào đường dẫn thích hợp |
| `pop()` | Pop từ đường dẫn động (dynamic path) gần nhất |
| `replace(T)` | Xóa stack và thay thế bằng route |
| `pushOrMoveToTop(T)` | Đẩy hoặc di chuyển route lên đầu |
| `recoverRouteFromUri(Uri)` | Xử lý URI deep link |

| Thuộc tính | Mô tả |
|----------|-------------|
| `root` | Đường dẫn điều hướng chính (luôn hiện diện) |
| `paths` | Tất cả các đường dẫn điều hướng được quản lý bởi coordinator |
| `routerDelegate` | Router delegate cho MaterialApp.router |
| `routeInformationParser` | Route information parser |

**Ví dụ:**
```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['profile'] => ProfileRoute(),
      _ => NotFoundRoute(),
    };
  }
}

MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```


## Route Mixins dành cho Coordinator

Các mixin này cung cấp chức năng đặc biệt khi sử dụng mẫu coordinator:

### RouteUnique

**Bắt buộc** đối với tất cả các route được sử dụng với Coordinator.

```dart
mixin RouteUnique on RouteTarget {
  // Chuyển đổi route thành URL
  Uri toUri();
  
  // Xây dựng giao diện người dùng (UI) cho route này
  Widget build(Coordinator coordinator, BuildContext context);
  
  // Tùy chọn: Bố cục (Layout) để điều hướng lồng nhau
  Type? get layout => null;
}
```

**Ví dụ:**
```dart
class HomeRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome!')),
    );
  }
}
```

### RouteLayout<T>

Tạo một bố cục điều hướng chứa các route khác.

```dart
mixin RouteLayout<T extends RouteUnique> on RouteUnique {
  // Bố cục này quản lý đường dẫn nào?
  StackPath<RouteUnique> resolvePath(Coordinator coordinator);
  
  // Xây dựng UI bố cục (tự động ủy quyền cho layoutBuilderTable)
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context);
  
  // Tùy chọn: Type của bố cục cha
  @override
  Type? get layout => null;
}
```

**Ví dụ - Bố cục điều hướng kiểu NavigationStack:**
```dart
class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: buildPath(coordinator),
    );
  }
}

// Các route chỉ định layout bằng tham chiếu Type
class DetailRoute extends AppRoute {
  @override
  Type? get layout => HomeLayout;
}

// Đăng ký trong Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, () => HomeLayout());
  }
}
```

**Ví dụ - Bố cục điều hướng được lập chỉ mục (tab):**
```dart
class TabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabPath;
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (index) => coordinator.push(tabs[index]),
        items: [...],
      ),
    );
  }
}

// Các route tab sử dụng tham chiếu Type
class HomeTab extends AppRoute {
  @override
  Type? get layout => TabLayout;
}
```

### RouteDeepLink

Xử lý deep link tùy chỉnh với các chiến lược.

```dart
mixin RouteDeepLink on RouteUnique {
  // Chiến lược để xử lý deep link
  DeeplinkStrategy get deeplinkStrategy;
  
  // Trình xử lý deep link tùy chỉnh
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri);
}

enum DeeplinkStrategy {
  replace,  // Thay thế stack hiện tại (mặc định)
  push,     // Đẩy vào stack hiện tại
  custom,   // Sử dụng trình xử lý tùy chỉnh
}
```

**Ví dụ:**
```dart
class ProductRoute extends AppRoute with RouteDeepLink {
  final String productId;
  
  ProductRoute(this.productId);
  
  @override
  Uri toUri() => Uri.parse('/product/$productId');
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // Logic tùy chỉnh: đảm bảo chúng ta đang ở đúng tab
    coordinator.replace(ShopTab());
    
    // Tải dữ liệu sản phẩm
    final product = await loadProduct(productId);
    
    // Sau đó điều hướng đến route này
    coordinator.push(this);
    
    // Ghi log phân tích
    analytics.logDeepLink(uri);
  }
}
```

## Deep Linking

### Cách Deep Link hoạt động

1. Ứng dụng mở với URL: `myapp://home/feed/123`
2. Coordinator gọi `parseRouteFromUri(Uri.parse('myapp://home/feed/123'))`
3. Bạn trả về: `FeedDetail(id: '123')`
4. Coordinator kiểm tra xem route có `RouteDeepLink` hay không
   - Nếu có và strategy == `custom`: Gọi `deeplinkHandler()`
   - Nếu có và strategy == `push`: Đẩy route (Push route)
   - Nếu không: Thay thế stack bằng route (Replace stack)

### Các chiến lược Deep Link

#### Replace (Mặc định)

Thay thế toàn bộ stack bằng route deep link:

```dart
// URL: myapp://profile/123
// Kết quả: Stack = [ProfileRoute('123')]
```

#### Push

Đẩy route vào stack hiện có:

```dart
class MyRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;
}

// Nếu stack là [HomeRoute()]
// Sau khi deep link: Stack = [HomeRoute(), ProfileRoute('123')]
```

#### Custom

Toàn quyền kiểm soát việc xử lý deep link:

```dart
class CheckoutRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // 1. Đảm bảo người dùng đã đăng nhập
    if (!await auth.isLoggedIn()) {
      coordinator.replace(LoginRoute(
        redirectTo: uri.toString(),
      ));
      return;
    }
    
    // 2. Thiết lập navigation stack
    coordinator.replace(HomeRoute());
    coordinator.push(CartRoute());
    coordinator.push(this);
    
    // 3. Theo dõi phân tích
    analytics.logDeepLink(uri);
  }
}
```

### Thử nghiệm Deep Link

#### iOS Simulator
```bash
xcrun simctl openurl booted "myapp://home/feed/123"
```

#### Android Emulator
```bash
adb shell am start -W -a android.intent.action.VIEW \\
  -d "myapp://home/feed/123" com.example.myapp
```

#### Flutter
```dart
// Trong mã của bạn
coordinator.recoverRouteFromUri(
  Uri.parse('myapp://home/feed/123'),
);
```

## Xem thêm

- [Điều hướng Mệnh lệnh (Imperative)](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) - Kiểm soát stack trực tiếp
- [Điều hướng Khai báo (Declarative)](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) - Định tuyến dựa trên trạng thái (State-driven)
- [Hướng dẫn Mixin Route](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md) - Tất cả các mixin có sẵn
- [API Coordinator](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md) - Tham khảo API đầy đủ
- [Hướng dẫn Deep Linking](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/deep-linking.md) - Thiết lập deep link
