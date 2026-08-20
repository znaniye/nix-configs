{ config, lib, ... }:

let
  inherit (lib) types;

  indent =
    n: text:
    let
      pad = lib.concatStrings (lib.genList (_: " ") n);
      lines = lib.splitString "\n" text;
      indented = map (l: if l == "" then "" else pad + l) lines;
    in
    lib.concatStringsSep "\n" indented;

  toYaml =
    value:
    if builtins.isBool value then
      (if value then "true" else "false")
    else if builtins.isInt value || builtins.isFloat value then
      builtins.toString value
    else if builtins.isString value then
      "\"${lib.escape [ "\"" "\\" ] value}\""
    else if builtins.isList value then
      if value == [ ] then
        "[]"
      else
        "\n" + lib.concatStringsSep "\n" (map (v: "- " + toYamlInline v) value)
    else if builtins.isAttrs value then
      if value == { } then
        "{}"
      else
        let
          renderEntry =
            name: v:
            let
              rendered = toYaml v;
            in
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

  toYamlInline =
    value:
    if builtins.isAttrs value then
      let
        pairs = lib.mapAttrsToList (k: v: "${k}: ${toYamlInline v}") value;
      in
      "{ ${lib.concatStringsSep ", " pairs} }"
    else if builtins.isList value then
      "[ ${lib.concatStringsSep ", " (map toYamlInline value)} ]"
    else
      toYaml value;

  attrsToFrontmatter =
    attrs:
    let
      filtered = lib.filterAttrs (_: v: v != null && v != { } && v != [ ]) attrs;
    in
    if filtered == { } then "" else toYaml filtered;

  renderClaudeAgent =
    name: agent:
    let
      base = {
        inherit name;
        inherit (agent) description;
      }
      // lib.optionalAttrs (agent.tools.claudeCode != [ ]) {
        tools = lib.concatStringsSep ", " agent.tools.claudeCode;
      }
      // lib.optionalAttrs (agent.mcpServers.claudeCode != { }) {
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

  renderOpencodeAgent =
    name: agent:
    let
      base = {
        inherit (agent) description;
        mode = "subagent";
      }
      // lib.optionalAttrs (agent.permission.opencode != { }) {
        permission = agent.permission.opencode;
      }
      // lib.optionalAttrs (agent.mcpServers.opencode != { }) {
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
      body = lib.mkOption {
        description = "Path to the markdown file containing the agent's system prompt (no frontmatter).";
        type = types.path;
      };
      description = lib.mkOption {
        description = "One-line summary of the agent. Used in both consumers' frontmatter.";
        type = types.str;
      };
      extraFrontmatter.claudeCode = lib.mkOption {
        default = { };
        description = "Escape hatch: extra fields merged into claude-code frontmatter.";
        type = types.attrsOf types.anything;
      };
      extraFrontmatter.opencode = lib.mkOption {
        default = { };
        description = "Escape hatch: extra fields merged into opencode frontmatter (e.g. model, temperature, color).";
        type = types.attrsOf types.anything;
      };
      mcpServers.claudeCode = lib.mkOption {
        default = { };
        description = "Per-agent MCP servers injected into claude-code frontmatter.";
        type = types.attrsOf types.anything;
      };
      mcpServers.opencode = lib.mkOption {
        default = { };
        description = "Per-agent MCP servers injected into opencode frontmatter (`mcp:`).";
        type = types.attrsOf types.anything;
      };
      permission.opencode = lib.mkOption {
        default = { };
        description = "Map rendered under opencode `permission:`. Values like \"allow\", \"deny\", \"ask\", or nested maps.";
        type = types.attrsOf types.anything;
      };
      tools.claudeCode = lib.mkOption {
        default = [ ];
        description = "Tool allowlist rendered as comma-separated `tools:` in claude-code frontmatter. Empty = inherit parent.";
        type = types.listOf types.str;
      };
    };
  };

in
{
  config.shared.codingAgents.agents = {
    pencil-designer = {
      body = ./agents/pencil-designer.md;
      description = "Designs in .pen files via the pencil MCP. Caller passes a goal (new screen, component edit, style refresh, etc.) and any references; the agent reads the active document, makes the changes, and reports back without flooding the parent context with MCP output.";
      permission.opencode = {
        edit = "deny";
        write = "deny";
      };
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
    };
    web-debugger = {
      body = ./agents/web-debugger.md;
      description = "Drives the agent-browser CLI to validate web app behavior. Caller passes a goal and any relevant context (URL, expected behavior, suspected bug, auth, etc.); the agent decides which agent-browser commands to run.";
      permission.opencode = {
        edit = "deny";
        write = "deny";
      };
      tools.claudeCode = [
        "Bash"
        "Read"
        "Grep"
        "Glob"
      ];
    };
  };
  options.shared.codingAgents = {
    agents = lib.mkOption {
      default = { };
      description = "Sub-agents shared across claude-code and opencode. Each consumer renders its own frontmatter.";
      type = types.attrsOf agentSubmodule;
    };

    renderClaudeAgent = lib.mkOption {
      default = renderClaudeAgent;
      description = "Function: name -> agent -> markdown string with claude-code frontmatter.";
      readOnly = true;
      type = types.functionTo (types.functionTo types.str);
    };

    renderOpencodeAgent = lib.mkOption {
      default = renderOpencodeAgent;
      description = "Function: name -> agent -> markdown string with opencode frontmatter.";
      readOnly = true;
      type = types.functionTo (types.functionTo types.str);
    };
  };
}
