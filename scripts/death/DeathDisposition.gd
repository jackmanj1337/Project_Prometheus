class_name DeathDisposition extends RefCounted
## Owns inventory/custody disposition. Groundwork intentionally preserves inventory.


func apply(_ctx: RefCounted, result: RefCounted) -> RefCounted:
	return result
