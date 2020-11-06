/*
 * Communications Subsystem
 *
 * How it works: These are the main parts of the system:
 * - Messages represent the actual communication message - they hold the contents and some metadata.
 * - Receivers represent targets for receiving messages.
 *       Think Centcom, Station Announcements, Station Radio, Station Faxes. NOT specific devices or machinery,
 *       just an abstract idea of them. It's up to them to deliver the message correctly based on its metadata.
 * - Routers are a "link" between Messages and Receivers. They decide if a message "goes through" to any given
 *       Receiver. Feel free to make one for every machine that message delivery should depend on. But keep in
 *       mind you only need a single Router to say it's okay to send the message to a Receiver for it to go through.
 *
 * Additionally, messages are not sent immediately, they are only queued for delivery. Depending on the message
 * it might be attempted to send it ASAP, or it might be delayed. Messages are also not just thrown out when
 * delivery fails; delivery is re-attempted several times (again depending on the message). Messages can also be
 * edited or canceled, but it's probably better not to do that once it has been delivered.
 *
 * What happens when you create a Message and submit it (by calling `Message.Send()`):
 * - The message is processed and put into the message queue and the subsystem is told to wake up if it was sleeping.
 * - When awake we go through the queue, looking for messages that are supposed to be delivered.
 * - We try to find at least one Router for every Receiver willing to accept the message. If we end up with
 *       even just a single Receiver, the delivery will go through and will be considered successful (even
 *       if you might have wanted to receive the message with multiple Receivers).
 * - Every Receiver's Receive method is called and they are expected to deliver this message WITHOUT FAILURE.
 *       The comms system doesn't care if the message wasn't *actually* delivered. The Receiver is free
 *       to implement a method of re-trying the delivery "for itself", though most will likely just ignore.
 * - If no Receiver was found `Message.AddFailure()` is called on the message and it is returned back to the
 *       waiting queue. By default this increases the failure count on the message, delays its delivery for
 *       some time and eventually if this happens too many times the message is marked as failed.
 *
 * Note that the system does not care about how messages are created and how they enter the system.
 * That is your responsibility. You may want to keep references to the messages you create and
 * call their various procs to find out how they are doing and modify them if necessary.
 */

var/datum/controller/subsystem/comms/SScomms

/datum/controller/subsystem/comms
	name = "Comms"
	wait = 1 // We fire "all the time" except we actually sleep most of the time. This makes sure when there are messages they get processed fast and on time.

	var/message_id = 0

	// Message lists
	var/list/datum/message/message_queue = list() // Holds messages waiting for delivery
	var/list/datum/message/messages_finished = list() // Holds messages that have completely finished processing one way or another

	var/list/datum/message_router/routers = list() // List of all registered routers
	var/list/datum/message_receiver/receivers = list() // List of registered message receivers

/datum/controller/subsystem/comms/stat_entry()
	..("Q:[message_queue.len] F:[messages_finished.len] R: [routers.len] E: [receivers.len]")

/datum/controller/subsystem/comms/New()
	NEW_SS_GLOBAL(SScomms)

/datum/controller/subsystem/comms/Initialize(start_timeofday)
	. = ..()

	// register admin receivers
	for(var/department in admin_departments)
		var/datum/message_receiver/admin/R = new()
		R.name = department
		RegisterReceiver(R)

	// register generic receivers
	RegisterReceiver(new /datum/message_receiver/station/announcement())
	RegisterReceiver(new /datum/message_receiver/station/radio())

/datum/controller/subsystem/comms/fire(resumed)
	for(var/datum/message/M in message_queue) // process queued messages one by one
		if(!M.ShouldDeliverNow()) // skip over messages that are to be delivered later
			continue

		message_queue -= M
		AttemptMessageDelivery(M)

		// pause after one attempted delivery if there's no time
		if(MC_TICK_CHECK)
			return

	// if there are still messages in queue, schedule a wake (otherwise they won't get processed on time)
	if(message_queue.len)
		ScheduleWake()

	// since there is nothing to do we can suspend until a new message arrives
	suspend()


// Public procs for using the message system

/datum/controller/subsystem/comms/proc/RegisterReceiver(var/datum/message_receiver/R)
	if(isnull(R.name))
		error("Message receiver [R]([R.type]) is invalid. It has no name.")
	receivers |= R

/datum/controller/subsystem/comms/proc/RemoveReceiver(var/datum/message_receiver/R)
	receivers |= R

/datum/controller/subsystem/comms/proc/RegisterRouter(var/datum/message_router/E)
	routers |= E

/datum/controller/subsystem/comms/proc/RemoveRouter(var/datum/message_router/E)
	routers |= E

/datum/controller/subsystem/comms/proc/SubmitMessage(var/datum/message/M)
	ProcessNewMessage(M)
	wake()


// Private procs handling the messages

/datum/controller/subsystem/comms/proc/ProcessNewMessage(var/datum/message/M)
	// set message ID
	M.id = message_id++
	// move message to queue
	message_queue += M
	log_debug("Queued message [M.type]")

// Schedules a wake so that we will wake up just as we are supposed to deliver a message
/datum/controller/subsystem/comms/proc/ScheduleWake()
	var/when = INFINITY
	for(var/datum/message/M in message_queue)
		if(M.deliver < when)
			when = M.deliver
	when = max(2 SECONDS, min(when - world.time, 10 MINUTES)) // wake up no sooner than in 2 seconds but no later than in 10 minutes

	log_debug("Scheduling wake to [when/10] seconds")
	addtimer(CALLBACK(src, .proc/wake), when, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)

// Attempts to deliver a message
/datum/controller/subsystem/comms/proc/AttemptMessageDelivery(var/datum/message/M)
	if(!M.IsDelivering()) // failed, finished or otherwise bad message, move it to finished
		messages_finished += M
		return

	// too soon, hold the message a little longer
	if (!M.ShouldDeliverNow())
		message_queue += M
		return

	// attempt delivery
	M.StartDelivery()
	var/list/datum/message_receiver/receivers = RouteMessage(M)
	if(!receivers.len) // no route found
		M.AddFailure()
		if(M.IsDelivering())
			message_queue += M // move it back to the queue
		else
			messages_finished += M // message no longer available for delivery (probably failed too many times)
		return

	M.FinishDelivery()
	messages_finished += M
	for(var/datum/message_receiver/R in receivers)
		try
			R.Receive(M)
		catch(var/exception/E) // let's not kill our subsystem when an invalid receiver is used
			error(E.name)


// Finds receivers for a given message using routers
/datum/controller/subsystem/comms/proc/RouteMessage(var/datum/message/M)
	var/list/datum/message_receiver/result = list()
	// go through all receivers and try to find at least one router for each
	for(var/datum/message_receiver/R in receivers)
		if(!R.AcceptsMessage(M)) // Receivers can decide to skip messages
			log_debug("Receiver [R.name] ([R.type]) decided to skip message [M.type]")
			continue
		for(var/datum/message_router/E in routers)
			if(!E.Routes(M, R)) // Routers can decide to not route to a receiver or based on the message
				log_debug("Router [R.type] decided to skip message [M.type]")
				continue
			result += R
			break // Found one and that's all we need
	return result
