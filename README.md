`git-partial-clone`
---

This script clones a subdirectory of a github/gitlab repository.

# Usage
## Quick test
Test the script with the example config file.
By the end of the execution, you will see a `tmp` directory containing the subfolder of the example repository.
```zsh
./git-partial-clone.sh --file example.conf
```
## Install
Install the script and autocompletion rules.
```zsh
./install.sh
```
Then you can execute the script from any directory with your custom config file and use `TAB` to autocomplete the CLI options.
```zsh
git-partial-clone --file path/to/your/config/file.conf
```

# Configuration
Fill in the config file ([`template.conf`](./template.conf)) with the information of the repository you're cloning. You can see the example file [here](./example.conf).

## Mandatory variables

- `GIT_HOST`:
    - `github` if the repository is hosted on Github.
    - `gitlab` if the repository is hosted on Gitlab.
- `REPO_OWNER`:
    - Username of the owner/author of the repository.
- `REPO_NAME`:
    - Name of the repository to be cloned.
- **`REMOTE_PARTIAL_DIR`**:
    - **Subdirectory of the repository you want to clone**.
    - Omit it to clone the entire repository.

## Mandatory variables for **private repositories**
You will need to generate an access token in order to clone private repositories, as password authentication is deprecated.

- Github: [github.com/settings/tokens](https://github.com/settings/tokens).
- Gitlab: [gitlab.com/-/profile/personal_access_tokens](https://gitlab.com/-/profile/personal_access_tokens).

Once you have a token, store it in a file.

- `TOKEN_PATH`:
    - Path to the file containing the access token.
- `GIT_USER`:
    - Username with access to the repository.

## Optional variables
The following variables give you more control over the objects you're cloning.
- `BRANCH`:
    - The branch to be fetched.
    - Omit it to pull all of the branches and switch to the default one.
- `COMMIT_DEPTH`:
    - Number of commits you want to fetch (useful for deployment purposes).
    - Omit it to fetch the entire remote history.
- `PARENT_DIR`:
    - Path to the target parent directory.
    - Omit it to clone the repository in the current directory.
 