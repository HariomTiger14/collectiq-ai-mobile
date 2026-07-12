# Behavior preservation matrix

| Area | Preserve exactly | Verification |
|---|---|---|
| Bootstrap | environment parsing, feature flags, telemetry/error hooks, unawaited safe cloud startup | environment/cloud startup tests |
| Onboarding | key `onboarding_completed_v1`, complete/reset semantics, Start Scan and Explore Dashboard destinations | first/following launch widget tests |
| Auth | session key `supabase_auth_session`, timeout/error mapping, email/password calls, confirmation cooldowns, anonymous/local behavior, sign-out | controller/repository/deep-link tests |
| Deep links | application IDs, flavour schemes, host/path, callback parser and method channel | Android callback + parser tests |
| Scanner | controller/session, image roles, camera/gallery, enhancement, quality gate, analyzer request/result, save/reset behavior | existing scanner/camera tests + Samsung smoke |
| Portfolio | repository persistence, image paths, filters/sorts, edit/delete, cloud sync metadata | repository/controller/widget tests |
| Shell | tab indices 0/1/2/3, Scan selected behavior, scanner reset rules, hidden nav during active capture | shell navigation tests |

Auth checklist: initialize configuration without secrets; restore and validate cached session; keep signed-out local access; retain anonymous Supabase option; preserve sign-in/sign-up validation; preserve confirmation-required and resend rate-limit states; keep reset email redirect contract until a dedicated security sprint; preserve callback environment validation; preserve safe messages; never log credentials/tokens; retain timeout/retry semantics; preserve sign-out session clearing; do not invent profile gating (none exists).

