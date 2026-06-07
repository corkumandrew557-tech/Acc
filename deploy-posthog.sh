#!/bin/bash

# PostHog GitHub Integration Setup Script
# This script deploys PostHog event tracking workflows to all your repositories

set -e

# Configuration
POSTHOG_API_KEY="${POSTHOG_API_KEY:?Please set POSTHOG_API_KEY environment variable}"
GITHUB_USER="corkumandrew557-tech"
COMMIT_MESSAGE="chore: Add PostHog event tracking workflow"

# List of repositories to set up
REPOS=(
  "cli"
  "django"
  "labs"
  "moby"
  "monorepo"
  "docs"
  "buildkit-pack"
  "cpython"
)

# Workflow content
read -r -d '' WORKFLOW_CONTENT << 'EOF' || true
name: Track Events to PostHog

on:
  push:
    branches: [main, master, develop]
  pull_request:
    types: [opened, closed, synchronize]
  release:
    types: [published, created]
  workflow_run:
    workflows: ["*"]
    types: [completed]
  issues:
    types: [opened, closed, labeled]

jobs:
  track-event:
    runs-on: ubuntu-latest
    if: github.event_name != 'workflow_run'
    steps:
      - name: Track Push Event
        if: github.event_name == 'push'
        run: |
          curl -X POST https://us.i.posthog.com/capture/ \
            -H "Content-Type: application/json" \
            -d '{
              "api_key": "${{ secrets.POSTHOG_API_KEY }}",
              "event": "github_push",
              "properties": {
                "repository": "${{ github.repository }}",
                "branch": "${{ github.ref }}",
                "commit_sha": "${{ github.sha }}",
                "author": "${{ github.actor }}",
                "commits_count": ${{ github.event.push.size || 1 }},
                "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'",
                "event_id": "${{ github.run_id }}"
              }
            }'

      - name: Track Pull Request Event
        if: github.event_name == 'pull_request'
        run: |
          curl -X POST https://us.i.posthog.com/capture/ \
            -H "Content-Type: application/json" \
            -d '{
              "api_key": "${{ secrets.POSTHOG_API_KEY }}",
              "event": "github_pull_request",
              "properties": {
                "repository": "${{ github.repository }}",
                "pr_number": ${{ github.event.pull_request.number }},
                "pr_title": "${{ github.event.pull_request.title }}",
                "action": "${{ github.event.action }}",
                "author": "${{ github.event.pull_request.user.login }}",
                "branch": "${{ github.event.pull_request.head.ref }}",
                "base_branch": "${{ github.event.pull_request.base.ref }}",
                "additions": ${{ github.event.pull_request.additions }},
                "deletions": ${{ github.event.pull_request.deletions }},
                "changed_files": ${{ github.event.pull_request.changed_files }},
                "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'",
                "event_id": "${{ github.run_id }}"
              }
            }'

      - name: Track Release Event
        if: github.event_name == 'release'
        run: |
          curl -X POST https://us.i.posthog.com/capture/ \
            -H "Content-Type: application/json" \
            -d '{
              "api_key": "${{ secrets.POSTHOG_API_KEY }}",
              "event": "github_release",
              "properties": {
                "repository": "${{ github.repository }}",
                "release_tag": "${{ github.event.release.tag_name }}",
                "release_name": "${{ github.event.release.name }}",
                "action": "${{ github.event.action }}",
                "author": "${{ github.event.release.author.login }}",
                "prerelease": ${{ github.event.release.prerelease }},
                "draft": ${{ github.event.release.draft }},
                "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'",
                "event_id": "${{ github.run_id }}"
              }
            }'

      - name: Track Issues Event
        if: github.event_name == 'issues'
        run: |
          curl -X POST https://us.i.posthog.com/capture/ \
            -H "Content-Type: application/json" \
            -d '{
              "api_key": "${{ secrets.POSTHOG_API_KEY }}",
              "event": "github_issue",
              "properties": {
                "repository": "${{ github.repository }}",
                "issue_number": ${{ github.event.issue.number }},
                "issue_title": "${{ github.event.issue.title }}",
                "action": "${{ github.event.action }}",
                "author": "${{ github.event.issue.user.login }}",
                "labels": "${{ join(github.event.issue.labels.*.name, ',') }}",
                "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'",
                "event_id": "${{ github.run_id }}"
              }
            }'

  track-workflow-completion:
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_run'
    steps:
      - name: Track Workflow Run Completion
        run: |
          curl -X POST https://us.i.posthog.com/capture/ \
            -H "Content-Type: application/json" \
            -d '{
              "api_key": "${{ secrets.POSTHOG_API_KEY }}",
              "event": "github_workflow_run",
              "properties": {
                "repository": "${{ github.repository }}",
                "workflow_name": "${{ github.event.workflow_run.name }}",
                "workflow_status": "${{ github.event.workflow_run.conclusion }}",
                "run_number": ${{ github.event.workflow_run.run_number }},
                "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'",
                "event_id": "${{ github.run_id }}"
              }
            }'
