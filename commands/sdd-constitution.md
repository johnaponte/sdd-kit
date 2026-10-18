---
description: SDD · Interview the user and propose the project constitution (principles, stack, tools)
argument-hint: [extra context]
---
We are going to create (or review, if it exists) the project constitution. Use the sdd skill.
`docs/constitution.md` is protected: never edit it. Your output is a proposal in
`docs/proposals/constitution.md`. Do NOT write code or any other file.
Extra context: $ARGUMENTS

1. If `docs/sdd-templates/profile.md` exists, it is the chosen stack profile: read it and start
   from its values; only ask about what it leaves open (marked `<…>`) and confirm the rest in a
   single message. If the project already has code, configuration or documentation, read them
   too and infer as much as you can. Never ask what you already know.
2. Ask me ONE question at a time (8 at most), only about what is missing:
   - kind of application and who it is for;
   - name of the product folder (recommended: `app/`) and which exceptions live at the root;
   - language, version, allowed frameworks and libraries;
   - dependency and environment management (does it run in a Docker container? which image,
     pinned to which tag or digest?);
   - whether there is a structure generator or template (e.g. cookiecutter, the Xcode wizard
     or a profile's `bin/bootstrap.sh`): it always runs inside the product folder;
   - test framework, lint/format and build;
   - how the interface or external behaviour is verified;
   - user data and security;
   - language of the code, the interface and the documentation;
   - what needs approval first and what is forbidden.
   When it makes sense, suggest a recommended option so I only have to confirm.
3. With my answers, show me the constitution based on
   `docs/sdd-templates/constitution.template.md`: 8 principles at most, short and verifiable.
   If `docs/constitution.md` already exists, show me only the changes.
4. Wait for my approval. Only then write `docs/proposals/constitution.md`.
5. When done, tell me to promote it from my own terminal with
   `<kit-path>/promote.sh . constitution`, and that the next step is `/sdd-agents`.
