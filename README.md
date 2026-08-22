# Codex Windows AppxVolume Fix

A small diagnostic and workaround for a Windows Codex Desktop failure where **Computer Use is bundled in the app, but its local runtime never materializes**.

> [!IMPORTANT]
> This is an **unofficial community workaround**, not an OpenAI-supported fix. It is intentionally conservative: it does **not** change WindowsApps ownership/ACLs, decrypt package files, patch `app.asar`, edit the registry, or replace OpenAI binaries.

## TL;DR

On one affected Windows 11 machine, Codex showed a `C:\Program Files\WindowsApps\...` `InstallLocation`, but Windows actually registered the package on a **non-system D: AppxVolume**.

In the failing state:

```text
Computer Use bundled plugin: present
cua_node source files:       3452
node_repl.exe:               Application Protected
user runtime files:          0
Computer Use UI:             unavailable
```

The real package association was discovered with `Get-AppxPackage -Volume`, not by trusting `InstallLocation` alone.

Moving the already-installed Codex package to the **system AppxVolume** restored Computer Use immediately:

```powershell
$pkg = Get-AppxPackage OpenAI.Codex
$systemVolume = Get-AppxVolume | Where-Object IsSystemVolume | Select-Object -First 1
Move-AppxPackage -Package $pkg.PackageFullName -Volume $systemVolume
```

After reopening Codex, **Computer Use appeared in Plugins, installed successfully, and completed a real desktop action**.

## When this repository may help

This workaround is worth testing when most of these are true:

- Windows Codex Desktop is installed from MSIX / Microsoft Store.
- Computer Use is missing or reports unavailable native helper paths.
- `app\resources\plugins\openai-bundled\plugins\computer-use` exists in the package.
- `app\resources\cua_node` contains thousands of bundled runtime files.
- `%LOCALAPPDATA%\OpenAI\Codex\runtimes\cua_node` exists but is empty or incomplete.
- `cipher /c` reports packaged runtime files as `Application Protected`.
- `Get-AppxPackage -Volume` shows Codex belongs to a **non-system** AppxVolume.

It is **not** a universal fix for every Computer Use failure. If Codex is already registered on the system AppxVolume, your root cause may be different.

## Quick start

Open PowerShell and run the read-only diagnostic first:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\diagnose.ps1
```

If the diagnostic reports that Codex is registered on a non-system AppxVolume, fully exit Codex/ChatGPT and preview the proposed move:

```powershell
.\fix-appxvolume.ps1
```

To perform the move from an elevated PowerShell:

```powershell
.\fix-appxvolume.ps1 -Apply
```

Then reopen Codex and check **Plugins → Computer Use**.

## Why `InstallLocation` can mislead

In the reproduced case, this looked normal:

```text
InstallLocation : C:\Program Files\WindowsApps\OpenAI.Codex_...
```

But volume-aware queries told a different story:

```powershell
$c = Get-AppxVolume -Path C:\
$d = Get-AppxVolume -Path D:\

Get-AppxPackage -Volume $c | Where-Object Name -eq 'OpenAI.Codex'
# no result

Get-AppxPackage -Volume $d | Where-Object Name -eq 'OpenAI.Codex'
# OpenAI.Codex was returned here
```

The Windows AppX deployment log also recorded `target volume D:`. After `Move-AppxPackage` moved Codex to the system volume, the C: query returned the package and the D: query did not.

## Files

- [`diagnose.ps1`](diagnose.ps1) — read-only checks for package volume, source protection, runtime staging, helper files, and recent AppX events.
- [`fix-appxvolume.ps1`](fix-appxvolume.ps1) — guarded workaround; dry-run by default and only moves the package with `-Apply`.
- [`docs/case-study.md`](docs/case-study.md) — sanitized A/B investigation and before/after evidence.

## Upstream reports

This symptom family is already tracked in OpenAI's Codex repository:

- [openai/codex#34764](https://github.com/openai/codex/issues/34764) — Application Protected files fail to copy from WindowsApps.
- [openai/codex#25220](https://github.com/openai/codex/issues/25220) — bundled plugins unavailable because `copyfile` fails on protected WindowsApps files.
- [openai/codex#32589](https://github.com/openai/codex/issues/32589) — EFS `copyfile UNKNOWN / -4094` breaks bundled marketplace and Computer Use native pipe.
- [Our AppxVolume workaround report on #34764](https://github.com/openai/codex/issues/34764#issuecomment-5251587580).

## Independent reproduction

On 2026-08-22, another reporter on `openai/codex#34764` independently reproduced the same non-system AppxVolume failure pattern on Windows 11 build `26200.9168` with Codex package `26.818.4152.0`.

Before moving the package, Codex was registered on `D:\WindowsApps` (`IsSystemVolume=False`). The reporter observed 25–50+ minute startup delays, repeated `Not Responding` states, `CopyFileW / uv_fs_copyfile` hangs, Procmon `ACCESS DENIED` results taking roughly 20 seconds while staging `cua_node\...\bin\corepack`, and repeated incomplete `.staging-*` runtime directories.

After moving only the `OpenAI.Codex` package to the system C: AppxVolume with Windows' built-in `Move-AppxPackage`, the runtime materialized successfully, `corepack` was deployed with a non-zero size, the first launch became usable in roughly 10–15 seconds, and a second clean launch was fully usable within about 15 seconds without the prior freezes.

This is independent before/after evidence supporting the AppxVolume diagnosis and the same mitigation described by this repository.

- [Independent reproduction and mitigation report](https://github.com/openai/codex/issues/34764#issuecomment-5379844462)

## Safety

The scripts in this repository deliberately avoid the more invasive workarounds seen in some troubleshooting threads. They do **not**:

- take ownership of `WindowsApps`;
- modify WindowsApps ACLs;
- run `cipher /d` against packaged files;
- modify EFS policy;
- patch package contents or `app.asar`;
- copy OpenAI runtime binaries into this repository.

`fix-appxvolume.ps1` only uses Windows' built-in `Move-AppxPackage` cmdlet to move the registered package to the system AppxVolume.

## Tested case

The successful case used Windows build `26200.8875` and Codex package `26.803.10989.0`. Those values document the reproduction; they are **not** intended as compatibility requirements.

See [`docs/case-study.md`](docs/case-study.md) for the full sanitized evidence chain.

## License

MIT. See [LICENSE](LICENSE).
