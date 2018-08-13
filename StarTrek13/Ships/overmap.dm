
//Movement system and upgraded ship combat!

//	face_atom(A)//////

//Remember: If your ship appears to have no damage, or won't charge, you probably didn't put physical phasers on the ship's map!
#define TORPEDO_MODE 1//1309
#define PHASER_MODE 2

/obj/structure/overmap
	name = "generic structure"
//	var/linked_ship = /area/ship //change me
	var/datum/beam/current_beam = null //stations will be able to fire back, too!
	var/health = 20000 //pending balance, 20k for now
	var/max_health = 20000
	var/obj/machinery/space_battle/shield_generator/generator
	var/obj/structure/fluff/helm/desk/tactical/weapons
	var/shield_health = 1050 //How much health do the shields have left, for UI type stuff and icon_states
	var/mob/living/pilot
	var/view_range = 7 //change the view range for looking at a long range.
	anchored = FALSE
	can_be_unanchored = FALSE //Don't anchor a ship with a wrench, these are going to be people sized
	density = TRUE
	var/list/interactables_near_ship = list()
	var/area/linked_ship //CHANGE ME WITH THE DIFFERENT TYPES!
	var/max_shield_health = 20000 //default max shield health, changes on process
	var/shields_active = FALSE
	pixel_y = -32
	var/next_vehicle_move = 0 //used for move delays
	var/vehicle_move_delay = 6 //tick delay between movements, lower = faster, higher = slower
	var/mode = 0 //add in two modes ty
	var/damage = 800 //standard damage for phasers, this will tank shields really quickly though so be warned!
	var/obj/structure/overmap/target_ship = null
	var/weapons_charge_time = 60 //6 seconds inbetween shots.
	var/in_use1 = FALSE //firing weapons?
	var/obj/machinery/computer/camera_advanced/transporter_control/transporters = list()//linked transporter CONTROLLER
	var/spawn_name = "ship_spawn"
	var/spawn_random = TRUE
	var/turf/initial_loc = null //where our pilot was standing upon entry
	var/can_move = TRUE // are we a station
	var/notified = TRUE //notify pilot of visitable structures
	var/recharge = FALSE //
	var/recharge_max = 1.4 //not quite spam, but not prohibitive either
	var/turret_recharge = FALSE
	var/max_turret_recharge = 0.8
	var/sensor_range = 10 //radius in which ships can be beamed to, amongst other things
	var/area/transport_zone = null
	var/marker = "cadaver"
	var/atom/movable/nav_target = null
	var/navigating = FALSE
	var/charge = 4000 //Phaser chareg													////TESTING REMOVE ME AND PUT BME BACK TO 0 OR THIS WILL KILL ALL BALANCE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	var/phaser_charge_total = 0 //How much power all the ship phasers draw together
	var/phaser_charge_rate = 0
	var/phaser_fire_cost = 0 //How much charge to fire all the guns
	var/max_charge = 0 //Max phaser power charge
	var/counter = 0 //Testing
	var/obj/ship_turrets/fore_turrets = null
	var/obj/ship_turrets/aft_turrets/aft_turrets = null
	var/obj/item/gun/energy/laser/ship_weapon/turret_gun/fore_turrets_gun = null	//If your ship has turrets, be sure to change has_turrets!
	var/obj/item/gun/energy/laser/ship_weapon/turret_gun/aft_turrets_gun = null
	var/has_turrets = 0 //By default, NO turrets installed. I recommend you keep federation turrets invisible as shields will bug out with overlays etc. You have been warned!
	var/image/list/gun_turrets = list() //because overlays are weird.
	var/atom/movable/target_fore = null// for gun turrets
	var/atom/movable/target_aft = null
	var/list/soundlist = list('StarTrek13/sound/borg/machines/phaser.ogg','StarTrek13/sound/borg/machines/phaser2.ogg','StarTrek13/sound/borg/machines/phaser3.ogg')//The sounds made when shooting
	var/datum/shipsystem_controller/SC
	var/turret_firing_cost = 100 //How much does it cost to fire your turrets?
	var/obj/structure/overmap/ship/fighter/fighters = list()
	var/take_damage_traditionally = TRUE //Are we a real ship? that will have a shield generator and such? exceptions include fighters.
	var/obj/structure/overmap/agressor = null //Who is attacking us? this is done to reset their targeting systems when they destroy us!
	var/warp_capable = FALSE //Does this ship have a warp drive?
	////IMPORTANT VAR!!!////
	var/datum/action/innate/exit/exit_action = new
	var/datum/action/innate/warp/warp_action = new
	var/datum/action/innate/stopfiring/stopfiring_action = new
	var/datum/action/innate/redalert/redalert_action = new
	var/datum/action/innate/autopilot/autopilot_action = new
	var/datum/action/innate/weaponswitch/weaponswitch = new
	var/obj/structure/ship_component/components = list()
	var/list/destinations = list()
	var/obj/effect/landmark/warp_beacon/target_beacon
	var/pilot_skill_req = 5
	var/wrecked = FALSE
	var/obj/effect/landmark/runaboutdock/docks = list()
	var/true_name = null //For respawning
	var/faction = null //Are we a faction's ship? if so, when we blow up, DEDUCT EXPENSES
	var/cost = 8000 //How much does this ship cost to replace?
	var/cloaked = FALSE
	var/stored_name //used in cloaking code to restore ship names

