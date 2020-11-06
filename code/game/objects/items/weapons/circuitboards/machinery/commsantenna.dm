#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif

/obj/item/circuitboard/bluespacerelay
	name = T_BOARD("bluespacerelay")
	build_path = /obj/machinery/bluespacerelay
	board_type = "machine"
	origin_tech = list(TECH_BLUESPACE = 2, TECH_DATA = 2)
	req_components = list(
							"/obj/item/stack/cable_coil" = 30,
							"/obj/item/stock_parts/manipulator" = 2,
							"/obj/item/stock_parts/subspace/filter" = 1,
							"/obj/item/stock_parts/subspace/crystal" = 1
						  )

/obj/item/circuitboard/message_router
	name = T_BOARD("message router")
	build_path = /obj/machinery/message_router
	board_type = "machine"
	origin_tech = list(TECH_BLUESPACE = 2, TECH_DATA = 2)
	req_components = list(
		"/obj/item/stack/cable_coil" = 20,
		"/obj/item/stock_parts/subspace/filter" = 1,
		"/obj/item/stock_parts/subspace/amplifier" = 1,
		"/obj/item/stock_parts/subspace/transmitter" = 1,
	)
