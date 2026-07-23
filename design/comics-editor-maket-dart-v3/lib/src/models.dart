import 'package:flutter/widgets.dart';

/// Domain model — mirrors the WPF Comics.Editor models 1:1
/// (Layer, Sound, Anim + AnimTypes, Cultures) with no invented functionality.

enum DocType { comics, puzzle }

enum Lang { en, ru, hi }

extension LangLabel on Lang {
  String get label => switch (this) {
        Lang.en => 'En',
        Lang.ru => 'Ru',
        Lang.hi => 'Hi',
      };
}

const kLangs = Lang.values;

/// AnimTypes { Translate, Rotate, Scale, Alpha, Sound }
enum AnimType { translate, rotate, scale, alpha, sound }

extension AnimTypeLabel on AnimType {
  String get label => switch (this) {
        AnimType.translate => 'Translate',
        AnimType.rotate => 'Rotate',
        AnimType.scale => 'Scale',
        AnimType.alpha => 'Alpha',
        AnimType.sound => 'Sound',
      };
}

/// One keyframed animation. Every anim shares Start/End (frames along the
/// scroll/timeline); type-specific fields carry the rest.
class Anim {
  Anim(this.type, {this.start = 0, this.end = 200});
  AnimType type;
  int start;
  int end;

  // translate
  double x = 0, y = 0;
  // rotate / scale pivot
  double pivotX = 0, pivotY = 0;
  double angle = 0;
  double scaleX = 1, scaleY = 1;
  // alpha
  double alpha = 1;

  String get title => type.label;
}

/// A localized artwork slot — one per culture (En/Ru/Hi).
class LayerImage {
  LayerImage({this.file = '', this.popup = ''});
  String file;
  String popup;
}

class EditorLayer {
  EditorLayer(this.name, {Offset? at}) : translate = at ?? Offset.zero {
    for (var i = 0; i < kLangs.length; i++) {
      images.add(LayerImage(file: i == 0 ? name : ''));
    }
    // default anim, like Layer.Create in the original
    anims.add(Anim(AnimType.translate)..y = translate.dy);
  }

  String name;
  bool visible = true;
  bool preview = false;
  final List<LayerImage> images = [];
  final List<Anim> anims = [];

  // live transform used by the canvas
  Offset translate;
  double size = 0.5; // fraction of page width, for the placeholder swatch
  Color swatch = const Color(0xFF57422D);
}

class EditorSound {
  EditorSound(this.file);
  String file;
  final List<Anim> anims = [];
}

class ComicsDoc {
  ComicsDoc({
    required this.name,
    required this.type,
    this.width = 1080,
    this.height = 1920,
  });

  String name;
  DocType type;
  int width;
  int height;
  final List<EditorLayer> layers = [];
  final List<EditorSound> sounds = [];
  double scale = 1; // puzzle zoom (0.125 .. 1 in the original)
}

/// A file the Open dialog can list.
class RecentFile {
  const RecentFile(this.name, this.type, this.meta);
  final String name;
  final DocType type;
  final String meta;
}
