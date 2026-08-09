class_name FormulaResult
extends RefCounted

var ok := false
var value: Variant
var error := ""


static func success(result: Variant) -> FormulaResult:
	var output := FormulaResult.new()
	output.ok = true
	output.value = result
	return output


static func failure(message: String) -> FormulaResult:
	var output := FormulaResult.new()
	output.error = message
	return output
