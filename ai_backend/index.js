const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
let db = null;
try {
  admin.initializeApp({
    projectId: 'smart-app-33082'
  });
  db = admin.firestore();
  console.log('Firebase Admin SDK initialized successfully.');
} catch (e) {
  console.error('Failed to initialize Firebase Admin SDK. Webhook database updates will run in dry-run mode.', e);
}


const app = express();
app.use(cors());
app.use(express.json());

// Log incoming requests
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Initialize Gemini API if API key is provided
let genAI = null;
if (process.env.GEMINI_API_KEY) {
  console.log('Gemini API Key detected. Initializing Generative AI Service...');
  genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
} else {
  console.log('No Gemini API Key detected. Using local advanced mathematical & NLP engine.');
}

// Helper: Custom Advanced Sentiment Analysis
function analyzeSentimentLocally(comment) {
  const text = comment.toLowerCase();
  
  // Lexicons
  const positiveWords = [
    'good', 'great', 'excellent', 'amazing', 'love', 'best', 'perfect', 'nice', 
    'awesome', 'wonderful', 'satisfied', 'happy', 'superb', 'beautiful', 'fast', 
    'quality', 'worth', 'recommend', 'glad', 'cool', 'fantastic', 'top'
  ];
  
  const negativeWords = [
    'bad', 'poor', 'terrible', 'hate', 'worst', 'awful', 'disappointing', 'horrible', 
    'waste', 'expensive', 'useless', 'broken', 'damage', 'wrong', 'late', 'slow', 
    'fake', 'cheap', 'defect', 'fail', 'regret', 'unhappy', 'annoyed'
  ];

  const intensifiers = ['very', 'extremely', 'really', 'so', 'highly', 'super', 'much', 'too'];
  const negations = ['not', 'no', 'never', 'dont', 'doesnt', 'wasnt', 'cannot', 'cant', 'without'];

  // Tokenize
  const words = text.replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, '').split(/\s+/);
  
  let score = 0;
  let positiveCount = 0;
  let negativeCount = 0;

  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    let isPositive = positiveWords.includes(word);
    let isNegative = negativeWords.includes(word);

    if (isPositive || isNegative) {
      // Check for negations in preceding 2 words
      let isNegated = false;
      for (let j = Math.max(0, i - 2); j < i; j++) {
        if (negations.includes(words[j])) {
          isNegated = true;
          break;
        }
      }

      // Check for intensifiers in preceding 2 words
      let multiplier = 1.0;
      for (let j = Math.max(0, i - 2); j < i; j++) {
        if (intensifiers.includes(words[j])) {
          multiplier = 1.5;
          break;
        }
      }

      if (isPositive) {
        if (isNegated) {
          score -= 1 * multiplier;
          negativeCount++;
        } else {
          score += 1 * multiplier;
          positiveCount++;
        }
      } else if (isNegative) {
        if (isNegated) {
          score += 0.5 * multiplier; // "not bad" is slightly positive/neutral
          positiveCount++;
        } else {
          score -= 1 * multiplier;
          negativeCount++;
        }
      }
    }
  }

  let sentiment = 'neutral';
  let confidence = 0.5;

  if (score > 0.2) {
    sentiment = 'positive';
    confidence = Math.min(0.5 + (score * 0.15), 0.98);
  } else if (score < -0.2) {
    sentiment = 'negative';
    confidence = Math.min(0.5 + (Math.abs(score) * 0.15), 0.98);
  } else {
    sentiment = 'neutral';
    confidence = 0.6;
  }

  return {
    sentiment,
    confidence: parseFloat(confidence.toFixed(2)),
    positiveWords: positiveCount,
    negativeWords: negativeCount,
    timestamp: new Date().toISOString()
  };
}

