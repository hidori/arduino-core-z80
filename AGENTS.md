# AGENTS.md

本リポジトリで作業するエージェント向けの指示。

## プロジェクト概要

Arduino IDE 2.x / Arduino CLI から、SDCC を使って
Z80 搭載レトロ PC（初期ターゲット：NEC PC-8001）向けの
C / Z80 アセンブリのプログラムをビルドするための Arduino Core。

- [README.md](README.md) — 概要・構成
- [SPEC.md](SPEC.md) — 設計仕様・API 仕様
- [TODO.md](TODO.md) — 未確定事項・技術検証・開発タスク
- [DEVELOPMENT.md](DEVELOPMENT.md) — 開発環境・手順
- [KNOWLEDGE.md](KNOWLEDGE.md) — 技術的な一般論・公開情報の、本プロジェクト向けのまとめ（Arduino Core の仕組み、MAME、Sduino）

## 作業方針

- 推測による仕様決定は行わない。
- 未確定事項・検証項目は `TODO.md` で管理する。
- 確定した項目は `TODO.md` から削除し、`SPEC.md` 等の該当ドキュメントへ移す。
- 開発開始後のタスク管理は GitHub Issues で行う。
  - TODO は内容が具体的に見えた時点で、1 件ずつ Issue（ルートチケット）にする
    （見えていないものは `TODO.md` に留め、事前にまとめて Issue 化しない）。
  - エージェントは、TODO が具体的になったと判断したら Issue 化を提案する。
  - Issue 化した TODO は `TODO.md` から削除する。
  - 細分化が必要な場合は、ルートチケットに子チケット（サブイシュー）としてぶら下げる。
- 機種固有の仕様は実機・技術資料等で検証する。
- 書籍を参照した場合、ドキュメントには出典として書籍名・ISBN（ある場合）・章・節名（必要ならページ）のみを書く。
  書籍の文章や ROM の逆アセンブルリストは転載しない。
- ROM イメージはリポジトリ・CI・コンテナイメージ等、外部に置かない
  （置き場所と指定方法は [DEVELOPMENT.md](DEVELOPMENT.md)「ROM」）。
- ドキュメントの書き分け（本書には書かない）：
  - `KNOWLEDGE.md`：技術的な一般論・公開情報を、本プロジェクトに必要な観点でまとめたもの。
    確度（公式ドキュメント・ソースコード・未検証等）を添える。
  - `SPEC.md`：本プロジェクト固有の技術情報・決定。
  - `DEVELOPMENT.md`：開発環境・手順。
  - `TODO.md`：未確定事項・検証項目。

## 作業前に読むもの

- Core（`platform.txt`・`boards.txt`・ビルド処理）に関わる作業：`KNOWLEDGE.md`「Arduino Core の仕組み」「Sduino から得られる知見」
- エミュレータ・E2E テストに関わる作業：`KNOWLEDGE.md`「MAME」、`DEVELOPMENT.md`
