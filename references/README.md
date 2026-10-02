# Reference repositories

This directory contains external Git repositories used for direct code comparison.

## Pinned references

| Path | Repository | Pinned revision |
|---|---|---|
| `kodi/` | `xbmc/xbmc` | `9c3e7f4d7b3ff314cd2f19a291766555e0346024` |
| `kodi-ps5/` | `VivaLaVent/kodi-ps5` | `0ea36e36d738aa045c1b8ed63c24a0314c7f72a5` |
| `ps4sdk/` | `ps4dev/ps4sdk` | `4df9d001b66ae4ec07d9a51b62d1e4c5e270eecc` |

These are Git submodules, not copied source trees. Initialize them with:

```bash
git submodule update --init --recursive
```

Use the official Kodi tree as the upstream contract, the PS5 tree as an implementation reference, and the PS4SDK tree as a historical/public PS4 API and FreeBSD-compatibility reference. Do not edit any reference submodule from this repository.

`ps4sdk/` is intentionally pinned to its last `master` commit. The repository is old (last commit in 2017) and targets an early PS4 software environment, so it is evidence only and must not be treated as a current replacement for OpenOrbis or as a source for blindly copied code or binaries.

The pinned revisions can be intentionally updated later as a separate,
documented change.
