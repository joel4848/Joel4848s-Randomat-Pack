CreateConVar("randomat_farmoredangerous_distance_minimum", 150,   FCVAR_REPLICATED, "The distance below which minimum damage is dealt", 20, 10000)
CreateConVar("randomat_farmoredangerous_distance_maximum", 1000,  FCVAR_REPLICATED, "The distance above which maximum damage is dealt", 20, 10000)
CreateConVar("randomat_farmoredangerous_damage_minimum",   0,     FCVAR_REPLICATED, "The damage percentage outside maximum distance",    0,  10000)
CreateConVar("randomat_farmoredangerous_damage_maximum",   150,   FCVAR_REPLICATED, "The damage percentage within minimum distance",   1,  10000)