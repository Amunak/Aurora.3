// Admin Receivers

/datum/message_receiver/admin
	category = "Centcom"
	name = "Admin Receiver"

/datum/message_receiver/admin/Receive(var/datum/message/M)
	var/atom/A = M.sender
	var/msg = SPAN_WARNING("Receiving Message as [src.name] from <strong>[A?.name] ([key_name(M.sender, 1)])</strong>")

	var/cciaa_present = 0
	var/cciaa_afk = 0
	for(var/s in staff)
		var/client/C = s
		var/flags = C.holder.rights & (R_ADMIN|R_CCIAA)
		if(flags)
			to_chat(C, msg)
		if (flags == R_CCIAA) // Admins sometimes get R_CCIAA, but CCIAA never get R_ADMIN
			cciaa_present++
			if (C.is_afk())
				cciaa_afk++

	// var/discord_msg = "New fax arrived! [faxname]: \"[sent.name]\" by [sender]. ([cciaa_present] agents online"
	var/discord_msg = msg
	if (cciaa_present)
		if ((cciaa_present - cciaa_afk) <= 0)
			discord_msg += ", **all AFK!**)"
		else
			discord_msg += ", [cciaa_afk] AFK.)"
	else
		discord_msg += ".)"

	discord_msg += " Gamemode: [SSticker.mode]"

	discord_bot.send_to_cciaa(discord_msg)


// Statio Receivers

/datum/message_receiver/station
	category = "Station"

/datum/message_receiver/station/announcement
	name = "Station Announcement"

/datum/message_receiver/station/announcement/AcceptsMessage(var/datum/message/M)
	return istype(M, /datum/message/announcement)

/datum/message_receiver/station/announcement/Receive(var/datum/message/announcement/M)
	world << M.GetBody()

/datum/message_receiver/station/radio
	name = "Station Radio"
	hidden = TRUE

	var/mob/living/announcer/AM

/datum/message_receiver/station/radio/New()
	AM = new
	return ..()

/datum/message_receiver/station/radio/Destroy(force)
	qdel(AM)
	return ..()

/datum/message_receiver/station/radio/AcceptsMessage(var/datum/message/M)
	return istype(M, /datum/message/radio)

/datum/message_receiver/station/radio/Receive(var/datum/message/radio/M)
	var/datum/radio_frequency/connection = SSradio.return_frequency(M.radio_frequency)
	if (!connection)
		return FALSE

	AM.PrepareBroadcast(M.announcer_name)

	// Shamelessly copied from Radios' Subspace Transmission Code
	var/datum/signal/signal = new
	signal.transmission_method = 2 // @TODO change to TRANSMISSION_SUBSPACE after PR#10406 is merged
	signal.frequency = connection.frequency
	signal.data = list(
		// Identity-associated tags:
		"mob" = AM, // store a reference to the mob
		"mobtype" = AM.type, 	// the mob's type
		"realname" = M.announcer_name, // the mob's real name
		"name" = M.announcer_name,	// the mob's display name
		"job" = M.jobname,		// the mob's job
		"key" = "none",			// the mob's key
		"vmessage" = null, // the message to display if the voice wasn't understood
		"vname" = M.announcer_name, // the name to display if the voice wasn't understood
		"vmask" = FALSE,	// 1 if the mob is using a voice gas mask

		"compression" = 0,
		"message" = M.GetBody(),
		"connection" = connection,
		"radio" = null, // stores the radio used for transmission
		"slow" = 0,
		"traffic" = 0,
		"type" = 0, // determines what type of radio input it is: normal broadcast
		"server" = null,
		"reject" = 0, // if nonzero, the signal will not be accepted by any broadcasting machinery
		"level" = null, // position.z, // The source's z level
		"language" = null
	)

	//#### Sending the signal to all subspace receivers ####//

	for(var/obj/machinery/telecomms/receiver/R in telecomms_list)
		R.receive_signal(signal)

	// Allinone can act as receivers.
	for(var/obj/machinery/telecomms/allinone/R in telecomms_list)
		R.receive_signal(signal)

	AM.Reset()

	if(!signal.data["done"] /*|| !(position.z in signal.data["level"])*/)
		log_debug("Radio receiver [name] ([type]) failed delivery. There's nothing we can do.")
