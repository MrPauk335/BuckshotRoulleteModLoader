import numpy as np
import json
import random
import os

class NeuralNetwork:
    def __init__(self, input_size=13, hidden_size=24, output_size=7):
        self.We = np.random.randn(input_size, hidden_size) * 0.1
        self.be = np.zeros((1, hidden_size))
        self.Wd = np.random.randn(hidden_size, output_size) * 0.1
        self.bd = np.zeros((1, output_size))

    def predict(self, inputs):
        x = np.array([inputs], dtype=float)
        h = np.maximum(0, np.dot(x, self.We) + self.be)
        out = np.dot(h, self.Wd) + self.bd
        return out

    def save(self, filename):
        data = {
            "We": self.We.tolist(),
            "be": self.be.tolist(),
            "Wd": self.Wd.tolist(),
            "bd": self.bd.tolist()
        }
        with open(filename, 'w') as f:
            json.dump(data, f)

    def load(self, filename):
        if os.path.exists(filename):
            with open(filename, 'r') as f:
                data = json.load(f)
                self.We = np.array(data['We'])
                self.be = np.array(data['be'])
                self.Wd = np.array(data['Wd'])
                self.bd = np.array(data['bd'])

class GameEnv:
    def __init__(self):
        self.reset()

    def reset(self):
        self.player_hp = 3
        self.dealer_hp = 3
        self.shells = ["live", "live", "blank", "blank"]
        random.shuffle(self.shells)
        self.current_turn = "player" # or "dealer"
        self.item_counts = {"beer": 0, "handcuffs": 0, "cigarettes": 0, "glass": 0, "saw": 0, "phone": 0}
        self.saw_active = 0
        self.opponent_jammed = 0
        return self.get_state()

    def get_state(self):
        live = self.shells.count("live")
        blank = self.shells.count("blank")
        return [
            float(self.dealer_hp),
            float(self.player_hp),
            float(live),
            float(blank),
            0.0, # padding
            float(self.saw_active),
            float(self.item_counts["beer"]),
            float(self.item_counts["handcuffs"]),
            float(self.item_counts["cigarettes"]),
            float(self.item_counts["glass"]),
            float(self.item_counts["saw"]),
            float(self.item_counts["phone"]),
            float(self.opponent_jammed)
        ]

    def step(self, action):
        # 0: shoot opp, 1: shoot self, 2: beer, 3: cuff, 4: cig, 5: glass, 6: saw
        # Simplified game logic for training/demo
        reward = 0
        done = False
        
        if action == 0: # Shoot Opponent
            shell = self.shells.pop(0) if self.shells else "blank"
            if shell == "live":
                dmg = 2 if self.saw_active else 1
                self.dealer_hp -= dmg
                reward = 10
            else:
                reward = -5
            self.saw_active = 0
        elif action == 1: # Shoot Self
            shell = self.shells.pop(0) if self.shells else "blank"
            if shell == "live":
                self.player_hp -= 1
                reward = -10
            else:
                reward = 5 # Blank to self gives extra turn? yes in Buckshot
            self.saw_active = 0
            
        if self.player_hp <= 0 or self.dealer_hp <= 0 or not self.shells:
            done = True
            
        return self.get_state(), reward, done

def main():
    print("Buckshot Roulette AI - Local MLP Environment")
    nn = NeuralNetwork()
    nn.load('ai_weights.json')
    
    env = GameEnv()
    state = env.reset()
    
    print("\nStarting Demo Match (AI vs Environment)...")
    done = False
    while not done:
        print(f"State: HP:{state[1]} vs {state[0]} | Shells: L:{state[2]} B:{state[3]}")
        out = nn.predict(state)
        action = np.argmax(out[0])
        print(f"AI chooses action: {action}")
        state, reward, done = env.step(action)
        
    print("Match Over.")

if __name__ == "__main__":
    main()
