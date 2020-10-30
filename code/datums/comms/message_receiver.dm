/datum/message_receiver
	var/category = null // Category name, used to differentiate groups of receivers
	var/name = null // IC-friendly name of the receiver
	var/hidden = FALSE // Whether the receiver should be hidden from delivery lists
	var/operating = TRUE // Whether the receiver is able to receive messages

/datum/message_receiver/New()
	SScomms.RegisterReceiver(src)

/datum/message_receiver/Destroy(force)
	SScomms.RemoveReceiver(src)
	return ..()

/datum/message_receiver/proc/AcceptsMessage(var/datum/message/M)
	throw EXCEPTION("Message receiver [src]([src.type]) is invalid. Either you are using the wrong type or you forgot to implement the AcceptsMessage proc.")

/datum/message_receiver/proc/Receive(var/datum/message/M)
	throw EXCEPTION("Message receiver [src]([src.type]) is invalid. Either you are using the wrong type or you forgot to implement the Receive proc.")
