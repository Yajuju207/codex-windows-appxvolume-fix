# Case Study: Codex Computer Use restored by AppxVolume migration

## Initial symptom

Codex Desktop was installed successfully, and the bundled Computer Use files existed, but Computer Use was unavailable.

## Before

Observed state:

```text
Computer Use plugin: present
CUA source: present
CUA runtime destination: empty
node_repl.exe: Application Protected
```

The important discovery was that `InstallLocation` alone was misleading.

## Investigation

The package appeared under:

```text
C:\Program Files\WindowsApps\...
```

but volume-aware inspection showed Codex was registered on a non-system AppxVolume.

The comparison machine with the same package and Windows environment had Codex registered on the system AppxVolume.

## Workaround

Move the package to the system AppxVolume:

```powershell
$pkg = Get-AppxPackage OpenAI.Codex
$systemVolume = Get-AppxVolume | Where-Object IsSystemVolume | Select-Object -First 1
Move-AppxPackage -Package $pkg.PackageFullName -Volume $systemVolume
```

## Result

After reopening Codex:

- Computer Use appeared in Plugins.
- Installation succeeded.
- A real desktop automation test completed successfully.

## Notes

This repository documents one reproducible case. It does not claim every Computer Use failure is caused by AppxVolume deployment.
