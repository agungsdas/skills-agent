SKILLS_DIR = $(HOME)/.kiro/skills
STEERING_DIR = $(HOME)/.kiro/steering
CURRENT_DIR = $(shell pwd)
SKILL_FOLDERS = $(shell find skills -maxdepth 1 -mindepth 1 -type d -printf '%f\n')
STEERING_FILES = $(shell find steering -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null)

.PHONY: link unlink status validate

link:
	@echo "📦 Copying skills to $(SKILLS_DIR)..."
	@mkdir -p $(SKILLS_DIR)
	@rm -rf $(SKILLS_DIR)/*
	@for folder in $(SKILL_FOLDERS); do \
		cp -r $(CURRENT_DIR)/skills/$$folder $(SKILLS_DIR)/$$folder; \
		echo "  ✔ $$folder → $(SKILLS_DIR)/$$folder"; \
	done
	@cp $(CURRENT_DIR)/README.md $(SKILLS_DIR)/README.md
	@echo "  ✔ README.md → $(SKILLS_DIR)/README.md"
	@echo ""
	@echo "📦 Copying steering to $(STEERING_DIR)..."
	@mkdir -p $(STEERING_DIR)
	@rm -f $(STEERING_DIR)/*.md
	@for file in $(STEERING_FILES); do \
		cp $(CURRENT_DIR)/steering/$$file $(STEERING_DIR)/$$file; \
		echo "  ✔ $$file → $(STEERING_DIR)/$$file"; \
	done
	@echo ""
	@echo "✅ Done! $(words $(SKILL_FOLDERS)) skills + $(words $(STEERING_FILES)) steering files copied."

unlink:
	@echo "🗑️  Removing copied files..."
	@rm -rf $(SKILLS_DIR)/*
	@rm -f $(STEERING_DIR)/*.md
	@echo "✅ Done!"

status:
	@echo "📂 Skills ($(SKILLS_DIR)):"
	@ls -la $(SKILLS_DIR)/ 2>/dev/null || echo "  (empty)"
	@echo ""
	@echo "📂 Steering ($(STEERING_DIR)):"
	@ls -la $(STEERING_DIR)/ 2>/dev/null || echo "  (empty)"

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
