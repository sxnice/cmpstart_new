#!/bin/bash
		source ~/.bashrc
		mongo <<-EOSQL 
		use collectDataDB;
		db.createUser(
        {
          user: "root",
          pwd: "$1",
          roles: [ { role: "root", db: "admin" } ]
        }
     );
	 db.auth('root','$1');

EOSQL
