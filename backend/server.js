const express = require("express");
const mysql = require("mysql2");
const bodyParser = require("body-parser");
const jwt = require("jsonwebtoken");
// const http = require("http");
// const WebSocket = require("ws");
const socketIO = require("socket.io");
const cors = require("cors");
const { start } = require("repl");
// const server_app = express();
const app = express();

const server = require("http").createServer(app);
// const wss = new WebSocket.Server({ server });
var io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    allowedHeaders: ["Authorization", "Content-Type"],
    credentials: true,
  },
});

app.use(cors());
app.use(bodyParser.json());



const db = mysql.createConnection({
  host: "localhost",
  user: "myuser",
  password: "mypassword",
  database: "kidsens_user",
});

db.connect((err) => {
  if (err) {
    throw err;
  }
  console.log("MySQL Connected...");
});

const SECRET_KEY = "mysecretkey";
const clients = new Map();

app.post("/signup", async (req, res) => {
  const { username, password } = req.body;
  // const hashedPassword = await bcrypt.hash(password, 10);
  if (username != undefined && password != undefined) {
    const query =
      "INSERT INTO users (username, password) VALUES" +
      " ('" +
      username +
      "', '" +
      password +
      "')";
    console.log(query);
    db.query(query, [username, password], (err, result) => {
      if (err) {
        if (err.code === "ER_DUP_ENTRY") {
          res.status(400).send("Username already exists");
          console.log("Username already exists");
        } else {
          res.status(500).send("Error on the server.");
          console.log("Error on the server.");
        }
      } else {
        res.status(201).send("User registered");
        console.log("User registered");
      }
    });
  }
});

// Login Route (GET method)
app.get("/login", (req, res) => {
  const { username, password } = req.query;
  const query = "SELECT * FROM users WHERE username = '" + username + "'";
  db.query(query, [username], async (err, result) => {
    // console.log(err);
    // console.log(result);
    if (err) {
      res.status(500).send("Error on the server.");
    } else if (result.length === 0) {
      res.status(401).send("Invalid credentials");
    } else {
      const user = result[0];

      if (user.password === password) {
        const token = jwt.sign({ username: user.username }, SECRET_KEY, {
          expiresIn: "1h",
        });
        res.status(200).json({ token: token });
      } else {
        res.status(401).send("Invalid credentials");
      }
    }
  });
});

const verifyToken = (req, res, next) => {
  const token = req.headers["authorization"];
  if (!token) {
    return res.status(403).send("A token is required for authentication");
  }
  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    req.user = decoded;
  } catch (err) {
    return res.status(401).send("Invalid Token");
  }
  return next();
};

// Start Eating Route
app.post("/start-eating", verifyToken, (req, res) => {
  const username = req.user.username;
  const startTime = req.body.start_time;
  // console.log(startTime);
  const query =
    "INSERT INTO eating_sessions (username, start_time) VALUES (?, ?);";
  db.query(query, [username, startTime], (err, result) => {
    // get result as id of the database where it got inserted
    // console.log(result);

    if (err) {
      res.status(500).send("Error on the server.");
    } else {
      // console.log(fields)
      console.log(result.insertId);
      broadcastSessions(username);
      res.status(200).json({
        'id': result.insertId,
    });
    }
  });
});

// Stop Eating Route
app.post("/stop-eating", verifyToken, (req, res) => {
  const username = req.user.username;
  let { time_taken, id } = req.body;
  // console.log(start_time);
  // console.log(typeof(start_time));
  // start_time = new Date(start_time);
  // // console.log(start_time);
  // // console.log(start_time);
  // const year = start_time.getFullYear();
  // const month = String(start_time.getMonth() + 1).padStart(2, "0");
  // const day = String(start_time.getDate()).padStart(2, "0");
  // const hours = String(start_time.getHours()).padStart(2, "0");
  // const minutes = String(start_time.getMinutes()).padStart(2, "0");
  // const seconds = String(start_time.getSeconds()).padStart(2, "0");

  // const mysqlStartTime = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  // // console.log(mysqlStartTime);
  const query =
    "UPDATE eating_sessions SET time_taken = ? WHERE username = ? AND id = ?";
  db.query(query, [time_taken, username, id], (err, result) => {
    if (err) {
      console.log(err);
      res.status(500).send("Error on the server.");
    } else {
      // console.log(fields);
      // console.log(result);
      broadcastSessions(username);
      res.status(200).send("Eating session stopped");
    }
  });
});

app.get("/eating-sessions", verifyToken, (req, res) => {
  const username = req.user.username;

  const query =
    "SELECT start_time, time_taken FROM eating_sessions WHERE username = ? ORDER BY start_time DESC";
  db.query(query, [username], (err, results) => {
    if (err) {
      res.status(500).send("Error on the server.");
    } else {
      // console.log(results);
      res.status(200).json(results);
    }
  });
});

const broadcastSessions = (username) => {
  const query =
    "SELECT start_time, time_taken FROM eating_sessions WHERE username = ? ORDER BY start_time DESC";
  db.query(query, [username], (err, results) => {
    if (err) {
      console.error("Error broadcasting sessions:", err);
    } else {
      const data = JSON.stringify(results);
      // console.log(results);
      // console.log(typeof(results[1].start_time));
      // console.log(data);
      const socketId = clients.get(username);
      console.log(data)
      // console.log(socketId);
      if (socketId) {
        io.to(socketId).emit("eating_sessions", data);
      }
    }
  });
};

// wss.on('connection', (ws, req) => {
//   const token = req.url.split('token=')[1];
//   if (token) {
//     try {
//       const decoded = jwt.verify(token, SECRET_KEY);
//       const username = decoded.username;
//       clients.set(username, ws);
//       console.log(`Client ${username} connected`);
//       ws.on('close', () => {
//         clients.delete(username);
//         console.log(`Client ${username} disconnected`);
//       });
//     } catch (err) {
//       ws.close();
//     }
//   } else {
//     ws.close();
//   }
// });
io.on("connection", (socket) => {
  console.log("New client connected");
  // console.log(socket)

  socket.on("register", (token) => {
    try {
      const decoded = jwt.verify(token, SECRET_KEY);
      // console.log(decoded)
      const username = decoded.username;
      clients.set(username, socket.id);
      console.log(`Client ${username} connected with socket ID ${socket.id}`);
      socket.on("disconnect", () => {
        clients.delete(username);
        console.log(`Client ${username} disconnected`);
      });
    } catch (err) {
      console.log("Invalid token");
      socket.disconnect();
    }
  });

  socket.on("eating_sessions", (_) => {
    const username = data.username;
    broadcastSessions(username);
  })

  socket.on("eating_sessions", (_) => {
    broadcastSessions(username);
  });

 
});

server.listen(5501, () => {
  console.log("Server started on port 5500");
});
// app.listen(5501, () => {
//   console.log("Socket started on port 5501");
// });
