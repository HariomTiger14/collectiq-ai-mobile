import 'package:flutter/material.dart';

enum ScanCaptureRole {
  front,
  back,
  leftSide,
  rightSide,
  closeUp,
  edge,
  side,
  top,
  bottom,
  baseUnderside,
  barcode,
  cornerCondition,
  surfaceGlare,
  dateMint,
  serialOrMark,
  damageDetail,
  angledReflective;

  String get id {
    return switch (this) {
      ScanCaptureRole.front => 'front',
      ScanCaptureRole.back => 'back',
      ScanCaptureRole.leftSide => 'leftSide',
      ScanCaptureRole.rightSide => 'rightSide',
      ScanCaptureRole.closeUp => 'closeup',
      ScanCaptureRole.edge => 'edge',
      ScanCaptureRole.side => 'side',
      ScanCaptureRole.top => 'top',
      ScanCaptureRole.bottom => 'bottom',
      ScanCaptureRole.baseUnderside => 'baseUnderside',
      ScanCaptureRole.barcode => 'barcode',
      ScanCaptureRole.cornerCondition => 'cornerCondition',
      ScanCaptureRole.surfaceGlare => 'surfaceGlare',
      ScanCaptureRole.dateMint => 'dateMint',
      ScanCaptureRole.serialOrMark => 'serialOrMark',
      ScanCaptureRole.damageDetail => 'damageDetail',
      ScanCaptureRole.angledReflective => 'angledReflective',
    };
  }

  String get title {
    return switch (this) {
      ScanCaptureRole.front => 'Front / Obverse',
      ScanCaptureRole.back => 'Back / Reverse',
      ScanCaptureRole.leftSide => 'Left side',
      ScanCaptureRole.rightSide => 'Right side',
      ScanCaptureRole.closeUp => 'Close-up / detail',
      ScanCaptureRole.edge => 'Edge',
      ScanCaptureRole.side => 'Side',
      ScanCaptureRole.top => 'Top',
      ScanCaptureRole.bottom => 'Bottom',
      ScanCaptureRole.baseUnderside => 'Base / underside',
      ScanCaptureRole.barcode => 'Logo / barcode',
      ScanCaptureRole.cornerCondition => 'Corner condition',
      ScanCaptureRole.surfaceGlare => 'Surface glare',
      ScanCaptureRole.dateMint => 'Date / mint close-up',
      ScanCaptureRole.serialOrMark => 'Serial',
      ScanCaptureRole.damageDetail => 'Damage Detail',
      ScanCaptureRole.angledReflective => 'Angled Reflective',
    };
  }

  String get guidance {
    return switch (this) {
      ScanCaptureRole.front => 'Capture the main front face clearly.',
      ScanCaptureRole.back => 'Capture the full back side.',
      ScanCaptureRole.leftSide => 'Capture the left side profile.',
      ScanCaptureRole.rightSide => 'Capture the right side profile.',
      ScanCaptureRole.closeUp => 'Capture logos, text, texture or defects.',
      ScanCaptureRole.edge => 'Capture the edge or thickness.',
      ScanCaptureRole.side => 'Capture the side profile clearly.',
      ScanCaptureRole.top => 'Capture the top surface or opening.',
      ScanCaptureRole.bottom => 'Capture the base or underside.',
      ScanCaptureRole.baseUnderside =>
        'Capture the underside/base with markings in focus.',
      ScanCaptureRole.barcode =>
        'Capture the packaging logo, barcode, or maker mark.',
      ScanCaptureRole.cornerCondition =>
        'Capture a corner angle that shows wear and edges.',
      ScanCaptureRole.surfaceGlare =>
        'Tilt slightly to show surface scratches or glare.',
      ScanCaptureRole.dateMint => 'Capture the date and mint mark close up.',
      ScanCaptureRole.serialOrMark =>
        'Capture serial numbers, signatures or maker marks.',
      ScanCaptureRole.damageDetail =>
        'Capture dents, scratches, stains or wear.',
      ScanCaptureRole.angledReflective =>
        'Tilt slightly to reveal scratches, foil or shine.',
    };
  }

  IconData get icon {
    return switch (this) {
      ScanCaptureRole.front => Icons.flip_to_front_outlined,
      ScanCaptureRole.back => Icons.flip_to_back_outlined,
      ScanCaptureRole.leftSide => Icons.view_sidebar_outlined,
      ScanCaptureRole.rightSide => Icons.view_sidebar_outlined,
      ScanCaptureRole.closeUp => Icons.center_focus_strong_outlined,
      ScanCaptureRole.edge => Icons.straighten_outlined,
      ScanCaptureRole.side => Icons.view_sidebar_outlined,
      ScanCaptureRole.top => Icons.vertical_align_top_outlined,
      ScanCaptureRole.bottom => Icons.vertical_align_bottom_outlined,
      ScanCaptureRole.baseUnderside => Icons.vertical_align_bottom_outlined,
      ScanCaptureRole.barcode => Icons.qr_code_2_outlined,
      ScanCaptureRole.cornerCondition => Icons.crop_free_outlined,
      ScanCaptureRole.surfaceGlare => Icons.flare_outlined,
      ScanCaptureRole.dateMint => Icons.calendar_month_outlined,
      ScanCaptureRole.serialOrMark => Icons.qr_code_2_outlined,
      ScanCaptureRole.damageDetail => Icons.report_problem_outlined,
      ScanCaptureRole.angledReflective => Icons.flare_outlined,
    };
  }

  static ScanCaptureRole fromId(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'obverse' || 'front' => ScanCaptureRole.front,
      'reverse' || 'back' => ScanCaptureRole.back,
      'left' || 'leftside' => ScanCaptureRole.leftSide,
      'right' || 'rightside' => ScanCaptureRole.rightSide,
      'close-up' || 'closeup' || 'detail' => ScanCaptureRole.closeUp,
      'base' || 'underside' || 'baseunderside' => ScanCaptureRole.baseUnderside,
      'barcode' || 'logo' || 'logobarcode' => ScanCaptureRole.barcode,
      'corner' ||
      'conditionangle' ||
      'cornercondition' => ScanCaptureRole.cornerCondition,
      'surface' || 'glare' || 'surfaceglare' => ScanCaptureRole.surfaceGlare,
      'date' || 'mintmark' || 'datemint' => ScanCaptureRole.dateMint,
      'serial' ||
      'signature' ||
      'serialormark' ||
      'maker' => ScanCaptureRole.serialOrMark,
      'damage' || 'damagedetail' => ScanCaptureRole.damageDetail,
      'reflective' || 'angledreflective' => ScanCaptureRole.angledReflective,
      'edge' => ScanCaptureRole.edge,
      'side' => ScanCaptureRole.side,
      'top' => ScanCaptureRole.top,
      'bottom' => ScanCaptureRole.bottom,
      _ => ScanCaptureRole.front,
    };
  }
}