// Helper: Linear Regression & Double Exponential Smoothing (Holt's Linear)
function forecastSalesLocally(history, engagementScore) {
  // If no history, generate synthetic history based on engagement score
  if (!history || history.length === 0) {
    const base = 50 + Math.round(engagementScore / 15);
    history = Array.from({ length: 6 }, (_, i) => Math.round(base * (1 + (i * 0.05))));
  }

  // Ensure positive values
  history = history.map(v => Math.max(0, Number(v)));

  // Model 1: Simple Linear Regression (Slope / Trend)
  const n = history.length;
  let sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
  for (let i = 0; i < n; i++) {
    const x = i;
    const y = history[i];
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumXX += x * x;
  }
  const meanX = sumX / n;
  const meanY = sumY / n;
  
  let slope = 0;
  let denominator = sumXX - (sumX * sumX) / n;
  if (denominator !== 0) {
    slope = (sumXY - (sumX * sumY) / n) / denominator;
  }
  const intercept = meanY - slope * meanX;

  // Model 2: Double Exponential Smoothing (Holt's method)
  const alpha = 0.4; // level smoothing factor
  const beta = 0.3;  // trend smoothing factor
  let level = history[0];
  let trend = (history[1] || history[0]) - history[0];

  for (let i = 1; i < n; i++) {
    const lastLevel = level;
    level = alpha * history[i] + (1 - alpha) * (level + trend);
    trend = beta * (level - lastLevel) + (1 - beta) * trend;
  }

  // Combine models (weighted forecast)
  const regressionForecast = slope * n + intercept;
  const holtForecast = level + trend;
  const predictedSales = Math.max(10, Math.round(regressionForecast * 0.4 + holtForecast * 0.6));

  // Growth calculation compared to the last sales history entry
  const lastSales = history[history.length - 1] || 1;
  const forecastGrowth = ((predictedSales - lastSales) / lastSales) * 100;

  // Confidence based on historic variance
  const variance = history.reduce((acc, val) => acc + Math.pow(val - meanY, 2), 0) / n;
  const stdDev = Math.sqrt(variance);
  const cv = meanY > 0 ? stdDev / meanY : 0.5;
  const confidence = Math.max(0.4, Math.min(0.95, 1 - cv * 0.5));

  return {
    predictedSales,
    forecastGrowth: parseFloat(forecastGrowth.toFixed(1)),
    confidence: parseFloat(confidence.toFixed(2))
  };
}

// Helper: Custom Multi-Factor Recommendation Engine
function generateRecommendationsLocally(product, demandScore) {
  const recommendations = [];
  const stock = Number(product.stock || 0);
  const price = Number(product.price || 0);
  const rating = Number(product.rating || 0);
  const views = Number(product.views || 0);
  const likes = Number(product.likes || 0);
  const comments = Number(product.comments || 0);

  // Conversion rate
  const conversionRate = views > 0 ? (likes / views) * 100 : 0;

  // 1. Stock / Inventory Management
  if (demandScore >= 60 && stock < 30) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '📦 Restock Immediately',
      message: `High consumer demand (${demandScore}%) with critical stock levels (${stock} units left).`,
      action: `Order an emergency batch of at least ${Math.max(30, 100 - stock)} units.`,
      priority: 'HIGH',
      icon: 'inventory'
    });
  } else if (stock > 120 && demandScore < 40) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '🏷️ Excess Stock Reduction',
      message: `Product has low demand (${demandScore}%) but high carrying costs with ${stock} units.`,
      action: 'Run a limited-time 15-20% discount promotion or create product bundles to clear inventory.',
      priority: 'MEDIUM',
      icon: 'local_offer'
    });
  }

  // 2. Conversion & Performance
  if (views > 100 && conversionRate < 8) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '🎯 Optimize Product Listing',
      message: `High page views (${views}) but extremely low conversion rate (${conversionRate.toFixed(1)}%).`,
      action: 'Improve the product description, add high-quality images, or lower the price slightly to increase buyer intent.',
      priority: 'HIGH',
      icon: 'tune'
    });
  } else if (views < 50 && product.engagementScore < 200) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '📢 Boost Product Visibility',
      message: 'Product lacks exposure with very few views and low user engagement.',
      action: 'Promote this item on the app dashboard, use social sharing features, or run a targeted campaign.',
      priority: 'MEDIUM',
      icon: 'visibility'
    });
  }

  // 3. Quality & Rating Control
  if (rating > 0 && rating < 3.5 && comments > 3) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '⭐ Quality & Feedback Action',
      message: `Customer rating is low (${rating.toFixed(1)}⭐). Critical comments indicate product or delivery issues.`,
      action: 'Review recent customer reviews immediately and contact suppliers or adjust packaging/shipping.',
      priority: 'HIGH',
      icon: 'star'
    });
  } else if (rating >= 4.5 && comments >= 8) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '🏆 Feature Highlight',
      message: `Outstanding rating (${rating.toFixed(1)}⭐) and great customer satisfaction.`,
      action: 'Feature this item as a "Best Seller" on your store homepage to attract more premium customers.',
      priority: 'LOW',
      icon: 'emoji_events'
    });
  }

  // 4. Pricing Strategy
  if (price > 150 && product.engagementScore < 300) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '💰 Dynamic Pricing Review',
      message: `High pricing ($${price.toFixed(2)}) might be deterring potential buyers given low engagement.`,
      action: 'A/B test a temporary price drop of 10% or offer free delivery to gauge price sensitivity.',
      priority: 'MEDIUM',
      icon: 'attach_money'
    });
  } else if (price < 30 && product.engagementScore > 1000) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '💎 Premium Upscale Opportunity',
      message: `High engagement suggests great value for a lower-priced item ($${price.toFixed(2)}).`,
      action: 'Consider a minor price increase of 5-10% or upsell related premium accessories.',
      priority: 'LOW',
      icon: 'trending_up'
    });
  }

  // Default fallback if no warnings
  if (recommendations.length === 0) {
    recommendations.push({
      productId: product.id,
      productName: product.name,
      title: '✅ Optimal Performance',
      message: 'Product performance metrics are currently stable and in balance.',
      action: 'No direct adjustments needed. Maintain current stock levels and monitoring schedules.',
      priority: 'LOW',
      icon: 'check_circle'
    });
  }

  return recommendations.sort((a, b) => {
    const priorityMap = { 'HIGH': 3, 'MEDIUM': 2, 'LOW': 1 };
    return priorityMap[b.priority] - priorityMap[a.priority];
  });
}

