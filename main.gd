extends Control

@onready var code_editor := $%CodeEditor
@onready var output_label := $%Output
@onready var run_button := $%RunButton

@onready var script_thread := Thread.new()
@onready var script_mutex := Mutex.new()

var script_processing: bool = false
var tmp_dir: String

var script_filename: String = "script.kts"
var execute_script: Callable = run_kotlin

func _ready() -> void:
	if OS.get_name() in ["Windows", "UWP"]:
		printerr("Windows not supported currently")
		get_tree().quit(1)
	
	output_label.push_mono()
	
	var output: Array[String] = []
	var exit_code := OS.execute("mktemp", ["-d"], output)
	if exit_code != 0:
		get_tree().quit(exit_code)
	tmp_dir = output[0].rstrip("\n")

func execute(file: FileAccess, output: Array[String]) -> int:
	var exit_code: int = execute_script.call(file, output)
	script_mutex.lock()
	script_processing = false
	script_mutex.unlock()
	return exit_code

func _on_run_button_pressed() -> void:
	if script_thread.is_alive():
		return
	
	var filepath := "%s/%s" % [tmp_dir, script_filename]
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	file.store_string(code_editor.text + "\n")
	file.close()
	
	var output: Array[String] = []
	script_mutex.lock()
	script_processing = true
	script_mutex.unlock()
	
	output_label.push_bold()
	output_label.append_text("Executing '%s'...\n" % filepath)
	output_label.pop()
	script_thread.start(execute.bind(file, output), Thread.PRIORITY_NORMAL)
	
	while script_processing:
		await get_tree().create_timer(0.1).timeout
	
	var exit_code: int = script_thread.wait_to_finish()
	
	output_label.append_text(output[0])
	if exit_code != 0:
		print_error("Runner exited with non-zero exit code (%d)" % exit_code)
	
	output_label.push_bold()
	output_label.append_text("\n--- Process Finished ---\n\n")
	output_label.pop()

func print_error(error: String) -> void:
	output_label.push_bold()
	output_label.push_color(Color.ORANGE_RED)
	output_label.append_text(error)
	output_label.pop()
	output_label.pop()
	printerr(error)

func _on_clear_button_pressed() -> void:
	output_label.clear()
	output_label.push_mono()

func run_kotlin(file: FileAccess, output: Array[String]) -> int:
	return OS.execute("kotlinc", ["-script", file.get_path()], output)

func run_swift(file: FileAccess, output: Array[String]) -> int:
	return OS.execute("swift", [file.get_path()], output)

func _on_language_selector_item_selected(index: int) -> void:
	match index:
		0:
			execute_script = run_kotlin
			script_filename = "script.kts"
		1:
			execute_script = run_swift
			script_filename = "script.swift"
