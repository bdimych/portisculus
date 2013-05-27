Какие проблемы были с файлами:

---
13.DJ Sim - Happy Organ.mp3
	ruby-mp3info 0.8 неправильно определяет длину 911 секунд вместо 227
	2013-04-29 09:46:57 написал багу https://github.com/moumar/ruby-mp3info/issues/28

---
Имена с юникодовыми символами:
04. Communiqué.mp3 - эту чёрточку в редакторе видно - "COMBINING ACUTE ACCENT" (U+0301)
11. Недетское Время.mp3 - а вот тут перед ".mp3" есть пустой символ который у меня в notepad++ даже невидно
                   ^
                   вот он тут, его можно увидеть например с помощью less или hexdump
                   два байта c2 8f - это юникод "U+008F" без названия
С этими именами было вот что:
На винде портискулус работает в цигвине но mplayer виндовский - я поставил SMPlayer и сделал симлинк /bin/mplayer -> mplayer.exe.
И вот виндовский mplayer не мог открыть эти файлы - ошибался "file not found".
Когда я это обнаружил я записал себе багу но дату не записал.
И вот наконец то (апрель 2013) руки дошли.
А т.к. с тех пор прошло достаточно времени то я конечно захотел попробовать последний mplayer.
Ну и короче обновил поставил SMPlayer 0.8.4 и всё стало нормально!, всё открывается! :)
Вот такая позитивная история :) а тест на всякий случай хуже не будет! :)

---
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 9/13 - S.u.n. Project - Hangin' Around.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 18/06 - Mantrix - Gaia.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 9/19 - Syn Sun - Ceremony.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 4/10 - Cosma - Time Has Come.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 17/17 - Psypsiq Jiouri - Histora De Un Sueno.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 4/02 - Gmo - Koiau (Exclusive Track).mp3

mp3info таги mp3 ошибки iconv


