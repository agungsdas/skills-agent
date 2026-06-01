SKILLS_DIR = $(HOME)/.kiro/skills
STEERING_DIR = $(HOME)/.kiro/steering
CURRENT_DIR = $(shell pwd)
SKILL_FOLDERS = $(shell find . -maxdepth 1 -type d ! -name '.' ! -name '.git' ! -name 'steering' -printf '%f\n')
STEERING_FILES = $(shell find steering -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null)

link:
	@echo "🔗 Linking skills to $(SKILLS_DIR)..."
	@mkdir -p $(SKILLS_DIR)
	@rm -rf $(SKILLS_DIR)/*
	@for folder in $(SKILL_FOLDERS); do \
		ln -sf $(CURRENT_DIR)/$$folder $(SKILLS_DIR)/$$folder; \
		echo "  ✔ $$folder → $(SKILLS_DIR)/$$folder"; \
	done
	@ln -sf $(CURRENT_DIR)/README.md $(SKILLS_DIR)/README.md
	@echo "  ✔ README.md → $(SKILLS_DIR)/README.md"
	@echo ""
	@echo "🔗 Linking steering to $(STEERING_DIR)..."
	@mkdir -p $(STEERING_DIR)
	@rm -f $(STEERING_DIR)/*.md
	@for file in $(STEERING_FILES); do \
		ln -sf $(CURRENT_DIR)/steering/$$file $(STEERING_DIR)/$$file; \
		echo "  ✔ $$file → $(STEERING_DIR)/$$file"; \
	done
	@echo ""
	@echo "✅ Done! $(words $(SKILL_FOLDERS)) skills + $(words $(STEERING_FILES)) steering files linked."

unlink:
	@echo "🗑️  Removing symlinks..."
	@rm -rf $(SKILLS_DIR)/*
	@rm -f $(STEERING_DIR)/*.md
	@echo "✅ Done!"

status:
	@echo "📂 Skills ($(SKILLS_DIR)):"
	@ls -la $(SKILLS_DIR)/ 2>/dev/null || echo "  (empty)"
	@echo ""
	@echo "📂 Steering ($(STEERING_DIR)):"
	@ls -la $(STEERING_DIR)/ 2>/dev/null || echo "  (empty)"
