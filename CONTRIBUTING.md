# When to contribute.

There are a few main cases in which you may want to make a contribution to this repository.

Among them are the following:
* An issue has presented itself to you.
* You would like to solve an existing issue.
* You would like to add/change a builder (see [Adding Builders](#adding-builders))

# General language rules.

The only experimental features necessary for this repository are and always will be `nix-command` and `flakes`

Do not use any other experimental features (i.e. pipe operators \[`|>`, `<|`\]).

# Style

run `nix fmt` before any commit.

`@` Patterns should be used before destructured arguments.

Do: `args@{ a, b, ... }: { /*...*/ }`
Do Not: `{ a, b, ...}@args: { /*...*/ }`

Additionally, use a comprehensible name for arguments that may be exposed to a user.

# Adding Builders

Any builder added to the project should be placed in the [builder directory](./parts/builders).

Do not try to add builders for niche, unpopular, or duplicate items.

Keep each build/aggregate function to one job/output. This keeps things modifiable by the consuming flake.

If using default search paths, ensure that they are typed as relative path strings that will be resolved against `burrow.root`. ***DO NOT use an absolute path as a default search path***.

Additionally you should make default search paths possible to easily disable, ideally by adding `options.useDefaultSearchPaths` (boolean, default true) to your settingsModules.

***TEST YOUR BUILDERS*** I am more likely to remove a bad builder than try to fix it myself, so make sure your builder works.

# Adding Discovery functions

Discovery functions *must* respect skipped folders, you should be aware the fact that any directory you enter, including the top search path
may contain a `.burrow_skip` file. Use `burrow.lib.dirIgnored` to discern.

Unless you have good reason not to, skip hidden files when discovering.

Clearly document the discovery style of your discovery function.

Respect naming conventions (There aren't many as of now)
- `flat<name>` Does not evaluate a meta file.