// Route: Analyze Sentiment
app.post('/analyze_sentiment.php', async (req, res) => {
  const { comment } = req.body;
  
  if (!comment) {
    return res.status(400).json({ error: 'Comment required' });
  }

  // If Gemini is active, use it
  if (genAI) {
    try {
      const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
      const prompt = `
        Analyze the sentiment of this product review comment: "${comment}".
        Respond ONLY with a valid JSON object in this format:
        {
          "sentiment": "positive" | "negative" | "neutral",
          "confidence": number between 0.0 and 1.0,
          "positiveWords": count of positive words,
          "negativeWords": count of negative words
        }
      `;
      
      const result = await model.generateContent(prompt);
      const responseText = result.response.text();
      // Clean potential JSON markdown wrapper
      const cleanedJSON = responseText.replace(/```json/i, '').replace(/```/g, '').trim();
      const parsed = JSON.parse(cleanedJSON);
      
      return res.json({
        ...parsed,
        timestamp: new Date().toISOString()
      });
    } catch (e) {
      console.error('Gemini Sentiment Analysis Error, falling back to local NLP:', e.message);
    }
  }

  // Fallback / Default Local Advanced NLP
  const result = analyzeSentimentLocally(comment);
  return res.json(result);
});

// Route: Predict Sales & Recommendations
app.post('/predict_sales.php', async (req, res) => {
  const { products } = req.body;

  if (!products || !Array.isArray(products) || products.length === 0) {
    return res.status(400).json({ error: 'Products array is required' });
  }

  // If Gemini is active, generate highly premium forecasts & recommendations
  if (genAI) {
    try {
      const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
      const prompt = `
        You are an advanced business intelligence AI. Given the following products data (which includes each product's salesHistory):
        ${JSON.stringify(products, null, 2)}
        
        Compute:
        1. A predicted growth rate (as a percentage, e.g. 12.5 for 12.5% growth) for each product.
        2. A demand score between 0 and 100 for each product.
        3. A demand level string ('VERY HIGH', 'HIGH', 'MEDIUM', 'LOW', or 'CRITICAL') for each product.
        4. A corresponding hex color code for the demand level (e.g. '#673AB7', '#4CAF50', '#59F797', '#FF9800', '#F44336').
        5. Tailored action recommendations for EACH product.
        6. A predicted sales number (integer units) for next week.
        
        Respond ONLY with a valid JSON object in this format:
        {
          "predictions": [
            {
              "productId": "id of product",
              "productName": "name of product",
              "productImage": "image url of product or null",
              "productCategory": "category of product",
              "price": number,
              "stock": number,
              "rating": number,
              "forecastGrowth": number (percentage growth rate, e.g. 8.5),
              "predictedSales": number (integer predicted units),
              "demandScore": number (integer 0-100),
              "demandLevel": "VERY HIGH" | "HIGH" | "MEDIUM" | "LOW" | "CRITICAL",
              "demandColor": "hex color string starting with #",
              "recommendations": [
                {
                  "title": "Short title, e.g. 📦 Increase Stock",
                  "message": "Detailed context explaining why",
                  "action": "Specific concrete action steps",
                  "priority": "HIGH" | "MEDIUM" | "LOW",
                  "icon": "inventory" | "local_offer" | "visibility" | "star" | "emoji_events" | "tune" | "attach_money" | "check_circle" | "trending_up"
                }
              ],
              "engagementScore": number,
              "views": number,
              "likes": number,
              "comments": number
            }
          ]
        }
      `;
      
      const result = await model.generateContent(prompt);
      const responseText = result.response.text();
      const cleanedJSON = responseText.replace(/```json/i, '').replace(/```/g, '').trim();
      const parsed = JSON.parse(cleanedJSON);

      return res.json({
        ...parsed,
        timestamp: new Date().toISOString()
      });
    } catch (e) {
      console.error('Gemini Sales Prediction Error, falling back to local models:', e.message);
    }
  }

  // Generate predictions locally for each product
  const predictions = [];
  products.forEach(p => {
    // calculate a customized demand score for this product specifically
    const conversion = (p.views > 0 ? (p.likes / p.views) : 0) * 100;
    let score = (p.engagementScore / 18).clamp(0, 45); // weight 45
    score += (conversion * 0.25); // weight 25
    score += (p.stock < 20 ? 20 : (p.stock < 50 ? 10 : 0)); // weight 20
    score += ((p.rating || 0) * 2); // weight 10
    const finalProductDemand = Math.round(score).clamp(0, 100);

    const productForecast = forecastSalesLocally(p.salesHistory || [], p.engagementScore || 0);
    
    // Get demand color & level
    let demandLevel = 'MEDIUM';
    let demandColor = '#59F797'; // default green
    if (finalProductDemand >= 80) {
      demandLevel = 'VERY HIGH';
      demandColor = '#673AB7'; // deepPurple
    } else if (finalProductDemand >= 60) {
      demandLevel = 'HIGH';
      demandColor = '#4CAF50'; // green
    } else if (finalProductDemand >= 40) {
      demandLevel = 'MEDIUM';
      demandColor = '#59F797'; // light green
    } else if (finalProductDemand >= 20) {
      demandLevel = 'LOW';
      demandColor = '#FF9800'; // orange
    } else {
      demandLevel = 'CRITICAL';
      demandColor = '#F44336'; // red
    }

    const productRecs = generateRecommendationsLocally(p, finalProductDemand);

    predictions.push({
      productId: p.id,
      productName: p.productName || p.name,
      productImage: p.imageUrl || p.productImage || null,
      productCategory: p.category || '',
      price: Number(p.price || 0),
      stock: Number(p.stock || 0),
      rating: Number(p.rating || 0),
      forecastGrowth: productForecast.forecastGrowth,
      predictedSales: productForecast.predictedSales,
      demandScore: finalProductDemand,
      demandLevel: demandLevel,
      demandColor: demandColor,
      recommendations: productRecs.map(r => ({
        title: r.title,
        message: r.message,
        action: r.action,
        priority: r.priority,
        icon: r.icon
      })),
      engagementScore: Number(p.engagementScore || 0),
      views: Number(p.views || 0),
      likes: Number(p.likes || 0),
      comments: Number(p.comments || 0)
    });
  });

  return res.json({
    predictions: predictions,
    timestamp: new Date().toISOString()
  });
});

