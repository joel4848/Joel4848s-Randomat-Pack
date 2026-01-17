Thanks to [Malivil](https://steamcommunity.com/sharedfiles/filedetails/?id=2055805086) and [The Stig](https://steamcommunity.com/workshop/filedetails/?id=2426397260), both for the original randomats on which some of the below (acknowledged specifically) were based/served as inspiration, and for their patience and support as I learned Lua 'on-the-job'. I appreciate you both very much :) 

# Joel4848's Randomat Pack

Randomats are a TTT mechanic added by Malivil's [TTT Randomat 2.0](https://steamcommunity.com/sharedfiles/filedetails/?id=2055805086) which trigger a random event, either automatically at the start of each round or when the 'Randomat-4000' item is bought and used (typically available to Detective-like roles).\
\
This mod adds new randomats. **It requires [TTT Randomat 2.0](https://steamcommunity.com/sharedfiles/filedetails/?id=2055805086) in order to do anything!** Where I've ~~shamelessly ripped off~~ drawn inspiration from existing randomats/elsewhere, credit will be given in the relevant randomat's entry. If I've missed any, please raise an issue and I'll add it ASAP.\
\
Some of the randomats will require other mods to be present in order to work. Any such dependencies will be specified in the relevant randomat description below. If you don't add them then nothing will break; the randomat simply won't be triggered either by start-of-round event or the Randomat-4000.

# Settings/Options

For general commands and convars, and information on saving default convars for servers/listen servers, read the [TTT Randomat 2.0 README.md](https://github.com/Malivil/TTT-Randomat-20/blob/main/README.md).\
\
Otherwise, randomat-specific convars will be detailed in each randomat's entry below.\

# Newly added randomats

1. Budget Jetpacks For All! - Infinite stronger multijumps!
1. Maljumption - Causes players to randomly jump
1. R-Tex Vision - Your vision is now based on YOUR movement
1. You MUST jump twice. - Explodes players who DON'T use their double jumps!
1. Don't. Stop. Me. Noooooowwwwwww - Everyone randomly freezes - no immunity!

# Randomats

## Budget Jetpacks For All!

Everyone has infinite multijumps. The jump power multiplier is configurable between 1-10 (defaults to 2 - **warning:** values > 2 will cause players to take fall damage after their second jump. I should probably just make this a "Double extra jumps' power?" toggle, but maybe someone out there WANTS 10x power).\
\
**Dependency:** Malvil's [Improved Double Jump!](https://steamcommunity.com/sharedfiles/filedetails/?id=2501234496)\
\
_ttt_randomat_budgetjetpacks_ - Default: 1 - Whether this event is enabled\
_ttt_randomat_budgetjetpacks_min_players_ - Default: 0 - The minimum number of players required for this event to start\
_ttt_randomat_budgetjetpacks_weight_ - Default: - 1 - The weight this event should use during the randomized event selection process\
_randomat_budgetjetpacks_newJumpPower_ - Default: 2 - 'Jetpack' jump power multiplier

## Don't. Stop. Me. Noooooowwwwwww

Random freezes affecting all roles, and frozen players are not immune. Configurable whether frozen players can still look around and attack or not. The intended configuration is `affectAll = 0` and `allowMouseInput = 1` so that not all players are frozen, but those that are can defend themselves. \
\
_ttt_randomat_dontstopmenow_ - Default: 1 - Whether this event is enabled\
_ttt_randomat_dontstopmenow_min_players_ - Default: 0 - The minimum number of players required for this event to start\
_ttt_randomat_dontstopmenow_weight_ - Default: - 1 - The weight this event should use during the randomized event selection process\
_randomat_dontstopmenow_delayUpper_ - Default: 45 - The upper limit for the freeze interval\
_randomat_dontstopmenow_delayLower_ - Default: 20 - The lower limit for the freeze interval\
_randomat_dontstopmenow_freezeUpper_ - Default: 5 - The upper limit for the freeze duration\
_randomat_dontstopmenow_freezeLower_ - Default: 5 - The lower limit for the freeze duration\
_randomat_dontstopmenow_affectAll_ - Default: 0 - Does the event affect everyone at the same time\
_randomat_dontstopmenow_allowMouseInput_ - Default: 1 - Can players look and shoot while frozen\
\
It's a horrible (yet hopefully still fun) bastardisation of Malvil's [FREEZE! aka Winter has come at last. aka The Ice Man cometh. aka In this universe, there is only one absolute: everything freezes! aka Tonight, Hell freezes over. aka I'm afraid my condition has left me cold to your pleas of mercy. aka Cool party. aka You are not sending me to the cooler. aka Stay cool, bird boy. aka Alright, everyone! Chill! aka It's a cold town. aka Tonight's forecast: a freeze is coming! aka What killed the dinosaurs?! The ice age! aka Let's kick some ice! aka Can you feel it coming? The icy cold of space! aka Freeze in hell, Batman!](https://github.com/Malivil/TTT-Randomat-20/blob/main/lua/randomat2/events/freeze.lua).

## Maljumption

Players will randomly jump. Seems kinda lame, but maybe it'll trigger while someone's falling and their double jump early, or while they're on a ladder.\
\
_ttt_randomat_maljumption_ - Default: 1 - Whether this event is enabled\
_ttt_randomat_maljumption_min_players_ - Default: 0 - The minimum number of players required for this event to start\
_ttt_randomat_maljumption_weight_ - Default: - 1 - The weight this event should use during the randomized event selection process\
_randomat_maljumption_upper_ - Default: 15 - The upper limit for the random timer"\
_randomat_maljumption_lower_ - Default: 1 - The lower limit for the random timer"\
_randomat_maljumption_affectall_ - Default: 1 - Set to 1 for the event to affect everyone at the same time\
\
It's Malvil's [Malfunction](https://github.com/Malivil/TTT-Randomat-20/blob/main/lua/randomat2/events/malfunction.lua) but with jumping.

## R-Tex Vision

Other players are invisible to you unless you're moving or attacking.\
\
_ttt_randomat_rtexvision_ - Default: 1 - Whether this event is enabled\
_ttt_randomat_rtexvision_min_players_ - Default: 0 - The minimum number of players required for this event to start\
_ttt_randomat_rtexvision_weight_ - Default: - 1 - The weight this event should use during the randomized event selection process\
_randomat_rtexvision_attackRevealTime_ - Default: 1 - Vision time after attacking\
_randomat_rtexvision_moveRevealTime_ - Default: 1 - Vision time after stopping moving\
\
A reverse of [Malivil's T-Rex Vision randomat](https://github.com/Malivil/TTT-Randomat-20/blob/main/lua/randomat2/events/trexvision.lua), updated to trigger on any kind of attack (i.e. including crowbars and non-bullet weapons) rather than using `EntityFireBullets`.

## You MUST jump twice.

Kills any player who jumps and then lands without using their double jump.

- Message spam protection now separated from repeat randomat kills; i.e if repeat death announcements are disabled:
    - Players who die to the randomat can die to it again if they're revived
    - Players who fail to die to the randomat because of immunity (e.g. Jesters, players immune to blast damage) can die to it if their role is subsequently changed
    - Another "X failed to use their double jump." annoucement is correctly made on the first failure following the above
- Configurable spam failure announcement message cooldown timer
- Ignores players in water levels > 1 (submerged at least to the waist)

_ttt_randomat_mustjump_ - Default: 1 - Whether this event is enabled\
_ttt_randomat_mustjump_min_players_ - Default: 0 - The minimum number of players required for this event to start\
_ttt_randomat_mustjump_weight_ - Default: - 1 - The weight this event should use during the randomized event selection process\
_randomat_mustjump_spam_ - Default 0 - Whether to show the message again for a player who doesn't die\
_randomat_mustjump_spamTimer_ - Default 5 - Delay before repeating the message\
_randomat_mustjump_killBlastImmune_ - Default 1 - Whether to kill players who are immune to blast damage\
\
It's Malvil's [You can only jump once.](https://github.com/Malivil/TTT-Randomat-20/blob/main/lua/randomat2/events/jump.lua) but made horrendously more complicated as a learning exercise.

## Steam Workshop Link

*Coming when I upload this to the Steam Workshop.*