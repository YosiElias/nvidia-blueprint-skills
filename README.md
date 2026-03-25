# NVIDIA Blueprint Skills

Claude Code skills for managing common OpenShift deployment issues when working with NVIDIA AI Blueprints.

**Repository:** [https://github.com/your-org/nvidia-blueprint-skills](https://github.com/your-org/nvidia-blueprint-skills)

## Skills

### 📖 blueprint-issues
Search team common issues based on conversation context.

**Usage:**
```
/blueprint-issues             # Search based on current context
/blueprint-issues GPU         # Search for GPU-related issues
```

### ➕ blueprint-add-issue
Add a new issue to the team knowledge base.

**Usage:**
```
/blueprint-add-issue [describe the issue you encountered]
```

**What it does:**
1. Asks for issue details (title, category, problem, solution)
2. Formats the issue in the standard template
3. Shows preview and asks for approval
4. Commits to new branch and pushes
5. Provides GitHub link to create PR

## Setup

**1. Clone this repository:**
```bash
git clone https://github.com/your-org/nvidia-blueprint-skills.git
cd nvidia-blueprint-skills
```

**2. Choose installation method:**

**Option A - User-level (works in ALL projects):**
```bash
ln -s ~/nvidia-blueprint-skills/skills/blueprint-issues ~/.claude/skills/
ln -s ~/nvidia-blueprint-skills/skills/blueprint-add-issue ~/.claude/skills/
```

**Option B - Project-level (specific project only):**
```bash
cd ~/your-project
mkdir -p .claude/skills
ln -s ~/nvidia-blueprint-skills/skills/blueprint-issues .claude/skills/
ln -s ~/nvidia-blueprint-skills/skills/blueprint-add-issue .claude/skills/
```

**3. Test:**
```
/blueprint-issues
```

## Issues Database

All issues are stored in [`skills/blueprint-issues/issues.md`](skills/blueprint-issues/issues.md).

- **Edit manually:** Commit directly to main or create PR
- **Add via skill:** Use `/blueprint-add-issue` for guided workflow

## Contributing

When you solve a new OpenShift deployment issue:
1. Run `/blueprint-add-issue` in Claude Code
2. Provide the details
3. Review and approve
4. Create PR from the pushed branch
