TOP=../../..
include $(TOP)/mk/boilerplate.mk
include $(TOP)/mk/test.mk

# Recompilation tests

clean:
	rm -f *.o *.hi
	rm -f A.hsinc B.hsinc
	rm -f Main$(exeext)

recomp011: clean
	echo "main = putStrLn x" >A.hsinc
	echo "x = show 42" >B.hsinc
	'$(TEST_HC)' $(TEST_HC_OPTS) --make -O Main.hs
	./Main
	sleep 1
	echo "x = show 43" >B.hsinc
	'$(TEST_HC)' $(TEST_HC_OPTS) --make -O Main.hs
	./Main
	sleep 1
	echo "main = putStrLn (x ++ x)" >A.hsinc
	'$(TEST_HC)' $(TEST_HC_OPTS) --make -O Main.hs
	sleep 1
	./Main
	'$(TEST_HC)' $(TEST_HC_OPTS) --make -O Main.hs
	# don't change anything; check that no compilation happened
	./Main
