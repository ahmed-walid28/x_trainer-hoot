#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Elite Fitness AI Coach - Powered by Groq (Blazing Fast)
"""

import os
import re
import json
from flask import Flask, request, jsonify
from flask_cors import CORS

# Import Groq
try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False
    print("[ERROR] groq not installed!")
    print("[INFO] Run: pip install groq")

app = Flask(__name__)
CORS(app)

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

def format_attachment_for_prompt(attachment):
    """Format attachment metadata for AI prompt."""
    if not attachment:
        return "No attachment"

    file_name = attachment.get('file_name', 'unknown')
    content_type = attachment.get('content_type', 'unknown')
    size_bytes = attachment.get('size_bytes', 0)
    remote_url = attachment.get('remote_url', '')

    lines = [
        f"File: {file_name}",
        f"Type: {content_type}",
        f"Size: {size_bytes} bytes",
    ]
    if remote_url:
        lines.append(f"URL: {remote_url}")

    return "\n".join(lines)


def get_ai_response(user_message, profile, attachment=None):
    """Get response from Groq AI."""
    
    if not GROQ_AVAILABLE:
        return "Error: Groq not installed. Run: pip install groq"
    
    api_key = os.getenv('GROQ_API_KEY')
    if not api_key:
        return "Error: No Groq API key set. Please set GROQ_API_KEY environment variable."
    
    try:
        client = Groq(api_key=api_key)
        
        profile_text = format_profile_for_prompt(profile)
        attachment_text = format_attachment_for_prompt(attachment)

        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"User Profile:\n{profile_text}\n\n"
                    f"Attachment Metadata:\n{attachment_text}\n\n"
                    f"User Message: {user_message}"
                )
            }
        ]
        
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=messages,
            temperature=0.7,
            max_tokens=1000
        )
        
        return response.choices[0].message.content
        
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
        attachment = data.get('attachment')

        if not user_message and not attachment:
            return jsonify({'answer': 'Please send a message!'}), 400
        
        # Extract profile data from message
        updated_profile = extract_profile_data(user_message, current_profile)
        
        # Check if we have enough data for calculations
        has_data = all(k in updated_profile for k in ['weight_kg', 'height_cm', 'age'])
        
        # Get AI response
        ai_response = get_ai_response(user_message, updated_profile, attachment)
        
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
    api_key = os.getenv('GROQ_API_KEY', '')
    return jsonify({
        'status': 'healthy',
        'service': 'AI Coach - Groq',
        'api_key_configured': bool(api_key),
        'model': 'llama-3.1-8b-instant'
    })

if __name__ == '__main__':
    print("="*60)
    print("  ELITE FITNESS AI COACH - Groq (Blazing Fast)")
    print("="*60)
    
    api_key = os.getenv('GROQ_API_KEY', '')
    if api_key:
        print(f"  [OK] API Key: {api_key[:15]}...")
        print(f"  [Model] llama-3.1-8b-instant")
    else:
        print("  [ERROR] No API Key set!")
        print("  Set: GROQ_API_KEY=your_key_here")
    
    print("="*60)
    print("  Get API key: https://console.groq.com/keys")
    print("="*60)
    print()
    
    app.run(host='0.0.0.0', port=5001, debug=False, use_reloader=False)
