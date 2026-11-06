local STRINGS = GLOBAL.STRINGS
STRINGS.eventtimer = {
    ui_title = "Event Timer",
    ui_desc = "Event Timer\nRight-click to drag",
    worldid = "World %s",
    worldtype = {
        forest = "Forest",
        cave = "Cave",
        shipwrecked = "Shipwrecked",
        volcano = "Volcano",
        porkland = "Hamlet",
    },
    time = {
        hour = " hour ",
        day = " day ",
        minutes = " min ",
        seconds = " sec"
    },

    ----------------------------------------Forest----------------------------------------

    hounded = {
        cooldowns = {
            forest = "<prefab=hound> will attack in %s.",
            cave = "<prefab=worm> will attack in %s.",
            worm_boss = "<prefab=worm_boss> will attack in %s.",
            shipwrecked = "<prefab=crocodog> will attack in %s.",
            volcano =  "<prefab=crocodog> will attack in %s.",
            porkland = "<prefab=vampirebat> will attack in %s.",
        },
        attack = {
            forest = "WARNING: <prefab=hound> is attacking!",
            cave = "WARNING: <prefab=worm> is attacking!",
            worm_boss = "WARNING: <prefab=worm_boss> is attacking!",
            shipwrecked = "WARNING: <prefab=crocodog> is attacking!",
            volcano =  "WARNING: <prefab=crocodog> is attacking!",
            porkland = "WARNING: <prefab=vampirebat> is attacking!",
        },
        worm_boss_chance = "<prefab=worm> will attack in %s.\n<prefab=worm_boss> chance: %s%%",
    },
    deerclopsspawner = {
        cooldown = "<prefab=deerclops> will spawn in %s.",
        target = "<prefab=deerclops> will spawn near %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=deerclops> is attacking!",
    },
    deerherdspawner = {
        cooldown = "<prefab=deer> will spawn in %s.",
    },
    klaussackspawner = {
        cooldown = "<prefab=klaus_sack> will spawn in %s.",
        despawn = "<prefab=klaus_sack> will despawn on day %s.",
        despawntext = "Despawns on day %s",
        tips = "<prefab=klaus_sack> has respawned!",
    },
    sinkholespawner = {
        cooldown = "<prefab=antlion> will become enraged in %s.",
        attack = "WARNING: <prefab=antlion> is becoming enraged!",
    },
    beargerspawner = {
        cooldown = "<prefab=bearger> will spawn in %s.",
        target = "<prefab=bearger> will spawn near %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=bearger> is attacking!",
    },
    dragonfly_spawner = {
        cooldown = "<prefab=dragonfly> will respawn in %s.",
        tips = "<prefab=dragonfly> has respawned!",
    },
    beequeenhive = {
        cooldown = "<prefab=beequeen> will respawn in %s.",
        tips = "<prefab=beequeen> has respawned!",
    },
    terrarium = {
        cooldown = "<prefab=terrarium> will be ready in %s.",
        tips = "<prefab=terrarium> is ready.",
    },
    malbatrossspawner = {
        cooldown = "<prefab=malbatross> will respawn in %s.",
    },
    crabkingspawner = {
        cooldown = "<prefab=crabking> will respawn in %s.",
    },
    moon = {
        moon_full = "Days until the full moon: %s",
        moon_new = "Days until the new moon: %s",
        str_full = "full moon",
        moon_full_ready = "There is a full moon tonight.",
        moon_new_ready = "There is a new moon tonight.",
    },
    farming_manager = {
        cooldown = "<prefab=lordfruitfly> will be ready in %s.",
        ready = "<prefab=lordfruitfly> is attacking!",
        tips = "WARNING: <prefab=lordfruitfly> is attacking!"
    },
    piratespawner = {
        cooldown = "A pirate raid may occur in %s."
    },
    forestdaywalkerspawner = {
        cooldown = "<prefab=daywalker2> will respawn in %s.",
        ready = "<prefab=daywalker2> is waiting to be uncovered.",
        exists = "<prefab=daywalker2> is roaming.",
        tips = "<prefab=daywalker2> has respawned!",
    },
    riftspawner = {
        lunar_cooldown = "A Lunar Rift will open in %s.",
        shadow_cooldown = "A Shadow Rift will open in %s.",
        stage = "Stage: %s / %s",
    },
	lunarthrall_plantspawner = {
		infested_count = "%s plants infested",
		spawn = "Infestation begins in %s.",
		next_wave = "Next wave in %s",
		remain_waves = "%s waves remaining",
	},
    rift_portal = {
        name = "Lunar Rift",
		next_stage = "Next stage in %s.",
		crystals = "<prefab=lunarrift_crystal_big>: %s available / %s total / %s max",
		next_crystal = "Next <prefab=lunarrift_crystal_big> wave in %s",
	},
    messagebottlemanager = {
        text = "Treasures to recover: %d / %d",
    },
    walrus_camp = {
        cooldown = "[%d] %s",
        ready = "Ready!",
    },

    ----------------------------------------Cave----------------------------------------
    shadowrift_portal = {
        name = "Shadow Rift",
        close = "<prefab=shadowrift_portal> will close in %s.",
    },
    daywalkerspawner = {
        cooldown = "<prefab=daywalker> will respawn in %s.",
        ready = "<prefab=daywalker> has respawned.",
        tips = "<prefab=daywalker> has respawned!",
    },
    shadowthrallmanager = {
		fissure_cooldown = "Next fissure can be taken over in %s",
		waiting_for_players = "Waiting for a player to come near",
		thralls_alive = "Thralls alive (%s): %s",
		dreadstone_regen = "<prefab=dreadstone> will regenerate in %s",
	},
    toadstoolspawner = {
		cooldown = "<prefab=toadstool> will respawn in %s.",
    },
    rockybossspawner = {
        cooldown = "Next <prefab=rocky_boss> spawn attempt in %s.",
    },
    batbosscave = {
        cooldown = "Respawns in %s",
        announce = "<prefab=bat_boss>: %s",
        tips = "<prefab=bat_boss> has respawned!",
    },
    atrium_gate = {
		cooldown = "<prefab=atrium_gate> will reset in %s.",
        destabilizing = "The Ruins will reset in %s.",
    },
    nightmareclock = {
        phase_locked_text = "Locked by the Ancient Key",
        phase_locked = "The Ruins are locked in the Nightmare phase.",
        phases = {
            calm = "Calm",
            warn = "Warning",
            wild = "Nightmare",
            dawn = "Dawn",
        },
        cooldown = "The Ruins are in the %s phase (%s remaining).",
        cooldown_none = "%s remaining in the current Ruins phase",
    },
    quaker = {
        cooldown = "An earthquake will occur in %s."
    },

    ----------------------------------------player----------------------------------------

    flotsamgenerator = {
        announce = "My next <prefab=messagebottle> spawn attempt is in %s.",
    },
    yoth_knightmanager = {
        announce = "My <prefab=knight_yoth> will respawn in %s.",
        tips = "<prefab=knight_yoth> is ready to spawn."
    },

    acidbatwavemanager = {
        chance = "Bat attack chance: %.1f%% (estimated: %.1f%%)",
        next_wave_spawn = "<prefab=bat> attack (%s bats) in %s",
        cooldown = "<prefab=bat> attack cooldown: %s",
    },

    ----------------------------------------Shipwrecked----------------------------------------

    chessnavy = {
        cooldown = "<prefab=knightboat> will spawn in %s.",
        ready = "<prefab=knightboat> is waiting for you to return to the scene of the crime.",
        readytext = "Waiting for you to return to the scene of the crime.",
    },
    volcanoactivity = {
        eruption = "Eruption ends in %s",
    },
    volcanomanager = {
        cooldown = "<prefab=volcano> will erupt in %s.",
        attack = "WARNING: The <prefab=volcano> is erupting!",
    },
    twisterspawner = {
        cooldown = "<prefab=twister> will spawn in %s.",
        target = "<prefab=twister> will spawn near %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=twister> is attacking!",
    },
    krakener = {
        cooldown = "<prefab=kraken> will respawn in %s.",
        ready = "<prefab=kraken> is waiting to be lured out.",
        tips = "<prefab=kraken> has respawned!",
    },
    tigersharker = {
        cooldown = "<prefab=tigershark> will respawn in %s.",
        ready = "<prefab=tigershark> is ready to spawn.",
        readytext = "Ready to spawn.",
        exists = "<prefab=tigershark> is roaming.",
        nospawn = "<prefab=tigershark>: Cannot spawn?",
        tips = "<prefab=tigershark> is ready to spawn.",
    },
    islandsklaussackspawner = {
        cooldown = "<prefab=klaus_sack_tropical> will spawn in %s.",
        despawn = "<prefab=klaus_sack_tropical> will despawn on day %s.",
        despawntext = "Despawns on day %s",
        tips = "<prefab=klaus_sack_tropical> has respawned!",
    },

    ----------------------------------------Hamlet----------------------------------------

    pugalisk_fountain = {
        cooldown = "<prefab=waterdrop> will regenerate in %s.",
        tips = "<prefab=waterdrop> has regenerated!",
    },
    banditmanager = {
        exists = "<prefab=pigbandit> is roaming.",
        cooldown = "Next spawn attempt in %s\n[Oincs stolen: %s, active bandit: %s]",
        announce_cooldown = "Next <prefab=pigbandit> spawn attempt in %s. Oincs stolen: %s.",
        announce_time = "Next <prefab=pigbandit> spawn attempt in %s.",
        ready = "<prefab=pigbandit> is roaming. Oincs stolen: %s",
        readytext = "<prefab=pigbandit> is roaming.\nOincs stolen: %s",
        tips = "WARNING: <prefab=pigbandit> is roaming!",
    },
    aporkalypse = {
        cooldown = "The Aporkalypse will begin in %s.",
        attack = "Next <prefab=vampirebat> attack: %s\nNext <prefab=ancient_herald> attack: %s",
        announce_attack = "Next <prefab=vampirebat> attack: %s    Next <prefab=ancient_herald> attack: %s",
        tips = "WARNING: The Aporkalypse will begin in %s.",
        tips_ready = "The blood moon has risen!",
        tips_attack = "WARNING: <prefab=ancient_herald> will spawn in %s.", -- Not in use
        tips_attack_ready = "WARNING: <prefab=ancient_herald> is attacking!", -- Not in use
    },
    batted = {
        cooldown = "<prefab=vampirebat> will attack in %s.",
        cooldowntext = "%s\n[Count: %s, next bat in %s]",
        attack = "WARNING: <prefab=vampirebat> is attacking!",
    },
    rocmanager = {
        cooldown = "<prefab=roc_head> will arrive in %s.",
        exists = "<prefab=roc_head> is roaming.",
        tips = "WARNING: <prefab=roc_head> is roaming!"
    },

    ----------------------------------------Uncompromising Mode----------------------------------------

    gmoosespawner = {
        cooldown = "<prefab=moose1> will spawn in %s.",
        target = "<prefab=moose1> will spawn near %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=moose1> is attacking!",
    },
    mock_dragonflyspawner = {
        cooldown = "<prefab=dragonfly> will spawn in %s.",
        target = "<prefab=dragonfly> will spawn near %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=dragonfly> is attacking!",
    },
}
