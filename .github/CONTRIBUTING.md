# Contributing to Brockhoff Cloud Platform Claude Tooling

Thank you for your interest in contributing to this collection of Claude plugins! This document provides guidelines for making contributions.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Plugin Development](#plugin-development)
- [Validation](#validation)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project has a [Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) that all contributors are expected to follow. Please be respectful and constructive.

## Getting Started

To get started, you'll need to have `make` installed. Most development tasks are handled via the `Makefile`.

## Development Workflow

The main development tasks are executed via `make`.

| Command | Description |
|---------|-------------|
| `make help` | Show the help message with all available commands. |
| `make lint` | Run the plugin linter to validate all plugins. |
| `make update` | Update the `PLUGINS.md` and website data. |
| `make new-plugin NAME=<name>` | Create a new plugin from the template. |
| `make update-from-template` | Update core files from the template repository. |

### Project Structure

The repository is structured as a [Claude Plugin Marketplace](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces).

```
.
├── plugins/                  # Contains all the plugins
│   └── example-plugin/       # An example plugin
├── scripts/                  # Helper scripts for build and docs
├── .claude-plugin/           # Marketplace configuration
│   └── marketplace.json
├── Makefile                  # Development commands
└── README.md
```

## Plugin Development

### Creating a New Plugin

To create a new plugin, use the `make new-plugin` command:

```bash
make new-plugin NAME=my-awesome-plugin
```

This will scaffold a new plugin in the `plugins/` directory and add it to the `marketplace.json`.

### Plugin Structure

A plugin must follow this directory structure:

```
plugins/your-plugin-name/
├── .claude-plugin/         # Plugin configuration directory (required)
│   └── plugin.json         # Plugin metadata (required)
├── commands/               # Custom commands (required)
├── skills/                 # Reusable skills/tools (optional)
├── agents/                 # Agent definitions (optional)
└── hooks/                  # Lifecycle hooks (optional)
```

The `plugin.json` file contains metadata about the plugin:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "A clear description of what the plugin does.",
  "author": {
    "name": "Author Name"
  }
}
```

## Validation

All plugins must pass the linter. To run the linter locally, use:

```bash
make lint
```

The linter checks for:
- Correct directory structure.
- Valid `plugin.json` metadata.
- Correct naming conventions.

Pull requests will not be merged if validation fails.

## Code Style

### Plugin Naming
- Use lowercase letters and hyphens (kebab-case).
- The directory name must match the `name` field in `plugin.json`.

### JSON Files
- Use 2-space indentation.

### Markdown Files
- Follow standard Markdown formatting.
- Keep descriptions and documentation clear and up-to-date.

## Submitting Changes

### Pull Request Process

1.  **Fork the repository** and create a new branch for your changes.
2.  **Make your changes.** Add or edit plugins as needed.
3.  **Test your changes.** Run `make lint` to ensure all plugins are valid.
4.  **Commit your changes.** Use the [Conventional Commits](https://www.conventionalcommits.org/) format.
5.  **Push to your fork** and create a Pull Request.
6.  **Fill out the PR template** and request a review.

### Commit Message Format

Use the following format for your commit messages:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: A new feature (e.g., adding a new plugin).
- `fix`: A bug fix.
- `docs`: Documentation changes.
- `style`: Formatting, missing semi colons, etc.
- `refactor`: Refactoring production code.
- `test`: Adding or refactoring tests.
- `chore`: Updating grunt tasks, etc; no production code change.