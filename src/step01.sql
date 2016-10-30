DROP TABLE IF EXISTS wd2schema_std CASCADE;

CREATE TABLE  IF NOT EXISTS wd2schema_std_temp (
	pLabel text, p text,
	equivclass text, equivprop text, sub text, super text
);
