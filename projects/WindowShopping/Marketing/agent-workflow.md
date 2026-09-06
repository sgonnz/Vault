# Content operations workflow

This is the operating specification for WindowShopping marketing. It supports TikTok, Instagram, and Pinterest through Buffer with a human approval gate. It is intentionally a content system, not a publishing bot: no credentials, account connections, direct platform APIs, or unattended publishing are part of this workflow.

## Objective

Turn useful shopping moments into accurate, platform-native content that produces measurable product activation. The primary audience is an intentional online shopper who keeps tabs, screenshots, and wishlists while waiting to decide, buy, or see a better price.

Core message: save it now, decide when the price is right.

## Source of truth

Before drafting, use shipped product behavior and release evidence as the claim authority, followed by product documentation and website copy. Record the source file and date in every content brief. The iOS app is pre-release and must not be mentioned, depicted, or linked until `Product claims.md` records a compiled and tested build plus a live App Store URL.

Reusable product facts:

- WindowShopping is free, has no ads, and does not sell user data.
- People can save products from almost any supported HTTPS store, organize them in collections, and optionally sync them with an account.
- Price and availability monitoring apply only where a product and retailer can be checked reliably.
- Checks run about hourly while the browser and device are available. Price changes require two successful observations.
- A product may remain saved even where monitoring, exact-variant tracking, or timing cannot be guaranteed.

Do not claim universal retailer coverage, real-time monitoring, a guaranteed price drop, a guaranteed restock, retailer partnerships, savings amounts, or iOS availability unless the current release and landing page have been verified.

## Roles and boundaries

| Role | Responsibility | May not do |
| --- | --- | --- |
| Content agent | Research ideas, draft briefs and assets, propose captions and UTMs, summarize results | Access accounts, schedule, publish, reply to people, invent product claims |
| Reviewer | Validate product claims, disclosures, brand fit, rights, and destination | Approve their own unreviewed factual claim without source evidence |
| Operator | Put approved content into Buffer, complete any native-platform steps, retain posting record | Alter approved claims without returning it to review |
| Owner | Final approval and escalation point | Waive legal, privacy, or safety requirements |

## Content lifecycle

`intake -> briefed -> drafted -> review-needed -> changes-requested -> approved -> scheduled -> published -> measured -> archived`

- `intake`: an idea is logged with audience, purpose, and source.
- `briefed`: the idea has a defined claim, CTA, destination, and success measure.
- `drafted`: copy and assets exist, but nothing is ready to schedule.
- `review-needed`: the reviewer has all final files, sources, and platform variants.
- `changes-requested`: revise only against the recorded feedback, then return to review.
- `approved`: the owner has approved the exact caption, asset, CTA, and destination. Approval expires after 14 days or when a product claim changes.
- `scheduled`: operator has entered the approved final into Buffer. A scheduled time is not proof of publication.
- `published`: operator verifies the live post and records the permalink, actual time, and any native completion.
- `measured`: metrics are captured after the review window.
- `archived`: no more routine work is planned; preserve the record and learnings.

Only the owner can move an item to `approved`; only the operator can move it to `scheduled` or `published`. If an approved asset, caption, CTA, destination, or claim changes, return it to `review-needed`.

## Weekly operating cadence

1. Log 5 to 10 ideas using the intake template.
2. Select 3 ideas that map to a single activation outcome, then complete a brief for each.
3. Draft platform-specific assets and captions. A single concept may be adapted, but never blindly cross-posted.
4. Review every factual claim and final destination, then obtain written owner approval in the approval queue.
5. The operator manually schedules approved items in Buffer. Complete any platform-required native step manually.
6. Verify each live post, record it, and review performance 7 days after publication.
7. Convert the strongest learning into a new intake item. Do not optimize against vanity metrics alone.

## Platform guidance

| Channel | Best use | Primary CTA | Operator check |
| --- | --- | --- | --- |
| TikTok | Short demos, shopping frustrations, before-and-after workflows | Visit link in bio or install from profile destination | Verify post, captions, audio rights, and any native completion |
| Instagram | Reels, carousels, Stories, visual save-and-organize demos | Link in bio, profile, or approved Story link | Verify crop, cover, alt text where supported, captions, and any native completion |
| Pinterest | Searchable evergreen guides, wishlists, seasonal planning, product-workflow pins | Open the linked guide or install page | Verify destination URL, title, description, pin image, and disclosure |

Use a single approved destination per post. Do not put affiliate links, retailer checkout links, coupon claims, or product-price callouts in content unless specifically reviewed.

## Safety and quality gates

Before approval, all checks below must pass:

