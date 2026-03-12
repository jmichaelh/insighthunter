
// this file is generated — do not edit it


/// <reference types="@sveltejs/kit" />

/**
 * This module provides access to environment variables that are injected _statically_ into your bundle at build time and are limited to _private_ access.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Static environment variables are [loaded by Vite](https://vitejs.dev/guide/env-and-mode.html#env-files) from `.env` files and `process.env` at build time and then statically injected into your bundle at build time, enabling optimisations like dead code elimination.
 * 
 * **_Private_ access:**
 * 
 * - This module cannot be imported into client-side code
 * - This module only includes variables that _do not_ begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) _and do_ start with [`config.kit.env.privatePrefix`](https://svelte.dev/docs/kit/configuration#env) (if configured)
 * 
 * For example, given the following build time environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://site.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { ENVIRONMENT, PUBLIC_BASE_URL } from '$env/static/private';
 * 
 * console.log(ENVIRONMENT); // => "production"
 * console.log(PUBLIC_BASE_URL); // => throws error during build
 * ```
 * 
 * The above values will be the same _even if_ different values for `ENVIRONMENT` or `PUBLIC_BASE_URL` are set at runtime, as they are statically replaced in your code with their build time values.
 */
declare module '$env/static/private' {
	export const APP_ENV: string;
	export const APP_TIER: string;
	export const AUTH_SERVICE_URL: string;
	export const AGENTS_SERVICE_URL: string;
	export const BOOKKEEPING_SERVICE_URL: string;
	export const CORS_ORIGIN: string;
	export const RATE_LIMIT_WINDOW: string;
	export const RATE_LIMIT_MAX: string;
	export const JWT_SECRET: string;
	export const SERVICE_API_KEY: string;
	export const CLOUDFLARE_API_TOKEN: string;
	export const CLOUDFLARE_ACCOUNT_ID: string;
	export const TURNSTILE_SECRET: string;
	export const SHELL: string;
	export const npm_command: string;
	export const COLORTERM: string;
	export const WORKSPACE_SERVICE_ACCOUNT_EMAIL: string;
	export const TERM_PROGRAM_VERSION: string;
	export const PKG_CONFIG_PATH: string;
	export const PYTHONNOUSERSITE: string;
	export const npm_config_npm_globalconfig: string;
	export const NODE: string;
	export const UV_USE_IO_URING: string;
	export const npm_config_verify_deps_before_run: string;
	export const npm_config__jsr_registry: string;
	export const MONOSPACE_ENV: string;
	export const npm_config_globalconfig: string;
	export const MONOSPACE_COMMIT_SHA: string;
	export const PWD: string;
	export const CAPRA_ENABLED_FEATURES: string;
	export const NIX_PATH: string;
	export const FIREBASE_DEPLOY_AGENT: string;
	export const npm_config_recursive: string;
	export const VSCODE_GIT_ASKPASS_NODE: string;
	export const WEB_HOST: string;
	export const ENABLE_CAPRA_GENKIT_TOKEN_LOGGING: string;
	export const HOME: string;
	export const LANG: string;
	export const COLLAB_WS_URL: string;
	export const npm_package_version: string;
	export const NIX_SSL_CERT_FILE: string;
	export const GIT_ASKPASS: string;
	export const PROMPT_COMMAND: string;
	export const MONOSPACE_ON_START_COMMANDS: string;
	export const WORKSPACE_SLUG: string;
	export const pnpm_config_verify_deps_before_run: string;
	export const MONOSPACE_ENV_CFG_HASH: string;
	export const INIT_CWD: string;
	export const npm_lifecycle_script: string;
	export const VSCODE_GIT_ASKPASS_EXTRA_ARGS: string;
	export const COLLAB_YJS_ROOM: string;
	export const NPM_CONFIG_PREFIX: string;
	export const IDX_CHANNEL: string;
	export const TERM: string;
	export const npm_package_name: string;
	export const IDX_ENV_CONFIG_FILE_PATH: string;
	export const ACLOCAL_PATH: string;
	export const npm_config_prefix: string;
	export const USER: string;
	export const npm_config_frozen_lockfile: string;
	export const VSCODE_GIT_IPC_HANDLE: string;
	export const TZDIR: string;
	export const MONOSPACE_RECOVERY_MODE: string;
	export const NIX_CFLAGS_LINK: string;
	export const npm_lifecycle_event: string;
	export const SHLVL: string;
	export const ENVIRONMENT_SERVICE_PATH: string;
	export const NIX_CFLAGS_COMPILE: string;
	export const npm_config_manage_package_manager_versions: string;
	export const LOCALE_ARCHIVE: string;
	export const npm_config_user_agent: string;
	export const PERMANENT_TAG: string;
	export const PNPM_SCRIPT_SRC_DIR: string;
	export const npm_execpath: string;
	export const MONOSPACE_ON_CREATE_COMMANDS: string;
	export const LC_CTYPE: string;
	export const SSL_CERT_FILE: string;
	export const NODE_PATH: string;
	export const npm_package_json: string;
	export const GOOGLE_CLOUD_WORKSTATIONS: string;
	export const VSCODE_GIT_ASKPASS_MAIN: string;
	export const XDG_DATA_DIRS: string;
	export const BROWSER: string;
	export const PATH: string;
	export const npm_config_node_gyp: string;
	export const IDX_TOKEN_SOCK: string;
	export const npm_config_registry: string;
	export const npm_node_execpath: string;
	export const NIX_LDFLAGS: string;
	export const TERM_PROGRAM: string;
	export const VSCODE_IPC_HOOK_CLI: string;
	export const NODE_ENV: string;
}

