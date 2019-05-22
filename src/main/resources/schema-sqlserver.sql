IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE NAME='pet' and XTYPE='U')
  CREATE TABLE pet (
    id      INT           IDENTITY  PRIMARY KEY,
    name    VARCHAR(255),
    species VARCHAR(255)
  );

/*
SELECT * FROM pet;
INSERT into pet (name, species) VALUES ('Cat', 'Mammal')
INSERT into pet VALUES ('Maus', 'Mammal')
SELECT * FROM pet;
*/
