-- pandoc filter for the kit's documentation:
-- 1. ```mermaid blocks become <pre class="mermaid"> (drawn by mermaid.js).
-- 2. Links to the built documents (README.md, docs/USAGE.md, docs/DEVELOPMENT.md) point to
--    their .html versions. Other .md links (e.g. profiles/README.md) are left as they are.

local function escape_html(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local BUILT = {
  ["README.md"] = true, ["../README.md"] = true,
  ["USAGE.md"] = true, ["DEVELOPMENT.md"] = true,
  ["docs/USAGE.md"] = true, ["docs/DEVELOPMENT.md"] = true,
}

function CodeBlock(el)
  if el.classes[1] == "mermaid" then
    return pandoc.RawBlock("html",
      '<div class="diagram"><pre class="mermaid">' .. escape_html(el.text) .. "</pre></div>")
  end
end

function Link(el)
  local path, anchor = el.target:match("^([^#]*)(#?.*)$")
  if BUILT[path] then el.target = path:gsub("%.md$", ".html") .. anchor end
  return el
end
