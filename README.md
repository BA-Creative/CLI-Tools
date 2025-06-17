# CLI Scripts Collection

This repository contains a collection of useful shell scripts that can be executed directly from the web without needing to clone the repository.

## Quick Usage

You can run any script in this repository directly using curl and bash:

```bash
bash <(curl -s https://raw.githubusercontent.com/BA-Creative/CLI-Tools/refs/heads/main/SCRIPT_NAME.sh)
```

Replace `BA-Creative` and `SCRIPT_NAME.sh` with the appropriate values.

## Available Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| Coming soon... | Scripts will be added here | - |

*This table will be updated as scripts are added to the repository.*

## Security Considerations

⚠️ **Important**: Always review scripts before executing them, especially when running them directly from the internet.

- **Inspect first**: `curl -s https://raw.githubusercontent.com/BA-Creative/CLI-Tools/refs/heads/main/SCRIPT_NAME.sh`
- **Only run trusted sources**: Verify the repository and script contents
- **Permission awareness**: Scripts run with your current user permissions
- **Network safety**: Ensure you trust the source and have a secure connection

## Adding New Scripts

When contributing scripts to this repository:

### Requirements
1. **Documentation**: Include clear comments explaining what the script does
2. **Error handling**: Implement proper error checking and meaningful exit codes
3. **Idempotency**: Make scripts safe to run multiple times when possible
4. **Testing**: Thoroughly test scripts before committing
5. **README updates**: Add your script to the "Available Scripts" table

### Script Structure
```bash
#!/bin/bash
# Script Name: example.sh
# Description: Brief description of what this script does
# Usage: bash <(curl -s https://raw.githubusercontent.com/USER/cli-scripts/main/example.sh)
# Author: Your Name
# Version: 1.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script content here...
```

## Best Practices

### Script Guidelines
- Use `#!/bin/bash` or `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail` for safer script execution
- Provide usage information and help options
- Use meaningful variable names and add comments
- Handle edge cases and provide clear error messages
- Include version information in script headers

### Error Handling
```bash
# Example error handling
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed" >&2
    exit 1
fi
```

## Usage Examples

### Basic Execution
```bash
# Run a script directly
bash <(curl -s https://raw.githubusercontent.com/BA-Creative/cli-scripts/main/setup.sh)
```

### With Parameters
```bash
# Pass arguments to the script
bash <(curl -s https://raw.githubusercontent.com/BA-Creative/cli-scripts/main/install.sh) --verbose --config=/path/to/config
```

### Download and Inspect
```bash
# Download, review, then execute
curl -s https://raw.githubusercontent.com/BA-Creative/cli-scripts/main/script.sh > temp_script.sh
cat temp_script.sh  # Review the script content
chmod +x temp_script.sh
./temp_script.sh
rm temp_script.sh
```

### Using with Different Shells
```bash
# For zsh users (default on macOS)
zsh <(curl -s https://raw.githubusercontent.com/BA-Creative/cli-scripts/main/script.sh)

# For bash users
bash <(curl -s https://raw.githubusercontent.com/BA-Creative/cli-scripts/main/script.sh)
```

## Environment Compatibility

These scripts are designed to work across different environments:

- **macOS**: Tested on current macOS versions
- **Linux**: Compatible with major distributions
- **WSL**: Windows Subsystem for Linux support
- **Shell compatibility**: Primarily bash, with notes for zsh/other shells

## Development Workflow

1. **Fork** this repository
2. **Create** a feature branch: `git checkout -b add-new-script`
3. **Develop** your script following the guidelines above
4. **Test** thoroughly on different systems if possible
5. **Document** your script in this README
6. **Commit** with descriptive messages
7. **Submit** a pull request

## Common Use Cases

This repository aims to provide scripts for:

- **Development setup**: Environment configuration, tool installation
- **System maintenance**: Cleanup, updates, backups
- **Automation**: Repetitive tasks, deployment helpers
- **Utilities**: File operations, text processing, network tools

## Contributing

We welcome contributions! Please:

1. Follow the script guidelines above
2. Test your scripts thoroughly
3. Update documentation
4. Use clear commit messages
5. Be responsive to feedback in pull requests

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Security**: Report security issues privately via GitHub Security Advisories

## Disclaimer

Scripts in this repository are provided as-is. Users are responsible for:

- Reviewing scripts before execution
- Understanding what scripts do before running them
- Ensuring scripts are appropriate for their environment
- Backing up important data before running system-modifying scripts

---

**Note**: Replace `BA-Creative` in the URLs above with your actual GitHub username once you publish this repository.
