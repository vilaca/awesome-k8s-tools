# Contributing to Awesome K8s Tools

Thank you for your interest in contributing to this project!

## Repository Structure

- `data/repos` - List of GitHub repository URLs (one per line)
- `build/` - Build and validation scripts
- `resources/` - Template files for README generation
- `.github/workflows/` - GitHub Actions workflows

## Build Scripts

### `build/validate.sh`

Validates the repository list:
- Checks for duplicate entries
- Checks for archived repositories (when GITHUB_TOKEN is available)

Usage:
```bash
./build/validate.sh
```

With archived repository check:
```bash
GITHUB_TOKEN=<your_token> ./build/validate.sh
```

### `build/check_archived.sh`

Standalone script to check which repositories in `data/repos` are archived on GitHub.

Usage:
```bash
GITHUB_TOKEN=<your_token> ./build/check_archived.sh
```

This script will:
- Fetch repository data from GitHub API
- Identify archived repositories
- Report which archived repos are already marked in `data/repos`
- Highlight archived repos that are not yet marked

### `build/pull.sh`

Fetches repository metadata from GitHub API (stars, forks, issues, etc.)

### `build/generate.sh`

Generates the README.md content from the fetched data

### `build/build.sh`

Main build script that orchestrates the entire build process:
1. Pulls repository data
2. Generates README content
3. Combines with header and footer

## Adding a Repository

To add a new repository to the list:

1. Add the GitHub URL to `data/repos` (one per line)
2. If the repository is archived, add a comment: `# 💀 Archived`
3. Run validation: `./build/validate.sh`
4. Submit a pull request

Example:
```
https://github.com/owner/repo
https://github.com/owner/archived-repo # 💀 Archived
```

## Marking Archived Repositories

When a repository becomes archived:

1. Add a comment to the repository line in `data/repos`:
   ```
   https://github.com/owner/repo # 💀 Archived
   ```

2. You can verify archived repositories using:
   ```bash
   GITHUB_TOKEN=<your_token> ./build/check_archived.sh
   ```

## GitHub Actions Workflow

The project uses GitHub Actions to automatically update the list:

- **Trigger**: Daily at midnight UTC, on push to specific paths, or manual trigger
- **Process**:
  1. Validate repository list (check duplicates and archived status)
  2. Build awesome list (fetch data, generate README)
  3. Commit and push changes

## Local Development

To test the build locally:

1. Set your GitHub token:
   ```bash
   export GITHUB_TOKEN=<your_token>
   ```

2. Run the build:
   ```bash
   ./build/build.sh
   ```

3. Check the generated `README.md`

## API Rate Limits

The scripts use GitHub API and are subject to rate limits:
- **Without authentication**: 60 requests per hour
- **With authentication**: 5,000 requests per hour

Always use a GITHUB_TOKEN for building to avoid rate limit issues.
