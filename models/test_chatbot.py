#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test script for AI Coach Chatbot
"""

import requests
import json
import sys

# Fix encoding for Windows
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

# Test messages
test_messages = [
    ("hi", "👋 Greeting Test"),
    ("وزني 70 و طولي 180 و عمري 25", "📊 Body Analysis Test"),
    ("plan", "🍽️ Meal Plan Test"),
]

url = "http://localhost:5000/chat"
profile = {}

print("=" * 60)
print("AI COACH CHATBOT TEST")
print("=" * 60)

for msg, desc in test_messages:
    print(f"\n{desc}")
    print(f"USER: {msg}")
    print("-" * 40)
    
    try:
        response = requests.post(
            url,
            json={"question": msg, "profile": profile},
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            answer = data.get('answer', 'No answer')
            
            print(f"AI:\n{answer}")
            print()
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"Error: {e}")

print("=" * 60)
print("TEST COMPLETE")
print("=" * 60)
