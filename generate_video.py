"""
Fully automated PPT demo video generator.
1. Screenshots HTML slides via Playwright
2. Generates TTS narration via macOS `say`
3. Composes final video via FFmpeg
No API keys required.
"""
import subprocess, os, json, time, shutil

WORK = "/Users/kun/swap-lottery-hook"
OUT = f"{WORK}/video_output"
os.makedirs(f"{OUT}/slides", exist_ok=True)
os.makedirs(f"{OUT}/audio", exist_ok=True)

# ═══════════════════════════════════════
# SLIDE DATA — text content for each slide
# ═══════════════════════════════════════
slides = [
    {  # Slide 1 - Cover
        "title": "Swap Lottery Hook",
        "subtitle": "Make Every Swap a Winning Ticket",
        "tagline": "Uniswap V4 Hook  ×  Game Theory  ×  On-Chain Lottery Engine",
        "footer": "Hook the Future Hackathon  |  X Layer  ×  Uniswap  ×  Flap  |  May 2026",
    },
    {  # Slide 2 - Problem
        "title": "Why Existing Solutions Don't Work",
        "cards": [
            ("Static LP Fees", "Passive income. Zero incentive\nfor traders to return.\nPools bleed volume."),
            ("Points / Blind Mining", "Delayed gratification.\n3-6 month vesting.\nUser fatigue & PUA."),
            ("Dynamic Fee Hooks", "Protect LPs but drive\ntraders AWAY with higher\nfees during volatility."),
        ],
    },
    {  # Slide 3 - Core Mechanism
        "title": "Core Mechanism: The Lottery Flywheel",
        "steps": [
            ("0.01% Tax", "1 basis point from\nevery swap output.\nInvisible friction."),
            ("Dynamic N", "Pool small → fast trigger.\nPool large → anticipation.\nBounded [100, 200]."),
            ("Multi-Tier Prizes", "60% Grand Prize\n10 × 4% Consolation.\n'I was so close!'"),
            ("LPs Win Too", "Volume surge lifts\nall LP fee revenue\nabove traditional pools."),
        ],
        "formula": "N = 100 + 100 × poolSize / (poolSize + 100 ETH)   |   Range: [100, 200]",
    },
    {  # Slide 4 - LP Value
        "title": "LP Value: The Critical Defense",
        "left": ("Traditional Pool\n(0.3% static)", ["LP APR: 12% flat", "Volume: baseline", "Trader retention: zero"]),
        "right": ("Lottery Pool\n(0.3% + 0.01% ticket)", ["LP APR: 15-18%", "Volume: +22-35%", "Retention: high"]),
        "highlight": "When lottery multiplier > 1.2×, LP fee revenue beats static pools by 15-30%",
    },
    {  # Slide 5 - Randomness Ethics
        "title": "Randomness: Engineering Ethics",
        "left": ("Hackathon Demo\nPseudo-Random", [
            "keccak256(prevrandao\n+ timestamp + sender)",
            "✔ OK for testnet",
            "✘ Block builder risk",
        ]),
        "right": ("Production\nChainlink VRF", [
            "Verifiable\ncryptographic\nrandomness",
            "✔ Immune to manipulation",
            "✔ X Layer supported",
        ]),
        "position": "We deliver an honest MVP with clear boundaries. The path to production security is documented.",
    },
    {  # Slide 6 - Flywheel
        "title": "The Flywheel Endgame",
        "quadrants": [
            ("More Trades", "Next swap could\nbe the winner"),
            ("Bigger Prize Pool", "0.01% × volume\ncompounds"),
            ("LPs Earn More", "Volume surge\noutpaces dilution"),
            ("More LPs Join", "Higher APR →\ntighter spreads"),
        ],
    },
    {  # Slide 7 - Architecture
        "title": "Smart Contract Architecture",
        "flow": ["User\nSwaps", "beforeSwap\nSet Fee", "PoolManager\nSwap", "afterSwap\nLottery", "Claim\nTicket", "Check\nDraw"],
        "details": [
            "getDynamicN() → N ∈ [100, 200], psychology-driven curve",
            "_draw() → 60% grand + 10×4% consolation, pseudo-random pick",
            "_pay() → manager.take() to winner from hook balance",
        ],
    },
    {  # Slide 8 - Deployment
        "title": "Deployed on X Layer Testnet",
        "contracts": [
            ("PoolManager", "0x1248...70Ba1"),
            ("SwapLotteryHook", "0x2D78...90C4"),
            ("Test USDC", "0xC679...4D90"),
            ("Test WETH", "0x2400...9eBb"),
        ],
        "stats": "getDynamicN() = 100  |  getProgress() = (0, 100)  |  4/4 Tests Passed  |  Chain ID: 1952",
    },
    {  # Slide 9 - Roadmap
        "title": "Known Limitations & Production Roadmap",
        "limitations": [
            "Pseudo-random: block.prevrandao demo, Chainlink VRF production",
            "Single-currency tracking → dual-currency in v2",
            "10-loop consolation gas → batch payout optimization",
        ],
        "roadmap": [
            ("Wk 1-2", "Chainlink VRF integration"),
            ("Wk 3-4", "Dual-currency + batch payouts"),
            ("Mo 2", "Spearbit audit + mainnet beta"),
            ("Mo 3", "dApp + analytics + LP simulator"),
        ],
    },
    {  # Slide 10 - Closing
        "title": "Every Swap Is a Ticket.",
        "subtitle": "Every LP Is a Winner.",
        "tagline": "0.01% tax  ·  Dynamic-N psychology  ·  Multi-tier prizes  ·  LP value growth",
        "cta": "Deployed on X Layer Testnet",
    },
]

