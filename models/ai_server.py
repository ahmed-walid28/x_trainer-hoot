#!/usr/bin/env python3
"""
Elite Fitness AI Coach - Simple Working Version
"""

import os
import re
from flask import Flask, request, jsonify
from flask_cors import CORS

try:
    import google.generativeai as genai
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False

app = Flask(__name__)
CORS(app)

def is_session_end(text):
    """Check if user is ending the session."""
    end_keywords = [
        'bye', 'goodbye', 'thanks', 'thank you', 'see you',
        'مع السلامة', 'شكراً', 'شكرا', 'باي', 'سلام',
        'talk later', 'later', 'see ya', 'خروج', 'مشي'
    ]
    lower_text = text.lower()
    return any(keyword in lower_text for keyword in end_keywords)

def get_ai_response(message, profile):
    """Generate AI response using Gemini or fallback."""
    lower_msg = message.lower()
    
    # Extract numbers from message - handle both Arabic and English formats
    # وزني 70 OR 70 kg OR وزن 80 كيلو
    weight_match = re.search(r'(?:وزني|وزن|weight|w)[\s:]*(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:ك|kg|كيلو)', message, re.IGNORECASE)
    # طولي 180 OR 180 cm OR طول 175 سم  
    height_match = re.search(r'(?:طولي|طول|height|h)[\s:]*(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:سم|cm)', message, re.IGNORECASE)
    # عمري 25 OR 25 سنة OR age 30
    age_match = re.search(r'(?:عمري|عمر|age)[\s:]*(\d+)|(\d+)\s*(?:سنة|سنه|years|year)', message, re.IGNORECASE)
    
    # Update profile from message - check both groups in regex
    if weight_match:
        weight_val = weight_match.group(1) if weight_match.group(1) else weight_match.group(2)
        if weight_val:
            profile['weight_kg'] = float(weight_val)
    if height_match:
        height_val = height_match.group(1) if height_match.group(1) else height_match.group(2)
        if height_val:
            profile['height_cm'] = float(height_val)
    if age_match:
        age_val = age_match.group(1) if age_match.group(1) else age_match.group(2)
        if age_val:
            profile['age'] = int(age_val)
    
    # Detect goal
    if any(word in lower_msg for word in ['تحجيم', 'تضخيم', 'bulking', 'bulk', 'اكبر']):
        profile['goal'] = 'bulking'
    elif any(word in lower_msg for word in ['تقطيع', 'تخسيس', 'cutting', 'cut', 'رشاقة', 'حرق']):
        profile['goal'] = 'cutting'
    
    # Greeting
    if any(word in lower_msg for word in ['hi', 'hello', 'مرحبا', 'أهلا', 'سلام', 'هاي']):
        return """أهلاً! أنا AI Coach بتاعك 💪

أقدر أساعدك في:
• حساب السعرات والماكروز
• عمل plan غذائي
• نصائح تمرين

قولي وزنك وطولك وهدفك (تحجيم/تقطيع) وهحسبلك كل حاجة!""", profile
    
    # Check if we have enough data for body analysis
    weight = profile.get('weight_kg')
    height = profile.get('height_cm')
    age = profile.get('age')
    goal = profile.get('goal', 'maintenance')
    
    if weight and height and age:
        # Calculate BMI
        bmi = weight / ((height/100) ** 2)
        
        # Calculate BMR (Mifflin-St Jeor)
        gender = profile.get('gender', 'male')
        if gender == 'female':
            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161
        else:
            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
        
        # Calculate TDEE (moderate activity)
        tdee = bmr * 1.55
        
        # Target calories
        if goal == 'bulking':
            target = tdee + 400
        elif goal == 'cutting':
            target = tdee - 500
        else:
            target = tdee
        
        # Save calculated values
        profile['calculated_bmr'] = round(bmr, 0)
        profile['calculated_tdee'] = round(tdee, 0)
        profile['calculated_target_kcal'] = round(target, 0)
        
        # Body analysis response
        if any(word in lower_msg for word in ['plan', 'أكل', 'وجبات', 'plan']):
            # Return meal plan
            return f"""┌─────────────────────────────────────────┐
│  DAILY MEAL PLAN — {target:.0f} kcal        │
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
│ TOTAL    │ ~{target:.0f} kcal | P:150g C:150g F:75g│
└──────────┴──────────────────────────────┘

💡 Tip: اشرب 3-4 لتر مياه يومياً!""", profile
        else:
            # Return body analysis
            return f"""┌─────────────────────────────────┐
│  BODY ANALYSIS CARD             │
├─────────────────────────────────┤
│  BMI        : {bmi:.1f}              │
│  BMR        : {bmr:.0f} kcal/day       │
│  TDEE       : {tdee:.0f} kcal/day       │
│  Goal       : {goal}             │
│  Target kcal: {target:.0f} kcal/day      │
└─────────────────────────────────┘

عايز تعمل plan للأكل؟ اكتب "plan" 👇

💡 Coach tip: لو هدفك {goal}، حاول تاخد 8 ساعات نوم يومياً!""", profile
    else:
        # Need more data
        return "أحتاج بياناتك الكاملة:\n• الوزن (كجم) - مثلاً: وزني 80 كيلو\n• الطول (سم) - مثلاً: طولي 180\n• العمر - مثلاً: عمري 25\n• الهدف (تحجيم/تقطيع/صيانة)\n\nقولي كل البيانات دي في رسالة واحدة!", profile

@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint."""
    try:
        data = request.get_json()
        user_message = data.get('question', '').strip()
        profile = data.get('profile', {})
        
        if not user_message:
            return jsonify({'answer': 'Please send a message!'}), 400
        
        # Get AI response
        answer, updated_profile = get_ai_response(user_message, profile)
        
        # Check if session ending
        session_ending = is_session_end(user_message)
        
        return jsonify({
            'answer': answer,
            'session_ended': session_ending,
            'updated_profile': updated_profile if session_ending else None
        })
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
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
    print("="*50)
    print("  ELITE FITNESS AI COACH SERVER")
    print("="*50)
    print("  Endpoints:")
    print("    POST /chat  - Main chat endpoint")
    print("    GET  /health - Health check")
    print("="*50)
    
    # Use Gemini if API key is set
    api_key = os.getenv('GOOGLE_API_KEY', '')
    if api_key and GENAI_AVAILABLE:
        print(f"  API Key: {api_key[:10]}...")
    else:
        print("  Running in FALLBACK mode (no AI)")
    print("="*50 + "\n")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
