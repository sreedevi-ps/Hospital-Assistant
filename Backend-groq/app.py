import os
import json
import uuid
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from dotenv import load_dotenv
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = Flask(__name__)
CORS(app)

API_KEY = os.getenv("GROQ_API_KEY")
if not API_KEY:
    raise Exception("GROQ_API_KEY not found in .env")

# Static hospital data with related keys
HOSPITAL_DATA ={
    "bt_lab_location": {"related": ["second_flr", "left_wing"]},
    "ad_pharmacy": {"related": ["main_block", "near_reception"]},
    "kids_pharmacy": {"related": ["toy_corner", "children_section"]},
    "emergency_room": {"related": ["ground_flr", "ambulance_entry"]},
    "canteen_location": {"related": ["ground_flr", "parking_area"]},
    "ground_flr": {"related": ["near_reception", "emergency_room", "canteen_location", "main_lift"]},
    "first_flr": {"related": ["main_block"]},
    "second_flr": {"related": ["bt_lab_location", "left_wing"]},
    "main_block": {"related": ["near_reception", "ad_pharmacy", "main_lift"]},
    "near_reception": {"related": ["main_block", "ad_pharmacy", "main_lift"]},
    "toy_corner": {"related": ["kids_pharmacy", "children_section"]},
    "parking_area": {"related": ["canteen_location", "ground_flr"]},
    "ambulance_entry": {"related": ["emergency_room", "ground_flr"]},
    "left_wing": {"related": ["second_flr", "bt_lab_location"]},
    "children_section": {"related": ["kids_pharmacy", "toy_corner"]},
    "main_lift": {"related": ["main_block", "near_reception", "ground_flr"]},
    "unknown_request": {"related": []},

    # Newly added hospital-service keys
    "book_token_doctor": {"related": ["second_flr", "main_block"]},
    "need_token_doctor": {"related": ["second_flr", "main_block"]},
    "ml_token_request": {"related": ["second_flr", "main_block"]},
    "ta_token_request": {"related": ["second_flr", "main_block"]},
    "today_token_number": {"related": ["second_flr", "main_block"]},
    "reschedule_appointment": {"related": ["second_flr", "main_block"]},
    "available_doctors_now": {"related": ["second_flr", "main_block"]},
    "availability_suresh_nair": {"related": ["third_flr", "cardiology"]},
    "suggest_doctor_stomach_pain": {"related": ["second_flr", "gastroenterology"]},
    "emergency_duty_doctor": {"related": ["ground_flr", "emergency_room"]},
    "reach_priya_menon_room": {"related": ["second_flr", "room_212"]},
    "where_is_laboratory": {"related": ["ground_flr", "bt_lab_location"]},
    "guide_to_ot": {"related": ["fourth_flr", "ot_complex"]},
    "ta_how_to_pharmacy": {"related": ["ground_flr", "ad_pharmacy"]},
    "reach_lab": {"related": ["ground_flr", "bt_lab_location"]},
    "where_is_pharmacy": {"related": ["ground_flr", "ad_pharmacy"]},
    "availability_paracetamol": {"related": ["ground_flr", "ad_pharmacy"]},
    "deliver_medicines_rooms": {"related": ["ground_flr", "ad_pharmacy"]},
    "blood_test_results": {"related": ["ground_flr", "bt_lab_location"]},
    "where_xray": {"related": ["first_flr", "radiology"]},
    "mri_results_ready": {"related": ["second_flr", "radiology"]},
    "operation_time": {"related": ["fourth_flr", "ot_complex"]},
    "family_updates_during_surgery": {"related": ["fourth_flr", "surgical_waiting"]},
    "where_wait_before_ot": {"related": ["fourth_flr", "pre_op_waiting"]},
    "where_billing_counter": {"related": ["ground_flr", "billing"]},
    "accept_upi": {"related": ["ground_flr", "billing"]},
    "insurance_accepted": {"related": ["ground_flr", "billing"]},
    "where_wheelchair": {"related": ["ground_flr", "emergency_room"]},
    "where_canteen": {"related": ["ground_flr", "canteen_location"]},
    "visiting_hours": {"related": ["wards", "ICU"]},
    "emergency_help": {"related": ["ground_flr", "emergency_room"]},
    "call_nurse_assist": {"related": ["any_floor", "nurse_station"]},
    "dial_nurse_number": {"related": ["any_floor", "nurse_station"]}
}


