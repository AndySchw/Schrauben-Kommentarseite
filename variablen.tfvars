
##### Bitte passen sie alles an um fehler zu vermeiden! Diese Variablen werden in der main.tf genutzt


# Keys für den Zugang in die privaten Instanzen
oeffentlicher_key = "provisioners_key"
privater_key = "C:/Users/andye/Documents/AWS/AndysTestServer/provisioners_key.pem"

# Namen für den DynamoDB und S3 Bucket
# bei Fehlern mit S3 ist die warscheinlichkeit hoch des der Bucket Name bereites exsistert

s3_bucket_kundendaten = "andykundendaten"
s3_bucket_zwischenspeicher = "andyuebergangbucket"

dynamodb = "kundendaten"
