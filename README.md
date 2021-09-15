`git-partial-clone`
---

This script clones a subdirectory of a github/gitlab repository.

- [Install](#install)
- [Using the comand line options](#using-the-comand-line-options)
  - [Clone from public repositories](#clone-from-public-repositories)
  - [Clone from private repositories](#clone-from-private-repositories)
- [Using a configuration file](#using-a-configuration-file)
  - [Configuration variables](#configuration-variables)
    - [Mandatory variables](#mandatory-variables)
    - [Variables for **private repositories**](#variables-for-private-repositories)
    - [Optional variables](#optional-variables)

# Install
Install the script and autocompletion rules.
```zsh
./install.sh
```
Then you can call the command `git-partial-clone` from any directory and use `TAB` to autocomplete the CLI options.

# Using the comand line options
Run with the `--help` flag to see the complete list of options (recommended). Or read the following sections to clone using the most common options.
```
$ git-partial-clone -h

Clone a subdirectory of a github/gitlab repository.

USAGE:
   git-partial-clone   [OPTIONS] ARGUMENTS
   git-partial-clone   # Or assume config variables in shell.

OPTIONS:
            --help     Show this manual.

   Using a config file:
       -f | --file     Path to the configuration file.

   CLI options (mandatory):
       -o | --owner    Author (owner) of the repository.
       -r | --repo     Name of the repository.

   CLI options (optional):
       -h | --host     github (default) or gitlab.
       -s | --subdir   Subfolder to be cloned.

       -t | --token    Path to your access token (for private repos).
       -u | --user     Your username (for private repos).

       -b | --branch   Branch to be fetched.
       -d | --depth    Number of commits to be fetched.
```

## Clone from public repositories
Provide the mandatory options `--repo`, `--owner` and the subdirectory (`--subdir`) you want to clone.

The following example clones a subfolder of my [vscode-settings](https://github.com/lu0/vscode-settings/tree/master/json/snippets) repository.
```zsh
git-partial-clone --owner=lu0 --repo=vscode-settings --subdir=json/snippets
```

You can also clone the entire repository, although this is not the intended use.
```zsh
git-partial-clone --owner=lu0 --repo=vscode-settings
```

## Clone from private repositories
You will need to generate an access token in order to clone private repositories, as password authentication is deprecated.

- Github: [github.com/settings/tokens](https://github.com/settings/tokens).
- Gitlab: [gitlab.com/-/profile/personal_access_tokens](https://gitlab.com/-/profile/personal_access_tokens).

Save your token in a file and provide its path with the `--token` option, then provide your username with the `--user` option.

The following example would clone a subfolder of a private repository.
```zsh
git-partial-clone --owner=owner --repo=repo --subdir=path/to/subdir \
    --token=/path/to/your/token/file --user=username_with_access
```

# Using a configuration file
Using a configuration file will give you more control over the objects you're cloning. You can test this functionality with the provided configuration file:
```zsh
git-partial-clone --file=example.conf
```
By the end of the execution, you will see a `tmp` directory containing the subfolder of the example repository.

## Configuration variables
Fill in the config file ([`template.conf`](./template.conf)) with the information of the repository you're cloning. You can see the example file [here](./example.conf).

### Mandatory variables

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

### Variables for **private repositories**
- `TOKEN_PATH`:
    - Path to the file containing the access token.
- `GIT_USER`:
    - Username with access to the repository.

### Optional variables
- `BRANCH`:
    - The branch to be fetched.
    - Omit it to pull all of the branches and switch to the default one.
- `COMMIT_DEPTH`:
    - Number of commits you want to fetch (useful for deployment purposes).
    - Omit it to fetch the entire remote history.
- `PARENT_DIR`:
    - Path to the target parent directory.
    - Omit it to clone the repository in the current directory.
 