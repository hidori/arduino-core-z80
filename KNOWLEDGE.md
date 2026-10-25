# KNOWLEDGE.md

技術的な一般論・公開情報を、本プロジェクトに必要な観点でまとめる。本プロジェクト固有の技術情報・決定は [SPEC.md](SPEC.md)、
開発手順は [DEVELOPMENT.md](DEVELOPMENT.md)、未確定事項は [TODO.md](TODO.md) を参照。

確度：

- 「Arduino Core の仕組み」は Arduino 公式ドキュメントに基づく。
- 「MAME」は MAME のソースコードに基づく。
- 「Sduino から得られる知見」は Sduino の実装（arduino-builder 時代）に基づき、
  現行 Arduino CLI での挙動は未検証である。

---

## Arduino Core の仕組み

出典：

- [Platform Specification](https://docs.arduino.cc/arduino-cli/platform-specification/)
- [Sketch Build Process](https://docs.arduino.cc/arduino-cli/sketch-build-process/)
- [Sketch Specification](https://docs.arduino.cc/arduino-cli/sketch-specification/)
- [Package Index Specification](https://docs.arduino.cc/arduino-cli/package_index_json-specification/)

### 配置

| インストール方法 | パス |
|---|---|
| Boards Manager | `{directories.data}/packages/<VENDOR>/hardware/<ARCH>/<VERSION>/` |
| 手動 | `{directories.user}/hardware/<VENDOR>/<ARCH>/`（バージョン階層なし） |

- ベンダー名・アーキテクチャ名は英数字と `_` `-` `.` のみ。
  アーキテクチャ名は大文字小文字を区別する。
- アーキテクチャ名はライブラリの `architectures` との照合に使われる。

プラットフォーム直下の構成：

| ファイル / フォルダ | 要否 | 内容 |
|---|---|---|
| `platform.txt` | 必須 | ビルド・アップロードのレシピ |
| `boards.txt` | 必須 | ボード定義 |
| `cores/<core>/` | 必須 | Core ソース。`Arduino.h` を含む |
| `variants/<variant>/` | 任意 | ボード固有ソース・ヘッダー |
| `libraries/` | 任意 | 同梱ライブラリ |
| `programmers.txt` | 任意 | 書き込み器定義 |
| `keywords.txt` | 任意 | IDE のシンタックスハイライト |
| `platform.local.txt` / `boards.local.txt` | 任意 | ユーザーによる上書き |
| `post_install.sh` / `.bat` | 任意 | インストール後スクリプト |

### スケッチのビルド処理

1. **前処理**
   - スケッチフォルダ直下の `.ino` を連結する
     （フォルダ名と同名のファイルが先頭、残りはアルファベット順）。
   - 連結結果は **`.cpp` ファイル**になる。
   - `#include <Arduino.h>` を先頭に自動挿入する（既にあれば挿入しない）。
   - 未宣言の関数のプロトタイプを自動生成する。
   - `#line` 指令を挿入し、エラー位置を元のファイルに対応させる。
   - `.ino` 以外のファイルは前処理しない。
2. **依存解決**
   - インクルードを再帰的に走査し、ライブラリを検出する。
   - 検索順：Core → Variant → システムディレクトリ → 検出済みライブラリ。
   - 前処理には `recipe.preproc.macros` を使う。
3. **コンパイル**
   - 対象はスケッチ直下と `src/`（再帰）の `.c` / `.cpp` / `.S`、
     生成された `.ino.cpp`、使用ライブラリ、Core、Variant。
   - アセンブラは大文字の **`.S` のみ**が対象。
   - 差分ビルドでは `.o` と `.d` が依存ファイルより新しければ再コンパイルを省略する。
4. **アーカイブ**
   - Core（と Variant）のオブジェクトを `core.a` にまとめる。
5. **リンク**
   - スケッチとライブラリのオブジェクトを `core.a` とリンクする。
   - `core.a` からは必要なオブジェクトのみ取り込まれる。
6. **後処理**
   - objcopy で出力形式へ変換し、サイズを表示する。
7. **アップロード**

### スケッチの構成

- フォルダがスケッチ。フォルダ名と同名の `.ino` が必須。
- 追加ファイル：`.ino` `.c` `.cpp` `.S` `.h` `.hpp` `.hh` `.tpp` `.ipp`
- `src/` は再帰的にコンパイルされる（`.ino` は不可）。
- `data/` はコンパイルされない。
- `sketch.yaml` でプロファイル（プラットフォーム・ライブラリのバージョン固定）を定義できる。

### platform.txt

必須メタ情報：`name`、`version`。

レシピ：

| プロパティ | 用途 | 主なプレースホルダー |
|---|---|---|
| `recipe.c.o.pattern` | `.c` のコンパイル | `{includes}` `{source_file}` `{object_file}` |
| `recipe.cpp.o.pattern` | `.cpp` と **`.ino.cpp`** のコンパイル | 同上 |
| `recipe.S.o.pattern` | `.S` のアセンブル | 同上 |
| `recipe.ar.pattern` | `core.a` の生成 | `{archive_file_path}` `{archive_file}` `{object_file}` |
| `recipe.c.combine.pattern` | リンク（`.NUMBER.pattern` で多段化可） | `{object_files}` `{archive_file_path}` |
| `recipe.objcopy.<EXT>.pattern` | 出力形式への変換（複数可） | |
| `recipe.output.tmp_file` / `save_file` | 「コンパイル済みバイナリをエクスポート」 | |
| `recipe.size.pattern` | サイズ表示 | `recipe.size.regex` / `recipe.size.regex.data` |
| `recipe.advanced_size.pattern` | JSON でサイズを返す方式（CLI 0.21.0 以降、優先） | |
| `recipe.preproc.macros` | 前処理 | `{preprocessed_file_path}` |

- `recipe.preproc.macros` が未定義の場合は `recipe.cpp.o.pattern` が使われる。
  また `-MMD` は自動的に除去される。
- `recipe.advanced_size.pattern` は `sections`（`name` `size` `max_size`）を
  持つ JSON を出力し、サイズ超過の判定もツール側で行う。

フック（`.NUMBER.pattern` で複数指定可、ソート順に実行。10 以上はゼロ埋め）：

- `recipe.hooks.prebuild`
- `recipe.hooks.sketch.prebuild` / `postbuild`
- `recipe.hooks.libraries.prebuild` / `postbuild`
- `recipe.hooks.core.prebuild` / `postbuild`
- `recipe.hooks.linking.prelink` / `postlink`
- `recipe.hooks.objcopy.preobjcopy` / `postobjcopy`
- `recipe.hooks.savehex.presavehex` / `postsavehex`

主な定義済みプロパティ：

| プロパティ | 内容 |
|---|---|
| `{build.path}` `{build.project_name}` `{build.arch}` | ビルドディレクトリ・プロジェクト名・アーキテクチャ |
| `{build.core.path}` `{build.variant.path}` `{build.system.path}` | 各フォルダのパス |
| `{runtime.platform.path}` `{runtime.hardware.path}` | プラットフォームのパス |
| `{runtime.ide.version}` | IDE バージョン（1.8.3 → `10803`） |
| `{runtime.os}` | ホスト OS |
| `{runtime.tools.<NAME>.path}` | Boards Manager で導入したツールのパス |
| `{build.fqbn}` `{build.source.path}` | FQBN・スケッチのパス |
| `{compiler.optimization_flags}` | デバッグ / リリース用最適化フラグ |

- `-DARDUINO={runtime.ide.version}`、`-DARDUINO_{build.board}`、
  `-DARDUINO_ARCH_{build.arch}` をレシピで渡すのが慣習。
- `compiler.*.extra_flags`、`build.extra_flags` も慣習的な拡張ポイント。
- プロパティは `.linux` / `.windows` / `.macosx` の接尾辞で OS 別に定義できる。

### boards.txt

- キーは `<BOARD_ID>.` で始まり、選択時に接頭辞なしのグローバル名へ昇格する。
- 主なキー：
  - `name` — 表示名
  - `build.board` — `ARDUINO_<値>` マクロ（未定義なら警告付きで自動生成）
  - `build.core` / `build.variant` — 使用する Core / Variant
  - `upload.tool.<PROTOCOL>` / `upload.tool.default` — アップロードツール
  - `upload.maximum_size` / `upload.maximum_data_size` — サイズ上限（超過でビルド失敗）
- `menu.<MENU_ID>` でユーザー選択式のビルドオプションを定義できる。
  FQBN では `VENDOR:ARCH:BOARD:menu=option` で指定する。
- `build.core=VENDOR:CORE` で他プラットフォームの Core を参照できる。

### アップロード

- ツールは `tools.<TOOL>.upload.pattern` で定義する。
- `upload.tool.<PROTOCOL>` でポートのプロトコル別にツールを選ぶ。
- **ポートが指定されない場合は `upload.tool.default` のツールが使われる。**
  ポートを持たないターゲット（エミュレータ起動等）はこれを使う。
- `tools.<TOOL>.upload.field.<NAME>` でユーザー入力欄を定義できる。
- discovery を宣言しないプラットフォームは
  `builtin:serial-discovery` / `builtin:mdns-discovery` を継承する。

### 開発中の Core の配置（手動インストール）

- スケッチブックフォルダ（`directories.user`）の `hardware/<VENDOR>/<ARCH>/` に置く。
  - Windows の既定：`%USERPROFILE%\Documents\Arduino\hardware\<VENDOR>\<ARCH>\`
  - Linux の既定：`~/Arduino/hardware/<VENDOR>/<ARCH>/`
  - 実際の場所は `arduino-cli config get directories.user` または IDE の設定で確認する
    （Windows ではドキュメントが OneDrive 配下にリダイレクトされている場合がある）。
- `<ARCH>` 直下に `platform.txt` `boards.txt` `cores/` 等を置く（バージョン階層なし）。
- `platform.txt` / `boards.txt` の変更は IDE の再起動後に反映される。

### ツールチェーンの配布（Boards Manager）

- パッケージインデックスのファイル名は `package_<NAME>_index.json`
  （`package_` と `_index.json` は必須）。
- `packages[].platforms[]` の主な項目：
  `name` `architecture` `version` `category`（サードパーティは `Contributed`）
  `url` `archiveFileName` `checksum` `size` `boards` `toolsDependencies`
- `packages[].tools[]` は `name` `version` `systems[]` を持ち、
  `systems[]` にホストごとの `host` `url` `archiveFileName` `checksum` `size` を並べる。
- ホスト識別子の例：
  `x86_64-.*linux-gnu`、`(aarch64|arm64)-linux-gnu`、
  `i[3456]86-.*(mingw32|cygwin)`、`(amd64|x86_64)-.*(mingw32|cygwin)`、
  `x86_64-apple-darwin.*`、`arm64-apple-darwin.*`
  （macOS arm64 は x86_64 版、Windows 64 ビットは 32 ビット版でも動作可）
- アーカイブはルートに単一フォルダを持つ。
  プラットフォームのアーカイブではアーキテクチャフォルダを除き、
  `cores/` `variants/` `platform.txt` 等を直下に置く。
- 形式：`.zip` `.tar.bz2` `.tar.gz`（CLI 0.30.0 以降は `.tar.xz` `.tar.zst` も可）。
- ツールは Boards Manager が自動でダウンロード・展開し、
  `platform.txt` から `{runtime.tools.<NAME>.path}` で参照する。
  **ユーザーにインストールスクリプトを実行させる必要はない。**
- `post_install` スクリプトは IDE 2.x では全プラットフォームで実行され、
  CLI では対話モード時に実行される（設定で変更可）。
  非対話環境では実行されないため、必須処理を依存させない。

---

## MAME

以下は MAME の PC-8001 ドライバー
（[src/mame/nec/pc8001.cpp](https://github.com/mamedev/mame/blob/master/src/mame/nec/pc8001.cpp)）
のソースに基づく。

- Windows / Linux / macOS で動作し、デバッガを内蔵する（`-debug`）。
- マシン名：`pc8001`、`pc8001mk2`、`pc8001mk2sr`。
- 必要な ROM（`pc8001`）：
  - N-BASIC：`n80v110.rom`（既定。`n80v101.rom` / `n80v102.rom` も選択可）
  - フォント：`font.rom`
  - ROM は再配布できないため、利用者が用意する。
- スナップショット（`-snapshot`、拡張子 `.bin` / `.n80`）：
  - RAM 64KB 構成が必要。
  - ファイル長は `0x7F40`〜`0x8000` バイト。
  - ファイル先頭 `0x4000` バイトを RAM の `0x4000` 以降へ、
    残りを RAM の `0x0000` 以降へコピーする。
  - ファイル内 `0x7F3E`〜`0x7F3F` の値を SP に設定し、PC を `0xFF3D` に設定して実行する。
  - RAM オフセットと Z80 アドレスの対応は未確認。
- カセットは `.t88` 形式に対応する。
- ドライバーは `MACHINE_NOT_WORKING` 扱い。主な未実装事項：
  - ウェイト・DMA による遅延が未再現で、実機より速く動作する。
    **時間精度の検証には使えない。**
  - uPD3301 の文字属性が未完成。
  - ブザー音に折り返しノイズがある。

その他の PC-8001 エミュレータ：

- Common Source Code Project（Qt 移植版）：PC-8001 対応、デバッガあり。Linux / Windows のみ。
- j80（Java）：OS 非依存、再現度の評判が高い。デバッガの有無は未確認。

---

## Sduino から得られる知見

[Sduino](https://github.com/tenbaht/sduino/) は SDCC を用いた STM8 向けの
Arduino Core（C のみ、C++ 非対応）であり、本プロジェクトと同じ課題を抱える。
以下は Sduino v0.5 のリポジトリ内容に基づく。

### SDCC と Arduino の前提の差異

Arduino のビルドシステムは gcc を前提に、以下を固定的に扱う。

| 種別 | Arduino の前提 | SDCC |
|---|---|---|
| ソース | 拡張子任意（`.ino.cpp` を含む） | `.c` |
| オブジェクト | `.o` | `.rel` |
| アーカイブ | `.a` | `.lib` |
| 依存ファイル | `.d` | `.d` |

### Sduino の解決方法

全レシピをラッパースクリプト（bash）経由で呼び出し、差異を吸収している。

- **コンパイル（`sdcc.sh`）**
  - `.cpp`（= `.ino.cpp`）は `.c` に一時コピーして C としてコンパイルする。
  - SDCC が生成した `.rel` を `.o` としてもコピーし、差分ビルドを成立させる。
- **アーカイブ（`sdar.sh`）**
  - `.o` を `.rel` に読み替えて `sdar` に渡し、生成した `.a` を `.lib` としてもコピーする。
- **リンク（`sdcc-link.sh`）**
  - 引数中の `.o` → `.rel`、`.a` → `.lib` を置換して SDCC を呼ぶ。
- **前処理**
  - `recipe.preproc.macros` もラッパー経由で `sdcc -E` を呼ぶ。
- **Windows 対応**
  - `busybox.exe` を同梱し、`busybox ash` で同じシェルスクリプトを実行する。
  - `compiler.wrapper.path.windows` で OS 別に呼び出し方法を切り替える。
- **ツールパス**
  - ラッパー内で自身のパスから同梱ツールの場所を求め、ユーザーの PATH 設定を不要にしている。
- **main() の取り込み**
  - `.ino` をコンパイルする際、`main` への参照を先頭に付加し、
    `core.a` 内の `main()` が必ずリンクされるようにしている。
- **サイズ表示**
  - リンク結果の各エリア（`HOME` `GSINIT` `GSFINAL` `CODE` `INITIALIZER` / `DATA` `INITIALIZED`）を
    正規表現で集計している。
- **ツール配布**
  - SDCC のスナップショットから対象 CPU 以外のファイルを除いて再パッケージ
    （約 250MB → 6MB）し、ホストごとのアーカイブを Boards Manager で配布している。
  - 書き込みツール等は別のツールパッケージ（`STM8Tools`）として配布している。
  - パッケージインデックスは Makefile とスクリプトで自動生成している。
