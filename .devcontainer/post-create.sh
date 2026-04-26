#!/bin/bash

echo "Setting up Chaos Engineering Lab environment..."

# Install additional tools
sudo apt-get update
sudo apt-get install -y curl zip unzip jq

# Verify installations
echo ""
echo "Installed versions:"
terraform version
aws --version
go version
docker --version

# Setup Go workspace
echo ""
echo "Setting up Go workspace..."
cd /workspaces/*/lambda
go mod download || true

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Create .env file with AWS credentials and ANTHROPIC_API_KEY"
echo "   (Your instructor will provide the Anthropic API key)"
echo "2. Build and deploy infrastructure: see README.md"
echo ""
echo "IMPORTANT: Before using Claude Code in Part 2/3, run:"
echo "  export \$(cat .env | xargs)"
echo ""
