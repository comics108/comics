import 'package:flutter/material.dart';

import 'models.dart';

/// Which element type is selected in the right-hand Properties pane.
enum SelKind { none, layer, sound }

/// Single source of truth. Every mutation calls notifyListeners();
/// widgets rebuild through EditorScope / ListenableBuilder.
class EditorController extends ChangeNotifier {
  ComicsDoc? doc;
  Lang lang = Lang.en;
  bool muted = false;

  SelKind selKind = SelKind.none;
  int selIndex = -1;
  int selAnim = -1;

  int playhead = 0; // current frame
  final int totalFrames = 600;

  bool get isOpen => doc != null;
  bool get isPuzzle => doc?.type == DocType.puzzle;

  EditorLayer? get selectedLayer =>
      selKind == SelKind.layer ? doc!.layers[selIndex] : null;
  EditorSound? get selectedSound =>
      selKind == SelKind.sound ? doc!.sounds[selIndex] : null;

  List<Anim> get selectedAnims =>
      selectedLayer?.anims ?? selectedSound?.anims ?? const [];
  Anim? get currentAnim =>
      (selAnim >= 0 && selAnim < selectedAnims.length) ? selectedAnims[selAnim] : null;

  // ---- recent files for the Open dialog ----
  static const recents = <RecentFile>[
    RecentFile('beach.comics', DocType.comics, 'Comics · 1080×1920 · edited today'),
    RecentFile('city.comics', DocType.comics, 'Comics · 1080×1920 · 3 days ago'),
    RecentFile('island.puzzle', DocType.puzzle, 'Puzzle · 1024×768 · last week'),
    RecentFile('maze.puzzle', DocType.puzzle, 'Puzzle · 1024×768 · 2 weeks ago'),
  ];

  // ---------- document lifecycle ----------
  void newDoc(DocType type) {
    doc = ComicsDoc(
      name: type == DocType.comics ? 'untitled.comics' : 'untitled.puzzle',
      type: type,
      width: type == DocType.comics ? 1080 : 1024,
      height: type == DocType.comics ? 1920 : 768,
    );
    _clearSelection();
    notifyListeners();
  }

  void openRecent(RecentFile f) {
    doc = ComicsDoc(
      name: f.name,
      type: f.type,
      width: f.type == DocType.comics ? 1080 : 1024,
      height: f.type == DocType.comics ? 1920 : 768,
    );
    if (f.name == 'beach.comics') _seedBeach();
    _clearSelection();
    if (doc!.layers.isNotEmpty) selectLayer(doc!.layers.length - 2 < 0 ? 0 : 2);
    notifyListeners();
  }

  /// The sample scene used across the mockups.
  void _seedBeach() {
    final d = doc!;
    d.layers
      ..add(EditorLayer('sky.png', at: const Offset(0, -40))
        ..swatch = const Color(0xFF2C4256)
        ..size = 1.0)
      ..add(EditorLayer('clouds.png', at: const Offset(40, 120))
        ..swatch = const Color(0xFF4E555C)
        ..size = .5)
      ..add(EditorLayer('hero.png', at: const Offset(70, 210))
        ..swatch = const Color(0xFF57422D)
        ..size = .55
        ..anims.add(Anim(AnimType.rotate, start: 210, end: 360)..angle = 45)
        ..anims.add(Anim(AnimType.alpha, start: 360, end: 480)..alpha = .5))
      ..add(EditorLayer('foreground.png', at: const Offset(0, 430))
        ..swatch = const Color(0xFF374A32)
        ..size = 1.0
        ..visible = false);
    d.sounds
      ..add(EditorSound('wind.mp3')..anims.add(Anim(AnimType.sound, start: 140, end: 320)))
      ..add(EditorSound('wave.mp3')..anims.add(Anim(AnimType.sound, start: 420, end: 560)));
  }

  void setLanguage(Lang l) {
    lang = l;
    notifyListeners();
  }

  void toggleMute() {
    muted = !muted;
    notifyListeners();
  }

  void setCanvasSize(int? w, int? h) {
    if (doc == null) return;
    if (w != null) doc!.width = w;
    if (h != null) doc!.height = h;
    notifyListeners();
  }

  void setScale(double s) {
    doc?.scale = s;
    notifyListeners();
  }

  void setPlayhead(int frame) {
    playhead = frame.clamp(0, totalFrames);
    notifyListeners();
  }

