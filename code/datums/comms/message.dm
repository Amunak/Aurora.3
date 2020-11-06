#define STATE_NEW        1 // Newly created messages
#define STATE_DELIVERING 2 // Delivery has started (or has been attempted and failed for now)
#define STATE_DELIVERED  3 // Delivery was successful
#define STATE_CANCELED   4 // Delivery was cancelled
#define STATE_FAILED     5 // Delivery has failed after too many tries - we gave up

/datum/message
	var/id = null // message ID, assigned by SSComms
	var/sender // holds sender (whatever that may be - mob, client, mind, null, ...)
	var/sender_key // holds sender's ckey at time of submission
	var/state = STATE_NEW
	var/created_at = null // when the message was created
	var/delivered_at = null // when the message was created
	var/deliver = 0 // when to deliver the message in world time
	var/first_delivery_attempt = null // when the first delivery attempt was made
	var/stop_retrying_after = 10 MINUTES // when to stop re-trying delivery (from first_delivery_attempt)
	var/failures = 0 // how many times a delivery failed

	var/for_categories = null
	var/contents = ""

/datum/message/New(var/sender = null, var/delay = 1)
	src.sender = sender
	src.sender_key = key_name(sender)
	src.created_at = world.time
	src.deliver = world.time + delay

/datum/message/proc/Send()
	if(src.state != STATE_NEW)
		return
	SScomms.SubmitMessage(src)

/datum/message/proc/IsDelivering()
	if(src.state == STATE_NEW)
		return TRUE
	if(src.state == STATE_DELIVERING)
		return TRUE
	return FALSE

/datum/message/proc/IsDelivered()
	return src.state == STATE_DELIVERED

/datum/message/proc/IsCanceled()
	return src.state == STATE_CANCELED

/datum/message/proc/ShouldDeliverNow()
	return world.time > src.deliver

/datum/message/proc/StartDelivery()
	if(!src.IsDelivering())
		return FALSE
	if(src.state == STATE_NEW)
		src.state = STATE_DELIVERING
		src.first_delivery_attempt = world.time
	return TRUE

/datum/message/proc/FinishDelivery()
	if(!src.IsDelivering())
		return FALSE
	src.state = STATE_DELIVERED
	src.delivered_at = world.time
	return TRUE

/datum/message/proc/AddFailure()
	src.failures++

	if(first_delivery_attempt && world.time > first_delivery_attempt + stop_retrying_after)
		src.state = STATE_FAILED
		return

	var/delay // delay grows; 5, 5, 20, 20, 20, then 60 seconds - this makes for about 13 delivery attempts in the first 10 minutes
	switch(failures)
		if(-INFINITY to 2)
			delay = 5 SECONDS
		if(2 to 6)
			delay = 20 SECONDS
		else
			delay = 60 SECONDS

	src.deliver = world.time + delay

/datum/message/proc/GetBody()
	return src.contents

#undef STATE_NEW
#undef STATE_DELIVERED
#undef STATE_CANCELED
#undef STATE_FAILED
