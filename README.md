# Vibe Didactics

**AI Didactics & Pedagogical Code Explanation for Developers**

## Overview

Modern AI coding assistants allow developers to build complex features and applications at unprecedented speed ("vibe coding"). However, rapid generation often comes at the cost of comprehension: developers end up shipping solutions they do not fully understand, making debugging, maintenance, and long-term skill growth difficult.

**Vibe Didactics** bridges the gap between **AI code generation** and **developer understanding**. Instead of treating AI purely as an output engine, this project focuses on **AI didactics**—explaining the solutions developers create with AI back to them in a structured, pedagogical, and actionable way.

## Project Goal

Our goal is to help **Developers** deeply understand the code and architecture they co-create with AI by:

- **Deconstructing AI-Generated Solutions**: Breaking down generated diffs, architectural patterns, and control flows into digestible mental models.
- **Contextual Teaching**: Explaining *why* a solution was built a certain way, including trade-offs, edge cases, and underlying concepts tailored to the developer's context.
- **Active Comprehension over Passive Acceptance**: Turning every AI-assisted coding session into a learning opportunity so developers retain full ownership of their codebase.

---

## Team & Git Workflow

We are a **team of 5** collaborating on this hackathon project. To avoid merge conflicts and keep `main` stable, **everyone must work in their own `develop` branch**.

### Branching Rules

1. **Never push directly to `main`.**
2. **Work in your own `develop` branch** (e.g., `develop/<your-name>` or `develop-<your-name>`).
3. **Merge via Pull Requests**: When a feature or component is ready, open a Pull Request into `main` (or the shared integration branch) and get a quick review from a teammate.

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/SoloninMichael/vibe-didactics.git
cd vibe-didactics

# 2. Create and switch to your personal develop branch
git checkout -b develop/<your-name>

# 3. Push your branch to origin
git push -u origin develop/<your-name>
```

### Keeping Your Branch Updated

```bash
git fetch origin
git rebase origin/main
```

---

## License

This project is licensed under the [MIT License](LICENSE).
