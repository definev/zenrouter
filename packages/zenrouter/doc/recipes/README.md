# ZenRouter Recipes

Practical, copy-paste ready solutions for common routing scenarios. Each recipe includes:
- **Problem statement** - The challenge you're facing
- **Solution overview** - Why this approach works
- **Complete code example** - Ready to use
- **Step-by-step explanation** - How it works
- **Advanced variations** - Take it further
- **Common gotchas** - Avoid mistakes

---

## 🎯 Core Patterns

### [404 Not Found Handling](404-handling.md)
Gracefully handle unknown routes and invalid deep links with custom 404 pages.

**Topics**: Error handling, fallback routing, user experience  
**Paradigm**: Coordinator  
**Difficulty**: ⭐ Easy

---

### [Authentication Flow](authentication-flow.md)
Protect routes, redirect unauthenticated users, and preserve intended destinations.

**Topics**: Route guards, redirects, auth state, login flow  
**Paradigm**: All paradigms  
**Difficulty**: ⭐⭐ Moderate

---

### [Bottom Navigation with Persistent State](bottom-navigation.md)
Create tab bars where each tab maintains its own navigation stack independently.

**Topics**: Tab navigation, IndexedStackPath, persistent state  
**Paradigm**: Coordinator, Imperative  
**Difficulty**: ⭐⭐ Moderate

---

## 🎨 UI & Transitions

### [Custom Route Transitions](route-transitions.md)
Customize page animations—slide, fade, scale, or create your own.

**Topics**: Animations, transitions, StackTransition, Hero  
**Paradigm**: All paradigms  
**Difficulty**: ⭐⭐ Moderate

---

## 🔧 Integration

### [State Management Integration](state-management.md)
Integrate routing with Riverpod, Bloc, Provider, and other state solutions.

**Topics**: Riverpod, Bloc, Provider, auth state, data loading  
**Paradigm**: All paradigms  
**Difficulty**: ⭐⭐ Moderate

---

## 🌐 Web

### [URL Strategies for Web](url-strategies.md)
Configure hash vs. path-based URLs, server setup, and deployment strategies.

**Topics**: URL strategies, hash routing, path routing, deployment  
**Paradigm**: Coordinator (web-only)  
**Difficulty**: ⭐⭐ Moderate

---

## Quick Reference

### By Use Case

| Use Case | Recipe |
|----------|--------|
| Tab bar with persistent tabs | [Bottom Navigation](bottom-navigation.md) |
| Login with protected routes | [Authentication Flow](authentication-flow.md) |
| Invalid URL handling | [404 Handling](404-handling.md) |
| Sidebar + content layout | [Nested Navigation](nested-navigation.md) |
| Custom animations | [Route Transitions](route-transitions.md) |
| Full-screen flows | [Modal Routing](modal-routing.md) |
| Riverpod/Bloc integration | [State Management](state-management.md) |
| Deploying to web | [URL Strategies](url-strategies.md) |

### By Paradigm

| Paradigm | Applicable Recipes |
|----------|-------------------|
| **Imperative** | All except URL Strategies |
| **Declarative** | Route Transitions, Authentication Flow, State Management |
| **Coordinator** | All recipes |

### By Difficulty

| Level | Recipes |
|-------|---------|
| ⭐ **Easy** | 404 Handling |
| ⭐⭐ **Moderate** | Authentication Flow, Bottom Navigation, Route Transitions, Modal Routing, State Management, URL Strategies |
| ⭐⭐⭐ **Advanced** | Nested Navigation |

---

## Need Help?

- **Can't find a recipe?** [Open an issue](https://github.com/definev/zenrouter/issues) requesting a new recipe
- **Found a problem?** [Report it](https://github.com/definev/zenrouter/issues)
- **Have a better solution?** [Contribute](https://github.com/definev/zenrouter/blob/main/CONTRIBUTING.md) your recipe!

---

## Related Documentation

- [Getting Started Guide](../guides/getting-started.md) - Choose your paradigm
- [API Reference](../api/) - Detailed API documentation
- [Paradigm Guides](../paradigms/) - Deep dives into each paradigm
- [Migration Guides](../migration/) - Switching from other routers

---

**Happy Routing! 🧘**
