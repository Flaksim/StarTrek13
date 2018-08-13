#define LOW 1
#define MED 2
#define HIGH 3

/mob
	var/datum/crew/crew

/datum/crew
	var/name = "crew"
	var/mob/living/carbon/human/captain //All other roles are secondary, but the captain is CRITICAL, as he can fly.
	var/list/crewmen = list() //All the other crewmen go here, if this is full with readied up players then we skip to the next ship, if that's full, switch faction and fill them up
	var/max_crewmen = 10 //10 crew total, more than enough for the sovereign.
	var/priority = LOW //How important is this ship? Romulan ships will be higher priority because nobody plays them.
	var/obj/structure/overmap/theship
	var/list/candidates = list() //People who want to join this crew
	var/faction = "starfleet"
	var/datum/faction/required //What faction is this crew for? if they get autobalanced, then force them to become a member of that faction.
	var/filled = FALSE //Stops it repeatedly filling crews.
	var/count = 0

/datum/crew/New()
	for(var/datum/faction/F in SSfaction.factions)
		if(F.name == faction)
			required = F
	SSfaction.crews += src
	. = ..()

/datum/crew/proc/Add(mob/M)
	candidates += M

/mob/proc/addme()
	var/datum/crew/S = pick(SSfaction.crews)
	S.Add(src)
	S.FillRoles()
	S.SanityCheck()

/datum/crew/proc/FillRoles()
	if(count >= max_crewmen)
		filled = TRUE
		var/list/L = SSfaction.crews
		for(var/datum/crew/ST in L)
			if(ST.crewmen.len >= ST.max_crewmen)
				L -= ST
			if(ST == src)
				L -= ST
		var/datum/crew/nextcrew = pick(L)
		for(var/mob/I in candidates)
			to_chat(I, "You did not get a position on a [name], trying to slot you in aboard a [nextcrew]")
			candidates -= I
		return 0
	for(var/I = 0 to max_crewmen)
		if(candidates.len)
			var/mob/living/steve = pick(candidates)
			candidates -= steve
			crewmen += steve
			to_chat(steve, "You have been posted on a [name]")
			SendToSpawn(steve)
			count ++
	SanityCheck()


/datum/crew/proc/SanityCheck() //Check that someone with piloting skills has spawned.
	for(var/mob/living/M in crewmen)
		if(M.skills.skillcheck(M, "piloting", 5))
			return //Good, one of them has a piloting skill and can fly.
	if(crewmen.len)
		var/mob/unluckybastard = pick(crewmen) //Nobody spawned with a piloting skill, so give someone the skill.
		to_chat(unluckybastard, "None of your crewmates had the skills to fly a [name], you have been made the designated pilot for this ship, this overrides your normal duties. If you are unable to stay / fly the ship due to inexperience, please contact an admin immediately.")
		unluckybastard.skills.add_skill("piloting", 7)
		for(var/mob/S in crewmen)
			if(unluckybastard)
				to_chat(S, "<FONT color='red'>[unluckybastard] is your substitute pilot for this shift.</font>")

/datum/crew/proc/SendToSpawn(mob/user)
	for(var/obj/effect/landmark/crewstart/S in world)
		if(S.name == name)
			user.forceMove(S.loc)
			to_chat(user, "<FONT color='red'><B>You have been assigned to a [name], you should not crew another ship unless explicitly ordered to do so by a higher ranking officer.</B></font>")
			if(!istype(user.player_faction, required))
				user.client.prefs.player_faction = null
				to_chat(user, "You have been autobalanced to [faction]. Please contact the admins if you're unable to play this faction.")
				required.addMember(user)
			return

/obj/effect/landmark/crewstart
	name = "sovereign class heavy cruiser"

/obj/effect/landmark/crewstart/defiant
	name = "defiant class warship"

/obj/effect/landmark/crewstart/romulan
	name = "dderidex class warbird"

/datum/crew/New()
	. = ..()
	SSfaction.crews += src

/datum/crew/sovereign
	name = "sovereign class heavy cruiser"
	priority = MED

/datum/crew/cruiser
	name = "defiant class warship"
	priority = LOW
	max_crewmen = 6

/datum/crew/romulan
	name = "dderidex class warbird"
	priority = HIGH
	faction = "romulan empire"

#undef LOW
#undef MED
#undef HIGH