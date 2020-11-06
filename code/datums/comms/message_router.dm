/datum/message_router
	var/list/routed_categories = list()
	var/operating = TRUE // Whether the router is working

/datum/message_router/New()
	SScomms.RegisterRouter(src)

/datum/message_router/Destroy(force)
	SScomms.RemoveRouter(src)
	return ..()

/datum/message_router/proc/Routes(var/datum/message/M, var/datum/message_receiver/R)
	if(!operating)
		return FALSE
	if(!(R.category in routed_categories))
		return FALSE
	if(islist(M.for_categories) && !(R.category in M.for_categories))
		return FALSE
	return TRUE