/**
 * This module provides access to environment variables that are injected _statically_ into your bundle at build time and are _publicly_ accessible.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Static environment variables are [loaded by Vite](https://vitejs.dev/guide/env-and-mode.html#env-files) from `.env` files and `process.env` at build time and then statically injected into your bundle at build time, enabling optimisations like dead code elimination.
 * 
 * **_Public_ access:**
 * 
 * - This module _can_ be imported into client-side code
 * - **Only** variables that begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) (which defaults to `PUBLIC_`) are included
 * 
 * For example, given the following build time environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://site.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { ENVIRONMENT, PUBLIC_BASE_URL } from '$env/static/public';
 * 
 * console.log(ENVIRONMENT); // => throws error during build
 * console.log(PUBLIC_BASE_URL); // => "http://site.com"
 * ```
 * 
 * The above values will be the same _even if_ different values for `ENVIRONMENT` or `PUBLIC_BASE_URL` are set at runtime, as they are statically replaced in your code with their build time values.
 */
declare module '$env/static/public' {
	
}

/**
 * This module provides access to environment variables set _dynamically_ at runtime and that are limited to _private_ access.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Dynamic environment variables are defined by the platform you're running on. For example if you're using [`adapter-node`](https://github.com/sveltejs/kit/tree/main/packages/adapter-node) (or running [`vite preview`](https://svelte.dev/docs/kit/cli)), this is equivalent to `process.env`.
 * 
 * **_Private_ access:**
 * 
 * - This module cannot be imported into client-side code
 * - This module includes variables that _do not_ begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) _and do_ start with [`config.kit.env.privatePrefix`](https://svelte.dev/docs/kit/configuration#env) (if configured)
 * 
 * > [!NOTE] In `dev`, `$env/dynamic` includes environment variables from `.env`. In `prod`, this behavior will depend on your adapter.
 * 
 * > [!NOTE] To get correct types, environment variables referenced in your code should be declared (for example in an `.env` file), even if they don't have a value until the app is deployed:
 * >
 * > ```env
 * > MY_FEATURE_FLAG=
 * > ```
 * >
 * > You can override `.env` values from the command line like so:
 * >
 * > ```sh
 * > MY_FEATURE_FLAG="enabled" npm run dev
 * > ```
 * 
 * For example, given the following runtime environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://site.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { env } from '$env/dynamic/private';
 * 
 * console.log(env.ENVIRONMENT); // => "production"
 * console.log(env.PUBLIC_BASE_URL); // => undefined
 * ```
 */
