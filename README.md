# How to Use
You can run any script in this repository directly using CURL and Bash.

### Basic Usage
```bash
bash <(curl -s https://raw.githubusercontent.com/BA-Creative/CLI-Tools/main/FILE_NAME)
```
*Ensure to replace `FILE_NAME` with the specific script you'd like to use.*

### With Parameters
```bash
bash <(curl -s https://raw.githubusercontent.com/BA-Creative/CLI-Tools/main/FILE_NAME) [VAR_1] [VAR_2]
```

### Available Scripts

| Script | Description | Parameters |
|--------|-------------|-------|
| roxypress | Creates a WordPress development instance using Docker | - |
| git-b2g | Bitbucket to GitHub repo migration tool | Repo name as VAR_1 |
| wal | Development tool for interacting with Likewise project | - |

*This table will be updated as scripts are added to the repository.*

# About This Repo
This repository is a collection of useful shell scripts that can be executed directly from the Terminal.
These scripts are intended for internal use within BA Creative.

### Security Considerations

⚠️ **Important**: Always review scripts before executing them, especially when running them directly from the internet.

- **Inspect first**: `curl -s https://raw.githubusercontent.com/BA-Creative/CLI-Tools/main/FILE_NAME`
- **Only run trusted sources**: Verify the repository and script contents
- **Permission awareness**: Scripts run with your current user permissions
- **Network safety**: Ensure you trust the source and have a secure connection

### Environment Compatibility
These scripts are designed to work across different shell environments. However, they are intended for MacOS.