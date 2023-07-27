.PHONY=all clean clean-all docker-compose-up login

all: test

create-env-file-if-needed:
	[ -e "./sqlserverdb.env" ] || echo "Creating env file" && cp sqlserverdb.env.example sqlserverdb.env

clean:
	$(info Clean)
	./run --docker-compose-down

clean-all:
	$(info Clean All)
	./run --clean-all

status:
	$(info Show docker status)
	./run --status

docker-compose-up: create-env-file-if-needed
	$(info Running docker-compose up)
	./run --docker-compose-up

test: docker-compose-up
	$(info Running test scripts on SQL Server)
	./run --run-test-scripts

login:
	$(info Logging into SQL Server)
	./run --login-sql-server
