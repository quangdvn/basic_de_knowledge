-- Build a graph
-- Which players played with each other
-- Which players belonged to which team, at which time
CREATE TYPE vertex_type 
  AS ENUM('player', 'team', 'game') 
  
create type edge_type
  as enum('plays_against', 
          'shares_team', 
          'plays_in',
          'plays_on'
          )

CREATE TABLE vertices (
    identifier TEXT,
    type vertex_type,
    properties JSON,
    PRIMARY KEY (identifier, type)
);

create table edges(
	subject_identifier text,
	subject_type vertex_type,
	object_identifier text,
	object_type vertex_type,
	edge_type edge_type,
	properties JSON,
	primary key (subject_identifier,
				subject_type,
				object_identifier,
				object_type,
				edge_type)
);