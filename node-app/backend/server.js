const express = require('express');
const AWS = require('aws-sdk'),
      {
        DynamoDBDocument
      } = require("@aws-sdk/lib-dynamodb"),
      {
        DynamoDB
      } = require("@aws-sdk/client-dynamodb"),
      {
        Upload
      } = require("@aws-sdk/lib-storage"),
      {
        S3
      } = require("@aws-sdk/client-s3");
const bodyParser = require('body-parser');
const fileUpload = require('express-fileupload');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');

const app = express();

app.use(cors());


// // Importiere Terraform-Ausgabevariablen
// const allowedOrigins = [process.env.ALLOWED_ORIGIN]; // Du kannst die Umgebungsvariable ALLOWED_ORIGIN in deinem System festlegen.

// app.use(function(req, res, next) {
//   const origin = req.headers.origin;
//   if (allowedOrigins.includes(origin)) {
//     res.header("Access-Control-Allow-Origin", origin);
//   }
//   res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");



// AWS SDK Konfiguration
AWS.config.update({
  accessKeyId: '*',
  secretAccessKey: '*',
  sessionToken: '*',
  region: 'eu-central-1'
});

const dynamodb = DynamoDBDocument.from(new DynamoDB());
const s3 = new S3();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(fileUpload());

// Route um die Frontend-Datei zu servieren
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Route um Formulardaten zu empfangen und in DynamoDB und S3 zu speichern
app.post('/submit', async (req, res) => {
  const { vorname, nachname, email, kommentar } = req.body;
  const file = req.files.bild;
  const currentDate = new Date().toISOString();
  const fileName = `${vorname}_${currentDate}.jpg`;

 
    // Bild in S3 speichern
    const s3Params = {
      Bucket: 'andykundendaten',
      Key: fileName,
      Body: file.data,
      // ACL: 'public-read'
    };

    await new Upload({
      client: s3,
      params: s3Params
    }).done();

    // Generieren Sie die S3-URL für das hochgeladene Bild
    const s3Url = `https://${s3Params.Bucket}.s3.${AWS.config.region}.amazonaws.com/${encodeURIComponent(s3Params.Key)}`;

    // Daten in DynamoDB speichern
    const params = {
      TableName: 'kundendaten',
      Item: {
        id: uuidv4(),
        vorname,
        nachname,
        email,
        kommentar,
        datum: currentDate,
        bildUrl: s3Url  // Speichern Sie die S3-URL als Bild-URL in DynamoDB
      }
    };

    await dynamodb.put(params, function(err,data){

      if(err){
        console.log("err",err);
        }
      else{
        console.log("data",data)
        }
    });

    res.json({ success: true, message: 'Form submitted successfully' });

});

app.listen(3000, () => {
  console.log('Server is running on http://localhost:3000');
});

module.exports = app;
