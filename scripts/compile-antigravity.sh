#!/usr/bin/env bash
set -euo pipefail

# compile-antigravity.sh
# Compiles steering/*.md into Antigravity rules/*.md and sets up plugin manifest & skills

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEST_PLUGIN_DIR="${1:-"${HOME}/.gemini/config/plugins/skills-agent"}"
DEST_SKILLS_DIR="${2:-"${HOME}/.gemini/config/skills"}"

echo "🔧 Compiling Antigravity plugin to ${DEST_PLUGIN_DIR}..."

mkdir -p "${DEST_PLUGIN_DIR}/rules"
mkdir -p "${DEST_PLUGIN_DIR}/skills"
mkdir -p "${DEST_SKILLS_DIR}"

# 1. Generate plugin.json
cat << 'EOF' > "${DEST_PLUGIN_DIR}/plugin.json"
{
  "name": "skills-agent",
  "description": "Clean Architecture patterns, engineering standards, and production rules for Kiro & Antigravity"
}
EOF
echo "  ✔ plugin.json generated"

# Helper: Strip YAML frontmatter
strip_frontmatter() {
  local file="$1"
  awk '
    BEGIN { in_fm=0; past_fm=0 }
    /^---$/ && !past_fm {
      if (in_fm==0) { in_fm=1; next }
      else { in_fm=0; past_fm=1; next }
    }
    !in_fm { print }
  ' "$file"
}

# 2. Process steering files into rules/*.md
echo "📋 Processing steering files into Antigravity rules..."
# Clean existing rule files
rm -f "${DEST_PLUGIN_DIR}/rules"/*.md

for file in "${ROOT_DIR}/steering"/*.md; do
  [ -f "$file" ] || continue
  filename="$(basename "$file")"
  target="${DEST_PLUGIN_DIR}/rules/${filename}"

  strip_frontmatter "$file" > "$target"

  # If this is skill-router.md, append the autonomous execution constraint
  if [ "$filename" = "skill-router.md" ]; then
    cat << 'EOF' >> "$target"

## Autonomous Agent Execution Rule
Ketika menerima task yang relevan dengan domain di atas, AI WAJIB membaca file `SKILL.md` terkait (menggunakan tool `view_file` atau file reference) SEBELUM mulai membuat atau memodifikasi file kode. DILARANG KERAS membuat kode monolitik (satu file ratusan baris) atau membuat kode di luar pattern arsitektur yang telah ditetapkan.
EOF
  fi

  echo "  ✔ steering/${filename} → rules/${filename}"
done

# 3. Copy skills to plugin and global skills directory
echo "📦 Copying skills to Antigravity plugin and global directory..."
for skill_dir in "${ROOT_DIR}/skills"/*; do
  if [ -d "$skill_dir" ]; then
    skill_name="$(basename "$skill_dir")"
    rm -rf "${DEST_PLUGIN_DIR}/skills/${skill_name}"
    cp -r "$skill_dir" "${DEST_PLUGIN_DIR}/skills/${skill_name}"

    rm -rf "${DEST_SKILLS_DIR}/${skill_name}"
    cp -r "$skill_dir" "${DEST_SKILLS_DIR}/${skill_name}"
    echo "  ✔ ${skill_name} → ${DEST_PLUGIN_DIR}/skills/${skill_name} & ${DEST_SKILLS_DIR}/${skill_name}"
  fi
done

cp "${ROOT_DIR}/README.md" "${DEST_PLUGIN_DIR}/skills/README.md"
cp "${ROOT_DIR}/README.md" "${DEST_SKILLS_DIR}/README.md"

echo "✅ Antigravity setup complete!"
