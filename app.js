// app.js
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const cors = require('cors');
const path = require('path');
const cookieParser = require('cookie-parser');
const { v4: uuidv4 } = require('uuid');
const multer = require('multer');

const app = express();
const PORT = 3000;

// Кеширование (опционально)
const NodeCache = require('node-cache');
const jokeCache = new NodeCache({ stdTTL: 300 });

// Multer для загрузки файлов
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'public/uploads'),
  filename: (req, file, cb) => {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1e9) + path.extname(file.originalname);
    cb(null, unique);
  }
});
// Убедимся, что папка для загрузки существует
const uploadsPath = path.join(__dirname, 'public', 'uploads');
if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath, { recursive: true });
}

const upload = multer({ storage });

// Middleware
app.use(cors({ credentials: true, origin: true }));
app.use(bodyParser.json());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Генерация userId через куки
app.use((req, res, next) => {
  if (!req.cookies.userId) {
    res.cookie('userId', uuidv4(), {
      maxAge: 30 * 24 * 60 * 60 * 1000,
      httpOnly: true
    });
  }
  next();
});

// Работа с файлами
const loadJokes = () => {
  try {
    return JSON.parse(fs.readFileSync('jokes.json', 'utf8'));
  } catch {
    return [];
  }
};

const saveJokes = (jokes) => {
  fs.writeFileSync('jokes.json', JSON.stringify(jokes, null, 2));
};

// Загрузка файла
app.post('/api/upload', upload.single('video'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Файл не загружен' });
  res.json({ url: `/uploads/${req.file.filename}` });
});

// Получение шуток с фильтрами и пагинацией
app.get('/api/jokes', (req, res) => {
  const cacheKey = JSON.stringify(req.query) + req.cookies.userId;
  if (jokeCache.has(cacheKey)) return res.json(jokeCache.get(cacheKey));

  let jokes = loadJokes();
  const { sort, mediaOnly, search, page = 1, limit = 10, category, tag } = req.query;
  const userId = req.cookies.userId;

  if (mediaOnly === 'true') jokes = jokes.filter(j => j.media);
  if (search) jokes = jokes.filter(j => j.text.toLowerCase().includes(search.toLowerCase()));
  if (category) jokes = jokes.filter(j => j.categories?.includes(category));
  if (tag) jokes = jokes.filter(j => j.tags?.includes(tag));

  switch (sort) {
    case 'popular':
      jokes.sort((a, b) => (b.likes - b.dislikes) - (a.likes - a.dislikes));
      break;
    case 'controversial':
      jokes.sort((a, b) => (b.likes + b.dislikes) - (a.likes + a.dislikes));
      break;
    default:
      jokes.sort((a, b) => b.id - a.id);
  }

  const paginated = jokes.slice((page - 1) * limit, page * limit).map(j => ({
    ...j,
    userVote: j.votes?.[userId] || null,
  }));

  jokeCache.set(cacheKey, paginated);
  res.json(paginated);
});

// Добавление шутки
app.post('/api/jokes', (req, res) => {
  const jokes = loadJokes();
  const newJoke = {
    id: Date.now(),
    text: req.body.text,
    media: req.body.media || null,
    date: new Date().toISOString(),
    likes: 0,
    dislikes: 0,
    votes: {},
    categories: req.body.categories || [],
    tags: req.body.tags || [],
    comments: []
  };
  jokes.unshift(newJoke);
  saveJokes(jokes);
  jokeCache.flushAll();
  res.status(201).json(newJoke);
});

// Голосование
app.post('/api/jokes/:id/vote', (req, res) => {
  const jokes = loadJokes();
  const joke = jokes.find(j => j.id === parseInt(req.params.id));
  const userId = req.cookies.userId;
  const { voteType } = req.body;

  if (!joke || !userId) return res.status(400).json({ error: 'Ошибка голосования' });

  const currentVote = joke.votes[userId];
  let newVote = null;

  if (currentVote) {
    joke[currentVote + 's']--;
    delete joke.votes[userId];
  }

  if (voteType && voteType !== currentVote) {
    joke.votes[userId] = voteType;
    joke[voteType + 's']++;
    newVote = voteType;
  }

  saveJokes(jokes);
  jokeCache.flushAll();

  res.json({
    likes: joke.likes,
    dislikes: joke.dislikes,
    userVote: newVote
  });
});

// Комментарии
app.post('/api/jokes/:id/comments', (req, res) => {
  const jokes = loadJokes();
  const joke = jokes.find(j => j.id === parseInt(req.params.id));
  if (!joke) return res.status(404).json({ error: 'Шутка не найдена' });

  const newComment = {
    id: Date.now(),
    userId: req.cookies.userId,
    text: req.body.text,
    date: new Date().toISOString()
  };

  joke.comments.push(newComment);
  saveJokes(jokes);
  jokeCache.flushAll();
  res.status(201).json(newComment);
});

// Категории
app.get('/api/categories', (req, res) => {
  const jokes = loadJokes();
  const categories = [...new Set(jokes.flatMap(j => j.categories || []))];
  res.json(categories);
});

// Запуск сервера
app.listen(PORT, () => console.log(`🚀 Сервер запущен: http://localhost:${PORT}`));
