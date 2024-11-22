# Git Semantic Version

Github action that should allow automated bumping of versions using just a bash shell.
Only supports major, minor, patch without anything else at the moment.

Can specify a "component" (used as a git tag prefix) and "paths" to make it usable in a mono-repo setup.