/obj/structure/overmap/shipwreck //Ship REKT
	name = "Wrecked ship"
	desc = "This used to be a ship...I think?"
	can_move = FALSE
	icon = 'StarTrek13/icons/trek/overmap_ships.dmi'
	spawn_name = null
	icon_state = "wreck"
	wrecked = TRUE

/obj/item/ammo_casing/energy/ship_turret
	projectile_type = /obj/item/projectile/beam/laser/ship_turret_laser
	e_cost = 0 // :^)
	select_name = "fuckyou"

/obj/item/ammo_casing/energy/photon
	select_name = "photon torpedo"
	e_cost = 0
	projectile_type = /obj/item/projectile/beam/laser/photon_torpedo

/obj/item/projectile/beam/laser/photon_torpedo
	hitscan = FALSE
	name = "photon torpedo"
	icon_state = "photon"
	damage = 3500//Ouch!.

/obj/item/projectile/beam/laser/disruptor
	hitscan = FALSE
	name = "photon torpedo"
	icon_state = "photon"
	damage = 1000//Ouch!.

/obj/item/projectile/beam/laser/ship_turret_laser
	name = "turbolaser"
	icon_state = "shiplaser"
	damage = 20//It has to actually dent ships tbh.

///obj/item/projectile/beam/laser/photon_torpedo
//	name = "turbolaser"
//	icon_state = "shiplaser"
//	damage = 1500//Monster damage because you only get a few

/obj/ship_turrets
	name = "Fore turrets"
	icon_state = null
	icon = null
	var/fire_cost = 100
	var/fire_amount = 3 //fire thrice per shot

/obj/ship_turrets/aft_turrets
	name = "Aft turrets"
	fire_cost = 100
	fire_amount = 2 //fire twice per shot

/*
		fore_turrets = new /obj/ship_turrets
		aft_turrets = new /obj/ship_turrets/aft_turrets
		fore_turrets.icon = src.icon
		aft_turrets.icon = src.icon
		fore_turrets.icon_state = initial(icon_state) + "-fore_turrets"	//Remember! fore = front, if you want your turrets to visibly turn and shoot ships you need to make them their own layer.
		aft_turrets.icon_state = initial(icon_state) + "-aft_turrets"
		fore_turrets.layer = 4.5
		overlays += fore_turrets
		aft_turrets.layer = 4.5
		overlays += aft_turrets
*/

/obj/structure/overmap/proc/toggle_shields(mob/user)
	generator.toggle(user)