# ═══════════════════════════════════════
# NARRATION TEXT for each slide
# ═══════════════════════════════════════
narrations = [
    "Swap Lottery Hook. Turning every Uniswap V4 swap into a lottery ticket. Built for Hook the Future on X Layer.",
    "Traders flow through pools like water, swap once, never return. Static fees give them no reason to come back. Points programs delay gratification for months. Existing dynamic fee hooks protect LPs but drive traders away. We need a mechanism that rewards both sides.",
    "Here's the solution. 0.01 percent invisible tax on every swap output. Dynamic-N curve, when the prize pool is small, N is low, quick wins build hope. When it grows large, N rises, anticipation builds. Always bounded between 100 and 200. Multi-tier prizes, 60 percent grand prize, ten consolation winners at 4 percent each. That I was so close effect keeps people swapping.",
    "The number one question, doesn't this dilute LP returns? No. In simulation, when the lottery multiplier exceeds 1.2x, LP fee revenue beats traditional pools by 15 to 30 percent. The volume surge from lottery-driven trading more than compensates. The 0.01 percent tax is a growth investment, not a cost.",
    "We are honest about our boundaries. The hackathon demo uses pseudo-random from block.prevrandao, good enough for testnet, not for mainnet. Production would integrate Chainlink VRF for cryptographically verifiable randomness. X Layer natively supports these oracle networks. We know where the line is, and we draw it clearly.",
    "This creates a compounding flywheel. More trades grow the prize pool. Bigger prizes attract more traders. Higher volume generates more LP fees. Better returns attract more liquidity. Tighter spreads bring even more traders. A self-reinforcing loop.",
    "The entire hook is 7.6 kilobytes of Solidity. beforeSwap sets the dynamic fee, PoolManager executes the swap, afterSwap runs the lottery logic. Clean, auditable, on-chain.",
    "Deployed on X Layer testnet with verifiable contract addresses. PoolManager, test tokens, and the SwapLotteryHook are all live. Four out of four tests passing. Every callback traceable on-chain.",
    "We know what needs to improve. Pseudo-random goes to Chainlink VRF. Single-currency tracking splits into dual-currency. The ten-loop consolation draw gets batch optimization. And we have a clear four-stage roadmap from audit to mainnet beta to full dApp launch.",
    "Swap Lottery Hook. Every swap is a ticket. Every LP is a winner. Thank you.",
]

# ═══════════════════════════════════════
# STEP 1: Generate slide images via HTML + Playwright
# ═══════════════════════════════════════
print("Generating slide images via Playwright...")

# Build HTML
def build_card_html(color_class, title, body):
    color_map = {"purple": "#A76BFF", "blue": "#5EB0FF", "cyan": "#00E4CC", "green": "#34D399", "amber": "#FFB627"}
    c = color_map.get(color_class, "#A76BFF")
    return f'''<div class="card"><div class="accent" style="background:{c}"></div><h3>{title}</h3><p>{body}</p></div>'''

