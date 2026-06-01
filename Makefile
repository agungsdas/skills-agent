SKILLS_DIR = $(HOME)/.kiro/skills
CURRENT_DIR = $(shell pwd)
SKILL_FOLDERS = $(shell find . -maxdepth 1 -type d ! -name '.' ! -name '.git' -printf '%f\n')

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
	@echo "✅ Done! $(words $(SKILL_FOLDERS)) skills linked."

unlink:
	@echo "🗑️  Removing symlinks from $(SKILLS_DIR)..."
	@rm -rf $(SKILLS_DIR)/*
	@echo "✅ Done!"

status:
	@echo "📂 $(SKILLS_DIR):"
	@ls -la $(SKILLS_DIR)/ 2>/dev/null || echo "  (empty or not found)"
