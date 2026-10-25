extends TestCase


func test_keeps_only_the_newest_entries() -> void:
	var log := DroneLog.new(3)
	for i in 5:
		log.add(i, "evento %d" % i)
	assert_eq(log.size(), 3)
	assert_eq(log.lines(), PackedStringArray(["[2] evento 2", "[3] evento 3", "[4] evento 4"]))


func test_repeated_entries_collapse_with_count() -> void:
	var log := DroneLog.new()
	log.add(1, "minerar")
	log.add(2, "minerar")
	log.add(3, "minerar")
	log.add(4, "descarregar")
	assert_eq(log.lines(), PackedStringArray(["[3] minerar ×3", "[4] descarregar"]))


func test_lines_can_be_limited() -> void:
	var log := DroneLog.new()
	for i in 4:
		log.add(i, "e%d" % i)
	assert_eq(log.lines(2), PackedStringArray(["[2] e2", "[3] e3"]))