html_parts = []
for i, s in enumerate(slides):
    content = ""
    if i == 0:
        content = f'''
        <div class="cover">
            <h1>{s["title"]}</h1>
            <h2>{s["subtitle"]}</h2>
            <p class="tag">{s["tagline"]}</p>
            <p class="footer-text">{s["footer"]}</p>
        </div>'''
    elif i == 1:
        cards = "".join([build_card_html(["purple","blue","cyan"][j], c[0], c[1].replace('\n','<br>')) for j,c in enumerate(s["cards"])])
        content = f'<h1 class="page-title">{s["title"]}</h1><div class="card-row">{cards}</div>'
    elif i == 2:
        steps = "".join([build_card_html(["purple","blue","cyan","green"][j], c[0], c[1].replace('\n','<br>')) for j,c in enumerate(s["steps"])])
        content = f'<h1 class="page-title">{s["title"]}</h1><div class="step-row">{steps}</div><div class="formula-box">{s["formula"]}</div>'
    elif i == 3:
        content = f'''
        <h1 class="page-title">{s["title"]}</h1>
        <div class="compare-row">
            <div class="compare-card bad"><h3>{s["left"][0].replace(chr(10),'<br>')}</h3>{"".join(f'<p>✘ {l}</p>' for l in s["left"][1])}</div>
            <div class="compare-card good"><h3>{s["right"][0].replace(chr(10),'<br>')}</h3>{"".join(f'<p>✔ {l}</p>' for l in s["right"][1])}</div>
        </div>
        <div class="highlight-box">{s["highlight"]}</div>'''
    elif i == 4:
        content = f'''
        <h1 class="page-title">{s["title"]}</h1>
        <div class="compare-row">
            <div class="compare-card warn"><h3>{s["left"][0].replace(chr(10),'<br>')}</h3>{"".join(f'<p>{l.replace(chr(10),"<br>")}</p>' for l in s["left"][1])}</div>
            <div class="compare-card good"><h3>{s["right"][0].replace(chr(10),'<br>')}</h3>{"".join(f'<p>{l.replace(chr(10),"<br>")}</p>' for l in s["right"][1])}</div>
        </div>
        <div class="position-box">{s["position"]}</div>'''
    elif i == 5:
        cards = "".join([f'<div class="quad-card"><div class="q-accent"></div><h3>{q[0]}</h3><p>{q[1].replace(chr(10),"<br>")}</p></div>' for q in s["quadrants"]])
        content = f'<h1 class="page-title">{s["title"]}</h1><div class="quad-grid">{cards}</div><div class="center-label">Compound<br>Growth</div>'
    elif i == 6:
        steps_html = "".join([f'<div class="flow-step">{f.replace(chr(10),"<br>")}</div>' for f in s["flow"]])
        details = "".join([f'<p class="detail">▸ {d}</p>' for d in s["details"]])
        content = f'<h1 class="page-title">{s["title"]}</h1><div class="flow-row">{steps_html}</div><div class="details-box">{details}</div>'
    elif i == 7:
        rows = "".join([f'<div class="addr-row"><span class="addr-label">{c[0]}</span><span class="addr-val">{c[1]}</span></div>' for c in s["contracts"]])
        content = f'<h1 class="page-title">{s["title"]}</h1><div class="addr-table">{rows}</div><div class="stats-box">{s["stats"]}</div>'
    elif i == 8:
        lims = "".join([f'<p class="lim">• {l}</p>' for l in s["limitations"]])
        rds = "".join([f'<div class="rd-row"><span class="rd-time">{r[0]}</span><span class="rd-desc">{r[1]}</span></div>' for r in s["roadmap"]])
        content = f'<h1 class="page-title">{s["title"]}</h1><div class="two-col"><div class="col"><h3 style="color:#FFB627">Limitations</h3>{lims}</div><div class="col"><h3 style="color:#34D399">Roadmap</h3>{rds}</div></div>'
    elif i == 9:
        content = f'''
        <div class="cover">
            <h1>{s["title"]}</h1>
            <h2>{s["subtitle"]}</h2>
            <p class="tag">{s["tagline"]}</p>
            <div class="cta-box">{s["cta"]}</div>
        </div>'''

    html_parts.append(f'''<div class="slide" id="slide{i}">{content}<div class="page-num">{i+1}/10</div></div>''')

