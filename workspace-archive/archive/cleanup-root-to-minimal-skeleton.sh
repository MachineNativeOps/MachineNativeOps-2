#!/bin/bash
# Move Root Files to Workspace Proper Locations
# Organize files according to their purpose

echo "=========================================="
echo "Root Directory Organization"
echo "Moving files to workspace proper locations"
echo "=========================================="

# Create necessary workspace directories
mkdir -p workspace/docs
mkdir -p workspace/archive/legacy
mkdir -p workspace/src
mkdir -p workspace/config
mkdir -p workspace/services
mkdir -p workspace/shared
mkdir -p workspace/db
mkdir -p workspace/deploy

# Move documentation/report files to workspace/docs
echo "Moving documentation to workspace/docs..."
[ -f "CLOUDFLARE_DEPLOYMENT_FIX.md" ] && mv -v CLOUDFLARE_DEPLOYMENT_FIX.md workspace/docs/ || true
[ -f "FINAL_COMPLETION_SUMMARY.md" ] && mv -v FINAL_COMPLETION_SUMMARY.md workspace/docs/ || true
[ -f "NAMESPACE_SPECIFICATION_COMPLETE.md" ] && mv -v NAMESPACE_SPECIFICATION_COMPLETE.md workspace/docs/ || true
[ -f "PROJECT_REORGANIZATION_REPORT.md" ] && mv -v PROJECT_REORGANIZATION_REPORT.md workspace/docs/ || true
[ -f "PR_REVIEW_COMPLETION_REPORT.md" ] && mv -v PR_REVIEW_COMPLETION_REPORT.md workspace/docs/ || true
[ -f "PR_REVIEW_REPORT.md" ] && mv -v PR_REVIEW_REPORT.md workspace/docs/ || true
[ -f "WORKSPACE_REORGANIZATION_COMPLETE.md" ] && mv -v WORKSPACE_REORGANIZATION_COMPLETE.md workspace/docs/ || true

# Move temporary/archive files to workspace/archive
echo "Moving temporary files to workspace/archive..."
[ -f "Screenshot_20251223_184259.jpg" ] && mv -v Screenshot_20251223_184259.jpg workspace/archive/ || true
[ -f "fix_indentation.py" ] && mv -v fix_indentation.py workspace/archive/ || true
[ -f "fix_main_function.py" ] && mv -v fix_main_function.py workspace/archive/ || true
[ -f "cleanup-root-directory.sh" ] && mv -v cleanup-root-directory.sh workspace/archive/ || true
[ -f "cleanup-workspace-root.sh" ] && mv -v cleanup-workspace-root.sh workspace/archive/ || true
[ -d "summarized_conversations" ] && mv -v summarized_conversations workspace/archive/ || true

# Move chatops directory to workspace/chatops (merge if exists)
if [ -d "chatops" ]; then
    echo "Moving chatops/ to workspace/..."
    if [ -d "workspace/chatops" ]; then
        echo "  workspace/chatops already exists, merging..."
        cp -rv chatops/* workspace/chatops/
        rm -rf chatops
    else
        mv -v chatops workspace/
    fi
fi

# Move client to workspace/client
if [ -d "client" ]; then
    echo "Moving client/ to workspace/..."
    if [ -d "workspace/client" ]; then
        echo "  workspace/client already exists, merging..."
        cp -rv client/* workspace/client/
        rm -rf client
    else
        mv -v client workspace/
    fi
fi

# Move db to workspace/db
if [ -d "db" ]; then
    echo "Moving db/ to workspace/..."
    if [ -d "workspace/db" ]; then
        echo "  workspace/db already exists, merging..."
        cp -rv db/* workspace/db/
        rm -rf db
    else
        mv -v db workspace/
    fi
fi

# Move server to workspace/services/server
if [ -d "server" ]; then
    echo "Moving server/ to workspace/services/..."
    mkdir -p workspace/services
    if [ -d "workspace/services/server" ]; then
        echo "  workspace/services/server already exists, merging..."
        cp -rv server/* workspace/services/server/
        rm -rf server
    else
        mv -v server workspace/services/
    fi
fi

# Move shared to workspace/shared
if [ -d "shared" ]; then
    echo "Moving shared/ to workspace/..."
    if [ -d "workspace/shared" ]; then
        echo "  workspace/shared already exists, merging..."
        cp -rv shared/* workspace/shared/
        rm -rf shared
    else
        mv -v shared workspace/
    fi
fi

# Move chatops-assistant to workspace/
if [ -d "chatops-assistant" ]; then
    echo "Moving chatops-assistant/ to workspace/..."
    mv -v chatops-assistant workspace/ || true
fi

# Move attached_assets to workspace/
if [ -d "attached_assets" ]; then
    echo "Moving attached_assets/ to workspace/..."
    mv -v attached_assets workspace/ || true
fi

# Move config files to workspace/config
echo "Moving config files to workspace/config..."
[ -f "drizzle.config.ts" ] && mv -v drizzle.config.ts workspace/config/ || true

echo ""
echo "=========================================="
echo "Organization Complete!"
echo "=========================================="
echo ""
echo "Root directory now contains only:"
echo "  ✓ Boot pointers (root.bootstrap.yaml, root.env.sh, root.fs.map)"
echo "  ✓ Git files (.git/, .github/, .gitignore)"
echo "  ✓ Project files (README.md, CNAME, .env.example, .replit, wrangler.toml)"
echo "  ✓ Primary directories (controlplane/, workspace/)"
echo ""
echo "Files moved to:"
echo "  → workspace/docs/ (documentation and reports)"
echo "  → workspace/archive/ (temporary and legacy files)"
echo "  → workspace/chatops/ (ChatOps framework)"
echo "  → workspace/client/ (client application)"
echo "  → workspace/db/ (database files)"
echo "  → workspace/services/server/ (server application)"
echo "  → workspace/shared/ (shared libraries)"
echo "  → workspace/config/ (configuration files)"