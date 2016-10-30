This wikipage is for *[issue-280](https://github.com/schemaorg/schemaorg/issues/280)'s working group* subsidy and reference.  See  also [Wikidata's Guidelines for external relationships](https://www.wikidata.org/wiki/Help:Statements/Guidelines_for_external_relationships#schema_case).

-----

The issue 280 started with the title's suggestion, *"Schema.org should have mappings to Wikidata terms where possible"*, but the simplest and collaborative way is to feed Wikidata: these are [the basic @thadguidry  rules](https://github.com/schemaorg/schemaorg/issues/280#issuecomment-226664317) to accomplish the task at Wikidata editions,

* Schema.org *types* mapped using [(external) *Equivalent Class* (P1709)](https://www.wikidata.org/wiki/Property:P1709);
* Schema.org *properties* mapped using [(external) *Equivalent Property* (P1628)](https://www.wikidata.org/wiki/Property:P1628);
* When there's no equivalent but there is a sub/super available, then it (Schema.org *properties* or *types*) will be mapped using:
  * [(external) *Super-property* (P2235)](https://www.wikidata.org/wiki/Property:P2235);
  * [(external) *Sub-property* (P2236)](https://www.wikidata.org/wiki/Property:P2236).

-----

Now, to get back the information, we need  ["figure out the SPARQL for query.wikidata.org that would extract these mappings"](https://github.com/schemaorg/schemaorg/issues/280#issuecomment-226857863), as @danbri  suggested.

## Quering and exporting

Test results at query.wikidata.org

### Simplest test
The "wanted universe" is  provided by  a simple query, and perhaps works fine for a local Wikidata user (at the [query.wikidata.org](https://query.wikidata.org)'s server without *timeout* restrictions), is like
```sparql
SELECT * WHERE {
  ?x ?eqv ?s . 
  FILTER (?eqv = wdt:P1709 || ?eqv = wdt:P1628 || ?eqv = wdt:P2235) .
  FILTER (?s = schema:Person)
}
```
Instead `FILTER (?s = schema:Person)`, need a  kind of  prefixed wildcard (imagine `schema:*`)... Using  regex, for example `FILTER( REGEX(STR(?s), "schema.org") )`, it  produces an  error,  *"Query deadline is expired"*, even when using `LIMIT 1`  clause.

A workaround is to use "less generic" quering... It works fine!
```sparql
SELECT * WHERE {  
       {?p wdt:P2235 ?s.}
       UNION { ?p wdt:P2236 ?s. }
       UNION { ?p wdt:P1628 ?s. }
       UNION { ?p wdt:P1709 ?s. }
       FILTER( REGEX(STR(?s), "schema.org") )
}
```
Add  `. FILTER( REGEX(STR(?x), "Q") )` (or `"P"`) to list only Wikidata-entities or only Wikidata-properties. 

### Standard sparql query
The @thadguidry  solution  to get relationship information (equivclass, equivprop, sub  or super) is the "standard query" for
export result to other algorithms, databases or spreadsheets.

```sparql
SELECT ?pLabel ?p ?equivclass ?equivprop ?sub ?super  
WHERE {
  { ?p wdt:P2235 ?super. }
  UNION
  { ?p wdt:P2236 ?sub. }
  UNION
  { ?p wdt:P1628 ?equivprop. }
  UNION
  { ?p wdt:P1709 ?equivclass. }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
  FILTER(
    (REGEX(STR(?equivprop), "schema.org")) 
    || (REGEX(STR(?sub), "schema.org")) 
    || (REGEX(STR(?super), "schema.org")) 
    || (REGEX(STR(?equivclass), "schema.org"))
  )
}
```

## Standard SQL analysis

After download as CSV (as file [`wd2schema-raw.csv`](data/wd2schema-raw.csv)), produce a standard SQL table to manipulate data... We can use a script with absolute path "COPY table FROM '/tmp/file.csv'", any other have permission problems... To avoid both, split in three-line command with two SQL scripts ([step01](src/step01.sql) and [step02](src/step02.sql)),

```sh
 psql -h localhost -U postgres postgres < step01.sql 

 cat data/wd2schema-raw.csv | psql -h localhost -U postgres postgres -c "COPY wd2schema_std_temp FROM STDIN CSV HEADER"

 psql -h localhost -U postgres postgres < step02.sql 

 psql -h localhost -U postgres postgres -c "
  COPY (SELECT * FROM wd2schema_std ORDER BY sch_id,reltype) TO STDOUT WITH CSV HEADER
 " > data/wd2schema-std.csv
```

So, as input we have [`wd2schema-raw.csv`](data/wd2schema-raw.csv) and as output  [`wd2schema-std.csv`](data/wd2schema-std.csv), and the SQL database with the same data to perform queries. 

### Summarizations

```sql
SELECT count(*) as n_tot FROM wd2schema_std;

-- summarize reltypes
SELECT reltype, count(*) as n  FROM wd2schema_std
GROUP BY 1 ORDER BY 1;

-- summarize reltypes and pure_prop
WITH t AS (
  SELECT *, (rel_isprop AND sch_isprop AND wd_isprop) as pure_prop
  FROM vw_wd2schema_std
) SELECT reltype, pure_prop, count(*) as n
  FROM t GROUP BY 1,2 ORDER BY 1,2;

-- summarize plabel that repeat
SELECT wd_label, count(*) as n FROM wd2schema_std
GROUP BY 1  HAVING count(*)>1
ORDER BY 2 DESC, 1;

-- summarize schemaOrg name that repeat
SELECT sch_id, count(*) as n FROM wd2schema_std
GROUP BY 1  HAVING count(*)>1
ORDER BY 2 DESC, 1;
```
### Results in 2016-06

* `n_tot` = 156
* repeated `wd_label`: location (13), image (3), audience (2), author (2), brand (2), ..., Uniform Resource Locator (2). Only 12 (8%).
*  reltypes:

|  reltype   | n  |
|------------|----|
equivclass | 68
equivprop  | 66
sub        | 12
super      | 10

### Results in 2016-08
* `n_tot` = 182
* repeated `wd_label`: location (13), brand (3), image (3), volume (3), author (2), child (2), director (2) ...
* repeated `wd_id`:  P276 (13), P40 (2), P433 (2), P478 (2), Q1656682 (2), Q42253 (2), Q431289 (2), Q478798 (2). 
* repeated `sch_id`: deathPlace (3), name (3), actor (2), author (2), birthDate (2), birthPlace (2), brand (2), ... 
*  reltypes:

|  reltype   | n  |
|------------|----|
equivclass | 80
pure equivprop | 63
equivprop  | 15
sub        | 12
super      | 12