html = f'''<!DOCTYPE html><html><head><meta charset="utf-8"><style>
*{{margin:0;padding:0;box-sizing:border-box}}
body{{background:#0A0A12;color:#EDEDF4;font-family:-apple-system,BlinkMacSystemFont,"Inter",sans-serif}}
.slide{{width:1280px;height:720px;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden}}
.slide::before{{content:"";position:absolute;top:0;left:0;right:0;height:4px;background:linear-gradient(90deg,#A76BFF,#5EB0FF,#00E4CC)}}
.page-num{{position:absolute;bottom:16px;right:24px;font-size:12px;color:#888A9A}}
.cover{{text-align:center;z-index:1}}
.cover h1{{font-size:64px;font-weight:800;background:linear-gradient(135deg,#A76BFF,#5EB0FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:12px}}
.cover h2{{font-size:36px;color:#EDEDF4;font-weight:600;margin-bottom:16px}}
.tag{{font-size:18px;color:#888A9A;margin-bottom:8px}}
.footer-text{{font-size:14px;color:#5EB0FF}}
.page-title{{position:absolute;top:28px;left:48px;font-size:32px;font-weight:700;color:#EDEDF4}}
.card-row,.step-row{{display:flex;gap:24px;position:absolute;top:110px;left:48px;right:48px}}
.card,.quad-card{{background:#141422;border-radius:12px;padding:24px;flex:1;position:relative}}
.accent{{position:absolute;left:0;top:16px;bottom:16px;width:4px;border-radius:2px}}
.card h3,.quad-card h3{{font-size:18px;margin-bottom:10px;margin-left:12px}}
.card p,.quad-card p{{font-size:14px;color:#888A9A;line-height:1.6;margin-left:12px}}
.formula-box{{position:absolute;bottom:60px;left:48px;right:48px;background:#141422;border:1px solid #2A2A38;border-radius:10px;padding:18px 28px;text-align:center;font-size:18px;color:#00E4CC;font-family:monospace}}
.compare-row{{display:flex;gap:32px;position:absolute;top:110px;left:48px;right:48px}}
.compare-card{{flex:1;border-radius:12px;padding:28px}}
.compare-card.bad{{background:#141422;border:2px solid #2A1A1A}}
.compare-card.good{{background:#141422;border:2px solid #1A2A1A}}
.compare-card.warn{{background:#141422;border:2px solid #2A2A1A}}
.compare-card h3{{font-size:20px;margin-bottom:16px;line-height:1.4}}
.compare-card.bad h3{{color:#FF5E7A}}
.compare-card.good h3{{color:#34D399}}
.compare-card.warn h3{{color:#FFB627}}
.compare-card p{{font-size:15px;color:#888A9A;margin-bottom:8px;line-height:1.5}}
.highlight-box,.position-box,.stats-box{{position:absolute;bottom:60px;left:48px;right:48px;background:#141422;border-radius:10px;padding:18px 28px;text-align:center;font-size:16px;color:#00E4CC}}
.position-box{{color:#888A9A;font-size:14px}}
.quad-grid{{display:grid;grid-template-columns:1fr 1fr;gap:24px;position:absolute;top:110px;left:48px;right:48px;bottom:60px}}
.quad-card{{border-left:4px solid #A76BFF;min-height:140px;display:flex;flex-direction:column;justify-content:center}}
.q-accent{{display:none}}
.center-label{{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);font-size:28px;font-weight:800;text-align:center;color:#EDEDF4;z-index:2;text-shadow:0 0 30px rgba(167,107,255,0.5)}}
.flow-row{{display:flex;gap:12px;position:absolute;top:110px;left:48px;right:48px}}
.flow-step{{flex:1;background:#141422;border-radius:10px;padding:20px 10px;text-align:center;font-size:14px;color:#EDEDF4;font-weight:600;line-height:1.5;border-top:3px solid #A76BFF}}
.details-box{{position:absolute;bottom:80px;left:48px;right:48px}}
.detail{{font-size:14px;color:#888A9A;margin-bottom:6px;font-family:monospace}}
.addr-table{{position:absolute;top:130px;left:80px;right:80px;display:flex;flex-direction:column;gap:14px}}
.addr-row{{display:flex;background:#141422;border-radius:8px;padding:16px 24px;align-items:center}}
.addr-label{{font-size:16px;font-weight:700;min-width:180px;color:#A76BFF}}
.addr-val{{font-size:14px;color:#888A9A;font-family:monospace}}
.two-col{{display:flex;gap:40px;position:absolute;top:110px;left:48px;right:48px;bottom:60px}}
.col{{flex:1}}
.col h3{{font-size:20px;margin-bottom:18px}}
.lim{{font-size:14px;color:#888A9A;margin-bottom:10px;line-height:1.5}}
.rd-row{{display:flex;margin-bottom:10px;align-items:baseline;gap:12px}}
.rd-time{{font-size:13px;color:#00E4CC;font-weight:700;min-width:50px;font-family:monospace}}
.rd-desc{{font-size:14px;color:#888A9A}}
.cta-box{{margin-top:20px;background:#A76BFF;display:inline-block;padding:14px 32px;border-radius:30px;font-size:16px;font-weight:600;color:#EDEDF4}}
</style></head><body>{"".join(html_parts)}</body></html>'''

