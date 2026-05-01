#!/usr/bin/env python3
"""
Simple Elite Fitness AI Coach Server
Uses Google Gemini API directly (no LangChain)
"""

import os
import json
import re
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

# Try to import google.generativeai, if not available use a simple fallback
try:
    import google.generativeai as genai
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False
    print("WARNING: google-generativeai not installed. Using fallback mode.")

app = Flask(__name__)
CORS(app)

# AI Coach System Prompt
AI_COACH_PROMPT = """You are an elite AI fitness and nutrition coach.

LANGUAGE RULE:
- User writes in Arabic → reply 100% in Arabic (units in English: kcal, g, kg, cm)
- User writes in English → reply 100% in English

MEMORY SYSTEM:
You have access to the user's profile data (weight, height, age, goal, etc.)
and conversation history. Use this to personalize responses.

BODY ANALYSIS:
When you have weight, height, age, and gender:
- Calculate BMI, BMR, TDEE, and target calories
- Show results in a card format

BMR FORMULA (Mifflin-St Jeor):
Male: BMR = (10 × kg) + (6.25 × cm) − (5 × age) + 5
Female: BMR = (10 × kg) + (6.25 × cm) − (5 × age) − 161

MACRO SPLITS:
- Bulking: Protein 2.0g/kg, Fat 25-30%, Carbs fill remaining
- Cutting: Protein 2.2g/kg, Fat 20-25%, Carbs reduce
- Maintenance: Protein 1.8g/kg, Carbs 45-55%, Fat 25-30%

SAFETY RULES:
- Never recommend < 1200 kcal/day for women or < 1500 kcal/day for men
- Always mention consulting a doctor for medical conditions
- Never diagnose or prescribe medications

OUTPUT FORMAT:
Use structured cards for body analysis, food, and meal plans.
Keep responses focused and practical.

CURRENT USER PROFILE:
{profile}

CONVERSATION HISTORY:
{history}

USER MESSAGE: {message}
"""


def format_profile(profile_data):
    """Format profile data for the AI prompt."""
    if not profile_data:
        return "No profile data available. New user."
    
    lines = []
    for key, value in profile_data.items():
        if value is not None and value != [] and value != {}:
            lines.append(f"  • {key}: {value}")
    
    return "\n".join(lines) if lines else "Empty profile - new user"


def format_history(messages):
    """Format conversation history for the AI prompt."""
    if not messages:
        return "No previous messages in this session."
    
    lines = []
    for msg in messages[-10:]:  # Last 10 messages
        role = "User" if msg.get('is_user', True) else "Coach"
        text = msg.get('text', '')[:100]
        lines.append(f"  [{role}]: {text}")
    
    return "\n".join(lines)


def is_session_end(text):
    """Check if user is ending the session."""
    end_keywords = [
        'bye', 'goodbye', 'thanks', 'thank you', 'see you',
        'مع السلامة', 'شكراً', 'شكرا', 'باي', 'سلام',
        'talk later', 'later', 'see ya', 'خروج', 'مشي'
    ]
    lower_text = text.lower()
    return any(keyword in lower_text for keyword in end_keywords)


