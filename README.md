# Arduino Core for Z80 PCs

Arduino IDE / Arduino CLI を使用して、Z80 搭載レトロ PC 向けの
アプリケーションを C 言語および Z80 アセンブリ言語で開発するための
Arduino Core。

最初のターゲットは **NEC PC-8001**。
将来的には MSX や PC-8801 などへの対応も目指す。

## 概要

本プロジェクトは、Arduino IDE / Arduino CLI の開発環境を
Z80 搭載レトロ PC で利用できるようにすることを目的とする。

Arduino の API や C++ ライブラリとの完全互換は目指さず、
Z80 の低レベル操作とレトロ PC の BASIC に由来する
シンプルな API を提供する。

主な特徴：

- Arduino IDE 2.x / Arduino CLI に対応
- SDCC による C 言語開発
- Z80 アセンブリ言語との混在開発
- Arduino 風の `setup()` / `loop()` に対応
- ユーザー定義の `main()` にも対応
- メモリ・I/O ポートの直接操作
- レジスタを指定した ROM ルーチンの呼び出し
- BASIC 風のテキスト入出力 API
- 機種別 Variant によるハードウェア対応

## 開発状況

**Status: Planning**

現在は仕様策定・技術検証段階。

実装・動作検証は未完了。

## 対応機種

| 機種 | 状態 |
|---|---|
| NEC PC-8001 | 初期開発対象 |
| MSX1 | 将来対応候補 |
| NEC PC-8801 | 将来対応候補 |
| SHARP X1 | 後回し |
| SHARP MZ シリーズ | 後回し |

初期開発では BASIC ROM を搭載した機種を優先する。

## 開発環境

| 用途 | ツール |
|---|---|
| IDE | Arduino IDE 2.x |
| ビルド | Arduino CLI |
| C コンパイラ | SDCC |
| アセンブラ | sdasz80 |
| アーカイバ | sdar |
| リンカ | SDCC / sdldz80 |

## 構成

Arduino CLI の Platform Specification に従い、
以下の要素で Arduino Core を構成する予定。

ベンダー名は `Z80Core`、アーキテクチャ名は `z80` とする
（FQBN：`Z80Core:z80:<ボード名>`）。
リポジトリでは `z80/` 以下に Core 一式を置く。

```
Z80Core/z80/
├── platform.txt        ビルド・アップロードのレシピ定義
├── boards.txt          ボード定義
├── programmers.txt     書き込み手段の定義（任意）
├── keywords.txt        IDE のシンタックスハイライト（任意）
├── cores/z80/          Core（スタートアップ、デフォルト main()、z80.h 等）
├── variants/pc8001/    PC-8001 Variant（basic.h 実装、時間管理、pc8001.h）
└── libraries/          同梱ライブラリ（任意）
```

主な構成要素：

| 要素 | 内容 |
|---|---|
| `platform.txt` | SDCC によるコンパイル・アセンブル・アーカイブ・リンク、プリプロセス、実行形式変換、サイズ表示、アップロードのレシピ |
| `boards.txt` | ボード名、Core / Variant の指定、ロードアドレス等のビルドパラメータ、最大サイズ |
| `cores/z80/` | `Arduino.h`（スケッチに自動インクルードされる）、スタートアップコード、デフォルト `main()`、`z80.h` の実装 |
| `variants/<機種>/` | `basic.h` の実装、時間管理の機種依存部分、機種固有ヘッダー、メモリマップ定義 |
| 変換ツール | SDCC の出力（Intel HEX）から `.hex` / `.bin` を生成（初期目標） |
| パッケージインデックス | Boards Manager 用の `package_<vendor>_index.json` と SDCC 等のツール配布 |

Arduino CLI はスケッチを C++ として扱う前提で設計されているため、
`.ino` の C 言語としてのコンパイルやオブジェクト形式の違いなど、
SDCC との差異を `platform.txt` とツールで吸収する必要がある。

## サンプル

以下は実装予定の API を用いたスケッチの例。

```c
#include <basic.h>

void setup(void)
{
    cls();
    print("HELLO, PC-8001!");
}

void loop(void)
{
    char c = inkey();

    if (c != 0) {
        putch(c);
    }

    delay(10);
}
```

このコードは仕様上の使用例であり、動作確認済みではない。

## ドキュメント

- [SPEC.md](SPEC.md) — 設計仕様・API 仕様
- [TODO.md](TODO.md) — 未確定事項・技術検証・開発タスク
- [DEVELOPMENT.md](DEVELOPMENT.md) — 開発環境・手順
- [KNOWLEDGE.md](KNOWLEDGE.md) — 技術的な一般論・公開情報の、本プロジェクト向けのまとめ

## 参考資料

- [Arduino CLI Platform Specification](https://docs.arduino.cc/arduino-cli/platform-specification/)
- [Arduino CLI Sketch Build Process](https://docs.arduino.cc/arduino-cli/sketch-build-process/)
- [Arduino CLI Sketch Specification](https://docs.arduino.cc/arduino-cli/sketch-specification/)
- [Arduino Language Reference](https://docs.arduino.cc/language-reference/)
- [SDCC](https://sdcc.sourceforge.net/)
- [Sduino](https://github.com/tenbaht/sduino/)

## 将来の展開

将来的には、MC6809 など他の CPU アーキテクチャ向けの
Arduino Core を開発するような展開も考えられる。

## ライセンス

[Apache License 2.0 with LLVM Exception](LICENSE)
（SPDX: `Apache-2.0 WITH LLVM-exception`）

Copyright 2026 Hiroaki SHIBUKI
