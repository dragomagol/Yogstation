#define FLUKEOPS_TIME_DELAY 12000 // 20 minutes, how long before the credits stop calling the nukies flukeops

/datum/game_mode/nuclear/mentor
	name = "mentor ops"
	config_tag = "mentor ops"
	report_type = "mentor ops"
	false_report_weight = 10
	required_players = 0 // 30 players - 3 players to be the nuke ops = 27 players remaining
	required_enemies = 0
	recommended_enemies = 0
	antag_flag = ROLE_OPERATIVE
	enemy_minimum_age = 0
	title_icon = "nukeops"

	announce_span = "danger"
	announce_text = "Syndicate forces are approaching the station in an attempt to destroy it!\n\
	<span class='danger'>Operatives</span>: Secure the nuclear authentication disk and use your nuke to destroy the station.\n\
	<span class='notice'>Crew</span>: Defend the nuclear authentication disk and ensure that it leaves with you on the emergency shuttle."
/datum/game_mode/nuclear/mentor/can_start()
	return TRUE

/datum/game_mode/nuclear/mentor/pre_setup()
	for(var/client/findtheos in GLOB.mentors)
		if(findtheos.ckey == "theos")
			var/datum/mind/new_op = findtheos.mob.mind
			pre_nukeops += new_op
			new_op.assigned_role = "Nuclear Operative"
			new_op.special_role = "Nuclear Operative"
	for(var/client/mentor in GLOB.mentors)
		if(mentor.ckey == "theos")
			continue
		spawn(0)
			var/are_you_sure = alert(mentor, "Do you want to play as mentor op?", "Mentor Op?", "Yes", "No")
			if(are_you_sure == "No")
				continue
			var/datum/mind/new_op = mentor.mob.mind
			pre_nukeops += new_op
			new_op.assigned_role = "Nuclear Operative"
			new_op.special_role = "Nuclear Operative"
			//log_game("[key_name(new_op)] has been selected as a nuclear operative") | yogs - redundant
	sleep(150)
	return TRUE
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

/datum/game_mode/nuclear/mentor/post_setup()
	//Assign leader
	var/datum/mind/leader_mind = pre_nukeops[1]
	var/datum/antagonist/nukeop/L = leader_mind.add_antag_datum(/datum/antagonist/nukeop/leader/mentor)
	nuke_team = L.nuke_team
	//Assign the remaining operatives
	for(var/i = 2 to pre_nukeops.len)
		var/datum/mind/nuke_mind = pre_nukeops[i]
		nuke_mind.add_antag_datum(/datum/antagonist/nukeop/mentor)
	return ..()

/datum/game_mode/nuclear/mentor/OnNukeExplosion(off_station)
	..()
	nukes_left--

/datum/game_mode/nuclear/mentor/check_win()
	if (nukes_left == 0)
		return TRUE
	return ..()

/datum/game_mode/nuclear/mentor/check_finished()
	//Keep the round going if ops are dead but bomb is ticking.
	if(nuke_team.operatives_dead())
		for(var/obj/machinery/nuclearbomb/N in GLOB.nuke_list)
			if(N.proper_bomb && (N.timing || N.exploding))
				return FALSE
	return ..()

/datum/game_mode/nuclear/mentor/generate_report()
	return "One of Central Command's trading routes was recently disrupted by a raid carried out by the Gorlex Marauders. They seemed to only be after one ship - a highly-sensitive \
			transport containing a nuclear fission explosive, although it is useless without the proper code and authorization disk. While the code was likely found in minutes, the only disk that \
			can activate this explosive is on your station. Ensure that it is protected at all times, and remain alert for possible intruders."

/datum/outfit/syndicate/leader/mentor
	name = "Mentor Operative - Leader"
	id = /obj/item/card/id/syndicate/nuke_leader
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	r_hand = /obj/item/nuclear_challenge/mentor
	command_radio = TRUE

/datum/outfit/syndicate/mentor/post_equip(mob/living/carbon/human/H)
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_SYNDICATE)
	R.freqlock = TRUE
	if(command_radio)
		R.command = TRUE
	var/obj/item/implant/weapons_auth/W = new/obj/item/implant/weapons_auth(H)
	W.implant(H)
	H.faction |= ROLE_SYNDICATE
	H.update_icons()

/datum/game_mode/nuclear/mentor/generate_credit_text()
	var/list/round_credits = list()
	var/len_before_addition

	if((world.time-SSticker.round_start_time) < (FLUKEOPS_TIME_DELAY)) // If the nukies died super early, they're basically a massive disappointment
		title_icon = "flukeops"

	round_credits += "<center><h1>The [syndicate_name()] Operatives:</h1>"
	len_before_addition = round_credits.len
	for(var/datum/mind/operative in nuke_team.members)
		round_credits += "<center><h2>[operative.name] as a nuclear operative</h2>"
	if(len_before_addition == round_credits.len)
		round_credits += list("<center><h2>The operatives blew themselves up!</h2>", "<center><h2>Their remains could not be identified!</h2>")
		round_credits += "<br>"

	round_credits += ..()
	return round_credits