html_path = f"{WORK}/slides.html"
with open(html_path, "w") as f:
    f.write(html)
print(f"HTML saved: {html_path}")

# Screenshot each slide via Playwright
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    page.goto(f"file://{html_path}")
    page.wait_for_timeout(1000)

    for i in range(10):
        slide_el = page.query_selector(f"#slide{i}")
        if slide_el:
            path = f"{OUT}/slides/slide-{i+1:02d}.png"
            slide_el.screenshot(path=path)
            print(f"  Screenshot: slide-{i+1:02d}.png")
    browser.close()

# ═══════════════════════════════════════
# STEP 2: Generate TTS audio via macOS `say`
# ═══════════════════════════════════════
print("\nGenerating TTS narration...")
for i, text in enumerate(narrations):
    path = f"{OUT}/audio/narration-{i+1:02d}.aiff"
    subprocess.run(["say", "-v", "Daniel", "-r", "220", "-o", path, text], check=True)
    print(f"  Audio: narration-{i+1:02d}.aiff")

# ═══════════════════════════════════════
# STEP 3: Compose video via FFmpeg (segment-by-segment then concat)
# ═══════════════════════════════════════
print("\nComposing video segments...")

segments = []
for i in range(10):
    img = f"{OUT}/slides/slide-{i+1:02d}.png"
    aud = f"{OUT}/audio/narration-{i+1:02d}.aiff"
    seg = f"{OUT}/segment-{i+1:02d}.mp4"

    # Get audio duration
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "csv=p=0", aud], capture_output=True, text=True
    )
    duration = float(result.stdout.strip())
    total_dur = duration + 0.6

    # Create single segment: still image + audio, then pad silence at end
    subprocess.run([
        "ffmpeg", "-y",
        "-loop", "1", "-i", img,
        "-i", aud,
        "-c:v", "libx264", "-tune", "stillimage", "-preset", "fast",
        "-c:a", "aac", "-b:a", "128k",
        "-pix_fmt", "yuv420p",
        "-shortest",
        "-t", str(duration),
        seg
    ], check=True, capture_output=True)
    segments.append(seg)
    print(f"  Segment {i+1}/10: {duration:.1f}s")

# ═══════════════════════════════════════
# STEP 4: Concatenate all segments
# ═══════════════════════════════════════
print("\nConcatenating...")
concat_list = f"{OUT}/segments.txt"
with open(concat_list, "w") as f:
    for seg in segments:
        f.write(f"file '{seg}'\n")

subprocess.run([
    "ffmpeg", "-y",
    "-f", "concat", "-safe", "0",
    "-i", concat_list,
    "-c", "copy",
    f"{OUT}/demo_video.mp4"
], check=True)

# Cleanup segments
for seg in segments:
    os.remove(seg)
os.remove(concat_list)

print(f"\n✅ Video saved: {OUT}/demo_video.mp4")
