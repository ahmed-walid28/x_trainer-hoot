#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Elite Fitness AI Coach - Powered by OpenRouter (Free Tier)
"""

import os
import re
import json
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# OpenRouter API - Free tier available
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

# System Prompt for AI Coach
SYSTEM_PROMPT = """You are an Elite Fitness & Nutrition AI Coach. You provide expert advice on bodybuilding, nutrition, and healthy lifestyle in Arabic and English.

## RESPONSE FORMAT - USE THESE EXACT CARD FORMATS:

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

For Body Analysis:
┌─────────────────────────────────┐
│  BODY ANALYSIS CARD             │
├─────────────────────────────────┤
│  BMI        : XX.X              │
│  BMR        : XXXX kcal/day     │
│  TDEE       : XXXX kcal/day     │
│  Target kcal: XXXX kcal/day     │
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

ALWAYS respond in the SAME LANGUAGE as the user's message.
Use (تقديري) for estimated calorie values."""

def extract_profile_data(message, current_profile):
    """Extract weight, height, age, goal from message."""
    profile = current_profile.copy() if current_profile else {}
    msg_lower = message.lower()
    
    # Weight patterns
    weight_patterns = [
        r'وزني\s*(\d+(?:\.\d+)?)',
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
        r'طولي\s*(\d+(?:\.\d+)?)',
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
    if any(word in msg_lower for word in ['تضخيم', 'تحجيم', 'bulking', 'bulk']):
        profile['goal'] = 'bulking'
    elif any(word in msg_lower for word in ['تقطيع', 'تخسيس', 'cutting', 'cut']):
        profile['goal'] = 'cutting'
    elif any(word in msg_lower for word in ['صيانة', 'maintenance']):
        profile['goal'] = 'maintenance'
    
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
    if 'goal' in profile:
        lines.append(f"Goal: {profile['goal']}")
    
    return "\n".join(lines) if lines else "No profile data yet."

def get_ai_response(user_message, profile):
    """Get response from OpenRouter AI."""
    
    api_key = os.getenv('OPENROUTER_API_KEY')
    if not api_key:
        return "Error: No OpenRouter API key set. Please set OPENROUTER_API_KEY environment variable."
    
    try:
        profile_text = format_profile_for_prompt(profile)
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:5000",
            "X-Title": "Elite Fitness AI Coach"
        }
        
        data = {
            "model": "deepseek/deepseek-chat:free",  # FREE model - higher limits
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"User Profile:\n{profile_text}\n\nUser Message: {user_message}"}
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        }
        
        response = requests.post(OPENROUTER_URL, headers=headers, json=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            return result['choices'][0]['message']['content']
        else:
            return f"API Error: {response.status_code} - {response.text[:200]}"
        
    except Exception as e:
        return f"Error: {str(e)}"

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
    api_key = os.getenv('OPENROUTER_API_KEY', '')
    return jsonify({
        'status': 'healthy',
        'service': 'AI Coach - OpenRouter',
        'api_key_configured': bool(api_key),
        'model': 'meta-llama/llama-3.1-8b-instruct:free'
    })

if __name__ == '__main__':
    print("="*60)
    print("  ELITE FITNESS AI COACH - OpenRouter")
    print("="*60)
    
    api_key = os.getenv('OPENROUTER_API_KEY', '')
    if api_key:
        print(f"  [OK] API Key: {api_key[:15]}...")
        print(f"  [FREE] Using model: meta-llama/llama-3.1-8b-instruct")
    else:
        print("  [ERROR] No API Key set!")
        print("  Set: OPENROUTER_API_KEY=your_key_here")
    
    print("="*60)
    print("  Get free API key: https://openrouter.ai/keys")
    print("="*60)
    print()
    
    app.run(host='0.0.0.0', port=5000, debug=True)
