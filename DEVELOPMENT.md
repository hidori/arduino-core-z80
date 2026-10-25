# DEVELOPMENT.md

Core 開発の環境と手順。

## 開発環境

- リポジトリと日常の開発作業は WSL 上に置く。
- 開発中の SDCC は手動でインストールする（apt 等でも可）。
  開発中はバージョンを厳密に管理しない。
- 開発用エミュレータは MAME を使う（[KNOWLEDGE.md](KNOWLEDGE.md)「MAME」参照）。
  Core 開発の利便性向上のためであり、Core の成果物には含めない。

## Core の配置

Core 一式はリポジトリの `z80/` に置く（[SPEC.md](SPEC.md)「2.5 リポジトリ構成」）。

- 日常のビルド確認は WSL 内の Linux 版 Arduino CLI で行う。
  `~/Arduino/hardware/Z80Core/z80` から Linux のシンボリックリンクでリポジトリの `z80/` を指す。
- Windows のリンク（シンボリックリンク / ジャンクション / ハードリンク）は使わない。
- Windows 版 Arduino IDE での確認は節目に行う。
  `make deploy` で Windows 側の `hardware\Z80Core\z80\` を削除し、`z80/` をコピーする。
  - スケッチブックフォルダは `scripts/win-sketchbook-dir.sh` が
    Arduino IDE の設定（`%USERPROFILE%\.arduinoIDE\arduino-cli.yaml`）から検出する。
  - `make deploy WIN_SKETCHBOOK=/mnt/c/...` または `.env` で明示指定もできる。
- Windows 側では Windows 版の SDCC・自作ツールが必要になる。
- `{runtime.tools.<NAME>.path}` は Boards Manager で導入したツールにのみ生成される。
  手動インストール時は SDCC 等のパスを別途与える必要がある
  （`platform.local.txt` での指定、`{runtime.hardware.path}` からの相対配置等）。

## ROM

- ROM はリポジトリの外、ホームディレクトリ配下に置く。
  MAME の ROM セットの慣例に従い、マシン名のサブディレクトリ（`pc8001/` 等）に
  ROM とフォントを同じディレクトリに置く。
- ROM の場所は `.env` の `MAME_ROM_DIR`（サブディレクトリの親）で明示的に与え、
  MAME には `-rompath` で渡す（MAME の既定の検索パスに依存しない）。
  `.env` はコミットせず、`.env.example` を雛形とする。
- devcontainer では、ホストの ROM ディレクトリを読み取り専用でマウントする。
- `.gitignore` の `*.rom` は誤コミット防止の保険であり、リポジトリ内に ROM を置くことを意図しない。

## テスト

- GitHub Actions：Arduino CLI によるサンプルスケッチのビルドのみ（Windows / macOS / Linux）。
- 手元：`make` による E2E テスト（MAME 上で実行。ROM は各開発者が用意する）。
- ROM を必要とするテストは GitHub Actions で実行しない。
