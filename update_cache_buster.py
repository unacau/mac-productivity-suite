files = [
    "/Users/igorekishev/.gemini/antigravity/worktrees/mac-productivity-suite/update_branding_and_icons/docs/site/index.html",
    "/Users/igorekishev/.gemini/antigravity/worktrees/website/update_branding_and_icons/projects/khomyak/website/index.html"
]

for file_path in files:
    with open(file_path, "r") as f:
        content = f.read()
    content = content.replace("?v=v4", "?v=v5")
    with open(file_path, "w") as f:
        f.write(content)
    print("Bumped cache buster to v5 in:", file_path)