// Helper clamp/min/max prototypes for simplicity
Number.prototype.clamp = function(min, max) {
  return Math.min(Math.max(this, min), max);
};

// Route: Get Market Trends (For backend/documentation compatibility)
app.get('/get_market_trends.php', (req, res) => {
  const trendingProducts = [
    {
      productId: 'mock_trend_1',
      productName: 'Bajaj Motorcycle',
      category: 'Automobile & Transport',
      engagementScore: 1680,
      trendGrowth: 0.38,
      trendPercentage: '+38%'
    },
    {
      productId: 'mock_trend_2',
      productName: 'Smart TV Pro',
      category: 'Electronics',
      engagementScore: 1350,
      trendGrowth: 0.30,
      trendPercentage: '+30%'
    },
    {
      productId: 'mock_trend_3',
      productName: 'Organic Tanzanian Coffee',
      category: 'Food & Beverages',
      engagementScore: 1100,
      trendGrowth: 0.25,
      trendPercentage: '+25%'
    }
  ];

  return res.json({
    trendingProducts,
    timestamp: new Date().toISOString()
  });
});

// Route: Get Sales Forecast (For backend/documentation compatibility)
app.post('/get_sales_forecast.php', (req, res) => {
  const { productId, salesHistory } = req.body;

  if (!productId) {
    return res.status(400).json({ error: 'Product ID required' });
  }

  const localForecast = forecastSalesLocally(salesHistory, 600);
  const nextWeekSales = localForecast.predictedSales;
  const growthRate = localForecast.forecastGrowth / 100;
  
  return res.json({
    productId,
    forecast: {
      nextWeek: nextWeekSales,
      nextMonth: Math.round(nextWeekSales * 4.2),
      growthRate: growthRate,
      confidence: localForecast.confidence
    },
    timestamp: new Date().toISOString()
  });
});

