# Platform parity: iOS app, browser extension, website

All three clients share one Supabase project and one data model: `public.products.data`
is a JSON blob whose canonical shape is the extension's product object. Every client must
preserve keys it does not understand. This note records the cross-platform decisions so
the three repos do not drift again.

## Decisions

| Area | Decision | Owner |
|---|---|---|
| Price checking rules | One rule set: two-observation confirmation, suspicious-ratio guard, shared `checkStatus` vocabulary, shared `history[]`, shared `lowestNotified` dedupe. Server worker (`WindowShoppingApp/supabase/functions/price-monitor/rules.ts`) and extension (`background.js`) must stay equivalent. | price-monitor `rules.ts` is the reference; extension test asserts field list parity |
| Schema | All migrations live in `WindowShoppingsExtensions/supabase/migrations`. Other repos keep only edge functions. | extension repo |
| Notification defaults | price_drop on, back_in_stock on, on_sale off, immediate, quiet hours off. Seed once when `user_metadata` has no notify keys; otherwise remote wins, only explicit UI changes write. | each client's single default constant |
| Delete account | Hard delete everywhere via the `delete-account` edge function. Extension keeps a separate local-only "Delete all WindowShopping data". | app repo edge function |
| Terminology | "Collections", "My saves", "Save", "Mark purchased", "Archive", "Target price", priority "Normal / High / Must have". Never "Wishlist", "List", "Track" in product UI. | all |

## Intentionally platform-specific

- Compare prices (SerpAPI-backed) and the feedback form stay extension-only for now, to keep backend cost bounded.
- On-page save button and card hearts are inherently extension-only. Share-sheet save is iOS-only.
- The extension keeps its browser-native `storage.sync` mirror; it is not a substitute for cloud sync.

## Checklist before shipping a feature on one platform

1. Does it add a key to `products.data`? Add it to the extension's canonical object and, if it is a monitoring key, to `CHECK_RESULT_FIELDS` and `rules.ts`.
2. Does it need schema? Put the migration in the extension repo only.
3. Does it change a user preference? Store it in `user_metadata` and apply the seed-once / remote-wins rule.
4. Add the feature to the parity table in the README of each repo it touches, or record here why it is platform-specific.
