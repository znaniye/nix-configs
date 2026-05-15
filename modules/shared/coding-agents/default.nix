{ config, lib, ... }:

let
  inherit (lib) types;

  indent = n: text:
    let
      pad = lib.concatStrings (lib.genList (_: " ") n);
      lines = lib.splitString "\n" text;
      indented = map (l: if l == "" then "" else pad + l) lines;
    in
    lib.concatStringsSep "\n" indented;

  toYaml = value:
    if builtins.isBool value then
      (if value then "true" else "false")
    else if builtins.isInt value || builtins.isFloat value then
      builtins.toString value
    else if builtins.isString value then
      "\"${lib.escape [ "\"" "\\" ] value}\""
    else if builtins.isList value then
      if value == [ ] then "[]"
      else "\n" + lib.concatStringsSep "\n" (map (v: "- " + toYamlInline v) value)
    else if builtins.isAttrs value then
      if value == { } then "{}"
      else
        let
          renderEntry = name: v:
            let rendered = toYaml v; in
            if builtins.isAttrs v && v != { } then
              "${name}:\n${indent 2 rendered}"
            else if builtins.isList v && v != [ ] then
              "${name}:${rendered}"
            else
              "${name}: ${rendered}";
        in
        lib.concatStringsSep "\n" (lib.mapAttrsToList renderEntry value)
    else
      throw "toYaml: unsupported type for value ${builtins.toJSON value}";

  toYamlInline = value:
    if builtins.isAttrs value then
      let
        pairs = lib.mapAttrsToList (k: v: "${k}: ${toYamlInline v}") value;
      in
      "{ ${lib.concatStringsSep ", " pairs} }"
    else if builtins.isList value then
      "[ ${lib.concatStringsSep ", " (map toYamlInline value)} ]"
    else
      toYaml value;

  attrsToFrontmatter = attrs:
    let
      filtered = lib.filterAttrs (_: v: v != null && v != { } && v != [ ]) attrs;
    in
    if filtered == { } then "" else toYaml filtered;

  renderClaudeAgent = name: agent:
    let
      base = {
        inherit name;
        inherit (agent) description;
      } // lib.optionalAttrs (agent.tools.claudeCode != [ ]) {
        tools = lib.concatStringsSep ", " agent.tools.claudeCode;
      } // lib.optionalAttrs (agent.mcpServers.claudeCode != { }) {
        mcpServers = agent.mcpServers.claudeCode;
      };
      merged = base // agent.extraFrontmatter.claudeCode;
      body = builtins.readFile agent.body;
    in
    ''
      ---
      ${attrsToFrontmatter merged}
      ---

      ${body}'';

  renderOpencodeAgent = name: agent:
    let
      base = {
        inherit (agent) description;
        mode = "subagent";
      } // lib.optionalAttrs (agent.permission.opencode != { }) {
        permission = agent.permission.opencode;
      } // lib.optionalAttrs (agent.mcpServers.opencode != { }) {
        mcp = agent.mcpServers.opencode;
      };
      merged = base // agent.extraFrontmatter.opencode;
      body = builtins.readFile agent.body;
    in
    ''
      ---
      ${attrsToFrontmatter merged}
      ---

      ${body}'';

  agentSubmodule = types.submodule {
    options = {
      description = lib.mkOption {
        type = types.str;
        description = "One-line summary of the agent. Used in both consumers' frontmatter.";
      };

      body = lib.mkOption {
        type = types.path;
        description = "Path to the markdown file containing the agent's system prompt (no frontmatter).";
      };

      tools.claudeCode = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Tool allowlist rendered as comma-separated `tools:` in claude-code frontmatter. Empty = inherit parent.";
      };

      permission.opencode = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Map rendered under opencode `permission:`. Values like \"allow\", \"deny\", \"ask\", or nested maps.";
      };

      mcpServers.claudeCode = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Per-agent MCP servers injected into claude-code frontmatter.";
      };

      mcpServers.opencode = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Per-agent MCP servers injected into opencode frontmatter (`mcp:`).";
      };

      extraFrontmatter.claudeCode = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Escape hatch: extra fields merged into claude-code frontmatter.";
      };

      extraFrontmatter.opencode = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Escape hatch: extra fields merged into opencode frontmatter (e.g. model, temperature, color).";
      };
    };
  };

in
{
  options.shared.codingAgents = {
    agents = lib.mkOption {
      type = types.attrsOf agentSubmodule;
      default = { };
      description = "Sub-agents shared across claude-code and opencode. Each consumer renders its own frontmatter.";
    };

    renderClaudeAgent = lib.mkOption {
      type = types.functionTo (types.functionTo types.str);
      readOnly = true;
      default = renderClaudeAgent;
      description = "Function: name -> agent -> markdown string with claude-code frontmatter.";
    };

    renderOpencodeAgent = lib.mkOption {
      type = types.functionTo (types.functionTo types.str);
      readOnly = true;
      default = renderOpencodeAgent;
      description = "Function: name -> agent -> markdown string with opencode frontmatter.";
    };
  };

  config.shared.codingAgents.agents = {
    web-debugger = {
      description = "Drives the agent-browser CLI to validate web app behavior. Caller passes a goal and any relevant context (URL, expected behavior, suspected bug, auth, etc.); the agent decides which agent-browser commands to run.";
      body = ./agents/web-debugger.md;
      tools.claudeCode = [ "Bash" "Read" "Grep" "Glob" ];
      permission.opencode = {
        edit = "deny";
        write = "deny";
      };
    };

    pencil-designer = {
      description = "Designs in .pen files via the pencil MCP. Caller passes a goal (new screen, component edit, style refresh, etc.) and any references; the agent reads the active document, makes the changes, and reports back without flooding the parent context with MCP output.";
      body = ./agents/pencil-designer.md;
      tools.claudeCode = [
        "Read"
        "Glob"
        "Grep"
        "mcp__pencil__get_editor_state"
        "mcp__pencil__open_document"
        "mcp__pencil__get_guidelines"
        "mcp__pencil__batch_get"
        "mcp__pencil__batch_design"
        "mcp__pencil__get_screenshot"
        "mcp__pencil__export_nodes"
        "mcp__pencil__find_empty_space_on_canvas"
        "mcp__pencil__get_variables"
        "mcp__pencil__set_variables"
        "mcp__pencil__replace_all_matching_properties"
        "mcp__pencil__search_all_unique_properties"
        "mcp__pencil__snapshot_layout"
      ];
      permission.opencode = {
        edit = "deny";
        write = "deny";
      };
    };
  };
}
