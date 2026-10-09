# Kiro config paths
KIRO_SKILLS_DIR = $(HOME)/.kiro/skills
KIRO_STEERING_DIR = $(HOME)/.kiro/steering

# Antigravity (Gemini) config paths
GEMINI_CONFIG_DIR = $(HOME)/.gemini/config
GEMINI_PLUGIN_DIR = $(GEMINI_CONFIG_DIR)/plugins/skills-agent
GEMINI_SKILLS_DIR = $(GEMINI_CONFIG_DIR)/skills

CURRENT_DIR = $(shell pwd)
SKILL_FOLDERS = $(shell find skills -maxdepth 1 -mindepth 1 -type d -printf '%f\n')
STEERING_FILES = $(shell find steering -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null)

.PHONY: link unlink status validate link-kiro link-antigravity unlink-kiro unlink-antigravity

# Default link: Install for BOTH Kiro and Antigravity
link: link-kiro link-antigravity
	@echo "🎉 Both Kiro and Antigravity skills & rules linked successfully!"

link-kiro:
	@echo "📦 [Kiro] Copying skills to $(KIRO_SKILLS_DIR)..."
	@mkdir -p $(KIRO_SKILLS_DIR)
	@rm -rf $(KIRO_SKILLS_DIR)/*
	@for folder in $(SKILL_FOLDERS); do \
		cp -r $(CURRENT_DIR)/skills/$$folder $(KIRO_SKILLS_DIR)/$$folder; \
		echo "  ✔ $$folder → $(KIRO_SKILLS_DIR)/$$folder"; \
	done
	@cp $(CURRENT_DIR)/README.md $(KIRO_SKILLS_DIR)/README.md
	@echo "  ✔ README.md → $(KIRO_SKILLS_DIR)/README.md"
	@echo ""
	@echo "📦 [Kiro] Copying steering to $(KIRO_STEERING_DIR)..."
	@mkdir -p $(KIRO_STEERING_DIR)
	@rm -f $(KIRO_STEERING_DIR)/*.md
	@for file in $(STEERING_FILES); do \
		cp $(CURRENT_DIR)/steering/$$file $(KIRO_STEERING_DIR)/$$file; \
		echo "  ✔ $$file → $(KIRO_STEERING_DIR)/$$file"; \
	done
	@echo "✅ [Kiro] Done! $(words $(SKILL_FOLDERS)) skills + $(words $(STEERING_FILES)) steering files copied."
	@echo ""

link-antigravity:
	@echo "🚀 [Antigravity] Linking plugin & skills..."
	@bash $(CURRENT_DIR)/scripts/compile-antigravity.sh $(GEMINI_PLUGIN_DIR) $(GEMINI_SKILLS_DIR)
	@echo ""

# Default unlink: Unlink BOTH
unlink: unlink-kiro unlink-antigravity
	@echo "🗑️  All Kiro and Antigravity links removed!"

unlink-kiro:
	@echo "🗑️  [Kiro] Removing copied files..."
	@rm -rf $(KIRO_SKILLS_DIR)/*
	@rm -f $(KIRO_STEERING_DIR)/*.md
	@echo "✅ [Kiro] Done!"

unlink-antigravity:
	@echo "🗑️  [Antigravity] Removing plugin & skills..."
	@rm -rf $(GEMINI_PLUGIN_DIR)
	@for folder in $(SKILL_FOLDERS); do \
		rm -rf $(GEMINI_SKILLS_DIR)/$$folder; \
	done
	@echo "✅ [Antigravity] Done!"

status:
	@echo "📂 === Kiro Status ==="
	@echo "Skills ($(KIRO_SKILLS_DIR)):"
	@ls -la $(KIRO_SKILLS_DIR)/ 2>/dev/null || echo "  (empty)"
	@echo ""
	@echo "Steering ($(KIRO_STEERING_DIR)):"
	@ls -la $(KIRO_STEERING_DIR)/ 2>/dev/null || echo "  (empty)"
	@echo ""
	@echo "📂 === Antigravity Status ==="
	@echo "Plugin ($(GEMINI_PLUGIN_DIR)):"
	@ls -la $(GEMINI_PLUGIN_DIR)/ 2>/dev/null || echo "  (not installed)"
	@echo ""
	@echo "Rules ($(GEMINI_PLUGIN_DIR)/rules):"
	@ls -la $(GEMINI_PLUGIN_DIR)/rules/ 2>/dev/null || echo "  (empty)"
	@echo ""
	@echo "Skills ($(GEMINI_SKILLS_DIR)):"
	@ls -la $(GEMINI_SKILLS_DIR)/ 2>/dev/null || echo "  (empty)"
	@echo ""

validate:
	@echo "🔍 Validating skills & steering..."
	@errors=0; \
	echo ""; \
	echo "── Steering: checking frontmatter ──"; \
	for file in steering/*.md; do \
		if ! head -1 "$$file" | grep -q "^---$$"; then \
			echo "  ✗ $$file — missing YAML frontmatter"; \
			errors=$$((errors + 1)); \
		elif ! grep -q "^inclusion:" "$$file"; then \
			echo "  ✗ $$file — missing 'inclusion:' in frontmatter"; \
			errors=$$((errors + 1)); \
		else \
			echo "  ✔ $$file"; \
		fi; \
	done; \
	echo ""; \
	echo "── Skills: checking SKILL.md ──"; \
	for folder in skills/*/; do \
		skill="$$folder"SKILL.md; \
		if [ ! -f "$$skill" ]; then \
			echo "  ✗ $$folder — missing SKILL.md"; \
			errors=$$((errors + 1)); \
		elif ! head -1 "$$skill" | grep -q "^---$$"; then \
			echo "  ✗ $$skill — missing YAML frontmatter"; \
			errors=$$((errors + 1)); \
		elif ! grep -q "^name:" "$$skill"; then \
			echo "  ✗ $$skill — missing 'name:' in frontmatter"; \
			errors=$$((errors + 1)); \
		elif ! grep -q "^description:" "$$skill"; then \
			echo "  ✗ $$skill — missing 'description:' in frontmatter"; \
			errors=$$((errors + 1)); \
		else \
			echo "  ✔ $$skill"; \
		fi; \
	done; \
	echo ""; \
	echo "── Skills: checking 'Refer to:' links ──"; \
	for skill in skills/*/SKILL.md; do \
		dir=$$(dirname "$$skill"); \
		grep -oP 'Refer to: `\K[^`]+' "$$skill" 2>/dev/null | while read -r ref; do \
			target="$$dir/$$ref"; \
			if [ ! -f "$$target" ]; then \
				echo "  ✗ $$skill → $$ref (file not found)"; \
				errors=$$((errors + 1)); \
			fi; \
		done; \
	done; \
	for ref_file in skills/*/references/*.md; do \
		[ -f "$$ref_file" ] || continue; \
		dir=$$(dirname "$$ref_file")/.. ; \
		grep -oP 'Refer to: `\K[^`]+' "$$ref_file" 2>/dev/null | while read -r ref; do \
			target="$$dir/$$ref"; \
			if [ ! -f "$$target" ]; then \
				echo "  ✗ $$ref_file → $$ref (file not found)"; \
				errors=$$((errors + 1)); \
			fi; \
		done; \
	done; \
	echo ""; \
	if [ $$errors -gt 0 ]; then \
		echo "❌ Validation failed with $$errors error(s)."; \
		exit 1; \
	else \
		echo "✅ All validations passed!"; \
	fi