/obj/structure/overmap/proc/announce(var/text, var/title, sound = 'sound/ai/attention.ogg')

	if(!text)
		return //No empty announcements
	if(!title)
		title = "Automated Ship Announcement"
	var/announce = "<br><h2 class='alert'>[html_encode(title)]</h2>"
	announce += "<br><span class='alert'>[html_encode(text)]</span><br>"
	announce += "<br>"

	var/list/mobs_heard = list()
	for(var/mob/living/L in linked_ship)
		to_chat(L, "[announce]")
		mobs_heard += L
	for(var/mob/M in GLOB.dead_mob_list)
		to_chat(M, "[announce]")
		mobs_heard += M
	var/s = sound(sound)
	for(var/mob/P in mobs_heard)
		mobs_heard -= P
		if(P.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
			SEND_SOUND(P, s)

/obj/structure/overmap/away/station
	name = "space station 13"
	icon = 'StarTrek13/icons/trek/large_overmap.dmi'
	icon_state = "station"
	spawn_random = TRUE
	can_move = FALSE
	spawn_name = "station_spawn"
	sensor_range = 10
	max_speed = 0
	speed = 0
	warp_capable = FALSE
	acceleration = 0

/obj/structure/overmap/ship //dummy for testing woo
	name = "USS thingy"
	icon_state = "generic"
	icon = 'StarTrek13/icons/trek/overmap_ships.dmi'
	spawn_name = "ship_spawn"
	damage = 800

/obj/structure/overmap/ship/borg_cube // we are the borg
	name = "Unimatrix 1-3"
	icon_state = "borg_cube"
	icon = 'StarTrek13/icons/trek/large_ships/borg_cube.dmi'
	spawn_name = "borg_spawn"
	damage = 800
	max_health = 50000
	turnspeed = 0.3
	pixel_z = -128
	pixel_w = -120
	max_speed = 1


/obj/structure/overmap/away/station/starbase
	name = "starbase59"
	spawn_name = "starbase_spawn"
	marker = "starbase"

/obj/structure/overmap/ship/federation_capitalclass
	name = "USS Cadaver"
	icon = 'StarTrek13/icons/trek/large_ships/cadaver.dmi'
	icon_state = "cadaver"
//	var/datum/shipsystem_controller/SC
	warp_capable = TRUE
	max_health = 30000
	pixel_z = -128
	pixel_w = -120
	faction = "starfleet"
	cost = 20000

/obj/structure/overmap/ship/federation_capitalclass/sovreign
	name = "sovereign"
	icon = 'StarTrek13/icons/trek/large_ships/sovreign.dmi'
	icon_state = "sovreign"
//	pixel_x = -100
//	pixel_y = -100
//	var/datum/shipsystem_controller/SC
	warp_capable = TRUE
	max_health = 40000
	pixel_z = -128
	pixel_w = -120
	turnspeed = 0.7 //It's still quite small for its class
	cost = 20000

/obj/structure/overmap/ship/cruiser
	name = "USS Excelsior"
	icon = 'StarTrek13/icons/trek/large_ships/excelsior.dmi'
	icon_state = "excelsior"
//	var/datum/shipsystem_controller/SC
	warp_capable = TRUE
	max_health = 30000
	pixel_z = -128
	pixel_w = -120
	faction = "starfleet"
	cost = 20000

/obj/structure/overmap/ship/fighter_medium
	name = "USS Hagan"
	icon = 'StarTrek13/icons/trek/overmap_ships.dmi'
	icon_state = "hagan"
	warp_capable = TRUE
	max_health = 10000
	spawn_name = "nt_capital" //Change me
	vehicle_move_delay = 2
	turnspeed = 4

/obj/structure/overmap/ship/cruiser/nanotrasen
	name = "NSV Hyperion"
	icon = 'StarTrek13/icons/trek/large_ships/hyperion.dmi'
	icon_state = "hyperion"
	pixel_x = -100
	pixel_y = -100
//	var/datum/shipsystem_controller/SC
	warp_capable = TRUE
	spawn_name = "nt_capital"
	max_health = 30000
	pixel_z = -128
	pixel_w = -120


/obj/structure/overmap/Initialize(timeofday)
	true_name = name //We want true name to always be the same, so we can respawn things correctly
	var/area/A = get_area(src)
	name = A.name
	linked_ship = A
	health = max_health
	SC = new(src)
	SC.generate_shipsystems()
	SC.theship = src
	global_ship_list += src
	START_PROCESSING(SSobj,src)
	linkto()
	update_weapons()
	addtimer(CALLBACK(src, .proc/update_stats), 500)
	for(var/obj/effect/landmark/warp_beacon/W in warp_beacons)
		destinations += W
	..()

/obj/structure/overmap/ship/Initialize(timeofday)
	. = ..()
	if(!istype(src,/obj/structure/overmap/ship/fighter))
		SetName()

/obj/structure/overmap/ship/nanotrasen_capitalclass
	name = "NSV annulment"
	desc = "Contract anulled....forever"
	icon = 'StarTrek13/icons/trek/large_ships/annulment.dmi'
	icon_state = "annulment"
	spawn_name = "nt_capital"
	has_turrets = 1
	max_health = 30000
	soundlist = list('StarTrek13/sound/trek/ship_gun.ogg','StarTrek13/sound/trek/ship_gun.ogg')//The sounds made when shooting

/obj/structure/overmap/away/station/nanotrasen/shop
	name = "NSV Mercator trading outpost"
	icon = 'StarTrek13/icons/trek/large_overmap.dmi'
	icon_state = "shop"
	spawn_name = "shop_spawn"

/obj/structure/overmap/away/station/nanotrasen/research_bunker
	name = "NSV Woolf research outpost"
	icon = 'StarTrek13/icons/trek/large_overmap.dmi'
	icon_state = "research"
	spawn_name = "research_spawn"

/obj/structure/overmap/ship/target //dummy for testing woo
	name = "miranda"
	icon_state = "destroyer"
	icon = 'StarTrek13/icons/trek/overmap_ships.dmi'
	spawn_name = "ship_spawn"
	pixel_x = -32
	pixel_y = -32
	health = 8000
	max_health = 15000
	vehicle_move_delay = 2
	warp_capable = TRUE
	turnspeed = 3
	pixel_collision_size_x = 48
	pixel_collision_size_y = 48
	max_speed = 3
	faction = "starfleet"
	cost = 7000

/obj/structure/overmap/ship/defiant
	name = "defiant"
	icon_state = "defiant"
	icon = 'StarTrek13/icons/trek/large_ships/defiant.dmi'
	spawn_name = "ship_spawn"
	health = 15000
	max_health = 15000
	warp_capable = TRUE
	turnspeed = 2.7
	pixel_collision_size_x = 48
	pixel_collision_size_y = 48
	max_speed = 5
	faction = "starfleet"
	cost = 7000

/obj/structure/overmap/ship/nanotrasen
	name = "NSV Muffin"
	icon_state = "whiteship"
	icon = 'StarTrek13/icons/trek/overmap_ships.dmi'
	spawn_name = "NT_SHIP"
	pixel_x = 0
	pixel_y = -32
	health = 8000
	max_health = 8000
	vehicle_move_delay = 2
	turnspeed = 3
	pixel_collision_size_x = 48
	pixel_collision_size_y = 48
	max_speed = 3

/obj/structure/overmap/ship/nanotrasen/freighter
	name = "NSV Crates"
	icon_state = "freighter"
	spawn_name = "FREIGHTER_SPAWN"
	health = 5000
	max_health = 5000
	vehicle_move_delay = 2
	turnspeed = 3
	pixel_collision_size_x = 48
	pixel_collision_size_y = 48
	max_speed = 3

//So basically we're going to have ships that fly around in a box and shoot each other, i'll probably have the pilot mob possess the objects to fly them or something like that, otherwise I'll use cameras.
/*
/obj/structure/overmap/ship/relaymove(mob/user,direction)
	update_observers()
	if(can_move)
		if(user.incapacitated())
			return //add things here!
		if(!Process_Spacemove(direction) || world.time < next_vehicle_move || !isturf(loc))
			return
		if(navigating)
			navigating = 0
		step(src, direction)
		next_vehicle_move = world.time + vehicle_move_delay
		speed += 3 //Makes you harder to hit
		if(has_turrets)
			update_turrets()
	//use_power
*/

//obj/structure/overmap/ship/Move(atom/newloc, direct)
//	. = ..()
//	if(.)
	//	events.fireEvent("onMove",get_turf(src))

/obj/structure/overmap/ship/Process_Spacemove(movement_dir = 0)
	if(SC.engines.integrity > 4000)
		return 1
	else
		return 0

//obj/structure/overmap/ship/GrantActions(mob/living/user, human_occupant = 0)
//	internals_action.Grant(user, src)
//	var/datum/action/innate/mecha/strafe/strafing_action = new

/obj/structure/overmap/proc/linkto()	//weapons etc. don't link!
	for(var/TT in linked_ship)
		if(istype(TT, /obj/structure/fluff/helm/desk/tactical))
			var/obj/structure/fluff/helm/desk/tactical/T = TT
			weapons = T
			T.theship = src
	for(var/obj/machinery/space_battle/shield_generator/G in linked_ship)
		generator = G
		G.ship = src
		var/obj/structure/overmap/ship/S = src
		S.SC.shields.linked_generators += G
		G.shield_system = S.SC.shields
	for(var/obj/machinery/computer/camera_advanced/transporter_control/T in linked_ship)
		transporters += T
	for(var/obj/structure/overmap/ship/fighter/F in linked_ship)
		F.carrier_ship = src
		if(!F in fighters)
			fighters += F
	for(var/obj/structure/fluff/helm/desk/functional/F in linked_ship)
		F.our_ship = src
		F.get_ship()
	for(var/obj/structure/subsystem_monitor/M in linked_ship)
		M.our_ship = src
		M.get_ship()
	for(var/obj/structure/viewscreen/V in linked_ship)
		V.our_ship = src
	for(var/obj/structure/weapons_console/WC in linked_ship)
		WC.our_ship = src
	for(var/obj/structure/overmap/ship/runabout/R in linked_ship)
		R.carrier = src
	for(var/obj/effect/landmark/runaboutdock/SS in linked_ship)
		docks += SS
	for(var/obj/structure/subsystem_panel/PP in linked_ship)
		PP.check_ship()
		PP.check_overlays()
	for(var/CD in linked_ship)
		if(istype(CD, /obj/structure/cloaking_device))
			var/obj/structure/cloaking_device/CC = CD
			CC.theship = src

/obj/structure/overmap/proc/update_weapons()	//So when you destroy a phaser, it impacts the overall damage
	SC.weapons.update_weapons()
	for(var/obj/structure/overmap/ship/fighter/F in linked_ship) //Update any fighters inside of us
		F.carrier_ship = src
		if(!F in fighters)
			fighters += F

/obj/effect/temp_visual/trek
	icon = 'StarTrek13/icons/trek/star_trek.dmi'
	icon_state = "shipexplode"
	duration = 30

/obj/effect/temp_visual/trek/Initialize()
	. = ..()
	pixel_x = rand(3,15)
	pixel_y = rand(3,15)

/obj/effect/temp_visual/trek/shieldhit
	icon = 'StarTrek13/icons/trek/star_trek.dmi'
	icon_state = "shieldhit"
	duration = 10

/obj/structure/overmap/take_damage(amount, var/override)
	playsound(src,'StarTrek13/sound/trek/ship_effects/torpedoimpact.ogg',100,1)
	if(wrecked)
		return 0
	var/obj/structure/overmap/source = agressor
	if(prob(40))
		var/meme = rand(1,6)
		switch(meme)
			if(1)
				visible_message("<span class='warning'>Bits of [name] fly off into space!</span>")
			if(2)
				visible_message("<span class='warning'>[name]'s hull ruptures!</span>")
			if(3)
				visible_message("<span class='warning'>[name]'s hull buckles!</span>")
			if(4)
				visible_message("<span class='warning'>Warp plasma vents from [name]'s engines!</span>")
			if(5)
				visible_message("<span class='warning'>A beam tears across [name]'s hull!</span>")
			if(6)
				visible_message("<span class='warning'>[name]'s hull is scorched!</span>")
	if(override)
		if(has_shields())
			new /obj/effect/temp_visual/trek/shieldhit(loc)
			var/heat_multi = 1
			playsound(src,'StarTrek13/sound/borg/machines/shieldhit.ogg',40,1)
			var/obj/structure/overmap/ship/S = src
			heat_multi = S.SC.shields.heat >= 500 ? 2 : 1 // double damage if heat is over 500.
			S.SC.shields.heat += round(amount/S.SC.shields.heat_resistance)
			//	generator.take_damage(amount*heat_multi)
			SC.shields.health -= amount*heat_multi
			if(source)
				if(source.target_subsystem)
					source.target_subsystem.integrity -= (amount)/5 //Shields absorbs most of the damage
				apply_damage(amount)
				return//no shields are up! take the hit
		else
			new /obj/effect/temp_visual/trek(loc)
			health -= amount
			SC.hull_integrity.integrity -= amount
			if(take_damage_traditionally)
				apply_damage(amount)
			return
	if(take_damage_traditionally) //Set this var to 0 to do your own weird shitcode
		if(has_shields())
			new /obj/effect/temp_visual/trek/shieldhit(loc)
			var/heat_multi = 1
			playsound(src,'StarTrek13/sound/borg/machines/shieldhit.ogg',40,1)
			var/obj/structure/overmap/ship/S = src
			heat_multi = S.SC.shields.heat >= 50 ? 2 : 1 // double damage if heat is over 50.
			S.SC.shields.heat += round(amount/S.SC.shields.heat_resistance)
		//	generator.take_damage(amount*heat_multi)
			SC.shields.health -= amount*heat_multi
			var/datum/effect_system/spark_spread/s = new
			s.set_up(2, 1, src)
			s.start() //make a better overlay effect or something, this is for testing
			if(source)
				if(source.target_subsystem)
					source.target_subsystem.integrity -= (amount)/5 //Shields absorbs most of the damage
				apply_damage(amount)
				return//no shields are up! take the hit
		if(SC.hull_integrity.failed)
			if(source)
				if(source.target_subsystem)
					if(source.target_subsystem.failed)
						to_chat(source.pilot, "[src]'s [source.target_subsystem.failed] subsystem has failed.")
						health -= amount
						source.target_subsystem = null
						apply_damage(amount)
						return
					source.target_subsystem.integrity -= (amount)/1.5 //No shields, fry that system
					source.target_subsystem.heat += amount/10 //Heat for good measure :)
					var/quickmaths = amount/2 //Halves the physical hull damage, the rest is given to the subsystems, so you can cripple a ship (just over half)
					health -= quickmaths
					apply_damage(amount)
					return
			else
				new /obj/effect/temp_visual/trek(loc)
				health -= amount
				apply_damage(amount)
				return
		else
			if(source)
				if(source.target_subsystem)
					source.target_subsystem.integrity -= (amount)/2 //Hull plates protect
					source.target_subsystem.heat += source.SC.weapons.damage/15 //Keeps the heat off
			var/quickmaths = amount/5 //Fives the physical hull damage, because the hull plates take a bunch of that damage
			health -= quickmaths
			SC.hull_integrity.integrity -= amount
			apply_damage(amount)
			return
	else
		new /obj/effect/temp_visual/trek(loc)
		shake_camera(pilot, 1, 10)
		var/sound/thesound = pick(ship_damage_sounds)
		SEND_SOUND(pilot, thesound)
		health -= amount
		return

/obj/structure/overmap/proc/update_transporters()
	var/list/L = range(5, src)
	for(var/obj/machinery/computer/camera_advanced/transporter_control/TC in transporters)
		TC.destinations = L
		//var/list/thelist = list(OM.transporter,OM.weapons,OM.generator,OM.initial_loc)
		//for(var/obj/machinery/trek/transporter/T in OM.transporter.linked)
		//	transporter.available_turfs += get_turf(T)

/obj/structure/overmap/CtrlClick(mob/user)
	if(pilot == user)
		set_nav_target(user)

/obj/structure/overmap/ShiftClick(mob/user)
	if(user != pilot) //No hailing yourself, please
		var/obj/structure/overmap/ship/sender = user.loc
		var/message = stripped_input(user,"Communications.","Send Hail")
		if(!message)
			return
		hail(message, null , sender, src)
		return

/obj/structure/overmap/proc/update_turrets()
	return


/obj/structure/overmap/proc/attempt_turret_fire()
	if(charge > 0 && has_turrets && target_ship && turret_recharge <= 0) //Not ready to fire the big guns, but smaller phaser batteries can still fire
		charge -= turret_firing_cost
		var/obj/item/projectile/beam/laser/ship_turret_laser/A = new /obj/item/projectile/beam/laser/ship_turret_laser(loc)
		A.starting = loc
		A.preparePixelProjectile(target_ship,pilot)
		A.pixel_x = rand(-20, 50)
		A.fire()
		playsound(src,'StarTrek13/sound/trek/ship_gun.ogg',40,1)
		turret_recharge = max_turret_recharge
		sleep(1)
		A.pixel_x = target_ship.pixel_x
		A.pixel_y = target_ship.pixel_y
		return 1

/*
		var/obj/effect/adv_shield/theshield = pick(generator.shields) //sample a random shield for health and stats.
		shield_health = theshield.health
		max_shield_health = theshield.maxhealth
*/

/obj/structure/overmap/proc/update_stats()
	SC.weapons.update_weapons()
	linkto()
	addtimer(CALLBACK(src, .proc/update_stats), 500)

/obj/structure/overmap/process()
	if(pilot)
		update_observers()
	if(wrecked)
		if(prob(5)) //This damn wreck is falling apart
			take_damage(1001)
	if(health < max_health) //What the fuck drunk me vvvvv
		if(prob(30))
			health += 50 //VeryYlow slol rege mn spo u can hide
	if(pilot)
		for(var/obj/screen/alert/charge/C in pilot.alerts)
			C.theship = src
	if(SC.shields.failed)
		shields_active = FALSE
	if(health <= 0)
		destroy(1)
	if(!health)
		destroy(1)
	if(turret_recharge >0)
		turret_recharge --
	location()
	if(agressor)
		if(agressor.target_ship != src)
			agressor = null
	check_overlays()
	counter ++
	damage = SC.weapons.damage
	if(nav_target)
		navigate()
	if(can_move)
		if(SC.engines.failed) //i hate you nichlas
			return
	get_interactibles()
	//transporter.destinations = list() //so when we leave the area, it stops being transportable.
	if(pilot)
		if(pilot.loc != src)
			for(var/obj/screen/alert/charge/C in pilot.alerts)
				C.theship = src
			pilot.clear_alert("Weapon charge", /obj/screen/alert/charge)
			pilot.clear_alert("Hull integrity", /obj/screen/alert/charge/hull)
			exit() //pilot has been tele'd out, remove them!
	if(charge > max_charge)
		charge = max_charge
	else
		charge = max_charge
//	parallax_update() //Need this to be on SUPERSPEED or it'll look awful

/obj/structure/overmap/AltClick(mob/user)
	if(user == pilot)
		switch(fire_mode)
			if(1)
				fire_mode = 2
				to_chat(pilot, "You'll now fire photons")
			if(2)
				fire_mode = 1
				to_chat(pilot, "You'll now fire phasers")

/obj/structure/overmap/proc/navigate()
//	if(isprocessing)
//		STOP_PROCESSING(SSobj, src)
	//	START_PROCESSING(SSfastprocess,src)
	if(!initial(can_move))
		return // :(
	update_turrets()
	if(world.time < next_vehicle_move)
		return 0
	next_vehicle_move = world.time + vehicle_move_delay
	TurnTo(nav_target)
	//	STOP_PROCESSING(SSfastprocess,src)
	//	START_PROCESSING(SSobj, src)

/obj/structure/overmap/proc/InputWarpTarget(mob/user) //inputs here were super broken for some fucking reason, so like yogs, i'm gonna say fuck democracy :)
	var/area/A = get_area(src)
	var/list/potential = list()
	to_chat(user, "Engaging kangaroo drive. Who the fuck knows where you'll end up, do you think I can be bothered to crunch the numbers for you? get out a piece of paper and account for hyperspatial drift yourself loser.")
	for(var/obj/effect/landmark/L in world)
		if(!L in A)
			potential += L
	var/obj/effect/landmark/warp_beacon/SS = pick(potential)
	if(can_move)
		if(!SC.engines.failed)
			do_warp(SS, SS.distance) //distance being the warp transit time.


/obj/structure/overmap/proc/do_warp(destination, jump_time) //Don't want to lock this behind warp capable because jumpgates call this
	if(!can_move)
		return
	if(SC.engines.failed) //i hate you nichlas
		return
	if(!SSfaction.jumpgates_forbidden)
		if(SC.engines.try_warp())
			var/area/hyperspace_area
			for(var/obj/effect/landmark/L in GLOB.landmarks_list)
				if(L.name == "hyperspace")
					hyperspace_area = get_area(L)
			var/turf/open/temp = list()
			for(var/turf/open/T in get_area_turfs(hyperspace_area))
				temp += T
			var/turf/theturf = pick(temp)
			forceMove(theturf)
			can_move = 0 //Don't want them moving around warp space.
			shake_camera(pilot, 1, 10)
			SEND_SOUND(pilot, 'StarTrek13/sound/trek/ship_effects/warp.ogg')
			to_chat(pilot, "The ship has entered warp space")
			angle = 180
			EditAngle()
		//	setDir(4)
			for(var/mob/L in linked_ship)
				shake_camera(L, 1, 10)
				SEND_SOUND(L, 'StarTrek13/sound/trek/ship_effects/warp.ogg')
				to_chat(L, "The deck plates shudder as the ship builds up immense speed.")
				linked_ship.parallax_movedir = NORTH
			addtimer(CALLBACK(src, .proc/finish_warp, destination),jump_time)
			for(var/obj/structure/overmap/ship/AI/A in world)
				if(A.stored_target == src)
					A.stored_target = null
		else
			to_chat(pilot, "Warp engines are recharging, or have been damaged.")
			return
	else
		to_chat(pilot,"Subspace distortions prevent warping at this time.")


/obj/structure/overmap/proc/do_warp_thing(var/fuckyou, var/byond)
	for(var/obj/effect/landmark/warp_beacon/fuckoff in warp_beacons)
		if(fuckoff.name == fuckyou)
			do_warp(fuckoff, fuckoff.distance)
			break;

/obj/structure/overmap/proc/finish_warp(atom/movable/destination)
	can_move = 1
	shake_camera(pilot, 4, 2)
	to_chat(pilot, "The ship has left warp space.")
	for(var/mob/L in linked_ship.contents)
		shake_camera(L, 4, 2)
		to_chat(pilot, "The ship slows.")
		linked_ship.parallax_movedir = FALSE
	forceMove(get_turf(destination))

/obj/structure/overmap/proc/set_nav_target(mob/user)
	if(nav_target)
		nav_target = null
		to_chat(user, "Tracking cancelled.")
		navigating = FALSE
		return
	if(!can_move)
		return
	if(SC.engines.failed) //i hate you nichlas
		return
	if(can_move)
		var/A
		var/list/theships = list()
		var/area/a = get_area(src)
		for(var/obj/structure/overmap/O in overmap_objects)
			var/area/thearea = get_area(O)
			if(O.z == z && a == thearea)
				theships += O
		if(!theships.len)
			return
		A = input("What ship shall we track?", "Ship navigation", A) as null|anything in theships//overmap_objects
		if(!A)
			return
		var/obj/structure/overmap/O = A
		nav_target = O
		//nav_target = overmap_objects[A]
		set_dir_to_target()
		to_chat(pilot, "now tracking: [nav_target], use this button again to cancel tracking")
	else
		to_chat(pilot, "ERROR: [src] does not have engines")

/obj/structure/overmap/proc/set_dir_to_target()
	if(!navigating)
		navigating = 1

/obj/structure/overmap/proc/get_interactibles()
	for(var/obj/structure/overmap/OM in interactables_near_ship)
		if(OM.shields_active == 0) //its shields are down
			update_transporters()
			return 1
		else
			return 0

/obj/structure/overmap/proc/location() //OK we're using areas for this so that we can have the ship be within an N tile range of an object
//	var/area/thearea = get_area(src)
	interactables_near_ship = list()
	for(var/obj/structure/overmap/A in orange(sensor_range,src))
		if(!istype(A))
			return
		interactables_near_ship += A
	if(interactables_near_ship.len > 0)
		return 1
	else//nope
		return 0

/obj/structure/overmap/proc/destroy(var/severity = 1)
	STOP_PROCESSING(SSobj,src)
	if(wrecked)
		for(var/datum/F in SC.systems)
			qdel(F)
		qdel(SC)
		return ..()
	. = ..()
	for(var/obj/structure/overmap/ship/AI/A in world)
		if(A.stored_target == src)
			A.stored_target = null
	for(var/datum/faction/F in SSfaction.factions)
		if(F.current_objective)
			var/datum/factionobjective/destroy1/O = F.current_objective
			O.check_completion(src)
	if(agressor)
		agressor.target_subsystem = null
		agressor.target_ship = null
		to_chat(agressor.pilot, "Target destroyed")
	var/thesound = pick(ship_damage_ambience) //blowing up noises
	for(var/obj/structure/overmap/L in orange(30, src))
		var/obj/structure/overmap/O = L
		SEND_SOUND(O.pilot, thesound)
	if(pilot)
		exit()
	if(agressor)
		agressor.stop_firing()
		agressor.target_subsystem = null
	SpinAnimation(2000, 1)
	new /obj/effect/temp_visual/trek(loc)
	for(var/datum/shipsystem/S in SC.systems)
		new /obj/effect/temp_visual/trek(loc)
		qdel(S)
	qdel(SC)
	for(var/mob/M in linked_ship)
		M << 'StarTrek13/sound/trek/corebreach.ogg'
		to_chat(M, "<span class='userdanger'>Warp core breach imminent!</span>")
	if(!istype(src, /obj/structure/overmap/ship/fighter))
		switch(severity)
			if(1)
				var/obj/structure/overmap/shipwreck/wreck = new(src.loc)
				wreck.name = "Shipwreck ([name])"
				if(linked_ship)
					wreck.linked_ship = linked_ship
					wreck.linkto()
					update_transporters()
				wreck.max_health = 10000000
				for(var/datum/shipsystem/F in SC.systems)
					qdel(F)
				wreck.true_name = true_name
				qdel(SC)
				qdel(src)



/obj/structure/overmap/proc/has_shields()
	if(SC.shields.health >= 5000 && shields_active && SC.shields.toggled)
		return 1
	else//no
		return 0

/obj/structure/overmap/bullet_act(var/obj/item/projectile/P)
	. = ..()
	if(has_shields())
		var/thedamage = P.damage / 2 //Shields will deflect most conventional weapons, including photons
		take_damage(thedamage,1)
		return
	take_damage(P.damage,1)
	return



/obj/structure/overmap/Collide(atom/movable/mover) //Collide is when this ship rams stuff, collided with is when it's rammed
	return ..()

/obj/structure/overmap/CollidedWith(atom/movable/mover)
	return ..() //This is fucky with fighters PINGING PEOPLE OFF INTO SPACE!!!
	if(!isOVERMAP(mover))
		if(!shields_active)
			var/turf/open/space/turfs = list()
			for(var/turf/T in get_area_turfs(linked_ship))
				if(istype(T, /turf/open/space))
					turfs += T
			var/turf/theturf = pick(turfs)
			mover.forceMove(theturf) //Force them into a random turf
			if(istype(mover, /obj/structure/photon_torpedo))
				var/obj/structure/photon_torpedo/P = mover
				if(P.armed)
					sleep(10)
					P.force_explode()
	else
		return ..()

/obj/structure/overmap/ship/starfleet
	name = "USS Cadaver"
	icon_state = "cadaver"
//obj/structure/fluff/ship/helm do me later


/obj/structure/overmap/proc/fire_torpedo(obj/structure/overmap/OM)
	var/list/thelist = list(OM.transporters,OM.weapons,OM.generator,OM.initial_loc)
	var/fuck = pick(thelist)
	var/turf/theturf = get_turf(fuck)
	weapons.fire_torpedo(theturf, pilot)
	SEND_SOUND(pilot, sound('StarTrek13/sound/borg/machines/torpedo1.ogg'))

#undef TORPEDO_MODE
#undef PHASER_MODE

