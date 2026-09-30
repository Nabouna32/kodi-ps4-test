# Reference repositories

This directory contains external Git repositories used for direct code comparison.

## Pinned references

| Path | Repository | Pinned revision |
|---|---|---|
| `kodi/` | `xbmc/xbmc` | `9c3e7f4d7b3ff314cd2f19a291766555e0346024` |
| `kodi-ps5/` | `VivaLaVent/kodi-ps5` | `0ea36e36d738aa045c1b8ed63c24a0314c7f72a5` |

These are Git submodules, not copied source trees. Initialize them with:

```bash
git submodule update --init --recursive
```

Use the official Kodi tree as the upstream contract and the PS5 tree as an
implementation reference. Do not edit either submodule from this repository.

The pinned revisions can be intentionally updated later as a separate,
documented change.
