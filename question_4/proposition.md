# Proposition de protocole de sexage à haut débit

En regardant les figures générées à la question 3 on peut faire ces deux constats : 

- Il ne semble pas y avoir de différence importante dans l'expression de FT1 entre les mâles et les femelles. 
- Il semble y avoir une différence d'expression du gène REM16 entre les mâles et les femelles. 

Dans ce contexte, il semble que REM16 est un meilleur candidat pour sexer à haut débit les plants de cannabis. 

Dans le graphique généré, on observe que les plants femelles expriment de manière plus importante le gène REM16 alors que les plants mâles expriment de manière beaucoup moins importante ce gène.

Devant cette observation, il serait pertinent d'analyser plus en profondeur les données d'expression issues du fichier `files/2_Data_RNASeq_Cannabis_Sex.csv` afin d'établir une valeur seuil d'expression du gène REM16.

Si les données d'expression d'un plant dont le sexe est inconnu est au-dessus de ce seuil, on considererait que le plant est femelle et si la valeur d'expression est en dessous de ce seuil, on pourrait considérer que le plant est mâle. 

L'expérience pourrait prendre la forme d'une qPCR permettant, à partir d'une petite quantité de tissus, de quantifier l'expression de REM16. 