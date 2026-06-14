# 🍊 OrangeDeck

[![Flutter Version](https://img.shields.io/badge/Flutter-v3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-v3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**OrangeDeck** is a premium, high-fidelity mobile Hacker News client designed around an immersive Tinder-style card-swiping interface. Built from the ground up using Flutter and Riverpod, it transforms how tech enthusiasts discover, read, and discuss Hacker News stories.

---

## ✨ Key Features

*   **Tinder-Style Swiper Feed:** Swipe right to **Save/Bookmark** articles to your personal shelf, and swipe left to **Skip** them. Engineered with realistic spring-back physics, tilt rotations, exit flings, and dynamic "SAVE" / "SKIP" progress overlays.
*   **Customizable Theme & Accent Palettes:** Full support for Light Mode, Dark Mode, and System Theme alignment. Personalize your workspace with 6 premium accent colors (Hacker News Orange, Emerald Green, Cyan Tech, Fuchsia Glow, Amber Alert, and Royal Indigo).
*   **Interactive Top Comment Preview:** A custom gesture-isolated comment preview capsule at the bottom of cards. Tapping it opens a premium glassmorphic modal bottom sheet displaying the commenter's custom initials avatar, timestamp, and full comment.
*   **Deep Discussion Webview Integration:** Tap "View Full Discussion" inside the comment preview sheet or the comments badge to transition into a dual-tab viewer preserving scroll states between the Article reader and the Hacker News discussion thread.
*   **Ad-Free Reader Mode:** An integrated article reader fallback that extracts paragraph elements to provide a distraction-free reading experience.
*   **Explore Category Grid:** An elegant Explore Grid layout mapping 6 Hacker News feeds (Top Stories, Newest, Best, Ask HN, Show HN, and Jobs) using vibrant color gradients and springy cards.
*   **Tactile Haptic Feedback:** Embedded device haptic feedback on card drag triggers, button taps, and category selection.
*   **Offline Cache Resilience:** Built-in automatic Hive caching allows the feed deck to failover gracefully and render cached stories when network connections are down.

---

## 🛠️ Tech Stack & Architecture

OrangeDeck implements a compile-safe, feature-first clean architecture:

```text
lib/
├── main.dart                          # App initialization, Hive startup, root widget
├── core/
│   └── theme/theme_provider.dart      # Persisted Material 3 theme & accent state notifier
├── shared/
│   ├── domain/models/article.dart     # Article JSON parser & HTML sanitizer
│   └── data/hive_persistence_service.dart # Persisted database layer for saved shelf & settings
└── features/
    ├── deck/
    │   ├── domain/models/story_filter.dart
    │   ├── data/                      # HnApiService (Dio) & paginated concurrent DeckRepository
    │   └── presentation/
    │       ├── providers/             # DeckNotifier stack controller & comments preview
    │       ├── widgets/               # CardStack gestures, SwipeCard UI, ExploreCategoryCard
    │       └── screens/               # MainDeckScreen visual swiper feed & explore grid
    ├── saved/
    │   └── screens/                   # SavedArticlesScreen swipe-to-delete chronological list
    └── article_detail/
        └── screens/                   # ArticleWebviewScreen dual-tab webview & reader mode
```

### Key Libraries Used:
*   **State Management:** `flutter_riverpod` (v2.x)
*   **Local Storage:** `hive_flutter`
*   **HTTP Client:** `dio`
*   **Rich Typography:** `google_fonts`
*   **Web Rendition:** `webview_flutter`

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (v3.44.0 or higher recommended)
*   Dart SDK (v3.12.0 or higher)
*   An Android or iOS Emulator/Simulator booted.

### Installation

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/rajann44/orangedeck.git
    cd orangedeck
    ```

2.  **Restore dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run Static Analysis:**
    Ensure code formatting and typing guidelines conform to specifications:
    ```bash
    flutter analyze
    ```

4.  **Execute Unit Tests:**
    ```bash
    flutter test
    ```

5.  **Run on Device:**
    ```bash
    flutter run
    ```

---

## 📱 Release Build

To generate a compiled release build for testing on physical devices:

*   **Android APK:**
    ```bash
    flutter build apk --release
    ```
    The output APK will be placed at `build/app/outputs/flutter-apk/app-release.apk`.

*   **iOS Archive:**
    ```bash
    flutter build ipa
    ```

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
