extends CodeEdit

func _ready() -> void:
	self.add_comment_delimiter("//", "")
	var highlighter: CodeHighlighter = self.syntax_highlighter
	highlighter.add_color_region("//", "", Color("#696969"), true)
	highlighter.add_color_region('"', '"', Color("#f0dfa3"))
	highlighter.add_color_region("'", "'", Color("#f0dfa3"))