EOF

# Setup docs
read -r -d '' SETUP_DOCS << 'EOF' || true
# PostHog Integration Setup

This repository is configured to send GitHub events to PostHog for analytics tracking.

## Setup Instructions

### 1. Add PostHog API Key as GitHub Secret

1. Go to **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Create a secret named `POSTHOG_API_KEY`
4. Paste your PostHog project API key (format: `phc_...`)
5. Click **Add secret**

### 2. Verify Configuration

The workflow will automatically start tracking:
- **Push events** - Code commits to main/master/develop branches
- **Pull requests** - Created, closed, and synchronized PRs
- **Releases** - New version releases
- **Issues** - Created, closed, and labeled issues
- **Workflow runs** - CI/CD pipeline completions

### 3. Monitor in PostHog

Events will appear in your PostHog dashboard with the following event names:
- `github_push`
- `github_pull_request`
- `github_release`
- `github_issue`
- `github_workflow_run`

## Configuration

**PostHog Host:** `https://us.i.posthog.com`
**Workflow File:** `.github/workflows/posthog-events.yml`
**Project ID:** `1780784617`

## Tracked Data

Each event includes:
- Repository name
- Branch/tag information
- Author information
- Event-specific metadata (commit hash, PR number, release tag, etc.)
- Timestamp
- Unique event ID

## Troubleshooting

If events aren't appearing in PostHog:
1. Check that `POSTHOG_API_KEY` secret is set correctly
2. Verify the API key starts with `phc_`
3. Check workflow logs in **Actions** tab for any errors
4. Ensure the key has proper permissions in PostHog

## Learn More

- [PostHog Documentation](https://posthog.com/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
EOF

echo "🚀 Starting PostHog GitHub Integration Setup"
echo "=============================================="
echo ""

# Function to setup a repository
setup_repo() {
  local repo=$1
  echo "📦 Setting up: $repo"
  
  # Clone or update repo
  if [ -d "/tmp/$repo" ]; then
    cd "/tmp/$repo"
    git fetch origin
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || git checkout develop 2>/dev/null
  else
    git clone "https://github.com/$GITHUB_USER/$repo.git" "/tmp/$repo"
    cd "/tmp/$repo"
  fi
  
  # Create directory structure
  mkdir -p ".github/workflows"
  
  # Write workflow file
  echo "$WORKFLOW_CONTENT" > ".github/workflows/posthog-events.yml"
  echo "$SETUP_DOCS" > ".github/POSTHOG_SETUP.md"
  
  # Commit and push
  git add ".github/workflows/posthog-events.yml" ".github/POSTHOG_SETUP.md"
  git commit -m "$COMMIT_MESSAGE" || echo "⚠️  No changes to commit for $repo"
  git push origin HEAD:main 2>/dev/null || git push origin HEAD:master 2>/dev/null || git push origin HEAD:develop 2>/dev/null || echo "⚠️  Could not push to $repo"
  
  echo "✅ $repo setup complete"
  echo ""
}

# Setup each repository
for repo in "${REPOS[@]}"; do
  setup_repo "$repo" || echo "❌ Failed to setup $repo"
done

echo "=============================================="
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Go to each repository"
echo "2. Settings → Secrets and variables → Actions"
echo "3. Add secret: POSTHOG_API_KEY"
echo "4. Paste your PostHog project API key"
echo ""
echo "🎉 Your repositories are now connected to PostHog!"