1. **Product truth:** Every functional claim has a current source. Qualified monitoring language is retained where relevant.
2. **No deceptive urgency:** No fabricated scarcity, countdowns, false testimonials, fake discounts, or unsupported performance claims.
3. **Privacy:** No customer names, saved products, screenshots, analytics, account data, or private messages without documented permission and review. Demo accounts and sample products are preferred.
4. **Rights:** Operator has rights to every image, video, music, logo, product photograph, and creator asset. Use platform-cleared audio where required.
5. **Platform fit:** Format, length, crop, accessibility captions, alt text, hashtags, disclosures, and destination meet the channel's current requirements.
6. **Destination:** Final URL loads, matches the CTA, uses the approved UTM, and does not make a stronger claim than the post.
7. **Escalation:** Pause and send to the owner if content concerns health, finance, regulated products, minors, controversy, a complaint, a partnership, a paid promotion, a retailer, a takedown, or a user's personal situation.

No automated comment replies, direct messages, influencer outreach, paid-ad launch, or real-time trend participation is allowed within this workflow.

## UTM convention

Use lowercase, hyphen-separated values. Do not include a person's name, email address, product URL, or other personal data.

```
https://windowshoppings.com/<path>?utm_source=<platform>&utm_medium=organic-social&utm_campaign=<yyyy-mm-theme>&utm_content=<content-id>-<format>
```

Required values:

| Field | Rule | Example |
| --- | --- | --- |
| `utm_source` | `tiktok`, `instagram`, or `pinterest` | `instagram` |
| `utm_medium` | Always `organic-social` for this workflow | `organic-social` |
| `utm_campaign` | `yyyy-mm` plus a concise campaign slug | `2026-09-save-now` |
| `utm_content` | Content ID plus asset format | `ws-202609-003-reel` |

For TikTok or Instagram traffic that shares one profile link, use a stable channel-level `utm_content`, such as `tiktok-profile` or `instagram-profile`. Do not claim placement-level attribution because older posts inherit the current profile destination. Use a unique content ID only when the placement has its own durable destination, such as an individual Pinterest Pin.

## Channel readiness

Complete this once before the first scheduled batch and recheck after account or platform changes:

- Confirm Instagram account type and that its connection supports the intended publishing mode.
- Install and test Buffer mobile notifications for every operator who will complete `Notify Me` posts.
- Mark TikTok posts requiring native music, effects, or other unsupported fields as `Notify Me`.
- Record the destination Pinterest board for every Pin.
- For every placement, record `Automatic` or `Notify Me`, plus the native-completion owner and deadline.
- Use alt text where supported. For video, require burned-in captions, readable on-screen text, and audio description when visual context is necessary.

## Activation measurement

The north-star outcome is a person who installs the extension and saves their first product. Marketing cannot infer this from views alone.

Track only measures that can be attributed honestly. In the current release, post-level first-save, second-save, and alert-setup attribution is unavailable. Optional aggregate telemetry is a directional product-health signal and must not be presented as a campaign conversion. Post-level reporting is limited to platform engagement, UTM visits, and store installs where the store supplies attribution.

| Stage | Measure | Definition | Decision use |
| --- | --- | --- | --- |
| Attention | qualified views | Platform-defined views after excluding obvious bot or test traffic where visible | Does the hook earn attention? |
| Intent | outbound clicks | Tracked visits from the post's UTM destination | Does the CTA and destination fit? |
| Acquisition | extension-store visits or installs | Store analytics, attributed where available | Does intent reach the install surface? |
| Activation | aggregate first-save milestone | Optional aggregate product telemetry, not attributable to a post | Directional product health only |
| Retention signal | second save or alert setup within 7 days | Not instrumented in the current release | Not available |

Record the available evidence, not estimated conversions. Do not calculate first-save activation or retention rates until campaign-safe attribution is implemented and documented. Currently supported calculations are:

```
click-through rate = outbound clicks / qualified views
install rate = attributed installs / outbound clicks
```

Set a campaign target before scheduling. For the first 30-day baseline, prioritize three published, accurately measured posts per channel over a volume target. After the baseline, choose targets from actual median performance, not industry benchmarks.

## Records and retention

Each item needs a content ID in the form `ws-YYYYMM-###`. Store its intake, brief, approval decision, final asset location, UTM, publishing record, and metric snapshot together. Keep the final caption exactly as published. Keep source links and approval evidence for at least one year or the project retention period, whichever is longer.

Templates:

- [Idea intake](templates/idea-intake.md)
- [Content brief](templates/content-brief.md)
- [Approval queue](templates/approval-queue.md)
- [Publishing record](templates/publishing-record.md)
- [Metrics review](templates/metrics-review.md)
