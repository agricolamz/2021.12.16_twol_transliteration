---
title: "`twol`, транслитерация"
author: "Г. Мороз, Н. Хауэлл"
date: "16 декабря 2021"
output: 
  html_document:
    toc: true
    toc_position: right
    toc_depth: 2
    toc_float: yes
    number_sections: true
    df_print: paged
    keep_md: true
---





# Наши встречи

| дата       | тема                                   | материалы                                                                                  | видео                                 |
|------------|----------------------------------------|--------------------------------------------------------------------------------------------|---------------------------------------|
| 2021.11.08 | нахско-дагестанские языки, linux, lexd |                                                                                            | [видео](https://youtu.be/oslfxrYjt_A) |
| 2021.12.02 | linux, lexd, github, makefiles         | [материалы](https://agricolamz.github.io/2021.12.02_intro_to_linux_lexd_github_makefiles/) | [видео](https://youtu.be/3ULre3nuIhU) |
| 2021.12.09 | gitignore, tests, githooks             | [материалы](https://agricolamz.github.io/2021.12.09_gitignore_tests_githooks/)             | [видео](https://youtu.be/8v6ajrlOGuA) |
| 2021.12.16 | `twol`, транслитерация видео           | [материалы](https://agricolamz.github.io/2021.12.16_twol_transliteration/)                 |                                       |

# `twol`[^1]

[^1]: Весь этот раздел я бездумно списал из прошлогодних материалов Ника Хауэлла. Я старался списывать только то, что я понял...

`twol` --- это 

* формализм для описания морфонологии;
* язык программирования для описания морфонологических правил;
* `twolc` --- компилятор этого языка.

`twol` состоит из 

* 'алфавита' --- список возможных трансформаций;
* 'правила' --- список двухуровневых правил.

Важно понимать, что фонологические правила в `twol` не правила в стиле генеративной фонологии. Правила в `twol` не упорядочены, а применяются все сразу.

## Первый пример

В андийском есть коммитатив -лой, который ассимилируется, если основа заканчивается на *н*. Вот мой `and.lexd`:


```
PATTERNS
NounAbs [<n>:] Abs (Com)
NounObl [<n>:] [<obl>:] (NounInfl) | (NounInflEssive Elative?)

LEXICON NounAbs
берка # змея
цIцIон # соль

LEXICON NounObl
берка:берку # змея
цIцIон:цIцIон # соль

LEXICON Abs
<abs>:

LEXICON NounInfl
<erg>:ди
<ins>:хъи
<sub><lative>:лIи
<super><lative>:ъо

LEXICON NounInflEssive
<super><essive>:ъа
<sub><essive>:лIи

LEXICON Elative
<elative>:кку

LEXICON Com
<com>:{л}ой
```


Я хочу написать, правило `л -> н / н _`. Так как это правило должно применяться не всегда, а только в показателе коммитатива, я ввожу специальную абстракцию `{л}` (ее принято называть *архифонемой*, но лучше не думать над лингвистическим употреблением этого термина), реализацию которой я пропишу в правилах `and.twol`.


```
Alphabet
  а б д е и й к л н о х ъ р ц I у ъ
  %{л%}:н %{л%}:л
;

Rules

"{л} realisation"
%{л%}:н <=> н _ ;
```

Теперь можно сделать из этого файла трансдьюcер:


```bash
$ hfst-twolc and.twol -o and.twol.hfst
```

```
Reading input from and.twol.
Writing output to and.twol.hfst.
Reading alphabet.
Reading rules and compiling their contexts and centers.
Compiling rules.
Storing rules.
```

На него нельзя поглядеть при помощи `hfst-fst2strings`, потому что он зациклен. Теперь нужно сделать трансдьюсер из файла `.lexd`:


```bash
$ lexd and.lexd | hfst-txt2fst -o and.lexd.hfst
```

Давайте поглядим на результат:

```bash
$ hfst-fst2strings and.lexd.hfst
```

```
берка<n><abs><com>:берка{л}ой
берка<n><obl><erg>:беркуди
берка<n><obl><ins>:беркухъи
берка<n><obl><sub><lative>:беркулIи
берка<n><obl><sub><essive>:беркулIи
берка<n><obl><sub><essive><elative>:беркулIикку
берка<n><obl><super><lative>:беркуъо
берка<n><obl><super><essive>:беркуъа
берка<n><obl><super><essive><elative>:беркуъакку
цIцIон<n><abs><com>:цIцIон{л}ой
цIцIон<n><obl><erg>:цIцIонди
цIцIон<n><obl><ins>:цIцIонхъи
цIцIон<n><obl><sub><lative>:цIцIонлIи
цIцIон<n><obl><sub><essive>:цIцIонлIи
цIцIон<n><obl><sub><essive><elative>:цIцIонлIикку
цIцIон<n><obl><super><lative>:цIцIонъо
цIцIон<n><obl><super><essive>:цIцIонъа
цIцIон<n><obl><super><essive><elative>:цIцIонъакку
```

Теперь давайте соединим наши трансдьюсеры и посмотрим, что получилось:

```bash
$ hfst-compose-intersect and.lexd.hfst and.twol.hfst -o and.generator.hfst
```


```bash
$ hfst-fst2strings and.generator.hfst
```

```
берка<n><abs><com>:беркалой
берка<n><obl><sub><lative>:беркулIи
берка<n><obl><sub><essive><elative>:беркулIикку
берка<n><obl><sub><essive>:беркулIи
берка<n><obl><erg>:беркуди
берка<n><obl><ins>:беркухъи
берка<n><obl><super><essive><elative>:беркуъакку
берка<n><obl><super><essive>:беркуъа
берка<n><obl><super><lative>:беркуъо
цIцIон<n><abs><com>:цIцIонной
цIцIон<n><obl><sub><lative>:цIцIонлIи
цIцIон<n><obl><sub><essive><elative>:цIцIонлIикку
цIцIон<n><obl><sub><essive>:цIцIонлIи
цIцIон<n><obl><erg>:цIцIонди
цIцIон<n><obl><ins>:цIцIонхъи
цIцIон<n><obl><super><essive><elative>:цIцIонъакку
цIцIон<n><obl><super><essive>:цIцIонъа
цIцIон<n><obl><super><lative>:цIцIонъо
```

## Изменения в морфотактике, или элизия в `twol`[^2]

[^2]: Ник в последний момент пришел и помог с этой частью. Ура!

С прошлого раза у нас осталась проблема, заключающаяся в том, что в формах элатива оставался тэг эссива:

```
берка<n><obl><super><essive><elative>:беркуъакку
берка<n><obl><sub><essive><elative>:беркулIикку
```

Хотелось бы тег `<essive>` удалить. Это тоже можно решить при помощи отдельного `.twol` файла, который будет разбираться с морфотактикой (файл называется `and.morphotactics.twol`):


```
Alphabet %<essive%> %<essive%>:0 %<elative%> ;

Rules

"drop <essive> before <elative>"
%<essive%>:0 <=> _ %<elative%> ;
```

Мы его тоже можем скомпилировать в трансдьюсер 


```bash
$ hfst-twolc and.morphotactics.twol -o and.morphotactics.twol.hfst
```

```
Reading input from and.morphotactics.twol.
Writing output to and.morphotactics.twol.hfst.
Reading alphabet.
Reading rules and compiling their contexts and centers.
Compiling rules.
Storing rules.
```

```bash
$ hfst-invert and.lexd.hfst | hfst-compose-intersect - and.morphotactics.twol.hfst | hfst-invert -o and.morphotactics.hfst
```

```
hfst-compose-intersect: warning: 
Found output multi-char symbols ("<n>") in 
transducer in file - which are not found on the
input tapes of transducers in file and.morphotactics.twol.hfst.
```

```bash
$ hfst-compose-intersect and.morphotactics.hfst and.twol.hfst -o and.generator.hfst
```

```bash
$ hfst-fst2strings and.generator.hfst
```

```
берка<n><abs><com>:беркалой
берка<n><obl><sub><elative>:беркулIикку
берка<n><obl><sub><essive>:беркулIи
берка<n><obl><sub><lative>:беркулIи
берка<n><obl><erg>:беркуди
берка<n><obl><ins>:беркухъи
берка<n><obl><super><elative>:беркуъакку
берка<n><obl><super><essive>:беркуъа
берка<n><obl><super><lative>:беркуъо
цIцIон<n><abs><com>:цIцIонной
цIцIон<n><obl><sub><elative>:цIцIонлIикку
цIцIон<n><obl><sub><essive>:цIцIонлIи
цIцIон<n><obl><sub><lative>:цIцIонлIи
цIцIон<n><obl><erg>:цIцIонди
цIцIон<n><obl><ins>:цIцIонхъи
цIцIон<n><obl><super><elative>:цIцIонъакку
цIцIон<n><obl><super><essive>:цIцIонъа
цIцIон<n><obl><super><lative>:цIцIонъо
```

## `Makefile`

Все пройденное можно соединить в одном `Makefile`:


```bash
$ sed -n -e 1,16p -e 31,39p Makefile
```

```
.DEFAULT_GOAL := and.analizer.hfst

# generate analizer and generator
and.analizer.hfst: and.generator.hfst
	hfst-invert $< -o $@
and.generator.hfst: and.morphotactics.hfst and.twol.hfst
	hfst-compose-intersect $^ -o $@
and.morphotactics.hfst: and.lexd.hfst and.morphotactics.twol.hfst
	hfst-invert $< | hfst-compose-intersect - and.morphotactics.twol.hfst | hfst-invert -o $@
and.lexd.hfst: and.lexd
	lexd $< | hfst-txt2fst -o $@
and.twol.hfst: and.twol
	hfst-twolc $< -o $@
and.morphotactics.twol.hfst: and.morphotactics.twol
	hfst-twolc $< -o $@

# creat and apply tests
test.pass.txt: tests.csv
	awk -F, '$$3 == "pass" {print $$1 ":" $$2}' $^ | sort -u > $@
check: and.generator.hfst test.pass.txt
	bash compare.sh $< test.pass.txt

# cleans files created during the check
test.clean: check
	rm test.*
```

# Транслитерация

Как и в любой правиловой транслитерации нам нужен файл соответствий (`correspondence`):


```
a:а
b:б
d:д
e:е
i:и
j:й
k:к
kː:кк
l:л
n:н
o:о
qχ:хъ
r:р
tɬ:лI
tsː:цIцI
u:у
ʔ:ъ
```

Мы его можем превратить в трансдьюссер `correspondence.hfst`:


```bash
$ hfst-strings2fst -j correspondence -o correspondence.hfst
```

Пока мы можем его посмотреть, но он не отличается от нашего файла:


```bash
$ hfst-fst2strings correspondence.hfst
```

```
a:а
b:б
d:д
e:е
i:и
j:й
k:к
kː:кк
l:л
n:н
o:о
qχ:хъ
r:р
tɬ:лI
tsː:цIцI
u:у
ʔ:ъ
```

Мы можем даже его применить, но только к символам из нашей таблицы соответствий:


```bash
$ echo "b" | hfst-lookup correspondence.hfst
```

```
hfst-lookup: warning: It is not possible to perform fast lookups with OpenFST, std arc, tropical semiring format automata.
Using HFST basic transducer format and performing slow lookups
> b	б	0,000000

> 
```


```bash
$ echo "tɬ" | hfst-lookup correspondence.hfst
```

```
hfst-lookup: warning: It is not possible to perform fast lookups with OpenFST, std arc, tropical semiring format automata.
Using HFST basic transducer format and performing slow lookups
> tɬ	лI	0,000000

> 
```

Т. е. текст он пока не транслитерирует:

```bash
$ echo "berka" | hfst-lookup correspondence.hfst
```

```
hfst-lookup: warning: It is not possible to perform fast lookups with OpenFST, std arc, tropical semiring format automata.
Using HFST basic transducer format and performing slow lookups
> berka	berka+?	inf

> 
```

Чтобы построить транслитератор, нам нужно, чтобы наш трансдьюсер, применяя список соответствий, зациклился:


```bash
$ hfst-repeat -f 1 correspondence.hfst -o la2cy.transliterater.hfst
```

Теперь мы построили транслитератор `la2cy.transliterater.hfst`:


```bash
$ echo "berkutɬi" | hfst-lookup la2cy.transliterater.hfst
```

```
hfst-lookup: warning: It is not possible to perform fast lookups with OpenFST, std arc, tropical semiring format automata.
Using HFST basic transducer format and performing slow lookups
> berkutɬi	беркулIи	0,000000

> 
```

## Объединение с морфологическими анализаторами

Как и в случае с парой анализатор-генератор, мы можем инвертировать наш транслитератор, чтобы получить транслитератор, который транслитерирует из кириллицы в латиницу:


```bash
$ hfst-invert la2cy.transliterater.hfst -o cy2la.transliterater.hfst
```


```bash
$ echo "беркулIи" | hfst-lookup cy2la.transliterater.hfst
```

```
hfst-lookup: warning: It is not possible to perform fast lookups with OpenFST, std arc, tropical semiring format automata.
Using HFST basic transducer format and performing slow lookups
> беркулIи	berkutɬi	0,000000

> 
```

Если в прошлые разы мы строили морфологические анализаторы, которые работали с кириллицей, то теперь мы можем соединить их с нашими транслитераторами:




```bash
$ hfst-compose and.generator.hfst cy2la.transliterater.hfst -o and.generator.tr.hfst
```

Что получилось:

```bash
$ hfst-fst2strings and.generator.tr.hfst
```

```
берка<n><abs><com>:berkaloj
берка<n><obl><sub><elative>:berkutɬikku
берка<n><obl><sub><elative>:berkutɬikːu
берка<n><obl><sub><essive>:berkutɬi
берка<n><obl><sub><lative>:berkutɬi
берка<n><obl><erg>:berkudi
берка<n><obl><ins>:berkuqχi
берка<n><obl><super><elative>:berkuʔakku
берка<n><obl><super><elative>:berkuʔakːu
берка<n><obl><super><essive>:berkuʔa
берка<n><obl><super><lative>:berkuʔo
цIцIон<n><abs><com>:tsːonnoj
цIцIон<n><obl><sub><elative>:tsːontɬikku
цIцIон<n><obl><sub><elative>:tsːontɬikːu
цIцIон<n><obl><sub><essive>:tsːontɬi
цIцIон<n><obl><sub><lative>:tsːontɬi
цIцIон<n><obl><erg>:tsːondi
цIцIон<n><obl><ins>:tsːonqχi
цIцIон<n><obl><super><elative>:tsːonʔakku
цIцIон<n><obl><super><elative>:tsːonʔakːu
цIцIон<n><obl><super><essive>:tsːonʔa
цIцIон<n><obl><super><lative>:tsːonʔo
```

Можем перевернуть и сделать анализатор:


```bash
$ hfst-invert and.generator.tr.hfst -o and.analizer.tr.hfst
```

Результат:

```bash
$ hfst-fst2strings and.analizer.tr.hfst
```

```
berkaloj:берка<n><abs><com>
berkutɬikku:берка<n><obl><sub><elative>
berkutɬikːu:берка<n><obl><sub><elative>
berkutɬi:берка<n><obl><sub><essive>
berkutɬi:берка<n><obl><sub><lative>
berkudi:берка<n><obl><erg>
berkuqχi:берка<n><obl><ins>
berkuʔakku:берка<n><obl><super><elative>
berkuʔakːu:берка<n><obl><super><elative>
berkuʔa:берка<n><obl><super><essive>
berkuʔo:берка<n><obl><super><lative>
tsːonnoj:цIцIон<n><abs><com>
tsːontɬikku:цIцIон<n><obl><sub><elative>
tsːontɬikːu:цIцIон<n><obl><sub><elative>
tsːontɬi:цIцIон<n><obl><sub><essive>
tsːontɬi:цIцIон<n><obl><sub><lative>
tsːondi:цIцIон<n><obl><erg>
tsːonqχi:цIцIон<n><obl><ins>
tsːonʔakku:цIцIон<n><obl><super><elative>
tsːonʔakːu:цIцIон<n><obl><super><elative>
tsːonʔa:цIцIон<n><obl><super><essive>
tsːonʔo:цIцIон<n><obl><super><lative>
```

Теперь можно суммировать все изученное в одном `Makefile`:


```
.DEFAULT_GOAL := and.analizer.hfst

# generate analizer and generator
and.analizer.hfst: and.generator.hfst
	hfst-invert $< -o $@
and.generator.hfst: and.morphotactics.hfst and.twol.hfst
	hfst-compose-intersect $^ -o $@
and.morphotactics.hfst: and.lexd.hfst and.morphotactics.twol.hfst
	hfst-invert $< | hfst-compose-intersect - and.morphotactics.twol.hfst | hfst-invert -o $@
and.lexd.hfst: and.lexd
	lexd $< | hfst-txt2fst -o $@
and.twol.hfst: and.twol
	hfst-twolc $< -o $@
and.morphotactics.twol.hfst: and.morphotactics.twol
	hfst-twolc $< -o $@

# generate transliteraters
cy2la.transliterater.hfst: la2cy.transliterater.hfst
	hfst-invert $< -o $@
la2cy.transliterater.hfst: correspondence.hfst
	hfst-repeat -f 1 $< -o $@
correspondence.hfst: correspondence
	hfst-strings2fst -j correspondence -o $@

# generate analizer and generator for transcription
and.analizer.tr.hfst: and.generator.tr.hfst
	hfst-invert $< -o $@
and.generator.tr.hfst: and.generator.hfst cy2la.transliterater.hfst
	hfst-compose $^ -o $@

# creat and apply tests
test.pass.txt: tests.csv
	awk -F, '$$3 == "pass" {print $$1 ":" $$2}' $^ | sort -u > $@
check: and.generator.hfst test.pass.txt
	bash compare.sh $< test.pass.txt

# cleans files created during the check
test.clean: check
	rm test.*

# remove all hfst files
clean:
	rm *.hfst
```

## Сложности

Пока мне придумалось лишь несколько сложностей (вполне преодолимых, как мне кажется):

* при введение инородного символа все ломается (хотелось бы, чтобы появлялся какой-то символ обозначающий поломку):


```bash
$ echo "бяркулIи" | hfst-lookup cy2la.transliterater.hfst
```

```
hfst-lookup: warning: It is not possible to perform fast lookups with OpenFST, std arc, tropical semiring format automata.
Using HFST basic transducer format and performing slow lookups
> бяркулIи	бяркулIи+?	inf

> 
```

* case sensitivity


```bash
$ echo "БЕркулIи" | hfst-lookup cy2la.transliterater.hfst
```

```
hfst-lookup: warning: It is not possible to perform fast lookups with OpenFST, std arc, tropical semiring format automata.
Using HFST basic transducer format and performing slow lookups
> БЕркулIи	БЕркулIи+?	inf

> 
```

* перегенерация

```
берка<n><obl><sub><essive><elative>:berkutɬikku
берка<n><obl><sub><essive><elative>:berkutɬikːu
```

* учет контекста

В некоторых орфографиях графема обозначает одно в одном контексте и другое в другом (например /ё/ в ***ё**ж* и *Л**ё**ва*). Хотелось бы, чтобы этот контест можно было бы прописывать без использования `twolc` :)
