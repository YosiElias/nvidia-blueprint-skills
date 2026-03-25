---
name: blueprint-add-issue
description: Add a new issue to the team common issues document. Creates a formatted issue entry, commits it to a new branch, and pushes for PR creation.
disable-model-invocation: true
allowed-tools: "Read(issues.md)"
argument-hint: "[issue description or context]"
---

# Add Team Issue

This skill helps you add a new deployment issue to the team's common issues document (`skills/blueprint-issues/issues.md`).

**Workflow:**
1. Extract or ask for issue details (title, category, description, solution)
2. Format the issue according to the standard template
3. Show the formatted issue to the user for approval
4. Add the issue to `issues.md` (symlinked to blueprint-issues)
5. Run helper script to commit and push changes
6. Instruct user to create PR via GitHub web interface

## Issue Format Template

Each issue should follow this structure:

```markdown
## Issue: [Issue Title]

**Category:** [Category Name]

### Description
[Detailed description of the problem, including symptoms, error messages, and context]

### Solution
[Step-by-step solution or workaround that resolved the issue]

---
```

## Instructions

When the user invokes this skill:

1. **Gather Information** - If the user provides issue details in their message, extract:
   - Issue title (concise, descriptive)
   - Category (e.g., Security, Storage, Configuration, Runtime / Stability, Scheduling, Infrastructure, Functional, RAG / Embeddings)
   - Problem description
   - Solution/workaround

   If information is missing, ask the user for the missing details.

2. **Format the Issue** - Create the issue in the exact format shown above, maintaining consistency with existing issues in `issues.md`.

3. **Show for Approval** - Display the formatted issue to the user and ask for confirmation before proceeding.

4. **Add to issues.md** - Once approved:
   - Read `issues.md` (symlinked to `../blueprint-issues/issues.md`)
   - Insert the new issue before the final `---` separator (if present) or at the end
   - Write the updated file to `issues.md`

5. **Git Workflow** - After updating the file, run the helper script:
   ```bash
   ./commit-and-push.sh "add-issue-[short-slug]" "docs: add [Issue Title] to team issues"
   ```
   The script handles: repository navigation, branch creation, staging, committing, and pushing.

6. **Completion** - The script will output:
   - Confirmation that changes were pushed to the branch
   - Instructions to create a PR with the URL

   Display this output to the user.

## Example Invocation

```
User: /blueprint-add-issue I found an issue with pod security context when using custom service accounts

[The skill would then ask for more details about the problem and solution]
```

## Important Notes

- **Use the Template**: Always format new issues exactly as shown in the "Issue Format Template" section above
- **Concise Titles**: Keep titles short but descriptive
- **No Duplicate Issues**: Check if a similar issue already exists before adding
- **Git Safety**: Always create a new branch; never commit directly to main
