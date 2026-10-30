# Cursor Skills

Cursor plugin of engineering workflow skills: Jira task breakdown, pull requests, code review, and system design.

## Skills

| Skill | Use when |
| --- | --- |
| `jira-task` | Breaking a Jira story into subtasks with a fixed 1, 2, or 3 point scale |
| `create-pr` | Opening or updating a pull request (Conventional Commits, Jira key, 200-line budget, stack work report) |
| `code-review` | Reviewing a diff or pull request and returning severity-ranked findings |
| `system-design` | Writing a design doc with one recommended approach, interfaces, and tradeoffs |

## Layout

```
cursor-skills/
├── .cursor-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── skills/
│   ├── jira-task/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── create-pr/
│   │   ├── SKILL.md
│   │   └── examples.md
│   ├── code-review/SKILL.md
│   └── system-design/SKILL.md
└── README.md
```

`.cursor-plugin/marketplace.json` indexes this repo as one plugin. `.cursor-plugin/plugin.json` is that plugin. Skills are discovered from `skills/`.

## Install

Add this repository as a Cursor marketplace (Plugins → Add marketplace), then install **Cursor Skills**. Submit a public remote at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish) to list it in the Cursor Marketplace.
