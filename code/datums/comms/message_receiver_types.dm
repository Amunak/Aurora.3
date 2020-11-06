// Admin Receivers

/datum/message_receiver/admin
	category = "Centcom"
	name = "Admin Receiver"

/datum/message_receiver/admin/AcceptsMessage(var/datum/message/M)
	return istype(M, /datum/message/announcement)

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

	AM.PrepareBroadcast(M.announcer_name, M.language, null, AM.accent)
	Broadcast_Message(connection, AM,
						FALSE, "*garbled radio message*", null,
						M.GetBody(), M.announcer_name, M.jobname, M.announcer_name, AM.voice_name,
						4, 0, current_map.station_levels, connection.frequency, "states", AM.default_language)
	AM.ResetAfterBroadcast()
