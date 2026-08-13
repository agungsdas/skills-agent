SKILLS_DIR = $(HOME)/.kiro/skills
STEERING_DIR = $(HOME)/.kiro/steering
CURRENT_DIR = $(shell pwd)
SKILL_FOLDERS = $(shell find skills -maxdepth 1 -mindepth 1 -type d -printf '%f\n')
STEERING_FILES = $(shell find steering -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null)

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
