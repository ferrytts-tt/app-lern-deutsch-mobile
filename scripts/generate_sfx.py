import math
import struct
import wave
import os

def generate_wav(filepath, duration_sec, sample_rate, generate_sample_fn):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    num_samples = int(duration_sec * sample_rate)
    
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        frames = bytearray()
        for i in range(num_samples):
            t = i / sample_rate
            sample = generate_sample_fn(t)
            # Clamp to [-1.0, 1.0]
            sample = max(-1.0, min(1.0, sample))
            int_sample = int(sample * 32767.0)
            frames.extend(struct.pack('<h', int_sample))
            
        wav_file.writeframes(frames)
    print(f"Generated: {filepath} ({duration_sec}s, {len(frames)} bytes)")

def note_tone(t, start_time, duration, freq, amp=0.8):
    if t < start_time or t > start_time + duration:
        return 0.0
    dt = t - start_time
    # Envelope: 8ms attack, exponential decay
    attack = min(1.0, dt / 0.008)
    decay = math.exp(-4.5 * (dt / duration))
    env = attack * decay * amp
    
    # Fundamental + harmonic overtones for rich, organic bell/marimba sound
    sig = (
        1.0 * math.sin(2.0 * math.pi * freq * dt) +
        0.35 * math.sin(2.0 * math.pi * 2.0 * freq * dt) +
        0.12 * math.sin(2.0 * math.pi * 3.0 * freq * dt)
    )
    return env * (sig / 1.47)

def main():
    sr = 44100
    
    # 1. Correct Sound (Duolingo-style joyous rising 4-note chime: C5, E5, G5, C6)
    def correct_sample(t):
        notes = [
            (0.00, 0.35, 523.25, 0.75),  # C5
            (0.08, 0.35, 659.25, 0.80),  # E5
            (0.16, 0.38, 783.99, 0.85),  # G5
            (0.24, 0.45, 1046.50, 0.95), # C6
        ]
        val = sum(note_tone(t, st, dur, freq, amp) for st, dur, freq, amp in notes)
        return val * 0.75

    # 2. Wrong Sound (Gentle, soft descending double-tone: Eb4 -> C4)
    def wrong_sample(t):
        notes = [
            (0.00, 0.22, 311.13, 0.75),  # Eb4
            (0.18, 0.32, 261.63, 0.85),  # C4
        ]
        val = sum(note_tone(t, st, dur, freq, amp) for st, dur, freq, amp in notes)
        return val * 0.75

    target_dir = os.path.join("assets", "audio", "sfx")
    generate_wav(os.path.join(target_dir, "correct.wav"), 0.70, sr, correct_sample)
    generate_wav(os.path.join(target_dir, "wrong.wav"), 0.52, sr, wrong_sample)

if __name__ == "__main__":
    main()
