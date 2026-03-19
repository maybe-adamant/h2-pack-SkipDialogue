local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-Modpack_Lib']

config = chalk.auto('config.lua')
public.config = config

local backup, revert = lib.createBackupSystem()

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "AutoSkipDialogue",
    name     = "Auto Skip Dialogue",
    category = "QoLSettings",
    group    = "QoL",
    tooltip  = "Automatically skips dialogue prompts during gameplay.",
    default  = false,
    dataMutation = false,
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
end

local function registerHooks()
    modutil.mod.Path.Wrap("PlayTextLines", function(base, source, textLines, args)
        if not lib.isEnabled(config) then return base(source, textLines, args) end

        -- Not in a run
        if CurrentRun.Hero.IsDead then
            return base(source, textLines, args)
        end

        if not textLines then return end

        -- Don't skip main story conversations (wants-to-talk icon)
        if textLines.StatusAnimation == 'StatusIconWantsToTalk' then
            return base(source, textLines, args)
        end

        -- Don't skip NPC choice dialogues
        if textLines.PrePortraitExitFunctionName then
            local hasChoice = string.find(textLines.PrePortraitExitFunctionName, 'Choice')
            if hasChoice then
                return base(source, textLines, args)
            end
        end

        return
    end)
end

-- =============================================================================
-- Wiring
-- =============================================================================

public.definition.apply = apply
public.definition.revert = revert

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if lib.isEnabled(config) then apply() end
        if public.definition.dataMutation and not mods['adamant-Modpack_Core'] then
            SetupRunData()
        end
    end)
end)

local uiCallback = lib.standaloneUI(public.definition, config, apply, revert)
rom.gui.add_to_menu_bar(uiCallback)
