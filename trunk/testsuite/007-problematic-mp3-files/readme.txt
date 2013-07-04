Какие проблемы были с файлами:


---
13.DJ Sim - Happy Organ.mp3
	ruby-mp3info 0.8 неправильно определяет длину 911 секунд вместо 227
	2013-04-29 09:46:57 написал багу https://github.com/moumar/ruby-mp3info/issues/28


---
Имена с юникодовыми символами:
04. Communiqué.mp3 - сверху чёрточка это два байта cc 81 юникод U+0301 "COMBINING ACUTE ACCENT"
11. Недетское Время.mp3 - а вот тут перед ".mp3" есть пустой символ который у меня в notepad++ даже невидно
                   ^
                   вот он тут, его можно увидеть например с помощью less или hexdump
                   два байта c2 8f юникод U+008F без названия
С этими именами было вот что:
На винде портискулус работает в цигвине но mplayer виндовский - я поставил SMPlayer и сделал симлинк /bin/mplayer -> mplayer.exe.
И вот виндовский mplayer не мог открыть эти файлы - ошибался "file not found".
Когда я это обнаружил я записал себе багу но дату не записал.
И вот наконец то (апрель 2013) руки дошли.
А т.к. с тех пор прошло достаточно времени то я конечно захотел попробовать последний mplayer.
Ну и короче обновил поставил SMPlayer 0.8.4 и всё стало нормально!, всё открывается! :)
Вот такая позитивная история :) а тест на всякий случай хуже не будет! :)


---
02 - Gmo - Koiau (Exclusive Track).mp3
06 - Mantrix - Gaia.mp3
10 - Cosma - Time Has Come.mp3
13 - S.u.n. Project - Hangin' Around.mp3
17 - Psypsiq Jiouri - Histora De Un Sueno.mp3
19 - Syn Sun - Ceremony.mp3

На этих файлах ruby-mp3info ошибался
exception Iconv::IllegalSequence: ruby_18_encode - convert_to - decode_tag - read_id3v2_3_frames - parse_tags... и т.п. похожие по смыслу имена функций
т.е. он не мог перекодировать mp3 таги.

История получилась такая же как с mplayer-ом: сейчас руки дошли и оказалось что уже всё починили
но тест не помешает поэтому оставляю.


---
каталог lame-decode-error/ и 13.DJ Sim - Happy Organ.mp3

Тут история такая.
"13.DJ Sim - Happy Organ.mp3" оказался дважды проблемным.
Когда я поправил измерение длины то тест всё равно не проходил - теперь ошибался lame:
...
		[20:08:44.504] doing file 5 of 9 (added 4): testsuite/007-problematic-mp3-files/mp3/13.DJ Sim - Happy Organ.mp3
		[20:08:44.504] checkSongLength
		[20:08:44.633] 227 sec (3 min 47 sec) - ok
		[20:08:44.633] original bpm 145
		[20:08:44.633] out of the needed range, will calculate new
		[20:08:44.633] allowed range: 129-195
		[20:08:44.633] intersection: 150-153
		[20:08:44.633] target bpm 153 (+5.5%), going to apply soundstretch
		[20:08:44.695] lame --decode tmp.mp3 tmp-decoded.wav
		input:  tmp.mp3  (16 kHz, 1 channel, MPEG-2 Layer I)
		output: tmp-decoded.wav  (16 bit, Microsoft WAVE)
		skipping initial 241 samples (encoder+decoder delay)
		Error: sample frequency has changed in MP3 file - not supported

		[20:08:44.774] WARNING: tmp-decoded.wav is too small, probably lame failed
...
И т.к. эта ошибка уже была у меня записана раньше то я решил её и делать следующей.
И специально для неё нашёл ещё несколько таких же проблемных файлов и добавил lame-decode-error/
PS
Версия lame 3.99.5.
Время: сейчас когда я пишу - 7 июля 2013, а увидел я эту багу примерно весной 2012.
(Кстати погуглил сейчас "lame Error: sample frequency has changed in MP3 file - not supported"
результатов много, подробно не смотрел но судя по количеству бага известная)


