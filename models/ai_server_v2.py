#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Elite Fitness AI Coach - Powered by Google Gemini
"""

import os
import re
import json
from flask import Flask, request, jsonify
from flask_cors import CORS

# Import Gemini
try:
    import google.generativeai as genai
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False
    print("ERROR: google-generativeai not installed!")
    print("Run: pip install google-generativeai")

app = Flask(__name__)
CORS(app)

# System Prompt for AI Coach
SYSTEM_PROMPT = """You are an Elite Fitness & Nutrition AI Coach. You provide expert advice on bodybuilding, nutrition, and healthy lifestyle.

## YOUR ROLE:
- Analyze user data (weight, height, age, goal) and provide personalized recommendations
- Calculate BMI, BMR, TDEE, and macro targets when data is available
- Suggest meal plans and training programs based on user goals
- Analyze food items and estimate nutritional values
- Always respond in the SAME LANGUAGE as the user (Arabic or English)

## RESPONSE FORMAT:
Use structured cards for your responses:

For Body Analysis:
┌─────────────────────────────────┐
│  BODY ANALYSIS CARD             │
├─────────────────────────────────┤
│  BMI        : XX.X              │
│  BMR        : XXXX kcal/day     │
│  TDEE       : XXXX kcal/day     │
│  Goal       : bulking/cutting   │
│  Target kcal: XXXX kcal/day     │
└─────────────────────────────────┘

For Food Analysis:
┌─────────────────────────────────┐
│  FOOD CARD                      │
├─────────────────────────────────┤
│  Item     : [Food Name]         │
│  Portion  : [Size]              │
│  Calories : XXX kcal (تقديري)   │
├─────────────────────────────────┤
│  Protein  : XXg                 │
│  Carbs    : XXg                 │
│  Fat      : XXg                 │
└─────────────────────────────────┘

For Meal Plans:
┌─────────────────────────────────────────┐
│  DAILY MEAL PLAN — XXXX kcal            │
├──────────┬──────────────────────────────┤
│ Breakfast│ [Food items]                   │
│          │ P:XXg C:XXg F:XXg              │
├──────────┼──────────────────────────────┤
│ Lunch    │ [Food items]                   │
│          │ P:XXg C:XXg F:XXg              │
├──────────┼──────────────────────────────┤
│ Dinner   │ [Food items]                   │
│          │ P:XXg C:XXg F:XXg              │
└──────────┴──────────────────────────────┘

For Training:
┌─────────────────────────────────────────┐
│  TRAINING CARD — [Goal]                 │
├─────────────────────────────────────────┤
│  Exercise           │ Sets │ Reps       │
├─────────────────────┼──────┼────────────┤
│  [Exercise Name]    │  X   │ XX-XX      │
└─────────────────────────────────────────┘

## CALCULATIONS:
- BMI = weight(kg) / (height(m))²
- BMR (Mifflin-St Jeor): 
  Male: (10 × kg) + (6.25 × cm) − (5 × age) + 5
  Female: (10 × kg) + (6.25 × cm) − (5 × age) − 161
- TDEE = BMR × activity_multiplier (1.2-1.9)
- Target Calories: TDEE ± goal_adjustment

