import sys
import os
import json
from buckshot_ai import NeuralNetwork, GameEnv

def main():
    print("=== Buckshot Roulette AI Console ===")
    
    # Load weights
    weights_path = "ai_weights.json"
    if not os.path.exists(weights_path):
        print(f"Error: {weights_path} not found.")
        return

    with open(weights_path, 'r') as f:
        weights = json.load(f)

    nn = NeuralNetwork(input_size=13, hidden_size=64, output_size=7)
    nn.W_e = weights['We']
    nn.b_e = weights['be']
    nn.W_d = weights['Wd']
    nn.b_d = weights['bd']

    env = GameEnv()
    state = env.reset()

    while True:
        print(f"\nGame State: {state}")
        action = nn.get_action(state)
        action_names = ["Shoot Opponent", "Shoot Self", "Beer", "Cigarette", "Magnifier", "Sawn-off", "Heal"]
        print(f"AI suggests: {action_names[action]}")

        cmd = input("Press Enter to simulate step, or 'q' to quit: ")
        if cmd.lower() == 'q':
            break
        
        state, reward, done = env.step(action)
        if done:
            print("Game Over!")
            state = env.reset()

if __name__ == "__main__":
    main()
