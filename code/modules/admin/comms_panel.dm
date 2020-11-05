/datum/vueui_module/comms_panel

/datum/vueui_module/comms_panel/ui_interact(mob/user)
	if (!usr.client.holder)
		return
	var/datum/vueui/ui = SSvueui.get_open_ui(user, src)
	if(!ui)
		ui = new(user, src, "admin-comms-panel", 800, 600, "Comms panel", state = interactive_state)
		ui.header = "minimal"
		ui.auto_update_content = TRUE

	ui.open()

/datum/vueui_module/comms_panel/vueui_data_change(var/list/data, var/mob/user, var/datum/vueui/ui)
	if(!data)
		. = data = list()
	if(!user.client.holder)
		return
	if(!SScomms)
		return
	VUEUI_SET_CHECK_IFNOTSET(data["holder_ref"], "\ref[user.client.holder]", ., data)
	VUEUI_SET_CHECK_LIST(data["message_queue"], SScomms.message_queue, ., data)
	VUEUI_SET_CHECK_LIST(data["messages_finished"], SScomms.messages_finished, ., data)

	LAZYINITLIST(data["messages"])
	var/index = 1
	for(var/datum/message/M in SScomms.message_queue)
		LAZYINITLIST(data["messages"][index++])
		VUEUI_SET_CHECK_IFNOTSET(data["messages"][M.id]["queue"], "queue", ., data)
		VUEUI_SET_CHECK_IFNOTSET(data["messages"][M.id]["type"], M.type, ., data)
		VUEUI_SET_CHECK_IFNOTSET(data["messages"][M.id]["id"], M.id, ., data)
		VUEUI_SET_CHECK(data["messages"][M.id]["content"], istext(M.GetBody()) ? M.GetBody() : "nontext", ., data)
	for(var/datum/message/M in SScomms.messages_finished)
		LAZYINITLIST(data["messages"][index++])
		VUEUI_SET_CHECK_IFNOTSET(data["messages"][M.id]["queue"], "finished", ., data)
		VUEUI_SET_CHECK_IFNOTSET(data["messages"][M.id]["type"], M.type, ., data)
		VUEUI_SET_CHECK_IFNOTSET(data["messages"][M.id]["id"], M.id, ., data)
		VUEUI_SET_CHECK(data["messages"][M.id]["content"], istext(M.GetBody()) ? M.GetBody() : "nontext", ., data)

/datum/vueui_module/comms_panel/Topic(href, href_list)
