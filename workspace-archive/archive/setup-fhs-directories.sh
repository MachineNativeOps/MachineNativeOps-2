#!/bin/bash
# Setup FHS Directory Structure
# Create FHS directories with proper symlinks to workspace

echo "=========================================="
echo "Setting up FHS Directory Structure"
echo "=========================================="

# Create FHS directories as symlinks to workspace
echo "Creating FHS directories..."

# /bin -> workspace/src/bin (general user commands)
ln -sf workspace/src/bin bin
echo "✓ /bin -> workspace/src/bin"

# /sbin -> controlplane/baseline/validation (system administration commands)
ln -sf controlplane/baseline/validation sbin
echo "✓ /sbin -> controlplane/baseline/validation"

# /etc -> controlplane/baseline/config (configuration pointers)
ln -sf controlplane/baseline/config etc
echo "✓ /etc -> controlplane/baseline/config"

# /lib -> workspace/shared (shared libraries)
ln -sf workspace/shared lib
echo "✓ /lib -> workspace/shared"

# /var (variable runtime data - actual directory)
mkdir -p var/log var/run var/state var/cache var/evidence
ln -sf ../controlplane/overlay/evidence var/evidence
echo "✓ /var with subdirectories (log, run, state, cache, evidence)"

# /usr -> workspace (extended installation area)
ln -sf workspace usr
echo "✓ /usr -> workspace"

# /home -> workspace (user working area)
ln -sf workspace home
echo "✓ /home -> workspace"

# /tmp (temporary files - actual directory)
mkdir -p tmp
chmod 1777 tmp
echo "✓ /tmp (with sticky bit)"

# /opt (optional packages - actual directory)
mkdir -p opt
echo "✓ /opt"

# /srv -> workspace/services (service data)
ln -sf workspace/services srv
echo "✓ /srv -> workspace/services"

# /init.d (initialization scripts - actual directory)
mkdir -p init.d
echo "✓ /init.d"

echo ""
echo "=========================================="
echo "FHS Directory Structure Complete!"
echo "=========================================="
echo ""
echo "Created directories:"
echo "  /bin -> workspace/src/bin"
echo "  /sbin -> controlplane/baseline/validation"
echo "  /etc -> controlplane/baseline/config"
echo "  /lib -> workspace/shared"
echo "  /var (with subdirectories)"
echo "  /usr -> workspace"
echo "  /home -> workspace"
echo "  /tmp"
echo "  /opt"
echo "  /srv -> workspace/services"
echo "  /init.d"
echo ""
echo "Root directory now complies with FHS standard!"