// Route: AzamPesa Payment Checkout Simulation
app.post('/api/payment/azampesa/checkout', async (req, res) => {
  const {
    mobileNumber,
    amount,
    orderId,
    userId,
    customerName,
    customerEmail,
    shippingAddress,
    city,
    country,
    cartItems
  } = req.body;

  if (!mobileNumber || !amount || !orderId || !userId || !cartItems || !Array.isArray(cartItems)) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  console.log(`[Payment Checkout] Initiating AzamPesa payment for Order: ${orderId}, User: ${userId}, Amount: ${amount}`);

  // Generate a mock transaction ID
  const transactionId = `AZM-TXN-${Date.now()}-${Math.floor(Math.random() * 900) + 100}`;

  try {
    // 1. Reserve stock first (optional/preemptive) and write pending orders
    if (db) {
      const batch = db.batch();
      for (const item of cartItems) {
        const productRef = db.collection('products').doc(item.productId);
        const productSnap = await productRef.get();
        if (productSnap.exists) {
          const currentStock = productSnap.data().stock || 0;
          if (currentStock < item.quantity) {
            return res.status(400).json({ error: `Insufficient stock for ${item.productName}` });
          }
          batch.update(productRef, { stock: currentStock - item.quantity });
        }
      }
      
      // Write the pending order document to Firestore
      for (const item of cartItems) {
        const orderRef = db.collection('orders').doc(`${orderId}_${item.productId}`);
        batch.set(orderRef, {
          orderId,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          price: Number(item.price),
          totalAmount: Number(item.price) * Number(item.quantity),
          userId,
          customerName,
          customerEmail,
          status: 'pending',
          paymentStatus: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          shippingAddress,
          city,
          country,
        });
      }

      // Write pending payment document
      const paymentRef = db.collection('payments').doc(transactionId);
      batch.set(paymentRef, {
        orderId,
        userId,
        amount: Number(amount),
        currency: 'TZS',
        status: 'pending',
        paymentMethod: 'mobile_money',
        transactionId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();
      console.log(`[Payment Checkout] Pending orders & payment recorded in Firestore for ${orderId}`);
    } else {
      console.log(`[Payment Checkout] [Dry-Run] Skip writing pending orders & payment to Firestore (SDK not initialized)`);
    }

    // 2. Simulate AzamPesa Sandbox API request
    res.json({
      success: true,
      message: 'USSD push sent successfully. Please check your phone to input your PIN.',
      transactionId,
      orderId,
    });

    // 3. Simulate asynchronous callback webhook after 3 seconds
    setTimeout(async () => {
      try {
        console.log(`[Payment Callback] Triggering webhook callback for Order: ${orderId}, Transaction: ${transactionId}`);
        
        // Simulating the external callback hit. Numbers ending with '00' fail.
        const isSuccess = !mobileNumber.endsWith('00');

        await processPaymentCallback({
          transactionId,
          orderId,
          status: isSuccess ? 'success' : 'failed',
          message: isSuccess ? 'Payment completed successfully.' : 'Payment failed or cancelled by user.',
          amount,
          userId,
          customerName,
          customerEmail,
          shippingAddress,
          city,
          country,
          cartItems,
        });
      } catch (callbackErr) {
        console.error('[Payment Callback] Error during asynchronous callback handling:', callbackErr);
      }
    }, 3000);

  } catch (err) {
    console.error('[Payment Checkout] Error starting checkout:', err);
    res.status(500).json({ error: 'Internal server error starting payment checkout' });
  }
});

// Helper function to process callback
async function processPaymentCallback(payload) {
  const { transactionId, orderId, status, message, amount, userId, cartItems } = payload;
  console.log(`[Callback Processing] Order ID: ${orderId}, Transaction: ${transactionId}, Status: ${status}`);

  if (!db) {
    console.log(`[Callback Processing] [Dry-Run] Cannot write to Firestore. Payment Status: ${status}`);
    return;
  }

  const batch = db.batch();

  try {
    if (status === 'success') {
      // Update matching orders to status = 'processing', paymentStatus = 'paid'
      const ordersRef = db.collection('orders');
      const querySnap = await ordersRef.where('orderId', '==', orderId).get();
      querySnap.forEach((doc) => {
        batch.update(doc.ref, {
          paymentStatus: 'paid',
          status: 'processing',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Update payment to status = 'success'
      const paymentRef = db.collection('payments').doc(transactionId);
      batch.update(paymentRef, {
        status: 'success',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log purchase event to Firestore for analytics
      for (const item of cartItems) {
        const eventRef = db.collection('purchase_behavior_events').doc();
        batch.set(eventRef, {
          userId,
          userEmail: payload.customerEmail || 'customer@example.com',
          action: 'purchase',
          productId: item.productId,
          productName: item.productName,
          category: item.category || 'general',
          price: Number(item.price),
          quantity: Number(item.quantity),
          city: payload.city || 'Dar es Salaam',
          country: payload.country || 'Tanzania',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Delete the items from user's cart in Firestore
      for (const item of cartItems) {
        const cartRef = db.collection('cart').doc(`${userId}_${item.productId}`);
        batch.delete(cartRef);
      }

      console.log(`[Callback Processing] Payment successful. Committing updates.`);
    } else {
      // Payment failed
      // Update orders to paymentStatus = 'failed', status = 'cancelled'
      const ordersRef = db.collection('orders');
      const querySnap = await ordersRef.where('orderId', '==', orderId).get();
      querySnap.forEach((doc) => {
        batch.update(doc.ref, {
          paymentStatus: 'failed',
          status: 'cancelled',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Update payment to status = 'failed'
      const paymentRef = db.collection('payments').doc(transactionId);
      batch.update(paymentRef, {
        status: 'failed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Revert stock decrement
      for (const item of cartItems) {
        const productRef = db.collection('products').doc(item.productId);
        const productSnap = await productRef.get();
        if (productSnap.exists) {
          const currentStock = productSnap.data().stock || 0;
          batch.update(productRef, { stock: currentStock + item.quantity });
        }
      }

      console.log(`[Callback Processing] Payment failed. Reverting stock & updating order/payment records.`);
    }

    await batch.commit();
    console.log(`[Callback Processing] Transaction committed successfully.`);
  } catch (err) {
    console.error(`[Callback Processing] Error processing batch commit:`, err);
    throw err;
  }
}

// Route: Webhook Endpoint (For simulation/direct endpoint hit from external API test tools)
app.post('/api/payment/azampesa/callback', async (req, res) => {
  const { transactionId, orderId, status, message } = req.body;

  if (!transactionId || !orderId || !status) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  console.log(`[Callback Endpoint Hit] Transaction ID: ${transactionId}, Order: ${orderId}, Status: ${status}`);

  try {
    if (db) {
      const paymentSnap = await db.collection('payments').doc(transactionId).get();
      if (!paymentSnap.exists) {
        return res.status(404).json({ error: 'Transaction not found' });
      }

      const paymentData = paymentSnap.data();
      const userId = paymentData.userId;
      
      const ordersSnap = await db.collection('orders').where('orderId', '==', orderId).get();
      const cartItems = [];
      ordersSnap.forEach(doc => {
        const data = doc.data();
        cartItems.push({
          productId: data.productId,
          productName: data.productName,
          quantity: data.quantity,
          price: data.price,
        });
      });

      await processPaymentCallback({
        transactionId,
        orderId,
        status,
        message: message || (status === 'success' ? 'Callback success' : 'Callback failed'),
        amount: paymentData.amount,
        userId,
        cartItems,
      });

      return res.json({ success: true, message: 'Callback processed successfully' });
    } else {
      return res.status(500).json({ error: 'Firestore Admin SDK not initialized' });
    }
  } catch (err) {
    console.error('[Callback Endpoint Error]', err);
    return res.status(500).json({ error: 'Internal server error processing callback' });
  }
});

// Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Smart Business Analytics AI Backend listening on port ${PORT}`);
});

