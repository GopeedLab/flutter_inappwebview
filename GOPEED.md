# Profile feature maintenance

Maintenance branch: `codex/gopeed-profiles`, based on upstream `v6.1.5`
(`f67ae1f34868c7660c16a2473f53a7a7bfb6f784`). Upstream history and licenses
are preserved. `master` tracks upstream; feature changes live on this branch.

The fork exposes reusable public Dart APIs: `WebViewProfile`,
`InAppWebViewSettings.profileId`, and `CookieManager.instance(profileId: ...)`.
See [the API guide](doc/webview_profiles.md) for examples and platform limits.
There are no Gopeed-specific settings, method names, or proxy-host restrictions.

Gopeed consumes these APIs from its Flutter host. Gopeed alone owns the mapping
from extension identity to profile UUID and its loopback proxy. That policy is
not part of this library, and Gopeed does not expose these options to extension
JavaScript. The normal internal plugin MethodChannel implements the public Dart
API; application code does not call that channel directly.

Native additions cover named data stores, proxy initialization, scoped cookie
operations, and profile removal. macOS also resigns input focus before disposal
so AppKit cannot retain the store through the responder chain. Android persists
pending shell deletions until the next process start.

## Updating upstream

1. Fetch upstream and tags, then merge a compatible release into the maintenance
   branch. Preserve the additive public API and native lifecycle behavior.
2. Review the diff against the new baseline. Do not replace package directories
   with published archives.
3. Run the facade unit tests in the API guide, existing Android/iOS build jobs,
   and Gopeed's shared provider tests against a normal visible macOS app. Focus
   cleanup requires a visible app; hidden-only testing is insufficient.
4. Pin all five changed packages in Gopeed to the same verified immutable Git
   commit, run `flutter pub get`, and commit its lockfile.
