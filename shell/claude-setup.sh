#!/usr/bin/env zsh
# ============================================================================
# claude-setup.sh - Interactive Claude subagent setup for project folders
# ============================================================================
# This script provides an interactive walkthrough to add Claude subagents
# to a project's .claude directory based on the awesome-claude-code-subagents
# registry at ~/dotfiles/subagents-registry

DOTFILES_CLAUDE="${HOME}/dotfiles/.claude"
SUBAGENTS_REGISTRY="${DOTFILES_CLAUDE}/subagents-registry"
CATEGORIES_DIR="${SUBAGENTS_REGISTRY}/categories"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Display a welcome banner
_show_banner() {
  cat << 'EOF'

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🤖  Claude Subagent Setup Wizard  🤖                        ║
║                                                               ║
║   Interactive tool to add Claude subagents to your project    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF
}

# List available categories
_list_categories() {
  echo -e "${BLUE}Available Agent Categories:${NC}\n"

  echo "  01-core-development          - Backend, frontend, API, fullstack"
  echo "  02-language-specialists      - Language-specific experts"
  echo "  03-infrastructure            - DevOps, cloud, containerization"
  echo "  04-quality-security          - Testing, QA, security"
  echo "  05-data-ai                   - Data science, ML, AI specialists"
  echo "  06-developer-experience      - Developer tools, CLI, docs"
  echo "  07-specialized-domains       - Industry-specific agents"
  echo "  08-business-product          - Product, business analysis"
  echo "  09-meta-orchestration        - Orchestration, coordination"
  echo "  10-research-analysis         - Research, analysis, investigation"
  echo ""
}

# Browse agents in a category
_browse_category() {
  local category="$1"
  local cat_dir="${CATEGORIES_DIR}/${category}"

  if [[ ! -d "$cat_dir" ]]; then
    echo -e "${RED}✗ Category not found: $category${NC}"
    return 1
  fi

  echo -e "\n${BLUE}Agents in ${CYAN}${category}${BLUE}:${NC}\n"

  local index=1
  local -a agents=()

  for agent_file in "${cat_dir}"/*.md; do
    [[ "$agent_file" == *"README.md" ]] && continue

    local agent_name=$(basename "$agent_file" .md)
    agents+=("$agent_name")

    # Extract description from YAML frontmatter
    local description=$(sed -n '/^description: /s/^description: //p' "$agent_file")
    # Truncate long descriptions
    if [[ ${#description} -gt 70 ]]; then
      description="${description:0:67}..."
    fi
    printf "  ${MAGENTA}%2d${NC}. ${CYAN}%-30s${NC} %s\n" "$index" "$agent_name" "$description"
    ((index++))
  done

  echo ""
  echo -e "${YELLOW}Select agents (e.g., '1,2,3' or 'a' for all, or 'q' to skip):${NC}"
  printf "> "
  read -r selection

  if [[ "$selection" == "q" ]] || [[ -z "$selection" ]]; then
    return 0
  fi

  local -a selected_agents=()
  if [[ "$selection" == "a" ]]; then
    selected_agents=("${agents[@]}")
  else
    # Parse comma-separated selections
    local -a indices=()
    # Split on commas
    local temp_selection="$selection"
    while [[ -n "$temp_selection" ]]; do
      local part="${temp_selection%%,*}"
      part="${part// /}"  # Remove spaces
      if [[ -n "$part" ]]; then
        indices+=("$part")
      fi
      [[ "$temp_selection" == *"," ]] && temp_selection="${temp_selection#*,}" || temp_selection=""
    done

    # Convert indices to agent names
    for idx in "${indices[@]}"; do
      if [[ "$idx" =~ ^[0-9]+$ ]] && ((idx >= 1 && idx <= ${#agents[@]})); then
        selected_agents+=("${agents[$((idx-1))]}")
      fi
    done
  fi

  _add_agents "$category" "${selected_agents[@]}"
}

# Add selected agents to the project's .claude folder
_add_agents() {
  local category="$1"
  shift
  local -a agents=("$@")

  if [[ ${#agents[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No agents selected.${NC}"
    return 0
  fi

  echo -e "\n${BLUE}Adding ${#agents[@]} agent(s) to .claude/agents/:${NC}\n"

  local agents_dir=".claude/agents"
  mkdir -p "$agents_dir"

  for agent in "${agents[@]}"; do
    local source_file="${CATEGORIES_DIR}/${category}/${agent}.md"
    local dest_file="${agents_dir}/${agent}.md"

    if [[ -f "$source_file" ]]; then
      cp "$source_file" "$dest_file"
      echo -e "${GREEN}✓${NC} Added ${CYAN}${agent}${NC}"
    else
      echo -e "${RED}✗${NC} Failed to find ${CYAN}${agent}${NC}"
    fi
  done

  echo ""
}

# Interactive category selection menu
_interactive_menu() {
  echo -e "${BLUE}Select a category to browse (1-10, or 'q' to quit):${NC}\n"

  local -a categories=(
    "01-core-development"
    "02-language-specialists"
    "03-infrastructure"
    "04-quality-security"
    "05-data-ai"
    "06-developer-experience"
    "07-specialized-domains"
    "08-business-product"
    "09-meta-orchestration"
    "10-research-analysis"
  )

  for i in {1..10}; do
    printf "  ${MAGENTA}%2d${NC}. %s\n" "$i" "${categories[$i]}"
  done

  echo ""
  printf "${YELLOW}Enter choice: ${NC}"
  read -r "cat_choice"

  if [[ "$cat_choice" == "q" ]]; then
    return 1
  elif [[ "$cat_choice" =~ ^[0-9]+$ ]] && ((cat_choice >= 1 && cat_choice <= 10)); then
    _browse_category "${categories[$cat_choice]}"
    return 0
  else
    echo -e "${RED}Invalid choice${NC}"
    return 0
  fi
}

# Main setup flow
_run_setup() {
  _show_banner

  if [[ ! -d .claude ]]; then
    echo -e "${RED}✗ No .claude folder found in current directory${NC}"
    echo -e "${YELLOW}Run 'claude setup' to initialize the .claude directory first.${NC}"
    return 1
  fi

  while true; do
    _list_categories

    if ! _interactive_menu; then
      break
    fi

    echo ""
    printf "${YELLOW}Continue? (y/n): ${NC}"
    read -r "continue_choice"
    [[ "$continue_choice" == "y" ]] || break
  done

  echo -e "\n${GREEN}✓ Setup complete!${NC}"
  echo -e "${CYAN}Project agents are stored in: .claude/agents/${NC}\n"
}

# Run setup if this script is executed directly
_run_setup "$@"
