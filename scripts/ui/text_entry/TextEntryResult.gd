class_name TextEntryResult
extends RefCounted

enum Status { SUBMITTED, CANCELLED }

var status: Status
var value := ""
var generation := 0


func is_submitted() -> bool:
	return status == Status.SUBMITTED