# System role prompt
SYSTEM_PROMPT = ''' You are an intelligent, polite, and context-aware hospital assistant robot trained to help patients by identifying the type of hospital service or location they are asking about.
Your task is to interpret the patient's query and return the most relevant key from a predefined list.

IMPORTANT RULES:
- You must NEVER provide or infer any kind of medical advice, diagnosis, or treatment guidance.
- You are not allowed to generate free-form text, explanations, or suggestions.
- You must ALWAYS respond in *valid JSON format only* with the structure {"key": "<key>"}.
- If the query is about any external city, town, village, landmark, other hospital, or unrelated topic, ALWAYS use the fallback key "unknown_request".
- If the query is vague, unrelated, or you are unsure about the appropriate service, use "unknown_request".

YOUR OBJECTIVE:
From the patient’s query, determine which hospital service or location the query refers to (if any), and return the corresponding key.

VALID KEYS:
- bt_lab_location
- ad_pharmacy
- kids_pharmacy
- emergency_room
- canteen_location
- ground_flr
- first_flr
- second_flr
- main_block
- near_reception
- toy_corner
- parking_area
- ambulance_entry
- left_wing
- children_section
- main_lift
- book_token_doctor
- need_token_doctor
- ml_token_request
- ta_token_request
- today_token_number
- reschedule_appointment
- available_doctors_now
- availability_suresh_nair
- suggest_doctor_stomach_pain
- emergency_duty_doctor
- reach_priya_menon_room
- where_is_laboratory
- guide_to_ot
- ta_how_to_pharmacy
- reach_lab
- where_is_pharmacy
- availability_paracetamol
- deliver_medicines_rooms
- blood_test_results
- where_xray
- mri_results_ready
- operation_time
- family_updates_during_surgery
- where_wait_before_ot
- where_billing_counter
- accept_upi
- insurance_accepted
- where_wheelchair
- where_canteen
- visiting_hours
- emergency_help
- call_nurse_assist
- dial_nurse_number
- unknown_request

SPECIAL NOTE:
- If the query is about a city, town, external location (e.g., "Mundakkayam", "New Delhi", "home", "bus station", etc.), or anything outside this hospital, ALWAYS respond with: {"key": "unknown_request"}

RESPONSE FORMAT:
{
  "key": "<appropriate_key_from_above>"
}

EXAMPLES:
User: "Where can I collect my blood test report?"
→ Response: {"key": "bt_lab_location"}

User: "Can I get my son's medicine nearby?"
→ Response: {"key": "kids_pharmacy"}

User: "What are the symptoms of fever?"
→ Response: {"key": "unknown_request"}

User: "Where is the emergency department?"
→ Response: {"key": "emergency_room"}

User: "Is there a canteen here?"
→ Response: {"key": "canteen_location"}

User: "What's near the kids' pharmacy?"
→ Response: {"key": "toy_corner"}

User: "Where is the main elevator?"
→ Response: {"key": "main_lift"}

User: "How to go to Australlia?"
→ Response: {"key": "unknown_request"}

Be precise, consistent, and do not guess. Your job is only to classify the request and return the corresponding key.
'''


API_URL = "https://api.groq.com/openai/v1/chat/completions"
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

# Session Management
class SessionManager:
    def __init__(self):
        self.store = {}

    def get_session(self, session_id: str) -> dict:
        if session_id not in self.store:
            self.store[session_id] = {"last_key": None}
        return self.store[session_id]

    def update_session(self, session_id: str, key: str):
        session = self.get_session(session_id)
        session["last_key"] = key
        logger.info(f"Updated session {session_id}: last_key={key}")

    def reset_session(self, session_id: str) -> bool:
        if session_id in self.store:
            del self.store[session_id]
            logger.info(f"Reset session {session_id}")
            return True
        return False

session_manager = SessionManager()

