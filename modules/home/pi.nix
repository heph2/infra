{ ... }:
{
  infra.modules.homeManager.pi =
    { inputs, pkgs, ... }:
    let
      awsBestPracticesSkill = pkgs.runCommand "aws-best-practices-skill" { } ''
            cp -R ${inputs.aws-best-practices-skill} $out
            chmod -R u+w $out
            cat > $out/SKILL.md <<'EOF'
        ---
        name: aws-best-practices
        description: Local AWS best-practices catalog. Use for AWS Well-Architected/security/reliability/performance/cost/operations/sustainability guidance. Read local catalog files first; avoid web unless user asks for live verification or local coverage is missing.
        ---
        EOF
            awk 'BEGIN { frontmatter = 0; body = 0 } /^---$/ { frontmatter++; if (frontmatter == 2) { body = 1; next } } body { print }' ${inputs.aws-best-practices-skill}/SKILL.md >> $out/SKILL.md
      '';
      piSkills = {
        chrome-cdp = inputs.chrome-cdp-skill + "/skills/chrome-cdp";
        grill-me = inputs.mattpocock-skills + "/skills/productivity/grill-me";
        imagegen = inputs.openai-skills + "/skills/.system/imagegen";
        ponytail = inputs.ponytail + "/skills/ponytail";
        tdd = inputs.superpowers + "/skills/test-driven-development";
        ansible-good-practices =
          inputs.claude-ansible-skills + "/ansible-good-practices/skills/ansible-good-practices";
        ansible-new-role = inputs.claude-ansible-skills + "/ansible-new-role/skills/ansible-new-role";
        ansible-new-collection =
          inputs.claude-ansible-skills + "/ansible-new-collection/skills/ansible-new-collection";
        ansible-new-ee = inputs.claude-ansible-skills + "/ansible-new-ee/skills/ansible-new-ee";
        ansible-new-molecule =
          inputs.claude-ansible-skills + "/ansible-new-molecule/skills/ansible-new-molecule";
        ansible-docs = inputs.claude-ansible-skills + "/ansible-docs/skills/ansible-docs";
        ansible-zen = inputs.claude-ansible-skills + "/ansible-zen/skills/ansible-zen";
        aws-best-practices = awsBestPracticesSkill;
        nixos-host-workflow = ../../skills/nixos-host-workflow;
        linux-game-compatibility = ../../skills/linux-game-compatibility;
        hledger-finance = ../../skills/hledger-finance;
        vikunja = ../../skills/vikunja;
      };
    in
    {
      imports = [ inputs.pi.homeModules.default ];

      home.file.".agent-browser/config.json".text = builtins.toJSON {
        cdp = "9222";
      };

      home.file.".pi/agent/extensions/pi-tool-display/config.json".text = builtins.toJSON {
        # Keep tool output quiet by default; use /tool-display for temporary changes.
        readOutputMode = "hidden";
        searchOutputMode = "hidden";
        mcpOutputMode = "hidden";
        bashOutputMode = "summary";
        showTruncationHints = false;
        showRtkCompactionHints = false;

      };

      home.file.".pi/agent/themes/catpuccino-mocha.json".text = builtins.toJSON {
        "$schema" =
          "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
        name = "catpuccino-mocha";
        vars = {
          rosewater = "#f5e0dc";
          flamingo = "#f2cdcd";
          pink = "#f5c2e7";
          mauve = "#cba6f7";
          red = "#f38ba8";
          maroon = "#eba0ac";
          peach = "#fab387";
          yellow = "#f9e2af";
          green = "#a6e3a1";
          teal = "#94e2d5";
          sky = "#89dceb";
          sapphire = "#74c7ec";
          blue = "#89b4fa";
          lavender = "#b4befe";
          text = "#cdd6f4";
          subtext1 = "#bac2de";
          subtext0 = "#a6adc8";
          overlay2 = "#9399b2";
          overlay1 = "#7f849c";
          overlay0 = "#6c7086";
          surface2 = "#585b70";
          surface1 = "#45475a";
          surface0 = "#313244";
          base = "#1e1e2e";
          mantle = "#181825";
          crust = "#11111b";
        };
        colors = {
          accent = "mauve";
          border = "surface2";
          borderAccent = "mauve";
          borderMuted = "surface1";
          success = "green";
          error = "red";
          warning = "yellow";
          muted = "overlay2";
          dim = "overlay0";
          text = "text";
          thinkingText = "subtext0";
          selectedBg = "surface0";
          userMessageBg = "surface0";
          userMessageText = "text";
          customMessageBg = "surface0";
          customMessageText = "text";
          customMessageLabel = "mauve";
          toolPendingBg = "mantle";
          toolSuccessBg = "#1e3326";
          toolErrorBg = "#3a202e";
          toolTitle = "blue";
          toolOutput = "text";
          mdHeading = "mauve";
          mdLink = "blue";
          mdLinkUrl = "sapphire";
          mdCode = "peach";
          mdCodeBlock = "text";
          mdCodeBlockBorder = "surface2";
          mdQuote = "subtext0";
          mdQuoteBorder = "surface2";
          mdHr = "surface2";
          mdListBullet = "mauve";
          toolDiffAdded = "green";
          toolDiffRemoved = "red";
          toolDiffContext = "overlay1";
          syntaxComment = "overlay1";
          syntaxKeyword = "mauve";
          syntaxFunction = "blue";
          syntaxVariable = "text";
          syntaxString = "green";
          syntaxNumber = "peach";
          syntaxType = "yellow";
          syntaxOperator = "sky";
          syntaxPunctuation = "overlay2";
          thinkingOff = "overlay0";
          thinkingMinimal = "lavender";
          thinkingLow = "blue";
          thinkingMedium = "teal";
          thinkingHigh = "peach";
          thinkingXhigh = "red";
          bashMode = "green";
        };
        export = {
          pageBg = "base";
          cardBg = "mantle";
          infoBg = "surface0";
        };
      };

      programs.pi.coding-agent = {
        enable = true;
        skills = builtins.attrValues piSkills;
        settings = {
          hideThinkingBlock = true;
          theme = "catpuccino-mocha";
          packages = [
            # Agent orchestration and explicit goal tracking.
            "npm:pi-subagents@0.33.1"
            "npm:@narumitw/pi-goal@0.9.2"


            # Research and context tools: search/fetch/PDF/video plus skill UX polish.
            "npm:pi-web-access@0.13.0"
            "npm:pi-skillful@0.3.11"
            "npm:@eko24ive/pi-ask@1.1.0"
            "npm:pi-tool-display@0.5.0"
            # 0.6.1 monkey-patched tui.doRender; pi 0.84.0 proxies it -> infinite
            # recursion -> "Maximum call stack size exceeded" on TUI start.
            # 0.9.0 dropped the extension-owned fixed editor.
            "npm:pi-powerline-footer@0.12.1"
            "npm:@victor-software-house/pi-agent-browser"

            # Additional providers and account-usage visibility.
            # Runtime-discovered OpenCode Zen/Go models, so new free models show up immediately.
            "npm:pi-opencode-provider@0.7.3"
            "npm:@narumitw/pi-usage@0.52.1"

            # Reuse the local Claude Code OAuth session as a pi provider.
            # Risk accepted interactively: this third-party extension uses non-public Anthropic protocol details.
            "npm:@cgaravitoq/pi-claude-code-auth@2.3.0"
          ];
        };
      };

    };
}