def get_fallback_response(message, profile):
    """Generate fallback response when AI is not available."""
    lower_msg = message.lower()
    
    # Arabic greetings
    if any(word in lower_msg for word in ['hi', 'hello', 'مرحبا', 'أهلا', 'سلام', 'هاي']):
        return """أهلاً! أنا AI Coach بتاعك 💪

أقدر أساعدك في:
• حساب السعرات والماكروز
• عمل plan غذائي
• نصائح تمرين

قولي وزنك وطولك وهدفك (تحجيم/تقطيع) وهحسبلك كل حاجة!"""
    
    # Body data detection
    if any(word in lower_msg for word in ['وزني', 'طولي', 'وزن', 'height', 'weight', 'عمري', 'age']):
        weight = profile.get('weight_kg', 'غير معروف')
        height = profile.get('height_cm', 'غير معروف')
        age = profile.get('age', 'غير معروف')
        goal = profile.get('goal', 'غير معروف')
        
        if weight != 'غير معروف' and height != 'غير معروف' and age != 'غير معروف':
            # Calculate BMI
            bmi = weight / ((height/100) ** 2)
            
            # Calculate BMR (Mifflin-St Jeor)
            gender = profile.get('gender', 'male')
            if gender == 'female':
                bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161
            else:
                bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
            
            # Calculate TDEE (assume moderate activity)
            tdee = bmr * 1.55
            
            # Target calories based on goal
            if goal == 'bulking':
                target = tdee + 400
            elif goal == 'cutting':
                target = tdee - 500
            else:
                target = tdee
            
            return f"""┌─────────────────────────────────┐
│  BODY ANALYSIS CARD             │
├─────────────────────────────────┤
│  BMI        : {bmi:.1f}              │
│  BMR        : {bmr:.0f} kcal/day       │
│  TDEE       : {tdee:.0f} kcal/day       │
│  Goal       : {goal}             │
│  Target kcal: {target:.0f} kcal/day      │
└─────────────────────────────────┘

عايز تعمل plan للأكل؟ اكتب "plan" 👇"""
        else:
            return "أحتاج بياناتك الكاملة:\n• الوزن (كجم)\n• الطول (سم)\n• العمر\n• الهدف (تحجيم/تقطيع/صيانة)\n\nقولي مثلاً: وزني 80 كيلو وطولي 180 وهدفي التحجيم"
    
    # Meal plan request
    if any(word in lower_msg for word in ['plan', 'أكل', 'plan', 'dieta', 'وجبات']):
        target_kcal = profile.get('calculated_target_kcal', 2000)
        return f"""┌─────────────────────────────────────────┐
│  DAILY MEAL PLAN — {target_kcal:.0f} kcal        │
├──────────┬──────────────────────────────┤
│ Breakfast│ 3 eggs + 2 toast + cheese      │
│          │ P:25g C:30g F:20g            │
├──────────┼──────────────────────────────┤
│ Snack 1  │ Protein shake + banana       │
│          │ P:30g C:35g F:5g             │
├──────────┼──────────────────────────────┤
│ Lunch    │ Chicken breast 200g + rice   │
│          │ P:45g C:60g F:10g            │
├──────────┼──────────────────────────────┤
│ Snack 2  │ Greek yogurt + nuts          │
│          │ P:15g C:10g F:15g            │
├──────────┼──────────────────────────────┤
│ Dinner   │ Fish 150g + salad + olive oil│
│          │ P:35g C:15g F:25g            │
├──────────┼──────────────────────────────┤
│ TOTAL    │ ~{target_kcal:.0f} kcal | P:150g C:150g F:75g│
└──────────┴──────────────────────────────┘

💡 Tip: اشرب 3-4 لتر مياه يومياً!"""
    
    # Food analysis
    if any(word in lower_msg for word in ['food', 'أكل', 'سعرات', 'calories', 'كوشري', 'رز', 'chicken']):
        return """┌─────────────────────────────────┐
│  FOOD CARD                      │
├─────────────────────────────────┤
│  Item     : Egyptian Koshary   │
│  Portion  : 1 plate (~450g)    │
│  Calories : ~650 kcal          │
├─────────────────────────────────┤
│  Protein  : 22g                │
│  Carbs    : 110g               │
│  Fat      : 15g                │
└─────────────────────────────────┘

💡 Tip: لو هدفك تقطيع، خليني النص و زود سلطة!"""
    
    # Default response
    return """أنا هنا عشان أساعدك 💪

جرب تسألني:
• "وزني 80 كيلو وطولي 180 وهدفي التحجيم"
• "عملي plan للأكل"
• "كام سعرة في الكوشري؟"

أو قولي أي حاجة عن fitness و nutrition!"""


def get_ai_response(prompt, api_key):
    """Get response from Gemini API."""
    if not GENAI_AVAILABLE:
        return "AI service not available. Please install google-generativeai package."
    
    try:
        genai.configure(api_key=api_key)
        # Use gemini-1.5-pro-latest which is the current model
        model = genai.GenerativeModel('gemini-1.5-pro-latest')
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"AI Error: {e}")
        return f"AI Error: {str(e)}. Please check your API key."


@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint."""
    try:
        data = request.get_json()
        user_message = data.get('question', '').strip()
        profile_data = data.get('profile', {})
        history = data.get('history', [])
        
        if not user_message:
            return jsonify({'answer': 'Please send a message!'}), 400
        
        # Get API key
        api_key = os.getenv('GOOGLE_API_KEY', '')
        if not api_key and not GENAI_AVAILABLE:
            return jsonify({
                'answer': 'Please set GOOGLE_API_KEY environment variable or install google-generativeai.'
            }), 500
        
        # Check for session end
        session_ending = is_session_end(user_message)
        
        # Format context
        profile_text = format_profile(profile_data)
        history_text = format_history(history)
        
        # Build prompt
        prompt = AI_COACH_PROMPT.format(
            profile=profile_text,
            history=history_text,
            message=user_message
        )
        
        # Get AI response
        if GENAI_AVAILABLE and api_key:
            answer = get_ai_response(prompt, api_key)
            # If AI returned error, use fallback
            if answer.startswith("AI Error:"):
                answer = get_fallback_response(user_message, profile_data)
        else:
            # Fallback response when AI not available
            answer = get_fallback_response(user_message, profile_data)
        
        # Prepare response
        result = {
            'answer': answer,
            'session_ended': session_ending,
            'updated_profile': None
        }
        
        if session_ending:
            result['updated_profile'] = profile_data
        
        return jsonify(result)
        
    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        return jsonify({
            'answer': f'Sorry, I encountered an error: {str(e)}',
            'error': str(e)
        }), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'AI Coach',
        'genai_available': GENAI_AVAILABLE
    })


if __name__ == '__main__':
    api_key = os.getenv('GOOGLE_API_KEY', '')
    if not api_key:
        print("WARNING: GOOGLE_API_KEY not set!")
        print("Set it with: $env:GOOGLE_API_KEY='your-key-here'")
    else:
        print(f"API Key configured: {api_key[:10]}...")
    
    print("\n" + "="*50)
    print("  ELITE FITNESS AI COACH SERVER (SIMPLE MODE)")
    print("="*50)
    print("  Endpoints:")
    print("    POST /chat   - Main chat endpoint")
    print("    GET  /health - Health check")
    print("")
    print("  To test: curl http://localhost:5000/health")
    print("="*50 + "\n")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