@app.route('/query', methods=['POST'])
def handle_query():
    try:
        data = request.get_json(force=True)
        user_input = data.get("query", "").strip()
        session_id = data.get("session_id", str(uuid.uuid4()))
        logger.info(f"Processing query: {user_input}, session_id: {session_id}")

        session = session_manager.get_session(session_id)
        last_key = session.get("last_key")
        follow_up_keywords = ["എങ്ങനെ", "how to get", "how do i go", "directions", "path", "nearby", "close to", "next to"]

        # Handle follow-up queries
        if any(keyword in user_input.lower() for keyword in follow_up_keywords) and last_key:
            related_keys = HOSPITAL_DATA.get(last_key, HOSPITAL_DATA["unknown_request"])["related"]
            if related_keys:
                # Default to first related key for navigation/proximity
                selected_key = related_keys[0]
                # For specific follow-ups, query Groq with context
                if "nearby" in user_input.lower() or "close to" in user_input.lower() or "next to" in user_input.lower():
                    context = f"Last location: {last_key}. Related locations: {', '.join(related_keys)}."
                    payload = {
                        "model": "llama-3.1-8b-instant",
                        "messages": [
                            {"role": "system", "content": SYSTEM_PROMPT},
                            {"role": "user", "content": f"{context}\n{user_input}"}
                        ],
                        "temperature": 0,
                        "max_tokens": 50
                    }
                    response = requests.post(API_URL, json=payload, headers=HEADERS)
                    response.raise_for_status()
                    ai_reply = response.json()["choices"][0]["message"]["content"].strip()
                    try:
                        parsed_reply = json.loads(ai_reply)
                        selected_key = parsed_reply.get("key", related_keys[0])
                        if selected_key not in related_keys and selected_key != "unknown_request":
                            selected_key = related_keys[0]
                    except json.JSONDecodeError:
                        logger.error(f"Invalid JSON from AI: {ai_reply}")
                        selected_key = related_keys[0]
                session_manager.update_session(session_id, selected_key)
                response = {"key": selected_key}
                logger.info(f"Follow-up query, selected key: {selected_key}")
                return jsonify({
                    "session_id": session_id,
                    "response": response,
                    "timestamp": datetime.now().isoformat()
                })

        # Handle regular queries
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_input}
            ],
            "temperature": 0,
            "max_tokens": 50
        }

        response = requests.post(API_URL, json=payload, headers=HEADERS)
        response.raise_for_status()
        ai_reply = response.json()["choices"][0]["message"]["content"].strip()

        # Parse AI reply
        try:
            parsed_reply = json.loads(ai_reply)
            key = parsed_reply.get("key", "unknown_request")
            if key not in HOSPITAL_DATA:
                key = "unknown_request"
            session_manager.update_session(session_id, key)
            response = {"key": key}
            logger.info(f"AI reply: {ai_reply}, Parsed key: {key}")
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON from AI: {ai_reply}")
            response = {"key": "unknown_request"}

        return jsonify({
            "session_id": session_id,
            "response": response,
            "timestamp": datetime.now().isoformat()
        })

    except requests.exceptions.HTTPError as http_err:
        logger.error(f"HTTP error: {http_err}, Status: {response.status_code}, Body: {response.text}")
        return jsonify({
            "error": f"HTTP error occurred: {http_err}",
            "status_code": response.status_code,
            "response_body": response.text
        }), response.status_code

    except requests.exceptions.RequestException as req_err:
        logger.error(f"Request error: {req_err}")
        return jsonify({
            "error": f"Request error occurred: {req_err}"
        }), 503

    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return jsonify({
            "error": f"Unexpected error: {str(e)}"
        }), 500

@app.route('/reset_session', methods=['POST'])
def reset_session():
    try:
        session_id = request.get_json(force=True).get("session_id")
        if not session_id:
            return jsonify({"error": "Session ID required"}), 400
        success = session_manager.reset_session(session_id)
        return jsonify({"status": "Session reset" if success else "Session not found"})
    except Exception as e:
        logger.error(f"Error resetting session: {e}")
        return jsonify({"error": "Internal error"}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "timestamp": datetime.now().isoformat()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)