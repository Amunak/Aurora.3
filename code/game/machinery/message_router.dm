/obj/machinery/message_router
	name = "Message Router"
	desc = "This routes messages. Through bluespace, if necessary."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "sensors"

	anchored = TRUE
	density = TRUE
	use_power = 1
	var/on = TRUE

	idle_power_usage = 15000
	active_power_usage = 15000

	var/datum/message_router/router

	component_types = list(
		/obj/item/circuitboard/message_router,
		/obj/item/stock_parts/subspace/filter,
		/obj/item/stock_parts/subspace/amplifier,
		/obj/item/stock_parts/subspace/transmitter,
		/obj/item/stack/cable_coil = 20,
	)

/obj/machinery/message_router/Initialize()
	router = new
	router.routed_categories = list("Station", "Centcom")
	return ..()

/obj/machinery/message_router/Destroy()
	qdel(router)
	return ..()

/obj/machinery/message_router/power_change()
	if(inoperable(EMPED) || !on)
		router.operating = FALSE
	else
		router.operating = TRUE
	update_icon()

/obj/machinery/message_router/update_icon()
	if(inoperable(EMPED) || !on)
		icon_state = "[initial(icon_state)]_off"
	else
		icon_state = initial(icon_state)

/obj/machinery/message_router/attack_hand(mob/user)
	. = ..()
	if(!.)
		on = !on
		router.operating = on
		use_power = on ? 1 : 0
		user.visible_message(SPAN_NOTICE("[user] turns \the [src] [on ? "on" : "off"]!"))
	update_icon()

/obj/machinery/message_router/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(default_deconstruction_screwdriver(user, O))
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return

	..()
