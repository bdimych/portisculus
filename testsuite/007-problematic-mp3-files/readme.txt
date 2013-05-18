какие проблемы были с файлами:

13.DJ Sim - Happy Organ.mp3
	ruby-mp3info 0.8 неправильно определяет длину 911 секунд вместо 227
	2013-04-29 09:46:57 написал багу https://github.com/moumar/ruby-mp3info/issues/28

04. Communiqué.mp3
	mplayer для windows не мог открыть это имя - писал "file not found"
	не только в командной строке но я пробовал и другие способы передать имя
	насколько помню пробовал:
		-??????? и напечатать имя в stdin
		-после запуска в slave режиме открыть командой ????????
	ещё есть -playlist но его непомню мабыть и не пробовал, но щас это уже неважно
	и ничего тогда не работало

	записал напотом сделать
	а сейчас обновил mplayer и заработало!
	"сейчас" это 2013-05-01 18:16:31 и версия mplayer ??????????

		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 9/13 - S.u.n. Project - Hangin' Around.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 18/06 - Mantrix - Gaia.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 9/19 - Syn Sun - Ceremony.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 4/10 - Cosma - Time Has Come.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 17/17 - Psypsiq Jiouri - Histora De Un Sueno.mp3
		/cygdrive/k/Users/bdimych/Downloads/GOA 1 - 42/Goa vol. 4/02 - Gmo - Koiau (Exclusive Track).mp3

		-эта уже у меня длину определяет неправильно
			'/cygdrive/c/Users/bdimych/Downloads/_ М У З Ы К А _/Happy Hardcore Vol 1, Vol 2, Vol 3, Vol 4/Happy Hardcore Vol 1/Cd 1/13.DJ Sim - Happy Organ.mp3'
		-эта mplayer не открывает
			-/cygdrive/d/Downloads/_ М У З Ы К А _/Dire Straits VINYLRip Discography/1979 - Communique (1979) [VINYL]/04. Communiqué.mp3: byhands
			-ещё "11 недетское время" вроде
				ДА -найти и проверить
/cygdrive/d/Downloads/_ М У З Ы К А _/Diskoteka_Avariya-Diskografia/Альбомы и синглы/2011 - Недетское время/11. Недетское Время.mp3



