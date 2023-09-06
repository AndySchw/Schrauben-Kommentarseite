## Benutzen des Terraform Aufbaus
# Dieser Aufbau, sorgt für eine komplette Infrastrucktur die einem Express node.js server mit ec2 Instancen erstellt. wenn man über den ALB Zugriff auf diese nimmt, kann man dort Daten und ein Bild angeben welche in DynamoDB und S3 abgelegt werden.

Grundvorraussetzung
- AWS Konto
- Terraform auf dem Pc installiert 
- node.js auf dem Pc installiert 

Alles Runterladen
Terminal öffnen 
Credetials/Token von AWS verifizieren
in node-app/backend gehen und npm install durchlaufen !!! Einträge in der server.js ändern auf den eigenen S3 Bucket und DynamoDB Tabelle
dann zurück in das Hauptverzeichniss und `tar -cvf ./node-app/node-app.tar ./node-app` ausführen
das erstellt eine  node-app.tar Datei die in den EC2 Insctancen gebraucht wird für den web server
in der `variablen.tfvars` alles anpassen
Dann mit dem apply Befehl starten oder mit detroy wieder beenden Alle Fragen mit `yes` beantorten 

`terraform apply -var-file="variablen.tfvars` Starten der Terraform Datei zum erstellen
`terraform destroy -var-file="variablen.tfvars` löschen der Infrastrucktur
