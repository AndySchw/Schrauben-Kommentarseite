const express = require("express");
const cors = require("cors");
const multer = require("multer");
const AWS = require('aws-sdk'); // Hinzufügen
const fs = require('fs');

const app = express();
const port = 3000;

app.use(express.static('../frontend'));

const corsOptions = {
  origin: "http://localhost:3000",
};

app.use(cors(corsOptions));

// AWS SDK Konfiguration
AWS.config.update({
  region: "eu-central-1", // Ändern Sie dies nach Bedarf
});

const s3 = new AWS.S3();
const dynamoDb = new AWS.DynamoDB.DocumentClient();

// multer-Konfiguration
const storage = multer.diskStorage({
  destination: "./images/",
  filename: function (request, file, callback) {
    callback(null, Date.now() + "-" + file.originalname);
  },
});

const upload = multer({ storage: storage });

// Route zum Hochladen von Bildern in S3 und Speichern von Formulardaten in DynamoDB
app.post("/", upload.single("avatar"), (request, response) => {
  console.log(request.body, request.file);

  // Bild zu S3 hochladen
  const fileContent = fs.readFileSync(request.file.path);

  const params = {
    Bucket: 'my-unique-bucket-name', // Ändern Sie dies zu Ihrem Bucket-Namen
    Key: `${Date.now()}-${request.file.originalname}`,
    Body: fileContent
  };

  s3.upload(params, function(err, data) {
    if (err) {
      console.error("Fehler beim Hochladen des Bildes:", err);
      return response.status(500).send("Fehler beim Hochladen des Bildes.");
    }

    console.log(`Bild erfolgreich hochgeladen. ${data.Location}`);

    // Formulardaten in DynamoDB speichern
    const formData = {
      TableName: "ContactFormTable", // Ändern Sie dies zu Ihrem Tabellennamen
      Item: {
        id: `${Date.now()}`,
        firstname: request.body.firstname,
        lastname: request.body.lastname,
        email: request.body.email,
        avatar: data.Location,
        spam: request.body.spam === "on"
      }
    };

    dynamoDb.put(formData, function(err, data) {
      if (err) {
        console.error("Fehler beim Speichern der Daten:", err);
        return response.status(500).send("Fehler beim Speichern der Daten.");
      }

      console.log("Formulardaten erfolgreich gespeichert:", data);
      response.json("Vielen Dank!");
    });
  });
});

app.listen(port, () => console.info(`Server läuft auf http://localhost:${port}`));