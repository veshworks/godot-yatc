# godot-yatc

## Installation

Make sure to run this command on the root folder of your Godot project.

```bash
git remote add yatc git@github.com:veshworks/godot-yatc.git
git fetch yatc
git subtree add --prefix addons/godot-yatc yatc main --squash
```

## Updating addon

```bash
git subtree pull --prefix addons/godot-yatc yatc main --squash
```


## Contributing back to upstream

Make sure all changes to this add-on are committed separated (like `git add
addons/godot-yatc`, otherwise the subtree push will not really work
properly).

```bash
git subtree push --prefix addons/godot-yatc yatc main
```
