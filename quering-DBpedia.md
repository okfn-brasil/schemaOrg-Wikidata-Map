

## Wikimedia / DBpedia properties 

PREFIX       owl:  <http://www.w3.org/2002/07/owl#>
PREFIX      rdfs:  <http://www.w3.org/2000/01/rdf-schema#>

SELECT Distinct ?WikidataProp ?DBpediaProp  
WHERE
  {
    ?DBpediaProp  owl:equivalentProperty  ?WikidataProp .
                  FILTER ( CONTAINS ( str(?WikidataProp) , 'wikidata' ) ) .
 
  }
ORDER BY  ?DBpediaProp
