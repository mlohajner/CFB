# CFB Clipboard Files Bridge

Terminal <-> File Manager clipboard bridge for Linux.

```
@c file.conf     # copy
@x file.conf     # cut
@p               # paste into current directory
```

Copy/cut in the terminal, paste in Nemo/Nautilus/Thunar - OR the other way around.  
Same clipboard, both directions, no configuration.

```text
┌──────────┐
│ Terminal │
└────┬─────┘
     │
     ├───── @c foo.txt ────────┐
     ├───── @x foo.txt ────────┤
     │                         ▼
     │                ╔════════╪══════════╗
     │      ┌─────────╢  System Clipboard ║
     │      │         ╚═════╪════════╪════╝
     │      │               ▲        │
     │      │               │      Paste
     │      │            Copy/Cut    │
     │      │               │        ▼
     │      │            ┌──┴────────┴──┐
     │      │            │ File Manager │
     │      │            └──────┬───────┘
     │      │                   │
     │      │                   ▼
     │      ▼            ╔══════╪═══════╗
     └───── @p ────────►─╢ File System  ║
                         ╚══════════════╝
```

## Why it's nice

- **Three commands, zero ceremony.** No flags, no syntax to remember.
- **Real interoperability.** Not a separate terminal-only clipboard
  its compatible with GUI file managers
- **Silent on success**, like `cp`/`mv`/`cd`. Exit code `0` or `1`,
  nothing on stdout, errors on stderr.
- **No daemon, no background process, no dependencies beyond clipboard tool.**

## Install

Requires `xclip` (X11) **or** `wl-clipboard` (Wayland) — install
whichever matches your session:

```bash
sudo dnf install xclip         # X11
sudo dnf install wl-clipboard  # Wayland
```

Included `install.sh` copies a couple of files and creates aliases for you.  
Verify install procedure and provided information, when ready, execute:

```bash
chmod +x install.sh
./install.sh
```

## X11 / Wayland

Both are supported automatically. The scripts detect which one you're
running (`$WAYLAND_DISPLAY`) and use `wl-copy`/`wl-paste` or `xclip`
accordingly — nothing to configure either way.

## A few things to know!

`@p` performs an actual `cp`/`mv` on the filesystem. It needs a real
path, not just something a file manager *displays*. If you're browsing
a phone (MTP), a network share (SMB/SFTP), or anything else your file
manager shows through a virtual filesystem, it only becomes a real,
usable path once **GVFS** (or an equivalent: `mtpfs`, a manual
`mount`) has actually mounted it, typically under
`/run/user/$UID/gvfs/...`. This is true of any terminal tool, not
something specific to CFB.  
If `cp` can't reach it, neither can this. Regular local files and directories work out of the box.
