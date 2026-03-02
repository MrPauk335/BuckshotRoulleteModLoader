import sys
import json
import numpy as np
import requests

def load_config():
    try:
        with open('ai_config.json', 'r') as f:
            return json.load(f)
    except:
        return {"use_api": False}

def load_weights():
    try:
        with open('ai_weights.json', 'r') as f:
            return json.load(f)
    except:
        return None

def softmax(x):
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=1, keepdims=True)

def predict_local(inputs, weights):
    # Convert inputs to numpy array
    x = np.array([inputs], dtype=float)
    
    # Hidden layer: relu(x * We + be)
    We = np.array(weights['We'])
    be = np.array(weights['be'])
    h = np.maximum(0, np.dot(x, We) + be)
    
    # Output layer: h * Wd + bd
    Wd = np.array(weights['Wd'])
    bd = np.array(weights['bd'])
    out = np.dot(h, Wd) + bd
    
    # Get action with highest value
    return int(np.argmax(out))

def predict_api(inputs, config):
    headers = {
        "Authorization": f"Bearer {config['api_key']}",
        "Content-Type": "application/json"
    }
    
    labels = ["Opponent Health", "Bot Health", "Live Shells", "Blank Shells", "Padding", "Saw Active", "Beer", "Handcuffs", "Cigarettes", "Magnifying Glass", "Handsaw", "Burner Phone", "Opponent Jammed"]
    state_str = ", ".join([f"{labels[i]}: {inputs[i]}" for i in range(len(inputs))])
    
    payload = {
        "model": config["model"],
        "messages": [
            {"role": "system", "content": config["system_prompt"]},
            {"role": "user", "content": f"Game state: {state_str}"}
        ]
    }
    
    try:
        response = requests.post(config["base_url"], headers=headers, json=payload, timeout=10)
        result = response.json()
        content = result['choices'][0]['message']['content'].strip()
        # Find the first integer in the response
        for s in content.split():
            if s.isdigit():
                return int(s)
        return 0
    except Exception as e:
        print(f"API Error: {e}", file=sys.stderr)
        return -1 # Fallback

def main():
    if len(sys.argv) < 14:
        # Default/Test mode
        inputs = [2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    else:
        inputs = [float(x) for x in sys.argv[1:14]]

    config = load_config()
    
    action = -1
    if config.get("use_api"):
        action = predict_api(inputs, config)
    
    # Fallback to local neural network if API fails or is disabled
    if action == -1:
        weights = load_weights()
        if weights:
            action = predict_local(inputs, weights)
        else:
            action = 0 # Ultimate fallback
            
    print(action)

if __name__ == "__main__":
    main()