  // ---------- selection ----------
  void _clearSelection() {
    selKind = SelKind.none;
    selIndex = -1;
    selAnim = -1;
  }

  void selectLayer(int i) {
    selKind = SelKind.layer;
    selIndex = i;
    selAnim = doc!.layers[i].anims.isNotEmpty ? 0 : -1;
    notifyListeners();
  }

  void selectSound(int i) {
    selKind = SelKind.sound;
    selIndex = i;
    selAnim = doc!.sounds[i].anims.isNotEmpty ? 0 : -1;
    notifyListeners();
  }

  void selectAnim(int i) {
    selAnim = i;
    notifyListeners();
  }

  // ---------- layers ----------
  void addLayer() {
    final d = doc!;
    final l = EditorLayer('layer_${d.layers.length + 1}.png',
        at: Offset(40, 60.0 + d.layers.length * 30))
      ..swatch = Colors.primaries[d.layers.length % Colors.primaries.length].shade700;
    d.layers.add(l);
    selectLayer(d.layers.length - 1);
  }

  void moveLayer(int dir) {
    if (selKind != SelKind.layer) return;
    final i = selIndex, j = i + dir;
    final ls = doc!.layers;
    if (j < 0 || j >= ls.length) return;
    final tmp = ls[i];
    ls[i] = ls[j];
    ls[j] = tmp;
    selIndex = j;
    notifyListeners();
  }

  void deleteSelected() {
    if (selKind == SelKind.layer) {
      doc!.layers.removeAt(selIndex);
    } else if (selKind == SelKind.sound) {
      doc!.sounds.removeAt(selIndex);
    } else {
      return;
    }
    _clearSelection();
    notifyListeners();
  }

  void toggleVisible(int i) {
    doc!.layers[i].visible = !doc!.layers[i].visible;
    notifyListeners();
  }

  void togglePreview() {
    final l = selectedLayer;
    if (l == null) return;
    l.preview = !l.preview;
    notifyListeners();
  }

  /// Drag the selected layer around the canvas (Translate).
  void dragSelected(Offset delta) {
    final l = selectedLayer;
    if (l == null) return;
    l.translate += delta;
    notifyListeners();
  }

  void setImageFile(int langIndex, String file) {
    selectedLayer?.images[langIndex].file = file;
    notifyListeners();
  }

  void setImagePopup(int langIndex, String popup) {
    selectedLayer?.images[langIndex].popup = popup;
    notifyListeners();
  }

  // ---------- sounds ----------
  void addSound() {
    doc!.sounds.add(EditorSound('sound_${doc!.sounds.length + 1}.mp3')
      ..anims.add(Anim(AnimType.sound, start: playhead, end: playhead + 200)));
    selectSound(doc!.sounds.length - 1);
  }

  void moveSound(int dir) {
    if (selKind != SelKind.sound) return;
    final i = selIndex, j = i + dir;
    final ss = doc!.sounds;
    if (j < 0 || j >= ss.length) return;
    final tmp = ss[i];
    ss[i] = ss[j];
    ss[j] = tmp;
    selIndex = j;
    notifyListeners();
  }

  // ---------- animations ----------
  void addAnim(AnimType type) {
    final l = selectedLayer;
    final s = selectedSound;
    final start = playhead;
    if (l != null) {
      l.anims.add(Anim(type, start: start, end: start + 200));
      selAnim = l.anims.length - 1;
    } else if (s != null) {
      s.anims.add(Anim(AnimType.sound, start: start, end: start + 200));
      selAnim = s.anims.length - 1;
    }
    notifyListeners();
  }

  void deleteAnim() {
    if (currentAnim == null) return;
    selectedAnims.removeAt(selAnim);
    selAnim = selectedAnims.isEmpty ? -1 : 0;
    notifyListeners();
  }

  void editAnim(void Function(Anim a) fn) {
    final a = currentAnim;
    if (a == null) return;
    fn(a);
    notifyListeners();
  }
}

/// Inherited access + rebuild-on-change, no external state package.
class EditorScope extends InheritedNotifier<EditorController> {
  const EditorScope({
    super.key,
    required EditorController controller,
    required super.child,
  }) : super(notifier: controller);

  static EditorController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EditorScope>();
    assert(scope != null, 'EditorScope not found in context');
    return scope!.notifier!;
  }
}
