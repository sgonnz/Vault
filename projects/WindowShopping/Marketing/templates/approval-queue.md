# Approval queue

Use one row per platform-specific publication. The final caption, asset, CTA, and UTM must be attached or linked before review. An approval covers only that exact final version for 14 days.

| Content ID | Channel | Final asset | Final caption and CTA | Destination and UTM | Claim source checked | Rights checked | Reviewer decision | Owner approval and date | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ws-YYYYMM-### |  |  |  |  |  |  | pending / changes requested / approved / rejected |  |  |  |

Rules:

- `approved` requires the owner name, date, and the exact version approved.
- Any changed claim, caption, asset, CTA, or destination returns to `review-needed`.
- `scheduled` and `published` are recorded in the publishing record, not inferred from this queue.
