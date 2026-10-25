# ローカル環境の設定（.env.example を参照）
-include .env

VENDOR   := Z80Core
ARCH     := z80
CORE_DIR := z80

# Windows 側のスケッチブックフォルダ（WSL のパス）。未指定なら自動検出する。
WIN_SKETCHBOOK ?=

.PHONY: deploy

# Windows 側の hardware/$(VENDOR)/$(ARCH) を削除し、$(CORE_DIR)/ をコピーする。
deploy:
	@test -n "$(VENDOR)" -a -n "$(ARCH)" || { echo "error: VENDOR / ARCH が空です" >&2; exit 1; }
	@test -f "$(CORE_DIR)/platform.txt" || { echo "error: $(CORE_DIR)/platform.txt がありません" >&2; exit 1; }
	@set -e; \
	sketchbook='$(WIN_SKETCHBOOK)'; \
	[ -n "$$sketchbook" ] || sketchbook=$$(scripts/win-sketchbook-dir.sh); \
	[ -d "$$sketchbook" ] || { echo "error: スケッチブックフォルダがありません: $$sketchbook" >&2; exit 1; }; \
	dest="$$sketchbook/hardware/$(VENDOR)/$(ARCH)"; \
	echo "deploy: $(CORE_DIR)/ -> $$dest"; \
	rm -rf "$$dest"; \
	mkdir -p "$$dest"; \
	cp -r "$(CORE_DIR)/." "$$dest/"
