@echo off
echo ===================================================
echo   Smart Business Analytics - Advanced AI Backend   
echo ===================================================
echo.
echo To run the server with the Gemini LLM integration, set your key first:
echo   set GEMINI_API_KEY=your_gemini_api_key
echo.
echo If no key is set, the server automatically falls back to the
echo advanced mathematical forecasting & negation-aware NLP sentiment engine.
echo.
echo Starting Express server on port 3000...
node ai_backend/index.js
pause
