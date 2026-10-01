# HomeHarvest-AI

HomeHarvest AI provides an intelligent solution by allowing users to upload fruits and vegetables plant images for AI-based disease detection. The application identifies whether a plant is healthy or diseased, recommends suitable organic or chemical treatments, provides preventive care tips, and allows users to purchase recommended products through an integrated e-commerce system. An AI chatbot further assists users by answering plant care and gardening-related questions.

## Backend Configuration

Set these environment variables before starting `app.py`:

- `STRIPE_SECRET_KEY` and `GROQ_API_KEY` for payments and chatbot requests.
- `EMAIL_ADDRESS` and `EMAIL_PASSWORD` for order emails.
- `DB_PASSWORD` for the MySQL account. `DB_HOST`, `DB_USER`, and `DB_NAME` are optional; they default to `localhost`, `root`, and `homeharvest`.
- `GROQ_MODEL` is optional and defaults to `llama-3.3-70b-versatile`.
