.DEFAULT_GOAL := and.analizer.hfst

# generate analizer and generator
and.analizer.hfst: and.generator.hfst
	hfst-invert $< -o $@
and.generator.hfst: and.lexd
	lexd $< | hfst-txt2fst -o $@

# generate transliteraters
cy2la.transliterater.hfst: la2cy.transliterater.hfst
	hfst-invert $< -o $@
la2cy.transliterater.hfst: correspondence correspondence.hfst
	sed 's/$$/	1/g' $< | hfst-strings2fst -j | hfst-repeat | hfst-concatenate correspondence.hfst - -o $@
correspondence.hfst: correspondence
	sed 's/$$/	1/g' $< | hfst-strings2fst -j -o $@

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