## IMPORTANT NOTES:
- Always add "(تقديري)" for estimated values
- Provide practical tips after each card
- Be encouraging but realistic
- Never diagnose medical conditions
"""

def extract_profile_data(message, current_profile):
    """Extract weight, height, age, goal from message."""
    profile = current_profile.copy()
    msg_lower = message.lower()
    
    # Weight patterns
    weight_patterns = [
        r'وزni\s*(\d+(?:\.\d+)?)',
        r'وزن\s*(\d+(?:\.\d+)?)',
        r'weight\s*(\d+(?:\.\d+)?)',
        r'(\d+(?:\.\d+)?)\s*(?:ك|kg|كيلو)',
    ]
    for pattern in weight_patterns:
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            profile['weight_kg'] = float(match.group(1))
            break
    
    # Height patterns
    height_patterns = [
        r'طولi\s*(\d+(?:\.\d+)?)',
        r'طول\s*(\d+(?:\.\d+)?)',
        r'height\s*(\d+(?:\.\d+)?)',
        r'(\d+(?:\.\d+)?)\s*(?:سم|cm)',
    ]
    for pattern in height_patterns:
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            profile['height_cm'] = float(match.group(1))
            break
    
    # Age patterns
    age_patterns = [
        r'عمري\s*(\d+)',
        r'عمر\s*(\d+)',
        r'age\s*(\d+)',
        r'(\d+)\s*(?:سنة|سنه|years?)',
    ]
    for pattern in age_patterns:
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            profile['age'] = int(match.group(1))
            break
    
    # Goal detection
    if any(word in msg_lower for word in ['تضخيم', 'تحجيم', 'bulking', 'bulk', 'اكبر', 'حجم', 'ضخامة']):
        profile['goal'] = 'bulking'
    elif any(word in msg_lower for word in ['تقطيع', 'تخسيس', 'cutting', 'cut', 'تنحيف', 'حرق', 'رشاقة']):
        profile['goal'] = 'cutting'
    elif any(word in msg_lower for word in ['صيانة', 'maintenance', 'maintain', 'حفظ']):
        profile['goal'] = 'maintenance'
    
    # Gender detection
    if any(word in msg_lower for word in ['male', 'ذكر', 'رجل']):
        profile['gender'] = 'male'
    elif any(word in msg_lower for word in ['female', 'انثى', 'انثي', 'ست', 'بنت']):
        profile['gender'] = 'female'
    
    return profile

def format_profile_for_prompt(profile):
    """Format profile data for AI prompt."""
    if not profile:
        return "No profile data yet."
    
    lines = []
    if 'weight_kg' in profile:
        lines.append(f"Weight: {profile['weight_kg']} kg")
    if 'height_cm' in profile:
        lines.append(f"Height: {profile['height_cm']} cm")
    if 'age' in profile:
        lines.append(f"Age: {profile['age']} years")
    if 'gender' in profile:
        lines.append(f"Gender: {profile['gender']}")
    if 'goal' in profile:
        lines.append(f"Goal: {profile['goal']}")
    
    return "\n".join(lines) if lines else "No profile data yet."

def get_ai_response(user_message, profile, history=None):
    """Get response from Gemini AI."""
    
    if not GENAI_AVAILABLE:
        return "Error: Gemini AI not available. Please install google-generativeai."
    
    api_key = os.getenv('GOOGLE_API_KEY')
    if not api_key:
        return "Error: No API key set. Please set GOOGLE_API_KEY environment variable."
    
    try:
        # Configure Gemini
        genai.configure(api_key=api_key)
        
        # Use gemini-2.5-flash (available for this API key)
        model = genai.GenerativeModel('gemini-2.5-flash')
        
        # Build the prompt
        profile_text = format_profile_for_prompt(profile)
        
        prompt = f"""{SYSTEM_PROMPT}

USER PROFILE:
{profile_text}

USER MESSAGE:
{user_message}

Provide a helpful response using the appropriate card format based on the user's request. Respond in the same language as the user's message (Arabic if they wrote in Arabic, English if they wrote in English)."""

        # Generate response
        response = model.generate_content(prompt)
        
        return response.text
        
    except Exception as e:
        print(f"AI Error: {e}")
        return f"Sorry, I encountered an error: {str(e)}"

def is_session_end(text):
    """Check if user is ending the session."""
    end_keywords = ['bye', 'goodbye', 'thanks', 'thank you', 'see you', 'exit', 'quit',
                    'مع السلامة', 'شكراً', 'شكرا', 'باي', 'سلام', 'خروج']
    return any(kw in text.lower() for kw in end_keywords)

@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint."""
    try:
        data = request.get_json()
        user_message = data.get('question', '').strip()
        current_profile = data.get('profile', {})
        
        if not user_message:
            return jsonify({'answer': 'Please send a message!'}), 400
        
        # Extract profile data from message
        updated_profile = extract_profile_data(user_message, current_profile)
        
        # Check if we have enough data for calculations
        has_data = all(k in updated_profile for k in ['weight_kg', 'height_cm', 'age'])
        
        # Get AI response
        ai_response = get_ai_response(user_message, updated_profile)
        
        # Check session end
        session_ending = is_session_end(user_message)
        
        return jsonify({
            'answer': ai_response,
            'session_ended': session_ending,
            'updated_profile': updated_profile if session_ending else None,
            'has_complete_profile': has_data
        })
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({
            'answer': f'Error: {str(e)}',
            'error': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    api_key = os.getenv('GOOGLE_API_KEY', '')
    return jsonify({
        'status': 'healthy',
        'service': 'AI Coach v2',
        'genai_available': GENAI_AVAILABLE,
        'api_key_configured': bool(api_key),
        'api_key_preview': api_key[:10] + '...' if api_key else None
    })

if __name__ == '__main__':
    print("="*60)
    print("  🤖 ELITE FITNESS AI COACH v2")
    print("="*60)
    
    api_key = os.getenv('GOOGLE_API_KEY', '')
    if api_key and GENAI_AVAILABLE:
        print(f"  ✅ Gemini AI Ready")
        print(f"  🔑 API Key: {api_key[:15]}...")
    else:
        print("  ❌ Gemini AI NOT available!")
        if not api_key:
            print("  ⚠️  Set GOOGLE_API_KEY environment variable")
        if not GENAI_AVAILABLE:
            print("  ⚠️  Install: pip install google-generativeai")
    
    print("="*60)
    print("  Endpoints:")
    print("    POST /chat - Chat with AI Coach")
    print("    GET  /health - Health check")
    print("="*60)
    print()
    
    app.run(host='0.0.0.0', port=5000, debug=True)
