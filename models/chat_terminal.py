#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI Coach Terminal Chat - Talk to the chatbot directly!
"""

import requests
import json

URL = "http://localhost:5000/chat"
profile = {}

print("=" * 60)
print("  AI COACH CHATBOT - TERMINAL MODE")
print("=" * 60)
print("  Commands:")
print("    'exit' or 'quit' - Stop chatting")
print("    'clear' - Clear profile memory")
print("    'profile' - Show current profile")
print("=" * 60)
print()

while True:
    # Get user input
    try:
        user_msg = input("You: ").strip()
    except KeyboardInterrupt:
        print("\n\nGoodbye!")
        break
    
    if not user_msg:
        continue
    
    # Check commands
    if user_msg.lower() in ['exit', 'quit', 'خروج', 'مع السلامة']:
        print("\nAI: مع السلامة! استمر في التمرين\n")
        break
    
    if user_msg.lower() == 'clear':
        profile = {}
        print("AI: Profile cleared!\n")
        continue
    
    if user_msg.lower() == 'profile':
        print(f"AI: Current profile: {json.dumps(profile, ensure_ascii=False, indent=2)}\n")
        continue
    
    # Send to server
    try:
        response = requests.post(
            URL,
            json={"question": user_msg, "profile": profile},
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            answer = data.get('answer', 'No answer')
            updated_profile = data.get('updated_profile')
            
            print(f"AI: {answer}\n")
            
            # Update profile if session ended
            if updated_profile:
                profile = updated_profile
                print(f"Profile saved: {json.dumps(profile, ensure_ascii=False)}\n")
        else:
            print(f"Error: {response.status_code}")
            print(f"Response: {response.text}\n")
            
    except requests.exceptions.ConnectionError:
        print("Connection failed!")
        print("Make sure the server is running:")
        print("   cd models && python ai_server_v2.py\n")
    except Exception as e:
        print(f"Error: {e}\n")