declare module '$env/dynamic/private' {
	export const env: {
		APP_ENV: string;
		APP_TIER: string;
		AUTH_SERVICE_URL: string;
		AGENTS_SERVICE_URL: string;
		BOOKKEEPING_SERVICE_URL: string;
		CORS_ORIGIN: string;
		RATE_LIMIT_WINDOW: string;
		RATE_LIMIT_MAX: string;
		JWT_SECRET: string;
		SERVICE_API_KEY: string;
		CLOUDFLARE_API_TOKEN: string;
		CLOUDFLARE_ACCOUNT_ID: string;
		TURNSTILE_SECRET: string;
		SHELL: string;
		npm_command: string;
		COLORTERM: string;
		WORKSPACE_SERVICE_ACCOUNT_EMAIL: string;
		TERM_PROGRAM_VERSION: string;
		PKG_CONFIG_PATH: string;
		PYTHONNOUSERSITE: string;
		npm_config_npm_globalconfig: string;
		NODE: string;
		UV_USE_IO_URING: string;
		npm_config_verify_deps_before_run: string;
		npm_config__jsr_registry: string;
		MONOSPACE_ENV: string;
		npm_config_globalconfig: string;
		MONOSPACE_COMMIT_SHA: string;
		PWD: string;
		CAPRA_ENABLED_FEATURES: string;
		NIX_PATH: string;
		FIREBASE_DEPLOY_AGENT: string;
		npm_config_recursive: string;
		VSCODE_GIT_ASKPASS_NODE: string;
		WEB_HOST: string;
		ENABLE_CAPRA_GENKIT_TOKEN_LOGGING: string;
		HOME: string;
		LANG: string;
		COLLAB_WS_URL: string;
		npm_package_version: string;
		NIX_SSL_CERT_FILE: string;
		GIT_ASKPASS: string;
		PROMPT_COMMAND: string;
		MONOSPACE_ON_START_COMMANDS: string;
		WORKSPACE_SLUG: string;
		pnpm_config_verify_deps_before_run: string;
		MONOSPACE_ENV_CFG_HASH: string;
		INIT_CWD: string;
		npm_lifecycle_script: string;
		VSCODE_GIT_ASKPASS_EXTRA_ARGS: string;
		COLLAB_YJS_ROOM: string;
		NPM_CONFIG_PREFIX: string;
		IDX_CHANNEL: string;
		TERM: string;
		npm_package_name: string;
		IDX_ENV_CONFIG_FILE_PATH: string;
		ACLOCAL_PATH: string;
		npm_config_prefix: string;
		USER: string;
		npm_config_frozen_lockfile: string;
		VSCODE_GIT_IPC_HANDLE: string;
		TZDIR: string;
		MONOSPACE_RECOVERY_MODE: string;
		NIX_CFLAGS_LINK: string;
		npm_lifecycle_event: string;
		SHLVL: string;
		ENVIRONMENT_SERVICE_PATH: string;
		NIX_CFLAGS_COMPILE: string;
		npm_config_manage_package_manager_versions: string;
		LOCALE_ARCHIVE: string;
		npm_config_user_agent: string;
		PERMANENT_TAG: string;
		PNPM_SCRIPT_SRC_DIR: string;
		npm_execpath: string;
		MONOSPACE_ON_CREATE_COMMANDS: string;
		LC_CTYPE: string;
		SSL_CERT_FILE: string;
		NODE_PATH: string;
		npm_package_json: string;
		GOOGLE_CLOUD_WORKSTATIONS: string;
		VSCODE_GIT_ASKPASS_MAIN: string;
		XDG_DATA_DIRS: string;
		BROWSER: string;
		PATH: string;
		npm_config_node_gyp: string;
		IDX_TOKEN_SOCK: string;
		npm_config_registry: string;
		npm_node_execpath: string;
		NIX_LDFLAGS: string;
		TERM_PROGRAM: string;
		VSCODE_IPC_HOOK_CLI: string;
		NODE_ENV: string;
		[key: `PUBLIC_${string}`]: undefined;
		[key: `${string}`]: string | undefined;
	}
}

/**
 * This module provides access to environment variables set _dynamically_ at runtime and that are _publicly_ accessible.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Dynamic environment variables are defined by the platform you're running on. For example if you're using [`adapter-node`](https://github.com/sveltejs/kit/tree/main/packages/adapter-node) (or running [`vite preview`](https://svelte.dev/docs/kit/cli)), this is equivalent to `process.env`.
 * 
 * **_Public_ access:**
 * 
 * - This module _can_ be imported into client-side code
 * - **Only** variables that begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) (which defaults to `PUBLIC_`) are included
 * 
 * > [!NOTE] In `dev`, `$env/dynamic` includes environment variables from `.env`. In `prod`, this behavior will depend on your adapter.
 * 
 * > [!NOTE] To get correct types, environment variables referenced in your code should be declared (for example in an `.env` file), even if they don't have a value until the app is deployed:
 * >
 * > ```env
 * > MY_FEATURE_FLAG=
 * > ```
 * >
 * > You can override `.env` values from the command line like so:
 * >
 * > ```sh
 * > MY_FEATURE_FLAG="enabled" npm run dev
 * > ```
 * 
 * For example, given the following runtime environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://example.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { env } from '$env/dynamic/public';
 * console.log(env.ENVIRONMENT); // => undefined, not public
 * console.log(env.PUBLIC_BASE_URL); // => "http://example.com"
 * ```
 * 
 * ```
 * 
 * ```
 */
declare module '$env/dynamic/public' {
	export const env: {
		[key: `PUBLIC_${string}`]: string | undefined;
	}
}
