# Home H02 Emblem Asset Recovery

## Scope

This audit searched for an exact reusable PackLox layered emblem asset for Home H02 Correction Pass 1. It did not implement Flutter changes and did not modify the Design Bible, Design System, or Design Platform authority files.

Search areas:

- Design Platform approved Home authority, Design Lock, Home Design System v1, and Engineering Blueprint evidence.
- Flutter reconstruction repository assets, Android drawables, pubspec declarations, and Home implementation references.
- Legacy `collectiq_ai` repository assets and Android drawables as read-only reference.

## Candidate Matrix

| Path | Type | Dimensions | Hash | Visual match | Reusable? | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_lock\Home\Home_Design_System_v1\01_Authority\state_crops\H02_Empty_Collection.png` | PNG | 128x496 | `4473D72A897627E2A3EB19E1FD1FE5F0E149B479D33245D4BA59EA009DDE6375` | Exact | No | Approved H02 crop contains the layered emblem, but it is a low-resolution state crop and was explicitly not used as a source asset. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\images\home_screen_flow_master.png` | PNG | 1402x1122 | `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A` | Exact | No | Approved authority board includes H02 and the PackLox mark, but the emblem is raster-composited into the board/card artwork and is not a clean standalone asset. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_lock\Home\Home_Design_System_v1\01_Authority\home_screen_flow_master.png` | PNG | 1402x1122 | `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A` | Exact | No | Duplicate authority board; same raster-composited limitation. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\screens\02_empty_collection.png` | PNG | 127x426 | `39DAD412729A90D912D9B18BD8C96422E27B2C706184D75369FBE1EFC9229F27` | Exact | No | Low-resolution screen export; not a clean reusable emblem asset. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\engineering_blueprints\Home\evidence\H02_Empty_Collection_authority_verified.png` | PNG | 128x496 | `4473D72A897627E2A3EB19E1FD1FE5F0E149B479D33245D4BA59EA009DDE6375` | Exact | No | Duplicate of the low-resolution H02 authority crop. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\engineering_blueprints\Home\evidence\Home_H02_Authority_Measurement_Overlay.png` | PNG | 760x1540 | `3DCFEB831C17B366EB03557ABDA7C24817065BD5D301EC513A933422DD04EB0A` | Exact | No | Measurement evidence includes overlays and is not an emblem source asset. |
| `C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction\qa\screenshots\design_lock\home\H02_master_authority\authority\H02_Empty_Collection.png` | PNG | 128x496 | `4473D72A897627E2A3EB19E1FD1FE5F0E149B479D33245D4BA59EA009DDE6375` | Exact | No | Local copy of low-resolution H02 authority crop; prohibited as an extraction source. |
| `C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction\qa\screenshots\approved_authority_recovery\home\approved_reference\02_empty_collection.png` | PNG | 127x426 | `39DAD412729A90D912D9B18BD8C96422E27B2C706184D75369FBE1EFC9229F27` | Exact | No | Local low-resolution authority reference; not a standalone emblem. |
| `C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction\qa\screenshots\approved_authority_remediation\home\authority\phase1_authority_h02_empty_collection_crop.png` | PNG | 141x507 | `8074D10DEBDAF60656D38C9D7D34E98D66D4936B80ECF8D49A12A7D394C48FAC` | Exact | No | Local resized/cropped authority reference; not a clean asset source. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\owner_amendments\home_empty_state_v1.png` | PNG | 853x1844 | `117F5E10BAA05EB1AAB71006BBDACC3AE989F1BD88A3225556D0BE52FD0628E3` | Incorrect | No | Older empty-state screen using an archive-style icon, not the approved layered PackLox emblem. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_lock\Home\H02_Empty_Collection\Home_H02_Final.png` | PNG | 853x1844 | `117F5E10BAA05EB1AAB71006BBDACC3AE989F1BD88A3225556D0BE52FD0628E3` | Incorrect | No | Duplicate older final screen with archive-style icon. |
| `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_lock\Home\H02_Empty_Collection\Home_H02_Mockup_v1.png` | PNG | 1023x1537 | `A288588CB6F4F32D2958CE8F2AAEFE04F2A2201707796D4E3F650959D2169FCC` | Incorrect | No | Older purple first-scan mockup; does not contain the approved layered H02 emblem. |
| `C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction\android\app\src\main\res\drawable\splash_mark.xml` | XML vector | 96x96 viewport | `5661742DF328FD4D8290263B0292CAB0BC3E4122046D5EC233111BA115849560` | Incorrect | No | Android splash mark/check style vector; not the H02 layered collection emblem. |
| `C:\Users\hario\Desktop\projects\collectiq_ai\android\app\src\main\res\drawable\splash_mark.xml` | XML vector | 96x96 viewport | `357B47711F5F201B3BA3F953A15D04A1E3BDC865898D3254B8A25CE33B2EC760` | Incorrect | No | Legacy splash vector; not the H02 layered collection emblem. |
| `C:\Users\hario\Desktop\projects\collectiq_ai\assets\scanner\collectible_montage.png` | PNG | 1672x941 | `BC54505EE01A8DC1C3A96DD176276A235C3C9612E1C92A12A31910F1A3B2EA45` | Incorrect | No | Scanner montage asset; not an emblem. |

## Extraction Assessment

No exact standalone reusable PackLox layered emblem asset was found.

The approved visual emblem exists inside the authority crop and authority board, but those files are raster screen/board compositions. A clean lossless extraction from the higher-resolution board is not available because the emblem is already composited with glow, anti-aliasing, and surrounding dark hero surface pixels. Extracting from those sources would create a cropped or manually matted derivative, not an approved reusable asset.

## Outcome

- Exact reusable emblem found: No.
- Emblem copied into Flutter assets: No.
- `pubspec.yaml` asset registration changed: No.
- Archive icon replaced: No.
- Blocker retained: Yes.

Next required input: approved standalone PackLox layered emblem asset, preferably SVG or transparent PNG at sufficient resolution, supplied by the Design owner or recovered from the original source design file/export.
