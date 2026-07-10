import 'package:flutter/material.dart';

enum ScanCaptureRole {
  front,
  back,
  closeUp,
  edge,
  side,
  top,
  bottom,
  serialOrMark,
  damageDetail,
  angledReflective;

  String get id {
    return switch (this) {
      ScanCaptureRole.front => 'front',
      ScanCaptureRole.back => 'back',
      ScanCaptureRole.closeUp => 'closeup',
      ScanCaptureRole.edge => 'edge',
      ScanCaptureRole.side => 'side',
      ScanCaptureRole.top => 'top',
      ScanCaptureRole.bottom => 'bottom',
      ScanCaptureRole.serialOrMark => 'serialOrMark',
      ScanCaptureRole.damageDetail => 'damageDetail',
      ScanCaptureRole.angledReflective => 'angledReflective',
    };
  }

  String get title {
    return switch (this) {
      ScanCaptureRole.front => 'Front / Obverse',
      ScanCaptureRole.back => 'Back / Reverse',
      ScanCaptureRole.closeUp => 'Close-up / detail',
      ScanCaptureRole.edge => 'Edge',
      ScanCaptureRole.side => 'Side',
      ScanCaptureRole.top => 'Top',
      ScanCaptureRole.bottom => 'Bottom',
      ScanCaptureRole.serialOrMark => 'Serial',
      ScanCaptureRole.damageDetail => 'Damage Detail',
      ScanCaptureRole.angledReflective => 'Angled Reflective',
    };
  }

  String get guidance {
    return switch (this) {
      ScanCaptureRole.front => 'Capture the main front face clearly.',
      ScanCaptureRole.back => 'Capture the full back side.',
      ScanCaptureRole.closeUp => 'Capture logos, text, texture or defects.',
      ScanCaptureRole.edge => 'Capture the edge or thickness.',
      ScanCaptureRole.side => 'Capture the side profile clearly.',
      ScanCaptureRole.top => 'Capture the top surface or opening.',
      ScanCaptureRole.bottom => 'Capture the base or underside.',
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
      ScanCaptureRole.closeUp => Icons.center_focus_strong_outlined,
      ScanCaptureRole.edge => Icons.straighten_outlined,
      ScanCaptureRole.side => Icons.view_sidebar_outlined,
      ScanCaptureRole.top => Icons.vertical_align_top_outlined,
      ScanCaptureRole.bottom => Icons.vertical_align_bottom_outlined,
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
      'close-up' || 'closeup' || 'detail' => ScanCaptureRole.closeUp,
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
