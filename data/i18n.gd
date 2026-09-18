class_name HGLoc
extends Object

const EN := "en"
const RO := "ro"

const STRINGS := {
	EN: {
		"play": "PLAY",
		"continue": "CONTINUE",
		"settings": "SETTINGS",
		"main_menu": "MAIN MENU",
		"music": "Music",
		"sound": "Sound",
		"language": "Language",
		"lang_en": "English",
		"lang_ro": "Română",
		"paused": "PAUSED",
		"resume": "RESUME",
		"try_again": "TRY AGAIN",
		"levels": "LEVELS",
		"moves": "MOVES",
		"book_sealed": "That book is still sealed.",
		"coming_soon": "Coming soon.",
		"win_title": "It is good.",
		"win_detail": "Genesis 1 is fulfilled",
		"lose_title": "No moves left",
		"lose_detail": "The heavens still wait.\nTry again.",
		"book_genesis": "Genesis",
		"level_creation": "The beginning",
		"level_garden": "Paradise",
		"level_flood": "The Flood",
		"level_promise": "The Promise",
		"level_joseph": "Joseph",
		"verse_genesis_1_1": "In the beginning God made the heaven and the earth.",
		"ref_genesis_1_1": "Genesis 1:1",
		"book_page_title": "LEVELS 1–5",
	},
	RO: {
		"play": "JOACĂ",
		"continue": "CONTINUĂ",
		"settings": "SETĂRI",
		"main_menu": "MENIU",
		"music": "Muzică",
		"sound": "Sunet",
		"language": "Limbă",
		"lang_en": "English",
		"lang_ro": "Română",
		"paused": "PAUZĂ",
		"resume": "REIA",
		"try_again": "DIN NOU",
		"levels": "NIVELURI",
		"moves": "MUTĂRI",
		"book_sealed": "Cartea aceasta este încă pecetluită.",
		"coming_soon": "În curând.",
		"win_title": "Este bine.",
		"win_detail": "Facerea 1 s-a împlinit",
		"lose_title": "Nu mai ai mutări",
		"lose_detail": "Cerurile încă așteaptă.\nÎncearcă iarăși.",
		"book_genesis": "Facerea",
		"level_creation": "La început",
		"level_garden": "Raiul",
		"level_flood": "Potopul",
		"level_promise": "Făgăduința",
		"level_joseph": "Iosif",
		"verse_genesis_1_1": "La început a făcut Dumnezeu cerul și pământul.",
		"ref_genesis_1_1": "Facerea 1:1",
		"book_page_title": "NIVELURI 1–5",
	},
}


static func t(key: String) -> String:
	var table: Dictionary = STRINGS.get(HGSave.locale, STRINGS[EN])
	if table.has(key):
		return String(table[key])
	return String(STRINGS[EN].get(key, key))


static func is_ro() -> bool:
	return HGSave.locale == RO
