
CC=g++
WARNINGS = -Wall -W -Wformat-nonliteral -Wcast-align -Wpointer-arith \
	-Wmissing-declarations -Winline -Wundef -Wcast-qual \
	-Wshadow -Wwrite-strings -Wno-unused-parameter -Wfloat-equal -pedantic -ansi
CFLAGS=-c $(WARNINGS) -std=c++11
OBJECTS=$(SOURCES:.cpp=.o)
EXECUTABLE=sched-builder
SOURCES=main.cpp sched-builder.cpp
LDFLAGS=

# Targets
# ===============================================================================
all: $(SOURCES) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm *.o $(EXECUTABLE)

test: all
	./$(EXECUTABLE)
