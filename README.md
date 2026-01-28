# Website

This website is built using [Docusaurus 2](https://docusaurus.io/), a modern static website generator.

## Installation

### Requirements
* install latest version of NodeJs (version greater than 16.14). You could install it via npm
```shell
npm install -g n
```

* install yarn. You could install it via npm
```shell
npm install --global yarn
```

```
$ git clone git@github.com:bybit-exchange/docs.git  # clone the repo
```

```
$ cd docs
```

```
$ yarn  # install the dependencies
```


Running the below script copies our custom js files into an untracked lib directory, which enables sending authenticated requests to the bybit API.

It should be run on the first installation and on subsequent yarn upgrades.
```
$ chmod +x setup.sh
$ ./setup.sh
```

### Local Development
As we have english and chinese in the application, so you need to start them separately.
```
$ yarn start  # start the local EN site
```
```
$ yarn start --locale zh-TW  # start the local CN site
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

### Project Structure
```shell
├── docs   # put english mdx files here
│
├── i18n  
│   ├── en
│   │   ├── docusaurus-plugin-content-docs
│   │   │   └── current.json
│   │   └── docusaurus-theme-classic
│   │       └── navbar.json
│   └── zh
│       ├── docusaurus-plugin-content-docs
│       │   └── current   # maintain CN mdx files here
│       │   │   └── derivatives
│       │   └── current.json  # CN sidebar name
│       │
│       └── docusaurus-theme-classic
│           └── navbar.json   # CN navbar name
├── sidebars.js   # sort and organize side category
│ 
├── docusaurus.config.js  # basic configs, including logo, path, and navbar, etc
```

### Build

```shell
yarn build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

### Deployment

Ensure you have set the `GIT_USER` environment variable before trying to deploy.

```shell
yarn deploy
```

### Documentation Sync Workflow

This project includes an automated workflow for syncing documentation from Lark wiki and deploying to GitHub Pages.

#### Using Claude Code (Recommended)

Tell Claude Code to sync and deploy:

```
同步 <Lark_URL> 并部署到远程
```

Claude will automatically:
1. Fetch the latest documentation from Lark
2. Compare with local files and identify differences
3. Update all changed files
4. Commit and push to GitHub
5. Deploy to GitHub Pages (if token provided)

See [SKILL-sync-deploy.md](./SKILL-sync-deploy.md) for detailed workflow documentation.

#### Using the Script Manually

```bash
# Basic sync (no deploy)
./scripts/sync-lark-and-deploy.sh --url "<lark_url>"

# Sync and deploy
./scripts/sync-lark-and-deploy.sh --url "<lark_url>" --token "<github_token>"

# Custom documentation path
./scripts/sync-lark-and-deploy.sh --url "<lark_url>" --path "./docs/custom-path"
```

#### GitHub Actions Auto-Deployment

Every push to `master` branch automatically deploys to GitHub Pages via GitHub Actions.

Configuration: [.github/workflows/deploy.yml](./.github/workflows/deploy.yml)


